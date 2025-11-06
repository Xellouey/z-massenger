import 'dart:async';
import 'dart:developer';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config.dart';
import '../../models/position_item.dart';

class PermissionHandlerController extends GetxController {
  static const String _kLocationServicesDisabledMessage =
      'Location services are disabled.';
  static const String _kPermissionDeniedMessage = 'Permission denied.';
  static const String _kPermissionDeniedForeverMessage =
      'Permission denied forever.';
  static const String _kPermissionGrantedMessage = 'Permission granted.';
  final GeolocatorPlatform geoLocatorPlatform = GeolocatorPlatform.instance;
  final List<PositionItem> _positionItems = <PositionItem>[];

  //location
  Future<bool> handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await geoLocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      updatePositionList(
        PositionItemType.log,
        _kLocationServicesDisabledMessage,
      );
      return false;
    }

    permission = await geoLocatorPlatform.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await geoLocatorPlatform.requestPermission();
      if (permission == LocationPermission.denied) {
        updatePositionList(
          PositionItemType.log,
          _kPermissionDeniedMessage,
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      updatePositionList(
        PositionItemType.log,
        _kPermissionDeniedForeverMessage,
      );
      return false;
    }
    updatePositionList(
      PositionItemType.log,
      _kPermissionGrantedMessage,
    );
    return true;
  }

  //update position
  void updatePositionList(PositionItemType type, String displayValue) {
    _positionItems.add(PositionItem(type, displayValue));
    update();
  }

  //location permission check and request
  static Future<bool> checkAndRequestPermission(Permission permission) {
    Completer<bool> completer = Completer<bool>();
    log("permission :$permission");
    permission.request().then((status) {
      if (status != PermissionStatus.granted) {
        permission.request().then((status) {
          bool granted = status == PermissionStatus.granted;
          completer.complete(granted);
        });
      } else {
        completer.complete(true);
      }
    });
    return completer.future;
  }

//get contact permission
  Future<PermissionStatus> getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    debugPrint("getContactPermission : $permission");
    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.restricted) {
      PermissionStatus permissionStatus = await Permission.contacts.request();

      return permissionStatus;
    } else {
      debugPrint("getContactPermission 22: $permission");
      return permission;
    }
  }

//handle invalid permission
  handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      final snackBar = SnackBar(content: Text(appFonts.accessDenied.tr));
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      final snackBar =
      SnackBar(content: Text(appFonts.contactDataNotAvailable.tr));
      ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
    }
  }

  // get location
  getCurrentPosition() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      // When we reach here, permissions are granted and we can
      // continue accessing the position of the device.
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      log("messageError$e");
    }
  }

  Future<bool> permissionGranted() async {
    PermissionStatus permissionStatus = await getContactPermission();
    log("permissionStatus 22: $permissionStatus");
    if (permissionStatus == PermissionStatus.granted) {
      return true;
    } else {
      return false;
    }
  }

  //check permission and get contact
  Future<List<Contact>> getContact() async {
    List<Contact> contacts = [];
    bool permissionStatus = await permissionGranted();
    log("permissionStatus : $permissionStatus");
    if (permissionStatus) {
      contacts = await getAllContacts();
      appCtrl.storage.write(session.contactList, contacts);
      appCtrl.update();
    }
    debugPrint("GET contacts : $contacts");
    return contacts;
  }

  Future<PermissionStatus> getCameraPermission() async {
    PermissionStatus cameraPermission = await Permission.camera.request();
    log('Camera permission: $cameraPermission');
    if (cameraPermission != PermissionStatus.granted &&
        cameraPermission != PermissionStatus.denied) {
      return PermissionStatus.permanentlyDenied;
    }
    return cameraPermission;
  }

  // get microphone permission
  Future<PermissionStatus> getMicrophonePermission() async {
    PermissionStatus microphonePermission =
    await Permission.microphone.request();
    log('Microphone permission: $microphonePermission');
    if (microphonePermission != PermissionStatus.granted &&
        microphonePermission != PermissionStatus.denied) {
      return PermissionStatus.permanentlyDenied;
    }
    return microphonePermission;
  }

  Future<bool> getCameraMicrophonePermissions() async {
    PermissionStatus cameraPermission = await getCameraPermission();
    PermissionStatus microphonePermission = await getMicrophonePermission();

    if (cameraPermission == PermissionStatus.granted &&
        microphonePermission == PermissionStatus.granted) {
      return true;
    } else {
      _handleInvalidPermissions(cameraPermission, microphonePermission);
      return false;
    }
  }

  void _handleInvalidPermissions(PermissionStatus cameraPermission,
      PermissionStatus microphonePermission) {
    if (cameraPermission == PermissionStatus.denied ||
        microphonePermission == PermissionStatus.denied) {
      log('Permissions denied, please enable them in settings');
      // Optionally show a dialog to guide user to settings
      Get.snackbar(
        'Permissions Required',
        'Please enable camera and microphone permissions in settings.',
        snackPosition: SnackPosition.BOTTOM,
        onTap: (_) => openAppSettings(),
      );
    } else if (cameraPermission == PermissionStatus.permanentlyDenied ||
        microphonePermission == PermissionStatus.permanentlyDenied) {
      log('Permissions permanently denied');
      Get.snackbar(
        'Permissions Denied',
        'Camera or microphone permissions are permanently denied. Please enable them in settings.',
        snackPosition: SnackPosition.BOTTOM,
        onTap: (_) => openAppSettings(),
      );
    }
  }
}