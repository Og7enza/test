import 'dart:developer';
import 'dart:io';

import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/stripe_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';

import '../../models/coupon.dart';
import 'image_preview.dart';

class PaymentSummary extends StatefulWidget {
  final File? file;
  final String name;
  final String location;
  final Position position;
  final DateTime? dateTime;
  const PaymentSummary({
    required this.file,
    required this.name,
    required this.location,
    required this.position,
    required this.dateTime,
    super.key,
  });

  @override
  State<PaymentSummary> createState() => _PaymentSummaryState();
}

class _PaymentSummaryState extends State<PaymentSummary>
    with SingleTickerProviderStateMixin {
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Provider.of<NtfController>(context, listen: false).getCoupons();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String get code => _couponController.text.trim();
  bool isCouponApplied = false;
  Coupon? selectedCoupon;
  final double nftGenerationPrice = 0.59;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: kPrimaryColor),
        centerTitle: false,
        titleSpacing: 0.0,
        backgroundColor: kBackgroundColor,
        title: Text(
          'Payment Summary',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Consumer<NtfController>(
          builder: (context, NtfController nftController, _) {
        return Consumer<StripeController>(
            builder: (context, StripeController stripeController, _) {
          bool hasProduct =
              stripeController.products.any((element) => element.id == '1234');

          ProductDetails? product;
          if (hasProduct) {
            product = stripeController.products
                .firstWhere((element) => element.id == '1234');
          }

          bool isValid = nftController.isValid;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 24),
                  Text(
                    'Bill Details',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: kWhiteColor),
                      padding: const EdgeInsets.only(top: 16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'NFT generation fee',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    Text(
                                      Platform.isIOS && hasProduct
                                          ? product!.price
                                          : ('€ ${nftGenerationPrice.toStringAsFixed(2)}'),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (nftController.coupons.isNotEmpty)
                                  couponTile(nftController),
                              ],
                            ),
                          ),
                          paymentDetailsCard(product, hasProduct),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Get.height * 0.03),
                  if (!isValid)
                    Column(
                      children: [
                        SizedBox(height: Get.height * 0.02),
                        Text(
                          "Your device date is inaccurate! Adjust your clock and try again.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(color: Colors.black),
                        ),
                        const SizedBox(height: 16.0),
                        Text(
                          "Your device date and time is",
                          style: GoogleFonts.montserrat(),
                        ),
                        Text(
                          DateFormat("dd/mm/yyyy, h:mm a")
                              .format(DateTime.now()),
                          style: GoogleFonts.montserrat(),
                        ),
                        SizedBox(height: Get.height * 0.03),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                elevation: 4.0,
                                fixedSize: Size(Get.width * 0.5, 54),
                                backgroundColor: kPrimaryColor),
                            onPressed: () async {
                              SettingsUtil.openDateTimeSettings();
                            },
                            child: Text("Adjust".toUpperCase(),
                                style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kWhiteColor))),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  if (isValid)
                    Column(
                      children: [
                        if (Platform.isIOS)
                          iosPaymentButton(
                              context, nftController, product, hasProduct),
                        if (Platform.isAndroid)
                          androidPaymentButton(context, nftController,
                              stripeController, product),
                        const SizedBox(height: 50),
                      ],
                    )
                ],
              ),
            ),
          );
        });
      }),
    );
  }

  Center androidPaymentButton(BuildContext context, NtfController nftController,
      StripeController stripeController, ProductDetails? product) {
    return Center(
      child: CustomButton(
        child: null,
        callBack: () async {
          final NotificationController notificationController =
              Provider.of<NotificationController>(context, listen: false);
          final TransactionController transactionController =
              Provider.of<TransactionController>(context, listen: false);

          if (isCouponApplied) {
            await nftController.mintNft(
                applePaymentTransactionId: '',
                isCouponApplied: isCouponApplied,
                image: widget.file!,
                amount: 0,
                currency: '€',
                notificationController: notificationController,
                ntfController: nftController,
                stripeTransactionId: '',
                transactionController: transactionController,
                name: widget.name,
                location: widget.location,
                position: widget.position,
                date: widget.dateTime);
          } else {
            await stripeController.makePayment(
              amount: 0.59,
              isCouponApplied: isCouponApplied,
              notificationController: notificationController,
              transactionController: transactionController,
              ntfController: nftController,
              image: widget.file!,
              name: widget.name,
              location: widget.location,
              position: widget.position,
              date: widget.dateTime,
            );
          }
        },
        title: 'PROCEED TO PAY',
        height: 54,
        width: Get.width * 0.5,
        enabled: true,
      ),
    );
  }

  Center iosPaymentButton(BuildContext context, NtfController nftController,
      ProductDetails? product, bool hasProduct) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final NotificationController notificationController =
              Provider.of<NotificationController>(context, listen: false);
          final TransactionController transactionController =
              Provider.of<TransactionController>(context, listen: false);

          final StripeController stripeController =
              Provider.of<StripeController>(context, listen: false);

          if (isCouponApplied) {
            await nftController.mintNft(
                applePaymentTransactionId: '',
                isCouponApplied: isCouponApplied,
                image: widget.file!,
                amount: 0,
                currency: product?.currencySymbol ?? '€',
                notificationController: notificationController,
                ntfController: nftController,
                stripeTransactionId: '',
                transactionController: transactionController,
                name: widget.name,
                location: widget.location,
                position: widget.position,
                date: widget.dateTime);
          } else {
            if (product != null) {
              await stripeController.buy(
                nftController: nftController,
                currency: product.currencyCode,
                product: product,
                amount: product.rawPrice,
                notificationController: notificationController,
                transactionController: transactionController,
                image: widget.file!,
                name: widget.name,
                location: widget.location,
                position: widget.position,
                date: widget.dateTime,
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
            disabledBackgroundColor: kPrimaryAccentColor,
            backgroundColor: kPrimaryColor,
            fixedSize: Size(Get.width * 0.5, 54)),
        child: Text('Continue',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: kWhiteColor,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  AnimatedSize paymentDetailsCard(ProductDetails? product, bool hasProduct) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeIn,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: kPrimaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isCouponApplied)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform Fee',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: kWhiteColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        Platform.isIOS
                            ? product!.price
                            : '€ ${nftGenerationPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: kWhiteColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Coupon applied',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: kWhiteColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: Text(
                              Platform.isIOS
                                  ? product!.price
                                  : '€ ${nftGenerationPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kWhiteColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Transform.rotate(
                                angle: 12.1,
                                child: Container(
                                  height: 1,
                                  width: Platform.isIOS ? 30 : 50,
                                  color: kWhiteColor,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                      height: 10, thickness: 1, color: Color(0xFFF2F2F2)),
                  const SizedBox(height: 8.0),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'To Pay',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: kWhiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  isCouponApplied && Platform.isIOS
                      ? '${product!.currencySymbol}0.0'
                      : isCouponApplied
                          ? '€ 0.00'
                          : Platform.isIOS && hasProduct
                              ? product!.price
                              : '€ ${nftGenerationPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: kWhiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Column couponTile(NtfController nftController) {
    return Column(
      children: [
        Divider(height: 8, color: const Color(0xFF2B2B2B).withOpacity(0.13)),
        ExpansionTile(
          dense: true,
          tilePadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            height: 28,
            width: 28,
            decoration: BoxDecoration(
              color: kBackgroundColor,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(6),
            child: SvgPicture.asset(
              'assets/icons/coupon_icon.svg',
            ),
          ),
          title: Row(
            children: [
              Text(
                isCouponApplied
                    ? "Coupon (${nftController.appliedCoupon?.coupon})"
                    : 'Apply Coupon',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          collapsedIconColor: kPrimaryColor,
          children: [
            const SizedBox(height: 6),

            Row(
              children: [
                Flexible(
                  child: SizedBox(
                    height: 40,
                    child: TextFormField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.montserrat(fontSize: 13),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        suffixIcon: code.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  setState(() {
                                    _couponController.clear();
                                    isCouponApplied = false;
                                  });
                                },
                                icon: const Icon(Icons.close))
                            : null,
                        contentPadding: const EdgeInsets.all(10),
                        isDense: true,
                        hintText: 'Enter coupon code',
                        hintStyle: GoogleFonts.montserrat(fontSize: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                MaterialButton(
                  height: 40,
                  onPressed: nftController.isVerifingCoupon ||
                          code.isEmpty ||
                          isCouponApplied
                      ? null
                      : () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (code.isEmpty) {
                            Fluttertoast.showToast(
                                msg: 'Please enter a valid coupon code');
                            return;
                          }
                          final bool isValidCoupon =
                              await nftController.verifyCoupon(code: code);

                          if (isValidCoupon) {
                            setState(() {
                              isCouponApplied = true;
                            });
                          } else {
                            setState(() {
                              _couponController.clear();
                              isCouponApplied = false;
                            });
                          }
                        },
                  color: kPrimaryColor,
                  elevation: 0,
                  disabledColor: isCouponApplied
                      ? Colors.green.shade500
                      : kPrimaryAccentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  child: nftController.isVerifingCoupon
                      ? SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(kWhiteColor),
                          ))
                      : Text(
                          isCouponApplied ? 'Applied' : 'Apply',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: kWhiteColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                )
              ],
            ),
            // if (nftController.coupons.isNotEmpty)
            const SizedBox(height: 16),
            // if (nftController.coupons.isNotEmpty)
            //   Divider(
            //     height: 1,
            //     color: const Color(0xFF2B2B2B).withOpacity(0.13),
            //   ),

            // if (nftController.coupons.isNotEmpty)
            //   nftController.isFetchingCoupon
            //       ? SizedBox(
            //           width: Get.width,
            //           child: const Column(
            //             children: [
            //               SizedBox(height: 8.0),
            //               CouponLoadingShimmer(),
            //               SizedBox(height: 8.0),
            //               CouponLoadingShimmer(),
            //               SizedBox(height: 8.0),
            //             ],
            //           ),
            //         )
            //       : ListView.builder(
            //           padding: EdgeInsets.zero,
            //           itemCount: nftController.coupons.length,
            //           physics: const NeverScrollableScrollPhysics(),
            //           itemBuilder: (context, index) {
            //             Coupon currentCoupon = nftController.coupons[index];
            //             return Padding(
            //               padding: const EdgeInsets.symmetric(vertical: 6),
            //               child: Row(
            //                 crossAxisAlignment: CrossAxisAlignment.center,
            //                 children: [
            //                   Expanded(
            //                     flex: 20,
            //                     child: Text(
            //                       currentCoupon.description,
            //                       style: GoogleFonts.montserrat(
            //                         height: 1.5,
            //                         fontSize: 12,
            //                         color: Colors.black,
            //                         fontWeight: FontWeight.w400,
            //                       ),
            //                     ),
            //                   ),
            //                   const SizedBox(width: 8),
            //                   IconButton(
            //                     onPressed: () {
            //                       FocusManager.instance.primaryFocus?.unfocus();
            //                       if (!isCouponApplied) {
            //                         nftController.applyCoupon(
            //                             coupon: currentCoupon);
            //                         setState(() {
            //                           selectedCoupon = currentCoupon;
            //                           isCouponApplied = true;
            //                           _couponController.text =
            //                               currentCoupon.coupon;
            //                         });
            //                       } else {
            //                         if (currentCoupon == selectedCoupon) {
            //                           nftController.applyCoupon(coupon: null);
            //                           setState(() {
            //                             selectedCoupon = null;
            //                             isCouponApplied = false;
            //                             _couponController.text = '';
            //                           });
            //                         } else {
            //                           nftController.applyCoupon(
            //                               coupon: currentCoupon);
            //                           setState(() {
            //                             selectedCoupon = currentCoupon;
            //                             isCouponApplied = true;
            //                             _couponController.text =
            //                                 currentCoupon.coupon;
            //                           });
            //                         }
            //                       }
            //                     },
            //                     icon: isCouponApplied &&
            //                             selectedCoupon?.id == currentCoupon.id
            //                         ? Container(
            //                             decoration: const BoxDecoration(
            //                               color: Colors.green,
            //                               shape: BoxShape.circle,
            //                             ),
            //                             padding: const EdgeInsets.all(2),
            //                             child: Icon(
            //                               Icons.done,
            //                               size: 16,
            //                               color: kWhiteColor,
            //                             ))
            //                         : const Icon(Icons.circle_outlined),
            //                   )
            //                 ],
            //               ),
            //             );
            //           },
            //           shrinkWrap: true,
            //         ),
          ],
        ),
        // const SizedBox(height: 8),
      ],
    );
  }

  Container _header() {
    return Container(
      width: Get.width,
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: widget.file!.path,
            child: Container(
              height: Get.height * 0.15,
              width: Get.height * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                widget.file!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 15.0),
          Flexible(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Entry.offset(
                  duration: const Duration(milliseconds: 600),
                  yOffset: 30,
                  child: Text(
                    widget.name.trim(),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.dateTime != null)
                  Entry.offset(
                    duration: const Duration(milliseconds: 800),
                    yOffset: 40,
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(widget.dateTime!),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Entry.offset(
                  duration: const Duration(milliseconds: 1000),
                  yOffset: 50,
                  child: Text(
                    widget.location.trim(),
                    style: GoogleFonts.montserrat(
                      height: 1.1,
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CouponLoadingShimmer extends StatelessWidget {
  const CouponLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade100,
            highlightColor: Colors.grey.shade200,
            child: Container(
              height: 35,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
                color: Colors.grey.shade100,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade100,
          highlightColor: Colors.grey.shade200,
          child: Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}
