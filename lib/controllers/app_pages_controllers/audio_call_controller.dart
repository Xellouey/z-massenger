import 'dart:async';
import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../config.dart';
import '../../models/call_model.dart';
import '../common_controllers/firebase_common_controller.dart';

class AudioCallController extends GetxController {
  String? channelName, token;
  Call? call;
  bool localUserJoined = false;
  bool isSpeaker = true, switchCamera = false;
  late RtcEngine engine;
  final _infoStrings = <String>[];
  Stream<int>? timerStream;
  int? remoteUId;
  Timer? timer;

  // ignore: cancel_subscriptions
  StreamSubscription<int>? timerSubscription;
  bool muted = false;
  final _users = <int>[];
  bool isAlreadyEnded = false;
  ClientRoleType? role;
  dynamic userData;
  Stream<DocumentSnapshot>? stream;
  audio_players.AudioPlayer? player;
  AudioCache audioCache = AudioCache();
  int? remoteUidValue;
  bool isStart = false;
  bool _hasClosedCallView = false;
  bool _isEnding = false;

  // ignore: close_sinks
  StreamController<int>? streamController;
  String hoursStr = '00';
  String minutesStr = '00';
  String secondsStr = '00';
  int counter = 0;

  // Добавить участника в звонок
  void onAddParticipant() async {
    log("AudioCallController: onAddParticipant called");
    if (call == null) {
      log("Error: Call data is null");
      return;
    }
    
    log("Current call data: ${call!.toMap(call!)}");
    log("Channel name: $channelName");
    log("User ID: ${userData?['id']}");
    log("Is group: ${call?.isGroup}");
    
    // Проверяем, является ли звонок групповым
    if (call!.isGroup == true) {
      log("This is already a group call");
      // Переходим на экран выбора участников для группового звонка
      _navigateToAddParticipants();
    } else {
      log("Converting 1-to-1 call to group call");
      // Преобразуем обычный звонок в групповой
      await _convertToGroupCall();
    }
  }
  
  // Навигация на экран добавления участников
  void _navigateToAddParticipants() {
    // Подготовка данных для экрана добавления участников
    List<dynamic> existingParticipants = [];
    
    // Добавляем текущих участников звонка
    if (call!.callerId != null) {
      existingParticipants.add({
        'id': call!.callerId,
        'name': call!.callerName,
        'image': call!.callerPic,
      });
    }
    
    if (call!.receiverId != null && call!.receiverId != call!.callerId) {
      existingParticipants.add({
        'id': call!.receiverId,
        'name': call!.receiverName,
        'image': call!.receiverPic,
      });
    }
    
    log("Existing participants: $existingParticipants");
    
    // Переходим на экран выбора контактов
    Get.toNamed(
      routeName.addParticipants,
      arguments: {
        'exitsUser': existingParticipants,
        'groupId': channelName, // используем channelId как groupId для звонка
        'isGroup': true,
        'isCall': true, // флаг что это звонок, а не группа
        'channelName': channelName,
        'agoraToken': call!.agoraToken,
        'currentCall': call,
      },
    )?.then((result) {
      if (result != null && result is List) {
        log("Selected participants: $result");
        _addSelectedParticipantsToCall(result);
      }
    });
  }
  
  // Преобразование обычного звонка в групповой
  Future<void> _convertToGroupCall() async {
    try {
      log("Starting conversion to group call");
      
      // Обновляем модель звонка
      call!.isGroup = true;
      call!.groupName = "${call!.callerName}, ${call!.receiverName}";
      
      // Обновляем Firebase
      await FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(call!.callerId)
          .collection(collectionName.calling)
          .where('channelId', isEqualTo: channelName)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'isGroup': true,
            'groupName': call!.groupName,
          });
        }
      });
      
      await FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(call!.receiverId)
          .collection(collectionName.calling)
          .where('channelId', isEqualTo: channelName)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({
            'isGroup': true,
            'groupName': call!.groupName,
          });
        }
      });
      
      update();
      
      log("Converted to group call successfully");
      
      // Теперь открываем экран добавления участников
      _navigateToAddParticipants();
      
    } catch (e) {
      log("Error converting to group call: $e");
      Get.snackbar(
        'Error',
        'Failed to add participant. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Добавление выбранных участников в звонок
  Future<void> _addSelectedParticipantsToCall(List<dynamic> newParticipants) async {
    try {
      log("Adding ${newParticipants.length} new participants to call");
      
      for (var participant in newParticipants) {
        log("Adding participant: ${participant['name']}");
        
        // Получаем данные участника из Firebase
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection(collectionName.users)
            .doc(participant['id'])
            .get();
        
        if (!userDoc.exists) {
          log("User ${participant['id']} not found");
          continue;
        }
        
        Map<String, dynamic> userDataparticipant = userDoc.data() as Map<String, dynamic>;
        
        // Создаем звонок для нового участника
        Call newParticipantCall = Call(
          timestamp: call!.timestamp,
          callerId: call!.callerId,
          callerName: call!.callerName,
          callerPic: call!.callerPic,
          receiverId: participant['id'],
          receiverName: userDataparticipant['name'],
          receiverPic: userDataparticipant['image'],
          callerToken: call!.callerToken,
          receiverToken: userDataparticipant['pushToken'],
          channelId: channelName,
          isVideoCall: call!.isVideoCall,
          isGroup: true,
          groupName: call!.groupName,
          agoraToken: call!.agoraToken,
        );
        
        // Добавляем звонок в Firebase для нового участника
        await FirebaseFirestore.instance
            .collection(collectionName.calls)
            .doc(participant['id'])
            .collection(collectionName.calling)
            .add({
          'timestamp': call!.timestamp,
          'callerId': call!.callerId,
          'callerName': call!.callerName,
          'callerPic': call!.callerPic,
          'receiverId': participant['id'],
          'receiverName': userDataparticipant['name'],
          'receiverPic': userDataparticipant['image'],
          'callerToken': call!.callerToken,
          'receiverToken': userDataparticipant['pushToken'],
          'hasDialled': false,
          'channelId': channelName,
          'agoraToken': call!.agoraToken,
          'isGroup': true,
          'groupName': call!.groupName,
          'isVideoCall': call!.isVideoCall,
        });
        
        // Отправляем push-уведомление новому участнику
        final firebaseCtrl = Get.isRegistered<FirebaseCommonController>()
            ? Get.find<FirebaseCommonController>()
            : Get.put(FirebaseCommonController());
        await firebaseCtrl.sendNotification(
          notificationType: 'call',
          title: call!.isVideoCall == true 
              ? "Incoming Video Call..." 
              : "Incoming Audio Call...",
          msg: "${call!.callerName} added you to ${call!.isVideoCall == true ? 'video' : 'audio'} call",
          token: userDataparticipant['pushToken'],
          pName: call!.callerName,
          image: call!.callerPic,
          dataTitle: call!.callerName,
        );
        
        log("Successfully added participant: ${participant['name']}");
      }
      
      Get.snackbar(
        'Success',
        '${newParticipants.length} participant(s) added to call',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appCtrl.appTheme.online,
        colorText: appCtrl.appTheme.sameWhite,
      );
      
      update();
      
    } catch (e) {
      log("Error adding participants to call: $e");
      Get.snackbar(
        'Error',
        'Failed to add participants. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void stopTimer() {
    if (!isStart) return;

    timer?.cancel();
    counter = 0;
    isStart = false;
    update();
  }

  String getFormattedTime() {
    int hours = counter ~/ 3600;
    int minutes = (counter % 3600) ~/ 60;
    int seconds = counter % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await engine.leaveChannel();
    await engine.release();
    stopTimer();
  }

  void _closeCallView(BuildContext? context) {
    if (_hasClosedCallView) return;

    final navigatorContext = context ?? Get.context;
    if (navigatorContext != null && Navigator.of(navigatorContext).canPop()) {
      Navigator.of(navigatorContext).pop();
      _hasClosedCallView = true;
      return;
    }

    if (Get.isOverlaysOpen || (Get.key.currentState?.canPop() ?? false)) {
      Get.back();
      _hasClosedCallView = true;
    }
  }

  @override
  void onReady() async {
    // TODO: implement onReady

    super.onReady();
  }

  Future<bool> onWillPopNEw() {
    return Future.value(false);
  }

  //start time count
  startTimerNow() {
    log("isStart :$isStart");
    if (isStart) return;

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      counter++;
      log("START :$counter");
      update();
    });

    isStart = true;
    update();
    Get.forceAppUpdate();
  }

  //initialise agora
  Future<void> initAgora() async {
    _isEnding = false;
    _hasClosedCallView = false;
    var agora = appCtrl.storage.read(session.agoraToken);
    //create the engine
    engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(
      appId: agora['agoraAppId'],
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    log("agora['agoraAppId']${agora['agoraAppId']}");

    update();
    log("INITIALIZE AGORA");
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user dfdhfg ${connection.localUid} joined");
          localUserJoined = true;
          log("userData['id']::${userData["id"]}");
          if (call!.callerId == userData["id"]) {
            update();
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'type': 'OUTGOING',
              'isVideoCall': call!.isVideoCall,
              'id': call!.receiverId,
              'timestamp': call!.timestamp,
              'dp': call!.receiverPic,
              'isMuted': false,
              'receiverId': call!.receiverId,
              'isJoin': false,
              'status': 'calling',
              'started': null,
              "isGroup": call!.isGroup,
              "groupName": call!.groupName,
              'ended': null,
              'callerName': call!.receiverName,
            }, SetOptions(merge: true));
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.receiverId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'type': 'INCOMING',
              'isVideoCall': call!.isVideoCall,
              'id': call!.callerId,
              'timestamp': call!.timestamp,
              'dp': call!.callerPic,
              'isMuted': false,
              'receiverId': call!.receiverId,
              'isJoin': true,
              'status': 'missedCall',
              "isGroup": call!.isGroup,
              "groupName": call!.groupName,
              'started': null,
              'ended': null,
              'callerName': call!.callerName,
            }, SetOptions(merge: true));
          }
          WakelockPlus.enable();
          //flutterLocalNotificationsPlugin!.cancelAll();
          update();
          Get.forceAppUpdate();
        },
        onError: (err, msg) {
          log("ERROORRR : $err");
          log("ERROORRR : $msg");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          remoteUidValue = remoteUid;
          remoteUId = remoteUid;
          startTimerNow();
          update();

          debugPrint("remote user $remoteUidValue joined");
          if (userData["id"] == call!.callerId) {
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'started': DateTime.now(),
              'status': 'pickedUp',
              'isJoin': true,
            }, SetOptions(merge: true));
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.receiverId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'started': DateTime.now(),
              'status': 'pickedUp',
            }, SetOptions(merge: true));
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .set({
              "audioCallMade": FieldValue.increment(1),
            }, SetOptions(merge: true));
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.receiverId)
                .set({
              "audioCallReceived": FieldValue.increment(1),
            }, SetOptions(merge: true));
          }
          WakelockPlus.enable();
          update();
          Get.forceAppUpdate();
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) async {
          debugPrint("remote user $remoteUid left channel");
          remoteUid = 0;

          final info = 'userOffline: $remoteUid';
          _infoStrings.add(info);
          _users.remove(remoteUid);
          update();

          if (Get.context != null && !isAlreadyEnded) {
            isAlreadyEnded = true;
            await onCallEnd(Get.context!);
            return;
          }

          if (isAlreadyEnded == false) {
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'status': 'ended',
              'ended': DateTime.now(),
            }, SetOptions(merge: true));

            // Обработка групповых звонков
            if (call!.receiver != null) {
              List receiver = call!.receiver!;
              receiver.asMap().entries.forEach((element) {
                if (element.value["id"] != userData["id"]) {
                  FirebaseFirestore.instance
                      .collection(collectionName.calls)
                      .doc(element.value["id"])
                      .collection(collectionName.collectionCallHistory)
                      .doc(call!.timestamp.toString())
                      .set({
                    'status': 'ended',
                    'ended': DateTime.now(),
                  }, SetOptions(merge: true));
                }
              });
            } else {
              // Обычный звонок один-на-один
              FirebaseFirestore.instance
                  .collection(collectionName.calls)
                  .doc(call!.receiverId)
                  .collection(collectionName.collectionCallHistory)
                  .doc(call!.timestamp.toString())
                  .set({
                'status': 'ended',
                'ended': DateTime.now(),
              }, SetOptions(merge: true));
            }
          }
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          log("token::: $token");
        },
        onLeaveChannel: (connection, stats) {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
          _dispose();
          update();
          if (isAlreadyEnded == false) {
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'status': 'ended',
              'ended': DateTime.now(),
            }, SetOptions(merge: true));

            // Обработка групповых звонков
            if (call!.receiver != null) {
              List receiver = call!.receiver!;
              receiver.asMap().entries.forEach((element) {
                if (element.value["id"] != userData["id"]) {
                  FirebaseFirestore.instance
                      .collection(collectionName.calls)
                      .doc(element.value["id"])
                      .collection(collectionName.collectionCallHistory)
                      .doc(call!.timestamp.toString())
                      .set({
                    'status': 'ended',
                    'ended': DateTime.now(),
                  }, SetOptions(merge: true));
                }
              });
            } else {
              // Обычный звонок один-на-один
              FirebaseFirestore.instance
                  .collection(collectionName.calls)
                  .doc(call!.receiverId)
                  .collection(collectionName.collectionCallHistory)
                  .doc(call!.timestamp.toString())
                  .set({
                'status': 'ended',
                'ended': DateTime.now(),
              }, SetOptions(merge: true));
            }
          }
          WakelockPlus.disable();
          _closeCallView(Get.context);
          update();
        },
      ),
    );
    update();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.startPreview();
    await engine.joinChannel(
      token: call!.agoraToken!,
      channelId: channelName!,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
    update();
    update();
    Get.forceAppUpdate();
  }

  //speaker mute - unMute
  void onToggleSpeaker() {
    isSpeaker = !isSpeaker;
    update();
    engine.setEnableSpeakerphone(isSpeaker);
  }

  //firebase mute un Mute
  void onToggleMute() {
    muted = !muted;
    update();

    engine.muteLocalAudioStream(muted);
    FirebaseFirestore.instance
        .collection(collectionName.calls)
        .doc(userData["id"])
        .collection(collectionName.collectionCallHistory)
        .doc(call!.timestamp.toString())
        .set({'isMuted': muted}, SetOptions(merge: true));
  }

  //bottom tool bar
  Widget toolbar(
      bool isShowSpeaker,
      String? status,
      ) {
    if (role == ClientRoleType.clientRoleAudience) return Container();
    /* return AudioToolBar(
      status: status,
      isShowSpeaker: isShowSpeaker,
    );*/

    return Container();
  }

  //end call and remove
  Future<bool> endCall({required Call call}) async {
    try {

      FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(call.callerId)
          .collection(collectionName.calling)
          .where("callerId", isEqualTo: call.callerId)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.calls)
              .doc(call.callerId)
              .collection("calling")
              .doc(value.docs[0].id)
              .delete();
          log("DFFFF:${value.docs[0].id}");
        }
      });
      FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(call.receiverId)
          .collection(collectionName.calling)
          .where("receiverId", isEqualTo: call.receiverId)
          .get()
          .then((value) {
        if (value.docs.isNotEmpty) {
          FirebaseFirestore.instance
              .collection(collectionName.calls)
              .doc(call.receiverId)
              .collection("calling")
              .doc(value.docs[0].id)
              .delete();
          log("DDDDDDDDDDDDD:${value.docs[0].id}");

        }
      });
      return true;
    } catch (e) {
      log("error : $e");
      return false;
    }
  }

  //end call
  void onCallEnd(BuildContext context) async {
    if (_isEnding) {
      _closeCallView(context);
      return;
    }

    _isEnding = true;
    isAlreadyEnded = true;
    log("endCall1");
    await _dispose();
    _closeCallView(context);
    DateTime now = DateTime.now();
    if (remoteUId != null) {
      FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(call!.callerId)
          .collection(collectionName.collectionCallHistory)
          .doc(call!.timestamp.toString())
          .set({'status': 'ended', 'ended': now}, SetOptions(merge: true));
      await FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(call!.receiverId)
          .collection(collectionName.collectionCallHistory)
          .doc(call!.timestamp.toString())
          .set({'status': 'ended', 'ended': now}, SetOptions(merge: true));
    } else {
      await endCall(call: call!).then((value) async {
        FirebaseFirestore.instance
            .collection(collectionName.calls)
            .doc(call!.callerId)
            .collection(collectionName.collectionCallHistory)
            .doc(call!.timestamp.toString())
            .set({
          'type': 'outGoing',
          'isVideoCall': call!.isVideoCall,
          'id': call!.receiverId,
          'timestamp': call!.timestamp,
          'dp': call!.receiverPic,
          'isMuted': false,
          'receiverId': call!.receiverId,
          "isGroup": call!.isGroup,
          "groupName": call!.groupName,
          'isJoin': false,
          'started': null,
          'callerName': call!.receiverName,
          'status': 'ended',
          'ended': DateTime.now(),
        }, SetOptions(merge: true));
        FirebaseFirestore.instance
            .collection(collectionName.calls)
            .doc(call!.receiverId)
            .collection(collectionName.collectionCallHistory)
            .doc(call!.timestamp.toString())
            .set({
          'type': 'inComing',
          'isVideoCall': call!.isVideoCall,
          'id': call!.callerId,
          'timestamp': call!.timestamp,
          'dp': call!.callerPic,
          'isMuted': false,
          'receiverId': call!.receiverId,
          'isJoin': true,
          'started': null,
          "isGroup": call!.isGroup,
          "groupName": call!.groupName,
          'callerName': call!.callerName,
          'status': 'ended',
          'ended': now
        }, SetOptions(merge: true));
      });
    }
    update();
    log("endCall");
    WakelockPlus.disable();
    stopTimer();
    _closeCallView(context);
  }
}
