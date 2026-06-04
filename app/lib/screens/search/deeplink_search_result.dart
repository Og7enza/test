import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/screens/search/search.dart';

import '../../constant.dart';

class DeepLinkSearchResult extends StatefulWidget {
  const DeepLinkSearchResult({super.key});

  @override
  State<DeepLinkSearchResult> createState() => _DeepLinkSearchResultState();
}

class _DeepLinkSearchResultState extends State<DeepLinkSearchResult> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final nftController = Provider.of<NtfController>(context, listen: false);
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        nftController.searchNft(
            fromDeepLinks: true,
            matricule:
                Get.parameters['matricule'] ?? Get.arguments['matricule']);
      } else {
        Get.back();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        titleSpacing: 0.0,
        centerTitle: false,
        title: Text(
          'Search',
          style: TextStyle(
            fontSize: 20,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: IconThemeData(color: kPrimaryColor),
      ),
      body: Consumer<NtfController>(
          builder: (context, NtfController ntfController, _) {
        if (ntfController.deeplinkingSearchedImage == null) {
          return const Center(child: LoadingAnimation());
        }
        return SearchWidget(
          image: ntfController.deeplinkingSearchedImage!,
        );
      }),
    );
  }
}
