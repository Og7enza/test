import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truthcatcher/screens/capture_image/image_preview.dart';

class CameraControllerProvider extends ChangeNotifier {
  CameraControllerProvider() {
    initializeController();
  }
  bool isFlashOn = false;
  bool isInitilizing = false;
  List<CameraDescription> _cameras = [];
  CameraController? controller;
  Future initializeController() async {
    _cameras = await availableCameras();

    controller = CameraController(_cameras[camera], ResolutionPreset.max);
    controller?.initialize().then((_) {
      controller?.setFocusMode(FocusMode.auto);
      notifyListeners();
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  XFile? selectedImage;
  int camera = 0;

  Future captureImage() async {
    try {
      selectedImage = await controller?.takePicture();
      Get.back();
      Get.to(() => ImagePreviewScreen(
          image: File(selectedImage!.path), date: DateTime.now()));

      notifyListeners();
    } catch (error) {
      log("Error capturing image");
    }
  }

  Future rotateCamera() async {
    try {
      isInitilizing = true;
      notifyListeners();
      if (camera == 1) {
        controller = CameraController(_cameras[0], ResolutionPreset.ultraHigh);
        camera = 0;
        notifyListeners();
      } else {
        controller = CameraController(_cameras[1], ResolutionPreset.ultraHigh);
        camera = 1;
        notifyListeners();
      }

      await controller?.initialize();
      isInitilizing = false;
      notifyListeners();
    } catch (error) {
      isInitilizing = false;
      notifyListeners();
      log("Error capturing image");
    }
  }

  Future toggleFlash() async {
    try {
      if (isFlashOn) {
        await controller?.setFlashMode(FlashMode.off);
        isFlashOn = false;
      } else {
        await controller?.setFlashMode(FlashMode.torch);

        isFlashOn = true;
      }
      notifyListeners();
    } catch (error) {
      log("Error capturing image");
    }
  }
}