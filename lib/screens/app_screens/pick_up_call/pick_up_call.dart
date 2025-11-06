import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
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
      bool hasPermission = (await permissionCtrl.getCameraPermission()) as bool;
      if (!hasPermission) {
        log('Camera permission denied');
        return;
      }

      cameras = await availableCameras();
      if (cameras.isEmpty) {
        log('No cameras available');
        return;
      }
      isCameraInitialized = true;
      if (mounted) setState(() {});
    } catch (e) {
      log('Error setting up camera: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    cameraController?.dispose();
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
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty ||
            isCallEnded) {
          return widget.scaffold;
        }
        final callData =
        snapshot.data!.docs[0].data() as Map<String, dynamic>;
        log('Call data: $callData');
        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty ||
            isCallEnded) {
          return widget.scaffold;
        }
        if (callData['status'] == 'ended') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            isCallEnded = true;
            cameraController?.dispose();
            cameraController = null;
            Get.back();
          });
          return widget.scaffold;
        }
        Call call = Call.fromMap(callData);
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