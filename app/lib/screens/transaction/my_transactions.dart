import 'dart:developer';

import 'package:animated_floating_widget/animated_floating_widget.dart';
import 'package:animated_floating_widget/widgets/floating_widget.dart';
import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/models/transaction.dart';
import 'package:truthcatcher/screens/gallery/image_details.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          scrolledUnderElevation: 0.0,
          iconTheme: IconThemeData(color: kPrimaryColor),
          centerTitle: false,
          backgroundColor: kBackgroundColor,
          titleSpacing: 0.0,
          title: Text(
            'My Transactions',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          )),
      body: Consumer<TransactionController>(
          builder: (context, TransactionController transactionController, _) {
        List<Transaction> transactions =
            transactionController.transactions.reversed.toList();

        return LiquidPullToRefresh(
          color: kPrimaryColor,
          springAnimationDurationInMilliseconds: 300,
          showChildOpacityTransition: false,
          onRefresh: () async {
            await transactionController.refreshTransactions();
          },
          child: Builder(builder: (context) {
            if (transactionController.transactions.isEmpty) {
              return const EmptyTransactionsCard();
            }
            return ListView.separated(
                controller: transactionController.controller,
                physics: const AlwaysScrollableScrollPhysics(),
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12.0),
                itemCount: transactions.length,
                padding: EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 16.0,
                    bottom: Get.height * 0.1),
                itemBuilder: (context, index) {
                  final Transaction currentTransaction = transactions[index];
                  final int duration =
                      ((index + 1) * 150) > 800 ? 800 : (index + 1) * 150;
                  return Entry(
                    duration: Duration(milliseconds: duration),
                    scale: 0.6,
                    key: ValueKey(currentTransaction.id),
                    child:
                        TransactionCard(currentTransaction: currentTransaction),
                  );
                });
          }),
        );
      }),
      backgroundColor: kBackgroundColor,
    );
  }
}

class CustomAnimatedWidget extends StatelessWidget {
  const CustomAnimatedWidget({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final int duration = (index + 1) * 100 > 500 ? 500 : (index + 1) * 100;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween<double>(begin: 0.7, end: 1),
      builder: (context, value, _) => AnimatedScale(
        scale: value,
        duration: Duration(milliseconds: duration),
        child: child,
      ),
    );
  }
}

class EmptyTransactionsCard extends StatelessWidget {
  const EmptyTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Get.height,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Get.height * 0.25),
            FloatingWidget(
              verticalSpace: 4,
              duration: const Duration(seconds: 2),
              reverseDuration: const Duration(seconds: 2),
              child: SvgPicture.asset('assets/icons/no_trans.svg',
                  height: Get.height * 0.13),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: SizedBox(
                width: Get.width * 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'No pending or completed transactions. Stay informed as your deals unfold!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.currentTransaction,
  });

  final Transaction currentTransaction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        log(currentTransaction.toString());
        final NtfController ntfController =
            Provider.of<NtfController>(context, listen: false);

        List<MintedImage> images = ntfController.images;
        List<MintedImage> archivedImages = ntfController.archivedImages;
        if (images.any(
            (element) => element.matricule == currentTransaction.matricule)) {
          MintedImage image = images.firstWhere(
              (element) => element.matricule == currentTransaction.matricule);
          ntfController.setSelectedImage(image: image);

          Get.to(() => ImageDetails(
              image: image, isArchived: false, fromNotifications: false));
        } else if (archivedImages.any(
            (element) => element.matricule == currentTransaction.matricule)) {
          MintedImage image = archivedImages.firstWhere(
              (element) => element.matricule == currentTransaction.matricule);
          ntfController.setSelectedImage(image: image);

          Get.to(() => ImageDetails(
              image: image, isArchived: true, fromNotifications: false));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
            color: kWhiteColor, borderRadius: BorderRadius.circular(12.0)),
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid For',
                style: GoogleFonts.montserrat(
                    fontSize: 14.0, fontWeight: FontWeight.w600),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(currentTransaction.date),
                style: GoogleFonts.montserrat(
                    fontSize: 13.0, color: const Color(0xFF2B2B2B)),
              )
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Matricule no.',
                    style: GoogleFonts.montserrat(
                        fontSize: 13.0, fontWeight: FontWeight.w500),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: currentTransaction.matricule));
                      HapticFeedback.lightImpact();
                      Fluttertoast.showToast(msg: 'Copied to clipboard');
                    },
                    child: Row(
                      children: [
                        Text(
                          currentTransaction.matricule,
                          style: GoogleFonts.montserrat(
                              fontSize: 13.0, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4.0),
                        const Icon(
                          Iconsax.copy,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                    color: kPrimaryAccentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.0)),
                child: Text(
                  '${currentTransaction.currency} ${(currentTransaction.amount).toStringAsFixed(2)} paid',
                  style: GoogleFonts.montserrat(
                      fontSize: 13.0, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
