import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/models/user_model.dart';
import 'package:truthcatcher/screens/onboarding/onboarding.dart';

class UserController extends ChangeNotifier {
  UserModel? user;
  bool errorValue = false;
  Future<bool> getUser() async {
    try {
      log('FETCHING USER');
      user = null;
      errorValue = false;
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        http.Response response = await http
            .get(Uri.parse('$baseUrl/users/getUser'), headers: {
          'authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        });
        if (response.statusCode == 200) {
          final Map data = jsonDecode(response.body);
          final Map rawUSer = data['content'];
          user = UserModel.fromMap(rawUSer);
          final UserModel userModel = UserModel.fromMap(rawUSer);
          final String? uId = FirebaseAuth.instance.currentUser?.uid;
          await Hive.box<UserModel>(kUserBox).put(uId, userModel);
          log('USER CACHED TO HIVE');
          log(rawUSer.toString());

          await FirebaseAuth.instance.currentUser?.reload();
          return true;
        } else {
          errorValue = true;
          notifyListeners();
        }
      }
      return false;
    } catch (error) {
      errorValue = true;
      log('ERROR get user $error');
      Get.back();
      notifyListeners();
      return false;
    }
  }

  Future deleteAccount() async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      final User? user = FirebaseAuth.instance.currentUser;

      if (token != null && user != null) {
        await user.delete();
        http.Response response = await http.delete(
          Uri.parse('$baseUrl/users/deleteUser'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          await FirebaseAuth.instance.currentUser?.delete();
          Get.offAll(() => const Onboarding());
        } else {
          log(response.body);
          Map data = jsonDecode(response.body) as Map;
          Fluttertoast.showToast(
              msg: data['message'] ??
                  "Something is wrong, please try again later!");
        }
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        Get.back();
        showReauthenticationDialog();
        return;
      }

      Fluttertoast.showToast(
        toastLength: Toast.LENGTH_LONG,
        msg: error.message.toString(),
      );
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  void showReauthenticationDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        scrollable: false,
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: const Color(0xFFEEEAFC),
        titlePadding: const EdgeInsets.all(16),
        insetPadding: const EdgeInsets.all(16),
        contentPadding: const EdgeInsets.all(12),
        buttonPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: Get.height * 0.3),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Re-authentication Required',
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'To perform this action, we need you to log in again. This is required for sensitive operations like changing your password or deleting your account. Please log in again to proceed.',
                  style: GoogleFonts.montserrat(fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: kPrimaryColor,
                  ),
                  child: Text('Re-authenticate',
                      style: GoogleFonts.montserrat(color: kWhiteColor)),
                  onPressed: () async {
                    try {
                      Get.offAll(() => const Onboarding());

                      Hive.box<UserModel>(kUserBox).clear();
                      await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                    } catch (error) {
                      Fluttertoast.showToast(msg: error.toString());
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true, // Prevents dismissing by tapping outside
    );
    // title: 'Re-authentication Required',

    // content: const Padding(
    //   padding: EdgeInsets.all(8.0),
    //   child: Text(
    //     'To perform this action, we need you to log in again. This is required for sensitive operations like changing your password or deleting your account. Please log in again to proceed.',
    //     style: TextStyle(fontSize: 16.0),
    //   ),
    // ),
    // textConfirm: 'Re-authenticate',
    // confirmTextColor: Colors.white,
    // onConfirm: () {
    //   Get.back();
    //   // Navigate to the re-authentication screen or show a login dialog
    // },
    // );
  }
}
