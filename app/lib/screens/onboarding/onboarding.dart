import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:entry/entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/deeplinks_controller.dart';
import 'package:truthcatcher/screens/login/signup_screen.dart';
import 'package:truthcatcher/screens/search/deeplink_search_result.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

void initUniLinks() async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  final AppLinks appLinks = AppLinks();

  try {
    Uri? initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri, currentUser);
    }
  } catch (e) {
    log('Failed to get initial link: $e');
  }

  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      _handleDeepLink(uri, currentUser);
    }
  });
}

void _handleDeepLink(Uri uri, User? currentUser) async {
  log('handling deeplinks in onboarding');
  final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (currentUser == null) {
    Box<String?> deeplinksBox = Hive.box<String?>(kDeeplinlksBox);
    deeplinksBox.put('deepLink', uri.path);
  }
  if (token != null) {
    log("token in onboarding : $token");

    String path = uri.path;
    if (path.contains('nftDetails')) {
      log(uri.pathSegments.last);
      Get.to(() => const DeepLinkSearchResult(),
          arguments: {"matricule": uri.pathSegments.last});
    }
  } else {
    log("token in onboarding :null");
  }
}

class _OnboardingState extends State<Onboarding> {
  List<String> images = [
    'assets/images/onboarding_1.svg',
    'assets/images/onboarding_2.svg',
    'assets/images/onboarding_3.svg',
  ];
  List<String> titles = [
    'Catch an instant',
    'Immortalize a situation ',
    'Prove the moment ',
  ];
  List<String> subTitles = [
    'Prove deepfakes, thanks to blockchain',
    'Protect yourselves against fake news',
    'Assess the reality in a living instant, if it really happened.',
  ];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<DeeplinksController>(context, listen: false).initUniLinks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (value) {
            if (value.primaryVelocity! < 0) {
              if (currentIndex < 2) {
                setState(() {
                  currentIndex++;
                });
              }
            } else {
              if (currentIndex != 0) {
                setState(() {
                  currentIndex--;
                });
              }
            }
          },
          child: Container(
            color: kBackgroundColor,
            child: Column(
              children: [
                const SizedBox(height: 24),
                SizedBox(
                  height: Get.height * 0.43,
                  width: Get.width,
                  child: Entry.scale(
                    key: UniqueKey(),
                    delay: const Duration(milliseconds: 10),
                    child: SvgPicture.asset(
                      images[currentIndex],
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SvgPicture.asset(
                  'assets/icons/truth_catcher_logo.svg',
                  height: 36,
                  width: 57,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome on Truthcatcher!',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                Entry.offset(
                  key: UniqueKey(),
                  xOffset: -1000,
                  yOffset: 0,
                  delay: const Duration(milliseconds: 50),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        titles[currentIndex],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 54),
                  child: Entry.offset(
                    key: UniqueKey(),
                    xOffset: -1000,
                    yOffset: 0,
                    delay: const Duration(milliseconds: 80),
                    child: Center(
                      child: Text(
                        subTitles[currentIndex],
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Get.height * 0.05),
                SizedBox(
                  height: 10,
                  child: ListView.separated(
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentIndex == index
                            ? kPrimaryColor
                            : const Color(0xFFCAD8F8),
                      ),
                      height: 10,
                      width: 10,
                    ),
                    separatorBuilder: (context, index) => const SizedBox(
                      width: 16,
                    ),
                    itemCount: 3,
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: MaterialButton(
                    elevation: 0,
                    onPressed: () {
                      Get.offAll(() => const SignUpScreen());
                    },
                    child: Text(
                      currentIndex == 2 ? 'Next' : 'Skip',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
