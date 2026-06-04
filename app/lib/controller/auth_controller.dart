// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';
import 'package:truthcatcher/controller/user_controller.dart';
import 'package:truthcatcher/models/user_model.dart';
import 'package:truthcatcher/screens/bottom_nav_bar.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  bool isResettingPassword = true;
  bool isResettingPasswordLinkSent = false;

  void changePasswordResettingState({required bool state}) {
    if (state) {
      Get.dialog(
        const Center(
          child: Wrap(
            children: [
              LoadingAnimation(),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } else {
      Get.back();
    }
  }

  Future<bool> googleSignIn({required BuildContext context}) async {
    try {
      final String clientId = dotenv.get(kGoogleClientIdKey);
      GoogleSignIn googleSignIn =
          Platform.isIOS ? GoogleSignIn(clientId: clientId) : GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        user = userCredential.user;
        notifyListeners();
        if (userCredential.additionalUserInfo!.isNewUser) {
          await createUser(
              name: googleSignInAccount.displayName!, context: context);
          await FirebaseAuth.instance.currentUser!
              .updateDisplayName(googleSignInAccount.displayName);
          log('new google account');
          return true;
        } else {
          bool status =
              await Provider.of<UserController>(context, listen: false)
                  .getUser();
          if (status) {
            Provider.of<NtfController>(context, listen: false).getMintedNfts();
            Provider.of<NotificationController>(context, listen: false)
                .getNotifications(isRefreshing: false);
            Provider.of<TransactionController>(context, listen: false)
                .getTransactions();
            Get.offAll(() => const BottomNavBar());
          } else {
            await createUser(
                name: googleSignInAccount.displayName!, context: context);
          }
          log('old google account');
          return true;
        }
      } else {
        log('google sign in error');
        Fluttertoast.showToast(
            msg:
                'Unable to login to Google account!. Please try after sometime');
        Get.back();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        Get.back();
        Fluttertoast.showToast(
            msg: 'Account already exist, Please try to login with password');
      } else if (e.code == 'invalid-credential') {
        Get.back();
        Fluttertoast.showToast(msg: 'Invalid credentials');
      } else {
        Get.back();

        Fluttertoast.showToast(msg: e.message ?? e.code);
      }

      return false;
    } catch (error) {
      log('google sign in error $error');
      Get.back();
      Fluttertoast.showToast(msg: error.toString());

      return false;
    }
  }

  Future<bool> signUp({
    required String userName,
    required String email,
    required String password,
    required String confirmPassword,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        await createUser(name: userName, context: context);
        // send email verification link
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
        Fluttertoast.showToast(
          msg: 'Email verification link has been sent to your registered mail.',
          toastLength: Toast.LENGTH_LONG,
        );

        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        toastMessage('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        toastMessage('The account already exists for that email.');
      }
      return false;
    } catch (e) {
      log('signup error $e');
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        bool isUserCreated =
            await Provider.of<UserController>(context, listen: false).getUser();
        if (isUserCreated) {
          Provider.of<NtfController>(context, listen: false).getMintedNfts();
          Get.offAll(() => const BottomNavBar());
        } else {
          Fluttertoast.showToast(msg: 'Email is not registered!!');
        }
      }

      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        toastMessage('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        toastMessage('The account already exists for that email.');
      } else {
        toastMessage(e.code);
      }
      return false;
    } catch (error) {
      log('Login error $error');
      return false;
    }
  }

  Future<bool> createUser({
    required String name,
    String? email,
    required BuildContext context,
  }) async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        http.Response response = await http.post(
          Uri.parse('$baseUrl/users/createUser'),
          headers: {
            'Content-Type': 'application/json',
            'authorization': 'Bearer $token',
          },
          body: jsonEncode(
            email != null ? {'name': name, 'email': email} : {'name': name},
          ),
        );
        log('Create User ${response.statusCode} ${response.body}');
        if (response.statusCode == 201) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(name);
          final Map data = jsonDecode(response.body);
          final UserModel userModel = UserModel.fromMap(data['content'] ?? {});
          final String? uId = FirebaseAuth.instance.currentUser?.uid;
          await Hive.box<UserModel>(kUserBox).put(uId, userModel);
          log('USER CACHED TO HIVE');
          Provider.of<NtfController>(context, listen: false).getMintedNfts();
          Get.offAll(() => const BottomNavBar());
          return true;
        }
      }

      return false;
    } catch (error) {
      log('ERROR get user $error');
      return false;
    }
  }

  Future sendResetPasswordLink({required String email}) async {
    try {
      changePasswordResettingState(state: true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
          msg:
              "Password reset link sent to your email. Check your inbox for further instructions.",
          toastLength: Toast.LENGTH_LONG);
      isResettingPasswordLinkSent = true;
      notifyListeners();

      changePasswordResettingState(state: false);
      // Get.back();
    } catch (error) {
      isResettingPasswordLinkSent = false;
      notifyListeners();
      changePasswordResettingState(state: false);
      log(error.toString());
      toastMessage(error.toString());
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = math.Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future signInWithApple({required BuildContext context}) async {
    try {
      Get.dialog(
        const LoadingAnimation(),
        barrierDismissible: false,
      );
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'PTN2FNT976',
            redirectUri: Uri.parse(
                'https://truthcatcher-e7e9f.firebaseapp.com/__/auth/handler')),
        nonce: nonce,
      );

      final OAuthCredential oauthCredential =
          OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(oauthCredential);

      // AppleAuthProvider appleProvider = AppleAuthProvider();
      // appleProvider = appleProvider.addScope('email');
      // appleProvider = appleProvider.addScope('name');
// the line below will start the Apple sign in flow for your platform
      // final UserCredential userCredential =
      //     await FirebaseAuth.instance.signInWithProvider(appleProvider);

      user = userCredential.user;
      if (userCredential.additionalUserInfo!.isNewUser) {
        await createUser(
            name:
                appleCredential.givenName ?? appleCredential.familyName ?? 'NA',
            context: context,
            email: appleCredential.email);
        await FirebaseAuth.instance.currentUser?.updateDisplayName(
            appleCredential.givenName ?? appleCredential.familyName ?? 'NA');
        log('new google account');
      } else {
        bool status =
            await Provider.of<UserController>(context, listen: false).getUser();
        if (status) {
          Provider.of<NtfController>(context, listen: false).getMintedNfts();
          Get.offAll(() => const BottomNavBar());
        } else {
          await createUser(
              name: appleCredential.givenName ??
                  appleCredential.familyName ??
                  'NA',
              context: context,
              email: appleCredential.email);
        }
        log('old google account');
      }
      Get.back();
    } catch (error) {
      Get.back();
      log(error.toString());
    }
  }
}
