import 'dart:developer';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';

import '../constant.dart';
import '../screens/search/deeplink_search_result.dart';

class DeeplinksController extends ChangeNotifier {
  DeeplinksController() {
    log('================ initializing deeplinks in controller =================='
        .toUpperCase());
    initUniLinks();
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
    log('handling deeplinks in main');
    final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (currentUser == null) {
      Box<String?> deeplinksBox = Hive.box<String?>(kDeeplinlksBox);
      deeplinksBox.put('deepLink', uri.path);
    }
    if (token != null) {
      String path = uri.path;
      if (path.contains('nftDetails')) {
        log(uri.pathSegments.last);
        Get.to(() => const DeepLinkSearchResult(),
            arguments: {"matricule": uri.pathSegments.last});
      }
    } else {
      log('Token is null');
    }
  }
}
