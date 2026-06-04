import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:entry/entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';
import 'package:truthcatcher/controller/user_controller.dart';
import 'package:truthcatcher/models/user_model.dart';
import 'package:truthcatcher/screens/login/login_screen.dart';
import 'package:truthcatcher/screens/onboarding/onboarding.dart';
import 'package:truthcatcher/screens/profile/archive.dart';
import 'package:truthcatcher/screens/profile/help.dart';
import 'package:truthcatcher/screens/profile/privacy_policy.dart';
import 'package:truthcatcher/screens/profile/term_and_condition.dart';
import 'package:truthcatcher/screens/transaction/my_transactions.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    List<MenuModel> menu = [
      MenuModel(
        iconPath: 'assets/icons/archive_dual_tone.svg',
        name: 'Private',
        callBack: () => Get.to(() => const Archive()),
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/transaction.svg',
        name: 'My Transactions',
        callBack: () => Get.to(() => const TransactionScreen(),
            duration: const Duration(microseconds: 200)),
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/star_icon.svg',
        hasLottie: true,
        name: 'Rate us',
        callBack: () async {
          if (Platform.isAndroid || Platform.isIOS) {
            final appId =
                Platform.isAndroid ? 'com.truthcatcher.app' : '6475279599';
            final url = Uri.parse(
              Platform.isAndroid
                  ? "market://details?id=$appId"
                  : "https://apps.apple.com/app/id/$appId",
            );
            launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          }
        },
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/terms_and_condition_icon.svg',
        name: 'Terms & Conditions',
        callBack: () => Get.to(() => const TermAndCondition()),
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/privacy_policy_icon.svg',
        name: 'Privacy Policy',
        callBack: () => Get.to(() => const ProvicyPolicy()),
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/message_icon.svg',
        name: 'Help',
        callBack: () => Get.to(() => const HelpPage()),
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/profile_delete_icon.svg',
        name: 'Delete Account',
        callBack: () => deleteAccountAlertBox(context: context),
        arrow: true,
      ),
      MenuModel(
        iconPath: 'assets/icons/logout_icon.svg',
        name: 'Logout',
        callBack: () => Get.dialog(logoutDialog(context)),
        arrow: false,
      ),
    ];
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 15.0,
        scrolledUnderElevation: 0.0,
        leading: const SizedBox(),
        leadingWidth: 0,
        centerTitle: false,
        backgroundColor: kBackgroundColor,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<UserModel>>(
          valueListenable: Hive.box<UserModel>(kUserBox).listenable(),
          builder: (context, userBox, _) {
            final String? uId = FirebaseAuth.instance.currentUser?.uid;
            final UserModel? user = userBox.get(uId);

            if (uId == null || user == null) {
              return Scaffold(
                body: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Session Expired, Please login again',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                            fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () {
                        Get.offAll(() => const LoginScreen());
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor),
                      child: Text(
                        'Login',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          color: kWhiteColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              );
            }

            log(user.toMap().toString());
            return SafeArea(
              child: LiquidPullToRefresh(
                color: kPrimaryColor,
                showChildOpacityTransition: false,
                onRefresh: () async {
                  await Provider.of<UserController>(context, listen: false)
                      .getUser();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: Get.height * 0.07),
                        UserDetailsCard(user: user),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: kWhiteColor,
                              borderRadius: BorderRadius.circular(16)),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) => menuTile(
                              iconPath: menu[index].iconPath,
                              isLottie: menu[index].hasLottie,
                              name: menu[index].name,
                              callBack: menu[index].callBack,
                              arrow: menu[index].arrow,
                            ),
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemCount: menu.length,
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
    );
  }

  Column logoutDialog(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: Get.width,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Are you sure you want to logout your \naccount?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  CustomButton(
                    enabled: true,
                    callBack: () {
                      Get.back();
                    },
                    title: 'CANCEL',
                    child: null,
                    height: 36,
                    width: 120,
                  ),
                  MaterialButton(
                    onPressed: () async {
                      try {
                        Get.offAll(() => const Onboarding());
                        Provider.of<NtfController>(context, listen: false)
                            .archivedImages
                            .clear();
                        Provider.of<NtfController>(context, listen: false)
                            .images
                            .clear();
                        Provider.of<NotificationController>(context,
                                listen: false)
                            .notifications
                            .clear();
                        Provider.of<TransactionController>(context,
                                listen: false)
                            .transactions
                            .clear();
                        Hive.box<UserModel>(kUserBox).clear();
                        await GoogleSignIn().signOut();
                        await FirebaseAuth.instance.signOut();
                      } catch (error) {
                        Fluttertoast.showToast(msg: error.toString());
                      }
                    },
                    child: Text(
                      'Logout',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget menuTile({
    required String name,
    required Function()? callBack,
    required bool arrow,
    bool isLottie = false,
    required String iconPath,
  }) {
    return MaterialButton(
      splashColor: kBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      padding: EdgeInsets.zero,
      highlightColor: Colors.transparent,
      onPressed: callBack,
      child: Row(
        children: [
          if (!isLottie) const SizedBox(width: 12),
          if (isLottie) Lottie.asset('assets/lottie/rateus.json', height: 48),
          if (!isLottie) SvgPicture.asset(iconPath),
          if (!isLottie) const SizedBox(width: 12),
          Text(
            name,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (arrow) const Icon(Iconsax.arrow_right_3)
        ],
      ),
    );
  }

  Future deleteAccountAlertBox({
    required BuildContext context,
  }) {
    return Get.dialog(
      Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: Get.width,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Are you sure you want to delete your \naccount?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    CustomButton(
                      enabled: true,
                      callBack: () {
                        Get.back();
                      },
                      title: 'CANCEL',
                      child: null,
                      height: 36,
                      width: 120,
                    ),
                    MaterialButton(
                      onPressed: () async {
                        Get.dialog(
                          const Center(child: LoadingAnimation()),
                          barrierDismissible: false,
                        );

                        await Provider.of<UserController>(context,
                                listen: false)
                            .deleteAccount();
                        Get.back();
                      },
                      child: Text(
                        'Delete account',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w400,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserDetailsCard extends StatelessWidget {
  const UserDetailsCard({
    super.key,
    required this.user,
  });

  final UserModel user;

  String generateConsistentUniqueNameFromEmail(String email) {
    // Extract the local part of the email (before the '@' symbol)
    String localPart = email.split('@').first;

    // Take the first few characters for brevity
    String shortLocalPart = localPart.substring(0, 2);

    // Generate a hash of the email to ensure uniqueness
    var bytes = utf8.encode(email); // Convert email to bytes
    var hash = sha256.convert(bytes); // Generate SHA-256 hash

    // Take a part of the hash to append for uniqueness
    String hashPart = hash
        .toString()
        .substring(3, 8); // Use the first 8 characters of the hash

    // Combine the short local part with the hash part
    String uniqueName = '$shortLocalPart$hashPart';

    return uniqueName;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEmailVerified =
        FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    return Container(
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      height: Get.height * 0.15,
      width: Get.width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 0.0,
            left: 0,
            top: 56,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: Get.width * 0.6,
                  child: Text(generateConsistentUniqueNameFromEmail(user.email),
                      // user.name.isEmpty
                      //     ? generateUniqueNameFromEmail(user.email)
                      //     : user.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(user.email,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          )),
                      const SizedBox(width: 8.0),
                      InkWell(
                        onTap: () {
                          Get.bottomSheet(Container(
                            padding: const EdgeInsets.all(16.0),
                            width: Get.width,
                            color: kWhiteColor,
                            child: isEmailVerified
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: Container(
                                          height: 3,
                                          width: 48,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24.0),
                                      Image.asset(
                                        'assets/images/validation.png',
                                        height: Get.height * 0.1,
                                      ),
                                      const SizedBox(height: 12.0),
                                      Text(
                                        'Email Verified',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 21),
                                      ),
                                      const SizedBox(height: 24.0),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Center(
                                        child: Container(
                                          height: 3,
                                          width: 48,
                                          decoration: const BoxDecoration(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24.0),
                                      Text(
                                        'Verify your email',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 21.0),
                                      ),
                                      const SizedBox(height: 16.0),
                                      Text(
                                          '${FirebaseAuth.instance.currentUser?.email} is not verified. Please verify your email inorder to make purchases!!'),
                                      const SizedBox(height: 24.0),
                                      Center(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            await FirebaseAuth
                                                .instance.currentUser
                                                ?.sendEmailVerification();

                                            Get.back();

                                            Fluttertoast.showToast(
                                              msg:
                                                  'Email verification link has been sent to your registered mail.',
                                              toastLength: Toast.LENGTH_LONG,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: kPrimaryColor),
                                          child: Text(
                                            'Send verify email link',
                                            style: GoogleFonts.montserrat(
                                              color: kWhiteColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24.0),
                                    ],
                                  ),
                          ));
                        },
                        child: Image.asset(
                          'assets/images/validation.png',
                          height: 16.0,
                          color: isEmailVerified ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -56,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Entry(
                // scale: 1.3,
                duration: const Duration(milliseconds: 1000),
                key: UniqueKey(),
                curve: Curves.easeInOutBack,
                child: Container(
                  height: 104,
                  width: 104,
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xffE0E8FC)),
                  clipBehavior: Clip.antiAlias,
                  child: SvgPicture.asset(
                    'assets/icons/iconamoon_profile-fill.svg',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MenuModel {
  MenuModel({
    required this.name,
    required this.callBack,
    required this.arrow,
    required this.iconPath,
    this.hasLottie = false,
  });
  String iconPath;
  String name;
  Function()? callBack;
  bool arrow;
  bool hasLottie;
}
