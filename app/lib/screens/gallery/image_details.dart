import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/stripe_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/screens/search/search.dart';
import 'package:truthcatcher/utils/extensions.dart';

import '../../controller/notification_controller.dart';
import '../../models/coupon.dart';

class ImageDetails extends StatefulWidget {
  final MintedImage image;
  final bool isArchived;
  final bool fromNotifications;
  const ImageDetails({
    required this.image,
    required this.isArchived,
    required this.fromNotifications,
    super.key,
  });

  @override
  State<ImageDetails> createState() => _ImageDetailsState();
}

class _ImageDetailsState extends State<ImageDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<NtfController>(context, listen: false).getCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NtfController>(
        builder: (context, NtfController nftController, _) {
      final List<MintedImage> images = widget.isArchived
          ? nftController.archivedImages
          : nftController.images;
      final MintedImage selectedImage =
          nftController.selectedImage ?? widget.image;
      return Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            backgroundColor: kBackgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0.0,
            titleSpacing: 0.0,
            centerTitle: false,
            title: Text(
              widget.isArchived ? 'Private Images' : 'Gallery',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            iconTheme: IconThemeData(color: kPrimaryColor),
            actions: [
              Tooltip(
                message: 'Share',
                child: IconButton(
                    splashRadius: 20,
                    onPressed: () {
                      Share.share(
                        'Excited to share my latest NFT drop!(${widget.image.matricule}) 🎨 This unique piece is now part of the blockchain, capturing a moment in digital art. Each piece tells a story, and I\'m thrilled to share this one with you 🔗 ${'https://truthcatcher.com/nftDetails/${widget.image.matricule}'}',
                      );
                    },
                    icon: SvgPicture.asset('assets/icons/share.svg')),
              ),
              Tooltip(
                message: widget.isArchived ? 'UnArchive' : 'Archive',
                child: IconButton(
                  splashRadius: 20,
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Are you sure you want to ${widget.isArchived ? 'remove this image from' : 'move this image to'} private images?',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Note: Images are ${!widget.isArchived ? 'not ' : ''}visible in searches when marked as ${widget.isArchived ? "Public" : "Private"}.',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          OutlinedButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.black)),
                            child: Text(
                              'Cancel',
                              style:
                                  GoogleFonts.montserrat(color: Colors.black),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (!widget.isArchived) {
                                nftController.archiveNft();

                                setState(() {});
                              } else {
                                nftController.unArchiveNft(
                                    image: nftController.selectedImage!);
                                setState(() {});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor),
                            child: Text(
                              'Move',
                              style: GoogleFonts.montserrat(
                                  color: kWhiteColor,
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                  icon: widget.isArchived
                      ? SvgPicture.asset('assets/icons/unarchive.svg')
                      : SvgPicture.asset('assets/icons/archive.svg'),
                ),
              ),
              const SizedBox(width: 15.0),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Hero(
                                  tag: widget.fromNotifications
                                      ? UniqueKey()
                                      : selectedImage.id,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // image
                                      NftImageWidget(image: selectedImage),
                                      // matricule
                                      MatriculeWidget(
                                          selectedImage: selectedImage)
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Entry(
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                        'assets/icons/gallery_icon.svg'),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: Get.width * 0.5,
                                      child: Text(
                                        selectedImage.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/clock_icon.svg',
                                        ),
                                        const SizedBox(width: 12),
                                        if (selectedImage.time != null)
                                          Text(
                                            DateFormat().add_jm().format(
                                                DateTime.parse(
                                                    selectedImage.time!)),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedImage.status != 'Success')
                                const SizedBox(height: 16),
                              if (selectedImage.status != 'Success')
                                Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/clock_icon.svg',
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      child: Text(
                                        selectedImage.status,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (selectedImage.time != null)
                                const SizedBox(height: 16),
                              if (selectedImage.time != null)
                                Entry(
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/calendar_icon.svg',
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Text(
                                          DateFormat().add_yMd().format(
                                              DateTime.parse(
                                                      selectedImage.time!)
                                                  .toLocal()),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 14,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Entry(
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      'assets/icons/location_icon.svg',
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        selectedImage.location,
                                        textAlign: TextAlign.start,

                                        maxLines: 3,
                                        // overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryAccentColor,
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12.0),
                      GalleryView(
                          nftController: nftController,
                          widget: widget,
                          images: images,
                          selectedImage: selectedImage),
                      if (!widget.isArchived) const SizedBox(height: 12.0),
                      if (!widget.isArchived)
                        AnimatedCrossFade(
                            firstChild: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  fixedSize: Size(Get.width * 0.6, 48),
                                  side: BorderSide(color: kPrimaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(56.0),
                                  )),
                              onPressed: () async {
                                await _saveNetworkImage(image: selectedImage);
                              },
                              child: Text(
                                'Download (${selectedImage.matricule})',
                                style: GoogleFonts.montserrat(
                                    color: kPrimaryColor),
                              ),
                            ),
                            secondChild: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  fixedSize: Size(Get.width * 0.6, 48)),
                              onPressed: (selectedImage.status != 'Success')
                                  ? null
                                  : () async {
                                      Get.bottomSheet(
                                        WalletDetailSheet(
                                          mintedImage: selectedImage,
                                          nftController: nftController,
                                        ),
                                        isDismissible: true,
                                        isScrollControlled: true,
                                      );
                                    },
                              child: Text('Buy (${selectedImage.matricule})',
                                  style: GoogleFonts.montserrat(
                                    color: (selectedImage.status == 'Success')
                                        ? kWhiteColor
                                        : Colors.grey,
                                  )),
                            ),
                            crossFadeState:
                                selectedImage.nftTransferHash != null &&
                                        (selectedImage.status == 'Success')
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 300)),
                      const SizedBox(height: 12.0),
                    ],
                  ),
                ),
              ],
            ),
          ));
    });
  }

  customLoadingAnimation() {
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

  _saveNetworkImage({required MintedImage image}) async {
    try {
      Get.dialog(
        customLoadingAnimation(),
        barrierDismissible: false,
      );

      final dio.Response response = await Dio(dio.BaseOptions(
              connectTimeout: const Duration(milliseconds: 7000)))
          .get(
        image.image,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(milliseconds: 5000),
          sendTimeout: const Duration(milliseconds: 5000),
        ),
      );
      final Map result = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
          quality: 90,
          name: "TrutchCatcher/${image.matricule}");
      Get.back();

      if (result['isSuccess'] ?? false) {
        Fluttertoast.showToast(msg: 'Image successfully downloaded.');
      }

      log(result.toString());
    } on DioException catch (error) {
      Get.back();

      log(error.message.toString());
      Fluttertoast.showToast(
        msg: error.message ?? "Unable to download",
        toastLength: Toast.LENGTH_LONG,
      );
    } catch (error) {
      Get.back();
      Fluttertoast.showToast(
          msg:
              'Unable to download the image now. Please try again later ($error)');
    }
  }
}

class GalleryView extends StatelessWidget {
  const GalleryView({
    super.key,
    required this.widget,
    required this.images,
    required this.selectedImage,
    required this.nftController,
  });

  final ImageDetails widget;
  final List<MintedImage> images;
  final MintedImage selectedImage;
  final NtfController nftController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          padding: widget.isArchived ? const EdgeInsets.all(0) : null,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemBuilder: (context, index) {
            final MintedImage currentImage = widget.isArchived
                ? nftController.archivedImages[index]
                : images[index];
            return Container(
              clipBehavior: Clip.none,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: kWhiteColor,
                boxShadow: selectedImage.id == currentImage.id
                    ? [
                        BoxShadow(
                            color: kPrimaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(2, 4))
                      ]
                    : null,
                border: selectedImage.id == currentImage.id
                    ? Border.all(
                        width: 1.5,
                        color: kPrimaryColor,
                      )
                    : const Border(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                height: 72,
                width: 60,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    nftController.setSelectedImage(image: currentImage);
                  },
                  child: CachedNetworkImage(
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                              child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 1.0),
                          )),
                      errorWidget: (context, url, error) => Center(
                            child: SvgPicture.asset(
                                'assets/icons/broken_image.svg',
                                height: 18.0),
                          ),
                      imageUrl: currentImage.image),
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemCount: widget.isArchived
              ? nftController.archivedImages.length
              : images.length,
        ),
      ),
    );
  }
}

class MatriculeWidget extends StatelessWidget {
  const MatriculeWidget({
    super.key,
    required this.selectedImage,
  });

  final MintedImage selectedImage;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: selectedImage.matricule));
              Fluttertoast.showToast(msg: 'Copied to clipboard');
            },
            child: Container(
              decoration: BoxDecoration(
                color: kWhiteColor,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  width: 1,
                  color: kPrimaryColor,
                ),
              ),
              alignment: Alignment.center,
              width: Get.width * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      SvgPicture.asset(
                        'assets/icons/truth_catcher_logo.svg',
                        height: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Matricule no.',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        selectedImage.matricule,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        cursorWidth: 2,
                        enableInteractiveSelection: true,
                        cursorRadius: const Radius.circular(5),
                      ),
                      const Icon(
                        Iconsax.copy,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WalletDetailSheet extends StatefulWidget {
  const WalletDetailSheet({
    super.key,
    required this.nftController,
    required this.mintedImage,
  });

  final NtfController nftController;
  final MintedImage mintedImage;

  @override
  State<WalletDetailSheet> createState() => _WalletDetailSheetState();
}

class _WalletDetailSheetState extends State<WalletDetailSheet> {
  final TextEditingController _walletController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  final GlobalKey<FormFieldState> _walletKey = GlobalKey<FormFieldState>();

  String get _receiverAddress => _walletController.text.trim();
  String get code => _couponController.text.trim();
  bool isCouponApplied = false;
  Coupon? selectedCoupon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Provider.of<StripeController>(context, listen: false).getCoupons();
      Provider.of<StripeController>(context, listen: false).getBuyBackPrice();
      Provider.of<StripeController>(context, listen: false).getProducts();
    });
  }

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NtfController>(
        builder: (context, NtfController nftController, _) {
      return Consumer<StripeController>(
          builder: (context, StripeController stripeController, _) {
        final bool hasProduct = stripeController.products
            .any((element) => element.id == '2X3C4V5B6');

        ProductDetails? product;
        if (hasProduct) {
          product = stripeController.products
              .firstWhere((element) => element.id == '2X3C4V5B6');
        }

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              color: kWhiteColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12.0))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nft Details',
                  style: GoogleFonts.montserrat(
                      fontSize: 20.0, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12.0),
                header(),
                const SizedBox(height: 24.0),
                Text(
                  'Enter Wallet Address',
                  style: GoogleFonts.montserrat(
                      fontSize: 21.0, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.visiblePassword,
                  onFieldSubmitted: (val) {
                    _walletKey.currentState!.validate();
                  },
                  style: GoogleFonts.montserrat(),
                  key: _walletKey,
                  controller: _walletController,
                  validator: (value) => value!.isEmpty
                      ? 'Please enter a valid wallet address'
                      : isValidEthereumAddress(value)
                          ? null
                          : 'Invalid wallet address',
                  decoration: InputDecoration(
                      hintStyle: GoogleFonts.montserrat(),
                      hintText: 'eg: 0x329xxxxxxxa64E',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0))),
                ),
                const SizedBox(height: 24.0),
                priceBreakupCard(
                    stripeController, hasProduct, product, nftController),
                const SizedBox(height: 24.0),
                if (Platform.isIOS)
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_walletKey.currentState!.validate()) {
                          final NotificationController notificationController =
                              Provider.of<NotificationController>(context,
                                  listen: false);
                          final TransactionController transactionController =
                              Provider.of<TransactionController>(context,
                                  listen: false);

                          if (isCouponApplied) {
                            await nftController.transferNft(
                                currency: product?.currencySymbol ?? '€',
                                applePaymentTransactionId: '',
                                isCouponApplied: isCouponApplied,
                                image: widget.mintedImage,
                                nftController: nftController,
                                receiverAddress: _receiverAddress,
                                stripeTransactionId: '',
                                notificationController: notificationController);
                            Get.back();
                          } else {
                            if (hasProduct) {
                              log(product!.rawPrice.toString());
                              await stripeController.buyBackNft(
                                currency: product.currencySymbol,
                                image: widget.mintedImage,
                                transactionController: transactionController,
                                nftController: nftController,
                                receiverAddress: _receiverAddress,
                                amount:
                                    double.parse(product.rawPrice.toString()),
                                notificationController: notificationController,
                                product: product,
                              );
                            }
                          }

                          // if (mounted) {
                          //   _walletController.clear();
                          // }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: kPrimaryAccentColor,
                          backgroundColor: kPrimaryColor,
                          fixedSize: Size(
                            Get.width * 0.55,
                            54,
                          )),
                      child: Text('Continue',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: kWhiteColor,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                if (!Platform.isIOS)
                  Center(
                      child: ElevatedButton(
                    onPressed: stripeController.isMakingPayment
                        ? null
                        : () async {
                            final TransactionController transactionController =
                                Provider.of<TransactionController>(context,
                                    listen: false);
                            if (_walletKey.currentState!.validate()) {
                              final NotificationController
                                  notificationController =
                                  Provider.of<NotificationController>(context,
                                      listen: false);

                              if (isCouponApplied) {
                                await nftController.transferNft(
                                    currency: product?.currencySymbol ?? '€',
                                    applePaymentTransactionId: '',
                                    isCouponApplied: isCouponApplied,
                                    image: widget.mintedImage,
                                    nftController: nftController,
                                    receiverAddress: _receiverAddress,
                                    stripeTransactionId: '',
                                    notificationController:
                                        notificationController);
                                Get.back();
                                transactionController.getTransactions();
                              } else {
                                if (Platform.isIOS) {
                                  await stripeController.buyBackNft(
                                    currency: product!.currencySymbol,
                                    image: widget.mintedImage,
                                    transactionController:
                                        transactionController,
                                    nftController: nftController,
                                    receiverAddress: _receiverAddress,
                                    amount: product.rawPrice,
                                    notificationController:
                                        notificationController,
                                    product: stripeController.products
                                        .firstWhere((element) =>
                                            element.id == '2X3C4V5B6'),
                                  );
                                } else {
                                  await stripeController.buyNft(
                                    isCouponApplied: isCouponApplied,
                                    notificationController:
                                        notificationController,
                                    receiverAddress: _receiverAddress,
                                    ntfController: widget.nftController,
                                    image: widget.mintedImage,
                                  );
                                }
                                transactionController.getTransactions();
                              }

                              // if (mounted) {
                              //   _walletController.clear();
                              // }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: kPrimaryAccentColor,
                        backgroundColor: kPrimaryColor,
                        fixedSize: Size(
                          Get.width * 0.55,
                          54,
                        )),
                    child: stripeController.isMakingPayment
                        ? Center(
                            child: CircularProgressIndicator.adaptive(
                              valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                            ),
                          )
                        : Text('Continue',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: kWhiteColor,
                              fontWeight: FontWeight.w600,
                            )),
                  )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      });
    });
  }

  Container priceBreakupCard(
    StripeController stripeController,
    bool hasProduct,
    ProductDetails? product,
    NtfController nftController,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: kPrimaryColor.withOpacity(0.1),
      ),
      padding: const EdgeInsets.only(top: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NFT Transfer fee',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (stripeController.ifFetchingBuyBackPrice)
                      const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                          )),
                    if (!stripeController.ifFetchingBuyBackPrice)
                      Text(
                        hasProduct
                            ? product?.price ?? ""
                            : '€ ${stripeController.buyBackPrice ?? 0}.00',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Divider(
                        height: 8.0,
                        color: const Color(0xFF2B2B2B).withOpacity(0.13)),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      shape:
                          const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape:
                          const RoundedRectangleBorder(side: BorderSide.none),
                      title: Row(
                        children: [
                          Container(
                            height: 28,
                            width: 28,
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: SvgPicture.asset(
                              'assets/icons/coupon_icon.svg',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCouponApplied
                                ? "Cuopon (${nftController.appliedCoupon?.coupon})"
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
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Flexible(
                              child: SizedBox(
                                height: 40,
                                child: TextFormField(
                                  controller: _couponController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                  ),
                                  onChanged: (val) => setState(() {}),
                                  decoration: InputDecoration(
                                    suffixIcon: code.isNotEmpty
                                        ? IconButton(
                                            onPressed: () {
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
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
                                    hintStyle:
                                        GoogleFonts.montserrat(fontSize: 13),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0)),
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
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      if (code.isEmpty) {
                                        Fluttertoast.showToast(
                                            msg:
                                                'Please enter a valid coupon code');
                                        return;
                                      }
                                      final bool isValidCoupon =
                                          await nftController.verifyCoupon(
                                              code: code);

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
                                  ? Colors.green
                                  : Colors.grey.withOpacity(0.6),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              child: nftController.isVerifingCoupon
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator.adaptive(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation(kWhiteColor),
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedSize(
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
                              'Transfer Fee',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kWhiteColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              hasProduct
                                  ? product!.price.toTwoDecimalPlaces()
                                  : '€ ${stripeController.buyBackPrice?.toString().toTwoDecimalPlaces() ?? 0}',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: kWhiteColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                                    hasProduct
                                        ? product!.price.toTwoDecimalPlaces()
                                        : '€ ${stripeController.buyBackPrice?.toString().toTwoDecimalPlaces() ?? 0.00}',
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
                                        width: 50,
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
                        isCouponApplied
                            ? '€ 0.00'
                            : hasProduct
                                ? product!.price.toTwoDecimalPlaces()
                                : '€ ${stripeController.buyBackPrice?.toString().toTwoDecimalPlaces() ?? 0.00}',
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
          ),
        ],
      ),
    );
  }

  Container header() {
    return Container(
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: widget.mintedImage.matricule,
            child: Container(
                height: Get.height * 0.1,
                width: Get.height * 0.1,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: widget.mintedImage.image,
                  errorWidget: (context, url, error) => Center(
                    child: SvgPicture.asset('assets/icons/broken_image.svg',
                        height: 18.0),
                  ),
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  fit: BoxFit.cover,
                )),
          ),
          const SizedBox(width: 15.0),
          Flexible(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  widget.mintedImage.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (widget.mintedImage.time != null)
                  const SizedBox(
                    height: 8,
                  ),
                if (widget.mintedImage.time != null)
                  Text(
                    DateFormat('dd/MM/yyyy')
                        .format(DateTime.parse(widget.mintedImage.time!)),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  widget.mintedImage.location,
                  style: GoogleFonts.montserrat(
                    height: 1.1,
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  bool isValidEthereumAddress(String address) {
    final RegExp ethereumAddressRegExp = RegExp(r'^0x[0-9a-fA-F]{40}$');
    return ethereumAddressRegExp.hasMatch(address);
  }
}
