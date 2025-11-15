import 'dart:async';
import 'dart:developer';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:audioplayers/audioplayers.dart';
import 'package:chatzy/models/call_model.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../config.dart';
import '../common_controllers/notification_controller.dart';
import '../common_controllers/firebase_common_controller.dart';

class VideoCallController extends GetxController {
  String? channelName;
  Call? call;
  bool localUserJoined = false, isFullScreen = false;
  bool isSpeaker = true, switchCamera = false, isCameraShow = true;
  late RtcEngine engine;
  Stream<int>? timerStream;
  int? remoteUId;
  List users = <int>[];
  final infoStrings = <String>[];

  // ignore: cancel_subscriptions
  StreamSubscription<int>? timerSubscription;
  bool muted = false;
  bool isAlreadyEndedCall = false;
  String nameList = "";
  ClientRoleType? role;
  dynamic userData;
  Stream<DocumentSnapshot>? stream;
  audio_players.AudioPlayer? player;
  AudioCache audioCache = AudioCache();
  int? remoteUidValue;
  String? token;
  bool isStart = false;

  // Защита от повторной инициализации
  bool _isInitialized = false;
  bool _isDisposed = false;

  // ignore: close_sinks
  StreamController<int>? streamController;
  String hoursStr = '00';
  String minutesStr = '00';
  String secondsStr = '00';
  int counter = 0;
  Timer? timer;

  // Добавить участника в видео звонок
  void onAddParticipant() async {
    log("VideoCallController: onAddParticipant called");
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
      log("Starting conversion to group video call");

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

      log("Converted to group video call successfully");

      // Теперь открываем экран добавления участников
      _navigateToAddParticipants();

    } catch (e) {
      log("Error converting to group video call: $e");
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
      log("Adding ${newParticipants.length} new participants to video call");

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
        '${newParticipants.length} participant(s) added to video call',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: appCtrl.appTheme.online,
        colorText: appCtrl.appTheme.sameWhite,
      );

      update();

    } catch (e) {
      log("Error adding participants to video call: $e");
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
  void onReady() {
    // TODO: implement onReady
    super.onReady();
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
  }

  Future<bool> onWillPopNEw() {
    return Future.value(false);
  }

  //initialise agora
  Future<void> initAgora() async {
    // Защита от повторной инициализации
    if (_isInitialized) {
      log("Agora already initialized, skipping...");
      return;
    }

    if (_isDisposed) {
      log("Controller disposed, cannot initialize");
      return;
    }

    try {
      var agoraData = appCtrl.storage.read(session.agoraToken);
      log("token :: ${call!.agoraToken}");
      log("token :: ${call!.channelId}");

      //create the engine
      engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: agoraData["agoraAppId"],
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _isInitialized = true;

      engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ;;;${connection.localUid} joined");

          // Используем postFrameCallback для безопасного обновления после build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isDisposed) return;

            localUserJoined = true;
            final noti = Get.find<CustomNotificationController>();

            final info =
                'onJoinChannel: ${noti.callChannel}, uid: ${connection.localUid}';
            infoStrings.add(info);
            log("info :info");

            if (call!.receiver != null) {
              List receiver = call!.receiver!;
              receiver.asMap().entries.forEach((element) {
                if (nameList != "") {
                  if (element.value["name"] != element.value["name"]) {
                    nameList = "$nameList, ${element.value["name"]}";
                  }
                } else {
                  if (element.value["name"] != userData["name"]) {
                    nameList = element.value["name"];
                  }
                }
              });
            }

            if (call!.callerId == userData["id"]) {
            // Собираем все Firestore операции для параллельного выполнения
            List<Future> firestoreOperations = [
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
                'isJoin': false,
                'status': 'calling',
                'started': null,
                'ended': null,
                'callerName':
                call!.receiver != null ? nameList : call!.callerName,
              }, SetOptions(merge: true)),
            ];

            if (call!.receiver != null) {
              List receiver = call!.receiver!;
              receiver.asMap().entries.forEach((element) {
                if (element.value["id"] != userData["id"]) {
                  firestoreOperations.add(
                    FirebaseFirestore.instance
                        .collection(collectionName.calls)
                        .doc(element.value["id"])
                        .collection(collectionName.collectionCallHistory)
                        .doc(call!.timestamp.toString())
                        .set({
                      'type': 'inComing',
                      'isVideoCall': call!.isVideoCall,
                      'id': call!.callerId,
                      'timestamp': call!.timestamp,
                      'dp': call!.callerPic,
                      'isMuted': false,
                      'receiverId': element.value["id"],
                      'isJoin': true,
                      'status': 'missedCall',
                      'started': null,
                      'ended': null,
                      'callerName':
                      call!.receiver != null ? nameList : call!.callerName,
                    }, SetOptions(merge: true)),
                  );
                }
              });
              log("nameList : $nameList");
            } else {
              firestoreOperations.add(
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
                  'status': 'missedCall',
                  'started': null,
                  'ended': null,
                  'callerName':
                  call!.receiver != null ? nameList : call!.callerName,
                }, SetOptions(merge: true)),
              );
            }

            // Выполняем все операции параллельно
            Future.wait(firestoreOperations);

            WakelockPlus.enable();
            // Один update вместо двух + Get.forceAppUpdate
            update();
            }
          });
        },
        onUserJoined:
            (RtcConnection connection, int remoteUserId, int elapsed) {
          debugPrint("remote user $remoteUserId joined");

          // Используем postFrameCallback для безопасного обновления
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isDisposed) return;

            remoteUId = remoteUserId;
            startTimerNow();

            final info = 'userJoined: $remoteUserId';
            infoStrings.add(info);
            if (users.isEmpty) {
              users = [remoteUserId];
            } else {
              users.add(remoteUserId);
            }
            debugPrint("remote user $remoteUserId joined");

          if (userData["id"] == call!.callerId) {
            // Собираем все Firestore операции для параллельного выполнения
            List<Future> firestoreOperations = [
              FirebaseFirestore.instance
                  .collection(collectionName.calls)
                  .doc(call!.callerId)
                  .collection(collectionName.collectionCallHistory)
                  .doc(call!.timestamp.toString())
                  .set({
                'started': DateTime.now(),
                'status': 'pickedUp',
                'isJoin': true,
              }, SetOptions(merge: true)),
              FirebaseFirestore.instance
                  .collection("calls")
                  .doc(call!.callerId)
                  .set({
                "videoCallMade": FieldValue.increment(1),
              }, SetOptions(merge: true)),
            ];

            if (call!.receiver != null) {
              List receiver = call!.receiver!;
              receiver.asMap().entries.forEach((element) {
                if (element.value["id"] != userData["id"]) {
                  firestoreOperations.add(
                    FirebaseFirestore.instance
                        .collection(collectionName.calls)
                        .doc(element.value["id"])
                        .collection(collectionName.collectionCallHistory)
                        .doc(call!.timestamp.toString())
                        .set({
                      'started': DateTime.now(),
                      'status': 'pickedUp',
                    }, SetOptions(merge: true)),
                  );
                  firestoreOperations.add(
                    FirebaseFirestore.instance
                        .collection("calls")
                        .doc(element.value["id"])
                        .set({
                      "videoCallReceived": FieldValue.increment(1),
                    }, SetOptions(merge: true)),
                  );
                }
              });
            } else {
              firestoreOperations.add(
                FirebaseFirestore.instance
                    .collection(collectionName.calls)
                    .doc(call!.receiverId)
                    .collection(collectionName.collectionCallHistory)
                    .doc(call!.timestamp.toString())
                    .set({
                  'started': DateTime.now(),
                  'status': 'pickedUp',
                }, SetOptions(merge: true)),
              );
              firestoreOperations.add(
                FirebaseFirestore.instance
                    .collection(collectionName.calls)
                    .doc(call!.receiverId)
                    .set({
                  "videoCallReceived": FieldValue.increment(1),
                }, SetOptions(merge: true)),
              );
            }

            // Выполняем все операции параллельно
            Future.wait(firestoreOperations);

            WakelockPlus.enable();
            // Один update вместо множественных
            update();
            }
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) async {
          debugPrint("remote user $remoteUid left channel");

          remoteUid = 0;
          users.remove(remoteUid);
          update();

          // Вызываем onCallEnd для завершения звонка у второго участника
          if (Get.context != null && !isAlreadyEndedCall) {
            isAlreadyEndedCall = true;
            await onCallEnd(Get.context!);
            return;
          }

          // Если по каким-то причинам контекст недоступен, обновляем Firebase
          if (isAlreadyEndedCall == false) {
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'status': 'ended',
              'ended': DateTime.now(),
            }, SetOptions(merge: true));
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
        },
        onError: (err, msg) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: $err, token: $msg)');
        },
        onFirstRemoteAudioFrame: (connection, userId, elapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isDisposed) return;
            final info = 'firstRemoteVideo: $userId';
            infoStrings.add(info);
            update();
          });
        },
        onLeaveChannel: (connection, stats) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_isDisposed) return;

            remoteUId = null;
            infoStrings.add('onLeaveChannel');
            stopTimer();
            users.clear();

            _dispose();
            update();
            if (isAlreadyEndedCall == false) {
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .add({});
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(call!.callerId)
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'status': 'ended',
              'ended': DateTime.now(),
            }, SetOptions(merge: true));
            if (call!.receiver != null) {
              List receiver = call!.receiver!;
              receiver.asMap().entries.forEach((element) {
                if (element.value['id'] != userData["id"]) {
                  FirebaseFirestore.instance
                      .collection(collectionName.calls)
                      .doc(element.value['id'])
                      .collection(collectionName.collectionCallHistory)
                      .doc(call!.timestamp.toString())
                      .set({
                    'status': 'ended',
                    'ended': DateTime.now(),
                  }, SetOptions(merge: true));
                }
              });
            } else {
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

            stopTimer();
            WakelockPlus.disable();
            Get.back();
            update();
            }
          });
        },
      ),
    );

      await engine.enableWebSdkInteroperability(true);
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      await engine.enableVideo();
      await engine.startPreview();

      await engine.joinChannel(
        token: call!.agoraToken!,
        channelId: channelName!,
        uid: 0,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      log("Agora initialized successfully");
    } catch (e) {
      log("Error initializing Agora: $e");
      _isInitialized = false;
      rethrow;
    }
  }

  //on speaker off on
  void onToggleSpeaker() {
    isSpeaker = !isSpeaker;
    update();
    engine.setEnableSpeakerphone(isSpeaker);
  }

  //mute - unMute toggle
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

  @override
  void onClose() {
    _isDisposed = true;
    _dispose();
    super.onClose();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    if (!_isInitialized) return;

    try {
      await engine.leaveChannel();
      await engine.release();
      stopTimer();
      _isInitialized = false;
    } catch (e) {
      log("Error disposing engine: $e");
    }
  }

  //bottom toolbar
  Widget toolbar(
      bool isShowSpeaker,
      String? status,
      ) {
    if (role == ClientRoleType.clientRoleAudience) return Container();

    return Container();
  }

  // //switch camera
  // Future<void> onSwitchCamera() async {
  //   engine.switchCamera();
  //
  //   update();
  // }

  bool _isFrontCamera = true;

  Future<void> onSwitchCamera() async {
    try {
      log("_isFrontCamera::${_isFrontCamera}");
      await engine.switchCamera();
      _isFrontCamera = !_isFrontCamera; // Toggle
      update();
    } catch (e) {
      print("Switch camera failed: $e");
    }
  }

  //end call and remove calling documents - MUST be awaited
  Future<bool> endCall({required Call call}) async {
    try {
      log("Deleting calling documents for channelId: ${call.channelId}");
      final firestore = FirebaseFirestore.instance;

      // Delete caller's calling document
      final callerCallQuery = firestore
          .collection(collectionName.calls)
          .doc(call.callerId)
          .collection(collectionName.calling)
          .where('channelId', isEqualTo: call.channelId);
      final callerCallDocs = await callerCallQuery.get();
      for (var doc in callerCallDocs.docs) {
        await doc.reference.delete();
        log("Deleted caller calling doc: ${doc.id}");
      }

      // Delete receiver's calling documents (handle both group and one-on-one)
      if (call.receiver != null) {
        // Group call
        for (var receiver in call.receiver!) {
          final receiverId = receiver['id'];
          final receiverCallQuery = firestore
              .collection(collectionName.calls)
              .doc(receiverId)
              .collection(collectionName.calling)
              .where('channelId', isEqualTo: call.channelId);
          final receiverCallDocs = await receiverCallQuery.get();
          for (var doc in receiverCallDocs.docs) {
            await doc.reference.delete();
            log("Deleted receiver calling doc for $receiverId: ${doc.id}");
          }
        }
      } else {
        // One-on-one call
        final receiverCallQuery = firestore
            .collection(collectionName.calls)
            .doc(call.receiverId)
            .collection(collectionName.calling)
            .where('channelId', isEqualTo: call.channelId);
        final receiverCallDocs = await receiverCallQuery.get();
        for (var doc in receiverCallDocs.docs) {
          await doc.reference.delete();
          log("Deleted receiver calling doc: ${doc.id}");
        }
      }

      log("All calling documents deleted successfully");
      return true;
    } catch (e) {
      log('Error deleting calling documents: $e');
      return false;
    }
  }

  // Navigate to chat with the other participant
  Future<void> _navigateToChat() async {
    if (call == null || userData == null || userData["id"] == null) {
      Get.back();
      return;
    }

    try {
      // Determine who is the "other" user in the call
      final bool isICaller = call!.callerId == userData["id"];
      final String otherUserId = isICaller ? (call!.receiverId ?? '') : (call!.callerId ?? '');
      final String otherUserName = isICaller ? (call!.receiverName ?? 'Unknown') : (call!.callerName ?? 'Unknown');
      final String otherUserPic = isICaller ? (call!.receiverPic ?? '') : (call!.callerPic ?? '');

      // Create UserContactModel for the other participant
      UserContactModel userContact = UserContactModel(
        username: otherUserName,
        uid: otherUserId,
        phoneNumber: '',
        image: otherUserPic,
        isRegister: true,
      );

      // Small delay to ensure Firebase documents are fully deleted
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigate to chat layout - go back to dashboard first, then to chat
      Get.back(); // Close call screen
      await Future.delayed(const Duration(milliseconds: 100));
      Get.toNamed(routeName.chatLayout, arguments: {
        'chatId': '0',
        'data': userContact,
      });
    } catch (e) {
      log('Error navigating to chat: $e');
      Get.back();
    }
  }

  Future<void> onCallEnd(BuildContext context) async {
    if (call == null) return;
    if (isAlreadyEndedCall) {
      Get.offAllNamed(routeName.dashboard);
      return;
    }

    isAlreadyEndedCall = true;
    log("onCallEnd: Starting call end sequence");

    DateTime now = DateTime.now();

    // CRITICAL: Delete calling documents FIRST to prevent pickup screen from showing again
    await endCall(call: call!);
    log("onCallEnd: Calling documents deleted");

    // Update call history
    if (remoteUId != null) {
      // Call was answered - update history for both users
      final historyUpdates = <Future>[];

      historyUpdates.add(
        FirebaseFirestore.instance
            .collection(collectionName.calls)
            .doc(call!.callerId)
            .collection(collectionName.collectionCallHistory)
            .doc(call!.timestamp.toString())
            .set({
          'status': 'ended',
          'ended': now
        }, SetOptions(merge: true))
      );

      if (call!.receiver != null) {
        // Group call
        for (var receiver in call!.receiver!) {
          historyUpdates.add(
            FirebaseFirestore.instance
                .collection(collectionName.calls)
                .doc(receiver['id'])
                .collection(collectionName.collectionCallHistory)
                .doc(call!.timestamp.toString())
                .set({
              'status': 'ended',
              'ended': now
            }, SetOptions(merge: true))
          );
        }
      } else {
        historyUpdates.add(
          FirebaseFirestore.instance
              .collection(collectionName.calls)
              .doc(call!.receiverId)
              .collection(collectionName.collectionCallHistory)
              .doc(call!.timestamp.toString())
              .set({
            'status': 'ended',
            'ended': now
          }, SetOptions(merge: true))
        );
      }

      await Future.wait(historyUpdates);
    }

    // Cleanup resources
    await engine.leaveChannel();
    stopTimer();
    remoteUId = null;
    channelName = '';
    users.clear();
    localUserJoined = false;
    _dispose();
    WakelockPlus.disable();
    update();

    log("onCallEnd: Cleanup complete, navigating to dashboard");

    // Navigate to dashboard (chat list)
    Get.offAllNamed(routeName.dashboard);
  }

}
