import 'dart:io';

import 'package:entry/entry.dart';
import 'package:fade_indexed_stack/fade_indexed_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/user_controller.dart';
import 'package:truthcatcher/screens/camera.dart';
import 'package:truthcatcher/screens/gallery/gallery.dart';
import 'package:truthcatcher/screens/home/home.dart';
import 'package:truthcatcher/screens/notification/notification.dart';
import 'package:truthcatcher/screens/profile/profile.dart';

import 'search/deeplink_search_result.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  List<Widget> pages = const [
    HomePage(),
    GalleryPage(),
    NotificationPage(),
    ProfilePage(),
  ];
  int index = 0;
  File? image;
  Uint8List? memoryImage;
  bool hasImageWatermarked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<NtfController>(context, listen: false).getMintedNfts();
      Box<String?> deeplinksBox = Hive.box<String?>(kDeeplinlksBox);
      String? deeplink = deeplinksBox.get('deepLink');
      if (deeplink != null) {
        if (deeplink.contains('nftDetails')) {
          List segments = deeplink.split('/');
          Get.to(() => const DeepLinkSearchResult(),
              arguments: {"matricule": segments.last});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
        builder: (context, UserController userProvider, _) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: kBackgroundColor,
        body: FadeIndexedStack(
          lazy: true,
          index: index,
          children: pages,
        ),
        floatingActionButton: Container(
          height: 76,
          width: Get.width * 0.3,
          color: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height: 76,
                  width: 76,
                  child: Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: kWhiteColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: Platform.isAndroid ? -Get.width * 0.01 : 0,
                top: 9,
                child: CustomPaint(
                  painter: RightCurve(),
                  child: const SizedBox(
                    height: 30,
                    width: 40,
                  ),
                ),
              ),
              Positioned(
                left: Platform.isAndroid ? -Get.width * 0.01 : 0,
                top: 9,
                child: Transform.flip(
                  flipX: true,
                  child: CustomPaint(
                    painter: RightCurve(),
                    child: const SizedBox(
                      height: 30,
                      width: 40,
                    ),
                  ),
                ),
              ),
              Center(
                child: Entry(
                  angle: 12,
                  delay: const Duration(milliseconds: 500),
                  scale: 0.8,
                  child: FloatingActionButton(
                    heroTag: UniqueKey(),
                    shape: StadiumBorder(
                      side: BorderSide(color: kPrimaryColor, width: 2),
                    ),
                    backgroundColor: kWhiteColor,
                    onPressed: () => Get.to(() => const CameraWidget()),
                    child: SvgPicture.asset('assets/icons/camera_capture.svg'),
                  ),
                ),
              )
            ],
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          height: Platform.isAndroid ? 80 : 70,
          elevation: 0,
          color: kWhiteColor,
          padding: EdgeInsets.only(
            top: Platform.isAndroid ? 0 : 10,
            left: 16,
            right: 16,
          ),
          notchMargin: 5,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              navItem(
                navItemIndex: 0,
                name: 'Home',
                icon: index == 0
                    ? Icon(
                        Iconsax.home_25,
                        color: kPrimaryColor,
                      )
                    : Iconsax.home_2,
                iconType: index == 0 ? 1 : 0,
              ),
              const Spacer(),
              navItem(
                navItemIndex: 1,
                name: 'Gallery',
                icon: index == 1
                    ? SvgPicture.asset('assets/icons/gallery_icon.svg')
                    : Iconsax.gallery,
                iconType: index == 1 ? 1 : 0,
              ),
              const Spacer(flex: 5),
              navItem(
                navItemIndex: 2,
                name: 'Notifications',
                icon: index == 2
                    ? SvgPicture.asset('assets/icons/notification_icon.svg')
                    : Iconsax.notification_bing,
                iconType: index == 2 ? 1 : 0,
              ),
              const Spacer(),
              navItem(
                navItemIndex: 3,
                name: 'Profile',
                icon: index == 3
                    ? SvgPicture.asset('assets/icons/profile_icon.svg')
                    : SvgPicture.asset('assets/icons/profile_outline_icon.svg'),
                iconType: 1,
              ),
            ],
          ),
        ),
        persistentFooterAlignment: AlignmentDirectional.center,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }

  Widget navItem({
    required int navItemIndex,
    required String name,
    required dynamic icon,
    required int iconType, // Icon(Icons)
  }) {
    final Color highlightColor =
        index == navItemIndex ? kPrimaryColor : const Color(0xFFAEAEAE);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        if (index != navItemIndex) {
          HapticFeedback.lightImpact();
          setState(() => index = navItemIndex);
          Provider.of<NotificationController>(context, listen: false)
              .clearSelectedNotifications();
        }
      },
      child: SizedBox(
        height: 50,
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Entry.scale(
              delay: const Duration(milliseconds: 100),
              child: iconType == 0 ? Icon(icon, color: highlightColor) : icon,
            ),
            const SizedBox(height: 5),
            Entry.scale(
              delay: const Duration(milliseconds: 100),
              child: Text(
                name,
                style:
                    GoogleFonts.montserrat(fontSize: 12, color: highlightColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
