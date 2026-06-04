// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/auth_controller.dart';
import 'package:truthcatcher/screens/login/reset_screen.dart';
import 'package:truthcatcher/screens/login/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(
      color: kPrimaryColor,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(50),
  );
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordCheck = true;
  bool confirmPasswordCheck = true;
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/icons/truth_catcher_logo.svg',
                  ),
                  const SizedBox(height: 50),
                  RichText(
                    text: TextSpan(
                        text: 'Join Our\n',
                        style: textTheme.displayLarge!.copyWith(
                          color: kPrimaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: 'Community Today',
                            style: textTheme.displayLarge!.copyWith(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Entering your details to Login',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 52),
                  TextFormField(
                    validator: (email) {
                      if (email!.isEmpty) {
                        return "Email cannot be empty";
                      } else {
                        bool valid =
                            EmailValidator.validate(emailController.text);
                        if (!valid) {
                          return 'Email address is not valid';
                        }
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    focusNode: emailFocusNode,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    onFieldSubmitted: (val) {
                      setState(() {
                        FocusScope.of(context).requestFocus(passwordFocusNode);
                      });
                    },
                    onTap: () => setState(() =>
                        FocusScope.of(context).requestFocus(emailFocusNode)),
                    onTapOutside: (value) {
                      FocusManager.instance.primaryFocus!.unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: textTheme.displaySmall?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFFAEAEAE),
                        fontWeight: FontWeight.w400,
                      ),
                      fillColor: emailFocusNode.hasFocus
                          ? kWhiteColor
                          : emailController.text.isNotEmpty
                              ? kWhiteColor
                              : Colors.transparent,
                      filled: true,
                      border: border,
                      errorBorder: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      disabledBorder: border,
                      focusedErrorBorder: border,
                      prefixIconConstraints: const BoxConstraints(minWidth: 60),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 18, right: 8),
                        child: Icon(
                          Iconsax.sms,
                          color: emailFocusNode.hasFocus
                              ? kPrimaryColor
                              : emailController.text.isNotEmpty
                                  ? kPrimaryColor
                                  : const Color(0xFFAEAEAE),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter Password';
                      }
                      return null;
                    },
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    obscureText: passwordCheck,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    onTapOutside: (value) {
                      setState(() {
                        FocusManager.instance.primaryFocus!.unfocus();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: textTheme.displaySmall?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFFAEAEAE),
                        fontWeight: FontWeight.w400,
                      ),
                      fillColor: passwordFocusNode.hasFocus
                          ? kWhiteColor
                          : passwordController.text.isNotEmpty
                              ? kWhiteColor
                              : Colors.transparent,
                      filled: true,
                      border: border,
                      errorBorder: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      disabledBorder: border,
                      focusedErrorBorder: border,
                      prefixIconConstraints: const BoxConstraints(minWidth: 60),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 18, right: 8),
                        child: Icon(
                          Iconsax.password_check,
                          color: passwordFocusNode.hasFocus
                              ? kPrimaryColor
                              : passwordController.text.isNotEmpty
                                  ? kPrimaryColor
                                  : const Color(0xFFAEAEAE),
                        ),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: IconButton(
                          splashRadius: 20,
                          onPressed: () {
                            setState(() {
                              passwordCheck = !passwordCheck;
                            });
                          },
                          icon: Icon(
                            !passwordCheck ? Iconsax.eye : Iconsax.eye_slash,
                            color: passwordFocusNode.hasFocus
                                ? kPrimaryColor
                                : passwordController.text.isNotEmpty
                                    ? kPrimaryColor
                                    : const Color(0xFFAEAEAE),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: MaterialButton(
                      onPressed: () {
                        emailController.clear();
                        passwordController.clear();
                        Provider.of<AuthController>(context, listen: false)
                            .isResettingPasswordLinkSent = false;
                        Get.to(() => const ResetPassword());
                      },
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: CustomButton(
                      enabled: true,
                      callBack: () async {
                        if (formKey.currentState!.validate()) {
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
                          await Provider.of<AuthController>(context,
                                  listen: false)
                              .login(
                            context: context,
                            email: emailController.text,
                            password: passwordController.text,
                          );
                          Get.back();
                        }
                      },
                      title: 'LOG IN',
                      child: null,
                      height: 54,
                      width: Get.width * 0.5,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: InkWell(
                      onTap: () {
                        Get.off(() => const SignUpScreen());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'New to our platform? ',
                                style: textTheme.displayMedium?.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF2A2A2A),
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign up',
                                    style: textTheme.displayMedium?.copyWith(
                                      fontSize: 14,
                                      color: kPrimaryColor,
                                      fontWeight: FontWeight.w500,
                                      decoration: TextDecoration.underline,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF2B2B2B).withOpacity(0.15),
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Text(
                          'or',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF2B2B2B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: Divider(
                              color: const Color(0xFF2B2B2B).withOpacity(0.15)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width: Get.width * 0.4,
                      child: MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        onPressed: () async {
                          Get.dialog(
                            const LoadingAnimation(),
                            barrierDismissible: false,
                          );
                          emailController.clear();
                          passwordController.clear();
                          await Provider.of<AuthController>(context,
                                  listen: false)
                              .googleSignIn(context: context);
                          Get.back();
                        },
                        color: kWhiteColor,
                        height: 54,
                        minWidth: Get.width * 0.5,
                        elevation: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icons/google_icon.svg',
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'GOOGLE',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: const Color(0xFF2B2B2B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (Platform.isIOS)
                    Center(
                      child: MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        onPressed: () async {
                          emailController.clear();
                          passwordController.clear();
                          await Provider.of<AuthController>(context,
                                  listen: false)
                              .signInWithApple(context: context);
                        },
                        color: kWhiteColor,
                        height: 54,
                        elevation: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.apple,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 10),
                            Text('Signup with Apple'.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: const Color(0xFF2B2B2B),
                                  fontWeight: FontWeight.w600,
                                ))
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
