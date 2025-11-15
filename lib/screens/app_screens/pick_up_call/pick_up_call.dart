import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import 'package:chatzy/screens/app_screens/pick_up_call/pick_up_body.dart';
import 'package:chatzy/models/call_model.dart';
import 'package:chatzy/controllers/common_controllers/all_permission_handler.dart';
import '../../../config.dart';

class PickupLayout extends StatefulWidget {
  final Widget scaffold;

  const PickupLayout({super.key, required this.scaffold});

  @override
  State<PickupLayout> createState() => _PickupLayoutState();
}

class _PickupLayoutState extends State<PickupLayout>
    with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation? colorAnimation;
  Animation? sizeAnimation;
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  bool isCallEnded = false;
  bool isCameraInitialized = false;
  bool isVibrating = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    colorAnimation = ColorTween(
      begin: appCtrl.appTheme.redColor,
      end: appCtrl.appTheme.redColor,
    ).animate(CurvedAnimation(parent: controller!, curve: Curves.bounceOut));
    sizeAnimation = Tween<double>(begin: 30.0, end: 60.0).animate(controller!);
    controller!.addListener(() {
      if (mounted) setState(() {});
    });
    controller!.repeat();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final permissionCtrl = Get.isRegistered<PermissionHandlerController>()
          ? Get.find<PermissionHandlerController>()
          : Get.put(PermissionHandlerController());

      // Исправлено: getCameraPermission возвращает PermissionStatus, а не bool
      final cameraPermissionStatus = await permissionCtrl.getCameraPermission();
      log('Camera permission status: $cameraPermissionStatus');

      if (cameraPermissionStatus != PermissionStatus.granted) {
        log('Camera permission denied: $cameraPermissionStatus');
        return;
      }

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        log('No cameras available');
        return;
      }
      isCameraInitialized = true;
      if (mounted) setState(() {});
      log('Camera initialized successfully: ${cameras.length} cameras found');
    } catch (e) {
      log('Error setting up camera: $e');
    }
  }

  Future<void> _startVibration() async {
    if (isVibrating) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        isVibrating = true;
        // Vibrate with pattern: 1000ms vibrate, 500ms pause, repeat
        await Vibration.vibrate(
          pattern: [0, 1000, 500, 1000, 500, 1000],
          repeat: 0, // Repeat the pattern
        );
        log('Vibration started for incoming call');
      }
    } catch (e) {
      log('Error starting vibration: $e');
    }
  }

  Future<void> _stopVibration() async {
    if (!isVibrating) return;

    try {
      await Vibration.cancel();
      isVibrating = false;
      log('Vibration stopped');
    } catch (e) {
      log('Error stopping vibration: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    cameraController?.dispose();
    _stopVibration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return appCtrl.user != null && appCtrl.user.isNotEmpty
        ? StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName.calls)
          .doc(appCtrl.user["id"])
          .collection(collectionName.calling)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        // Return scaffold immediately if no data, empty, or call ended
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty ||
            isCallEnded) {
          if (isVibrating) {
            _stopVibration();
          }
          return widget.scaffold;
        }

        final callData = snapshot.data!.docs[0].data() as Map<String, dynamic>;

        // Check if call has ended status - prevents flash of pickup screen
        if (callData['status'] == 'ended') {
          if (isVibrating) {
            _stopVibration();
          }
          if (!isCallEnded) {
            isCallEnded = true;
            cameraController?.dispose();
            cameraController = null;
          }
          return widget.scaffold;
        }

        Call call = Call.fromMap(callData);

        // Start vibration ONLY for incoming calls (not outgoing)
        // Incoming call: receiverId is current user
        // Outgoing call: callerId is current user
        final isIncomingCall = call.receiverId == appCtrl.user["id"];
        if (isIncomingCall && !isVibrating) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startVibration();
          });
        } else if (!isIncomingCall && isVibrating) {
          // Stop vibration if it's an outgoing call
          _stopVibration();
        }
        if (call.isVideoCall == true &&
            cameraController == null &&
            isCameraInitialized &&
            cameras.isNotEmpty &&
            mounted) {
          try {
            CameraDescription? selectedCamera;
            if (cameras.length > 1) {
              // Prefer back camera
              selectedCamera = cameras.firstWhere(
                    (c) => c.lensDirection == CameraLensDirection.back,
                orElse: () => cameras.firstWhere(
                      (c) => c.lensDirection == CameraLensDirection.front,
                  orElse: () => cameras.first,
                ),
              );
            } else {
              selectedCamera = cameras.first;
            }
            cameraController = CameraController(
              selectedCamera,
              ResolutionPreset.medium,
              enableAudio: false,
            );
            cameraController!.initialize().then((_) {
              if (mounted) {
                setState(() {});
                log('Camera initialized successfully: ${selectedCamera!.lensDirection}');
              }
            }).catchError((e) {
              log('Camera initialization error: $e');
              cameraController = null;
            });
          } catch (e) {
            log('Error creating CameraController: $e');
            cameraController = null;
          }
        }
        return PickupBody(
          call: call,
          cameraController:
          call.isVideoCall == true ? cameraController : null,
          imageUrl: callData['callerPic'],
          onCallEnded: () {
            isCallEnded = true;
            setState(() {});
          },
        );
      },
    )
        : widget.scaffold;
  }
}