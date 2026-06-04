import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/screens/camera.dart';
import 'package:truthcatcher/screens/capture_image/picture_information.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen({
    super.key,
    required this.image,
    required this.date,
  });

  final File image;
  final DateTime date;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  File? newImage;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Provider.of<NtfController>(context, listen: false).getTimeFromTimezone();
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        Provider.of<NtfController>(context, listen: false).stopTimer();
      },
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          iconTheme: IconThemeData(color: kPrimaryColor),
          elevation: 0.0,
          backgroundColor: kBackgroundColor,
          title: Text(
            'Preview',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              color: kPrimaryColor,
            ),
          ),
        ),
        body: Consumer<NtfController>(
            builder: (context, NtfController ntfController, _) {
          bool isValid = ntfController.isValid;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: newImage == null ? widget.image.path : newImage!.path,
                  child: AnimatedScale(
                    scale: 1,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                        constraints:
                            BoxConstraints(maxHeight: Get.height * 0.55),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        width: Get.width,
                        child: Image.file(
                          gaplessPlayback: true,
                          newImage == null ? widget.image : newImage!,
                          filterQuality: FilterQuality.medium,
                          fit: BoxFit.cover,
                        )),
                  ),
                ),
                if (isValid) const Spacer(),
                if (!isValid)
                  Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        "Your device date is inaccurate! Adjust your clock and try again.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(color: Colors.black),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        "Your device date and time is",
                        style: GoogleFonts.montserrat(),
                      ),
                      Text(
                        DateFormat("dd/MM/yyyy, h:mm a").format(DateTime.now()),
                        style: GoogleFonts.montserrat(),
                      ),
                      const SizedBox(height: 24),
                      // const Spacer(),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              elevation: 4.0,
                              fixedSize: Size(Get.width * 0.5, 54),
                              backgroundColor: kPrimaryColor),
                          onPressed: () async {
                            SettingsUtil.openDateTimeSettings();
                          },
                          child: Text("Adjust".toUpperCase(),
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: kWhiteColor))),
                      // const Spacer(),
                    ],
                  ),
                if (isValid)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomButton(
                        enabled: ntfController.imageTimestamp != null,
                        callBack: () {
                          Get.to(() => PictureInformation(
                                file: newImage ?? widget.image,
                                date:
                                    ntfController.imageTimestamp ?? widget.date,
                              ));
                        },
                        title: 'CONFIRM',
                        child: null,
                        height: 54,
                        width: Get.width * 0.45,
                      ),
                      // cancle button
                      const SizedBox(height: 16.0),

                      MaterialButton(
                        padding: EdgeInsets.zero,
                        height: 30,
                        onPressed: () async {
                          Get.back();
                          Get.to(() => const CameraWidget());
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.flip(
                              flipX: true,
                              child: Transform.rotate(
                                angle: 6.0,
                                child: Icon(
                                  Icons.replay_rounded,
                                  size: 16.0,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2.0),
                            Text(
                              'Retake',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kPrimaryColor,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24.0)
                    ],
                  )
              ],
            ),
          );
        }),
      ),
    );
  }

  bool isWithinFiveMinutes(DateTime? givenTime) {
    if (givenTime == null) {
      return true;
    }
    DateTime now = DateTime.now();
    Duration allowedRange = const Duration(minutes: 1);

    // Calculate the start and end of the allowed time window
    DateTime startRange = now.subtract(allowedRange);
    DateTime endRange = now.add(allowedRange);

    // Check if the given time is within the range
    if (givenTime.isAfter(startRange) && givenTime.isBefore(endRange)) {
      return true; // The time is within 5 minutes before or after the current time
    } else {
      return false; // The time is outside the 5-minute range
    }
  }

  void makeRequest(DateTime timestamp) {
    if (isValidTimestamp(timestamp)) {
      // Proceed with the request
      print('Timestamp is valid. Proceeding with the request.');
    } else {
      // Show an error or handle the invalid timestamp
      print('Timestamp is invalid. Please check the date and time.');
      // Optionally, show a dialog to inform the user
      Get.snackbar(
        'Invalid Timestamp',
        'The date and time provided is either in the past or too far in the future. Please check and try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool isValidTimestamp(DateTime timestamp) {
    DateTime now = DateTime.now();

    log(timestamp.toString());
    log(now.toString());

    // You can define your own range limits here. For example, you might only allow timestamps within the next 30 minutes.
    Duration maxAllowedFuture = const Duration(minutes: 30);

    if (timestamp.isBefore(now) ||
        timestamp.isAfter(now.add(maxAllowedFuture))) {
      return false; // Invalid timestamp
    }
    return true; // Valid timestamp
  }
}

class SettingsUtil {
  static const MethodChannel _channel = MethodChannel('com.example/settings');

  static Future<void> openDateTimeSettings() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('openDateTimeSettings');
      } else {
        Get.dialog(
          Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To change the date and time settings on your iOS device:',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const InstructionStep(
                      number: 1, text: 'Open the Settings app.'),
                  const InstructionStep(number: 2, text: 'Tap on "General".'),
                  const InstructionStep(
                      number: 3, text: 'Tap on "Date & Time".'),
                  const InstructionStep(
                      number: 4, text: 'Toggle "Set Automatically" to On.'),
                  const InstructionStep(
                      number: 5,
                      text: 'Ensure the correct time zone is selected.'),
                  const SizedBox(height: 16),
                  Text(
                    'After changing the settings, you can return to the app.',
                    style: GoogleFonts.montserrat(),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            fixedSize: Size(Get.width * 0.4, 42)),
                        onPressed: () async {
                          Get.close(1);
                          await _channel.invokeMethod('openAppSettings');
                        },
                        child: Text(
                          "Settings".toUpperCase(),
                          style: GoogleFonts.montserrat(
                              color: kWhiteColor, fontWeight: FontWeight.bold),
                        )),
                  )
                ],
              ),
            ),
          ),
          barrierDismissible: true,
        );
      }
    } on PlatformException catch (e) {
      print("Failed to open date and time settings: '${e.message}'.");
    }
  }
}

class InstructionStep extends StatelessWidget {
  final int number;
  final String text;

  const InstructionStep({super.key, required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(text,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                )),
          ),
        ],
      ),
    );
  }
}
