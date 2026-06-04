// import 'dart:developer';
// import 'dart:io';
// import 'package:camerawesome/camerawesome_plugin.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:truthcatcher/constant.dart';
// import 'capture_image/image_preview.dart';

// class CameraWidget extends StatelessWidget {
//   const CameraWidget({super.key});

//   @override
//   Widget build(BuildContext context) {

//     return CameraAwesomeBuilder.awesome(

//       previewPadding: EdgeInsets.zero,
//       previewAlignment: Alignment.center,
//       sensorConfig: SensorConfig.single(
//         sensor: Sensor.position(SensorPosition.back),
//         aspectRatio: CameraAspectRatios.ratio_16_9,
//       ),
//       saveConfig: SaveConfig.photo(mirrorFrontCamera: false),
//       enablePhysicalButton: false,
//       progressIndicator: const LoadingAnimation(),
//       defaultFilter: null,
//       onMediaCaptureEvent: (MediaCapture mediaCapture) async {
//         final String? path = mediaCapture.captureRequest.path;

//         if (path != null) {
//           final File imageFile = File(path);
//           await Future.delayed(const Duration(milliseconds: 500));

//           if (await imageFile.exists()) {
//             Get.to(() => ImagePreviewScreen(
//                   image: imageFile,
//                   date: DateTime.now(),
//                 ));
//           } else {
//             log("Image file not found at path: $path");
//           }
//         } else {
//           log("Media capture event has no path.");
//         }
//       },
//     );
//   }
// }

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truthcatcher/constant.dart';
import 'capture_image/image_preview.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  SensorConfig sensorConfig = SensorConfig.single(
      sensor: Sensor.position(SensorPosition.front),
      aspectRatio: CameraAspectRatios.ratio_16_9,
      zoom: 0.0);
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timestapm) {
      Timer(const Duration(milliseconds: 800), () {
        setState(() {
          sensorConfig = SensorConfig.single(
            sensor: Sensor.position(SensorPosition.back),
            aspectRatio: CameraAspectRatios.ratio_16_9,
          );
        });
        // setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CameraAwesomeBuilder.awesome(
      previewPadding: EdgeInsets.zero,
      previewAlignment: Alignment.center,
      // previewFit: CameraPreviewFit.fitHeight,
      sensorConfig: sensorConfig,
      saveConfig: SaveConfig.photo(mirrorFrontCamera: false),
      enablePhysicalButton: false,
      progressIndicator: const LoadingAnimation(),
      defaultFilter: null,
      onMediaCaptureEvent: (MediaCapture mediaCapture) async {
        final String? path = mediaCapture.captureRequest.path;

        if (path != null) {
          final File imageFile = File(path);
          await Future.delayed(const Duration(milliseconds: 500));

          if (await imageFile.exists()) {
            Get.to(() => ImagePreviewScreen(
                  image: imageFile,
                  date: DateTime.now(),
                ));
          } else {
            log("Image file not found at path: $path");
          }
        } else {
          log("Media capture event has no path.");
        }
      },
    );
    CameraAwesomeBuilder.awesome(
      previewPadding: EdgeInsets.zero,
      previewFit: CameraPreviewFit.contain,
      previewAlignment: Alignment.center,
      sensorConfig: sensorConfig,
      saveConfig: SaveConfig.photo(mirrorFrontCamera: false),
      enablePhysicalButton: false,
      progressIndicator: const LoadingAnimation(),
      defaultFilter: null,
      onMediaCaptureEvent: (MediaCapture mediaCapture) async {
        final String? path = mediaCapture.captureRequest.path;

        if (path != null) {
          final File imageFile = File(path);
          await Future.delayed(const Duration(milliseconds: 500));

          if (await imageFile.exists()) {
            Get.to(() => ImagePreviewScreen(
                  image: imageFile,
                  date: DateTime.now(),
                ));
          } else {
            log("Image file not found at path: $path");
          }
        } else {
          log("Media capture event has no path.");
        }
      },
    );
  }
}
