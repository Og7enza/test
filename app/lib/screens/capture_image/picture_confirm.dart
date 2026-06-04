import 'dart:io';

import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/screens/bottom_nav_bar.dart';

class PictureConfirm extends StatelessWidget {
  final File image;
  final MintedImage mintedImage;
  const PictureConfirm({
    required this.image,
    super.key,
    required this.mintedImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          splashRadius: 20,
          onPressed: () {
            Get.offAll(() => const BottomNavBar());
          },
          icon: Icon(
            Iconsax.arrow_left,
            color: kPrimaryColor,
          ),
        ),
        centerTitle: false,
        backgroundColor: kBackgroundColor,
      ),
      body: Consumer<NtfController>(
          builder: (context, NtfController nftController, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Entry.offset(
                    yOffset: 35,
                    key: UniqueKey(),
                    duration: const Duration(milliseconds: 1300),
                    child: Hero(
                      tag: image.path,
                      child: Container(
                        constraints:
                            BoxConstraints(maxHeight: Get.height * 0.52),
                        height: Get.height * 0.52,
                        width: Get.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.file(
                            image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Get.height * 0.02),
              Entry.offset(
                  yOffset: 15,
                  key: UniqueKey(),
                  duration: const Duration(milliseconds: 500),
                  child: SvgPicture.asset('assets/icons/confirm_icon.svg')),
              const SizedBox(height: 5),
              Entry.offset(
                yOffset: 20,
                key: UniqueKey(),
                duration: const Duration(milliseconds: 700),
                child: Text(
                  'Congratulations!',
                  style: GoogleFonts.montserrat(
                    fontSize: 23,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Entry.offset(
                yOffset: 25,
                key: UniqueKey(),
                duration: const Duration(milliseconds: 900),
                child: Text('You have immortalized this moment',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    )),
              ),
              const SizedBox(height: 24.0),
              Entry.offset(
                yOffset: 30,
                key: UniqueKey(),
                duration: const Duration(milliseconds: 1000),
                child: CustomButton(
                  enabled: true,
                  callBack: () {
                    nftController.getMintedNfts();
                    Provider.of<NotificationController>(context, listen: false)
                        .getNotifications(isRefreshing: false);
                    nftController.selectedImage = mintedImage;

                    Get.back();
                  },
                  title: 'VIEW GALLERY',
                  child: null,
                  height: 54,
                  width: Get.width * 0.5,
                ),
              ),
              const SizedBox(height: 32.0),
            ],
          ),
        );
      }),
    );
  }
}
