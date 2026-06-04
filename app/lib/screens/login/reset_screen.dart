import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/auth_controller.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryColor, width: 1),
    borderRadius: BorderRadius.circular(50),
  );
  final FocusNode emailFocusNode = FocusNode();
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String get email => emailController.text.trim();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Consumer<AuthController>(
          builder: (context, AuthController authController, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/icons/truth_catcher_logo.svg'),
                    const SizedBox(height: 50),
                    Text(
                      'Reset Password',
                      style: textTheme.displayLarge!.copyWith(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter Email-Id associated with your account to reset password',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 52),
                    TextFormField(
                      controller: emailController,
                      focusNode: emailFocusNode,
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
                      onChanged: (value) {
                        setState(() {});
                      },
                      onFieldSubmitted: (value) {
                        formKey.currentState!.validate();
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
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 60),
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
                    const SizedBox(height: 40),
                    Center(
                      child: CustomButton(
                        enabled: email.isNotEmpty,
                        callBack: () async {
                          if (formKey.currentState!.validate()) {
                            authController.isResettingPasswordLinkSent = false;
                            await authController.sendResetPasswordLink(
                                email: email);
                            emailController.clear();
                          }
                        },
                        title: 'CONFIRM MAIL',
                        height: 54,
                        width: Get.width * 0.5,
                        child: null,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (authController.isResettingPasswordLinkSent)
                      Container(
                        width: Get.width,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Password reset link has been sent to\nyour Email!',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
