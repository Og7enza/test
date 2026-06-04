import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:get/route_manager.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:secure_application/secure_application.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/auth_controller.dart';
import 'package:truthcatcher/controller/deeplinks_controller.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/stripe_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';
import 'package:truthcatcher/controller/user_controller.dart';
import 'package:truthcatcher/hive_helper/register_adapters.dart';
import 'package:truthcatcher/models/user_model.dart';
import 'package:truthcatcher/screens/bottom_nav_bar.dart';
import 'package:truthcatcher/screens/login/signup_screen.dart';
import 'package:truthcatcher/screens/onboarding/onboarding.dart';
import 'package:truthcatcher/screens/search/deeplink_search_result.dart';

import 'controller/camera_controller.dart';

// DÉMO : options Firebase factices — permettent l'initialisation sans aucune
// configuration cloud (aucun appel réseau au démarrage). L'authentification
// réelle est contournée (voir l'utilisateur de démo amorcé plus bas).
const FirebaseOptions _demoFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyDEMO0truthcatcher0demo0key000000000000',
  appId: '1:123456789012:android:0000000000000000000000',
  messagingSenderId: '123456789012',
  projectId: 'truthcatcher-demo',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }
  await ScreenProtector.preventScreenshotOn();

  try {
    await Firebase.initializeApp(options: _demoFirebaseOptions);
  } catch (e) {
    log('Firebase init (démo) ignoré : $e');
  }

  registerAdapters();
  await Hive.initFlutter();
  final userBox = await Hive.openBox<UserModel>(kUserBox);
  await Hive.openBox<String?>(kDeeplinlksBox);

  // DÉMO : amorce un utilisateur local pour contourner l'auth cloud
  // (la clé "" correspond au cas `currentUser == null`).
  if (userBox.get('') == null) {
    await userBox.put(
      '',
      UserModel(
        id: 'demo',
        name: 'Démo',
        email: 'demo@truthcatcher.app',
        uid: 'demo',
        v: 0,
      ),
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return SecureApplication(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>(
              create: (context) => AuthController()),
          ChangeNotifierProvider<CameraControllerProvider>(
              create: (context) => CameraControllerProvider()),
          ChangeNotifierProvider<DeeplinksController>(
              create: (context) => DeeplinksController()),
          ChangeNotifierProvider<StripeController>(
              create: (context) => StripeController()),
          ChangeNotifierProvider<NtfController>(
              create: (context) => NtfController()),
          ChangeNotifierProvider<UserController>(
              create: (context) => UserController()),
          ChangeNotifierProvider<TransactionController>(
              create: (context) => TransactionController()),
          ChangeNotifierProvider<NotificationController>(
              create: (context) => NotificationController()),
        ],
        child: GetMaterialApp(
          navigatorKey: _navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            Widget routeWidget = const HomeScreen();
            String segment = '';
            final routeName = settings.name;
            if (routeName != null) {
              if (routeName.contains('https://')) {
                final Box<String?> deeplinksBox =
                    Hive.box<String?>(kDeeplinlksBox);
                deeplinksBox.put('deepLink', settings.name);
              }
              if (routeName.startsWith('/nftDetails/')) {
                routeWidget = const DeepLinkSearchResult();
                segment = Uri.parse(settings.name.toString()).pathSegments.last;
              }
            }
            return MaterialPageRoute(
              builder: (context) => routeWidget,
              settings: RouteSettings(
                arguments: {"matricule": segment},
                name: settings.name,
              ),
              fullscreenDialog: true,
            );
          },
          defaultTransition: Transition.native,
          debugShowCheckedModeBanner: false,
          title: 'Truth Catcher',
          theme: ThemeData(
            fontFamily: 'Century Gothic',
            appBarTheme: const AppBarTheme(titleSpacing: 0.0),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<UserModel>>(
      valueListenable: Hive.box<UserModel>(kUserBox).listenable(),
      builder: (context, userBox, _) {
        String? uId;
        try {
          uId = FirebaseAuth.instance.currentUser?.uid;
        } catch (_) {
          uId = null;
        }
        final UserModel? user = userBox.get(uId ?? "");
        if (user == null) {
          return const Onboarding();
        } else if (user.email.isEmpty || user.name.isEmpty) {
          return const SignUpScreen();
        } else {
          return const BottomNavBar();
        }
      },
    );
  }
}
