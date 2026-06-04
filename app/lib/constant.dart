import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

// urls

// String baseUrl = 'https://truthcatcher.wielabs.tech/api/v1';
String baseUrl = 'https://backend.truthcatcher.com/api/v1';

String kStripeBaseUrl = 'https://api.stripe.com/v1/payment_intents';
// String baseUrl = 'http://192.168.50.67:4000/api/v1';
// String baseUrl = 'http://192.168.50.129:4000/api/v1';
// String baseUrl = 'http://192.168.50.22:4010/api/v1';

// Colors
Color kBackgroundColor = const Color(0xFFEEEAFC);
// Color kBackgroundColor = const Color(0xFFEAF0FD);
Color kPrimaryColor = const Color(0xFF2D64E3);
Color kWhiteColor = Colors.white;
Color kPrimaryAccentColor = const Color(0xFF2D64E3).withOpacity(0.2);

// scerets
const String kGoogleClientIdKey = 'GOOGLE_CLIENT_ID';
// Hive
const String kUserBox = 'USER_BOX';
const String kDeeplinlksBox = 'DEEP_LINKING_BOX';

class CustomButton extends StatefulWidget {
  final String? title;
  final Widget? child;
  final double height;
  final double width;
  final Function()? callBack;
  final bool enabled;
  const CustomButton({
    required this.callBack,
    required this.title,
    required this.child,
    required this.height,
    required this.width,
    required this.enabled,
    super.key,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: MaterialButton(
        disabledColor: Colors.grey.shade300,
        color: widget.enabled
            ? kPrimaryColor
            : const Color(0xff2D64E3).withOpacity(0.5),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: widget.enabled ? 4 : 0,
        onPressed: widget.callBack,
        child: Center(
          child: widget.child ??
              Text(
                widget.title!,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: kWhiteColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ),
      ),
    );
  }
}

class RightCurve extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    paint.color = kWhiteColor;
    path = Path();
    path.lineTo(size.width * 0.05, size.height);
    path.cubicTo(size.width * 0.05, size.height, 0, size.height * 0.01, 0,
        size.height * 0.01);
    path.cubicTo(0, size.height * 0.01, size.width / 5, size.height * 0.48,
        size.width * 0.4, size.height * 0.72);
    path.cubicTo(size.width * 0.6, size.height * 0.97, size.width, size.height,
        size.width, size.height);
    path.cubicTo(size.width, size.height, size.width * 0.05, size.height,
        size.width * 0.05, size.height);
    path.cubicTo(size.width * 0.05, size.height, size.width * 0.05, size.height,
        size.width * 0.05, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

toastMessage(String msg) {
  return Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: kWhiteColor,
    fontSize: 16.0,
  );
}

class LoadingAnimation extends StatelessWidget {
  const LoadingAnimation({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: kWhiteColor,
          boxShadow: const [
            BoxShadow(
              offset: Offset(5, 5),
              color: Colors.black26,
              blurRadius: 10,
            ),
          ],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: LoadingAnimationWidget.stretchedDots(
          color: kPrimaryColor,
          size: 24.0,
        ),
      ),
    );
  }
}
