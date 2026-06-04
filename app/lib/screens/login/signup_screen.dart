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
import 'package:truthcatcher/screens/login/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryColor.withOpacity(0.8), width: 1),
    borderRadius: BorderRadius.circular(50),
  );
  final FocusNode userNameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> keyForm = GlobalKey<FormState>();
  bool passwordCheck = true;
  bool confirmPasswordCheck = true;

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String get email => emailController.text.trim();
  String get userName => userNameController.text.trim();
  String get password => passwordController.text.trim();
  String get confirmPassword => confirmPasswordController.text.trim();

  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: keyForm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/icons/truth_catcher_logo.svg'),
                  const SizedBox(height: 24),
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
                    'Enter your details to signup',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    controller: userNameController,
                    focusNode: userNameFocusNode,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).requestFocus(userNameFocusNode);
                      });
                    },
                    onFieldSubmitted: (val) {
                      setState(() {
                        FocusScope.of(context).requestFocus(emailFocusNode);
                      });
                    },
                    onTapOutside: (value) {
                      setState(() {});
                      FocusManager.instance.primaryFocus!.unfocus();
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter User Name';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'User Name',
                      hintStyle: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFFAEAEAE),
                        fontWeight: FontWeight.w400,
                      ),
                      fillColor: userNameFocusNode.hasFocus
                          ? kWhiteColor
                          : userNameController.text.isNotEmpty
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
                          Iconsax.user,
                          color: userNameFocusNode.hasFocus
                              ? kPrimaryColor
                              : userNameController.text.isNotEmpty
                                  ? kPrimaryColor
                                  : const Color(0xFFAEAEAE),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    textInputAction: TextInputAction.next,
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
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).requestFocus(emailFocusNode);
                      });
                    },
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    focusNode: emailFocusNode,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    onTapOutside: (value) {
                      setState(() {});
                      FocusManager.instance.primaryFocus!.unfocus();
                    },
                    onFieldSubmitted: (val) {
                      setState(() {
                        FocusScope.of(context).requestFocus(passwordFocusNode);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: GoogleFonts.montserrat(
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
                    textInputAction: TextInputAction.next,
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
                    onFieldSubmitted: (val) {
                      setState(() {
                        FocusScope.of(context)
                            .requestFocus(confirmPasswordFocusNode);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: GoogleFonts.montserrat(
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
                  const SizedBox(height: 16),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Enter Password';
                      }
                      if (passwordController.text.toLowerCase() !=
                          value.toLowerCase()) {
                        return 'Password Doesn\'t match';
                      }
                      return null;
                    },
                    controller: confirmPasswordController,
                    focusNode: confirmPasswordFocusNode,
                    obscureText: confirmPasswordCheck,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                    onTapOutside: (value) {
                      setState(() {});
                      FocusManager.instance.primaryFocus!.unfocus();
                    },
                    onTap: () {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: textTheme.displayMedium?.copyWith(
                        fontSize: 13,
                        color: const Color(0xFFAEAEAE),
                        fontWeight: FontWeight.w400,
                      ),
                      fillColor: confirmPasswordFocusNode.hasFocus
                          ? kWhiteColor
                          : confirmPasswordController.text.isNotEmpty
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
                          color: confirmPasswordFocusNode.hasFocus
                              ? kPrimaryColor
                              : confirmPasswordController.text.isNotEmpty
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
                              confirmPasswordCheck = !confirmPasswordCheck;
                            });
                          },
                          icon: Icon(
                            !confirmPasswordCheck
                                ? Iconsax.eye
                                : Iconsax.eye_slash,
                            color: confirmPasswordFocusNode.hasFocus
                                ? kPrimaryColor
                                : confirmPasswordController.text.isNotEmpty
                                    ? kPrimaryColor
                                    : const Color(0xFFAEAEAE),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: CustomButton(
                      enabled: true,
                      callBack: () async {
                        if (keyForm.currentState!.validate()) {
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
                              .signUp(
                            context: context,
                            userName: userName,
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword,
                          );
                          Get.back();
                        }
                      },
                      title: 'SIGN UP',
                      child: null,
                      height: 54,
                      width: Get.width * 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // login
                  Center(
                    child: InkWell(
                      onTap: () {
                        keyForm.currentState!.reset();
                        Get.to(() => const LoginScreen());
                      },
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Already have an account? ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: const Color(0xFF2A2A2A),
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Log In',
                                    style: GoogleFonts.montserrat(
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
                  const SizedBox(height: 16),
                  //or
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: const Color(0xFF2B2B2B).withOpacity(0.15),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'or',
                          style: textTheme.displayMedium?.copyWith(
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
                            color: const Color(0xFF2B2B2B).withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: Get.width * 0.4,
                      child: MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        onPressed: () async {
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
                            const SizedBox(width: 12),
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
                  if (Platform.isIOS) const SizedBox(height: 16),

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

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
