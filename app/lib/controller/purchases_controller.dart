import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';

import '../models/minted_image.dart';

mixin InAppPurchasesController on ChangeNotifier {
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  ProductDetails? lastPurchasedProduct;
  List<ProductDetails> products = [];

  bool isLoadingPurchases = true;
  NtfController? nftController;
  CacheImage? cacheImage;

  Future init() async {
    getProducts();
    checkCanMakePurchases();
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  bool isBuying = true;
  void changeBuyingState({required bool state}) {
    isBuying = state;
    notifyListeners();
  }

  void changeLoadingPurchaseState({required bool state}) {
    isLoadingPurchases = state;
    notifyListeners();
  }

  Future<bool> checkCanMakePurchases() async {
    final bool canMakePruchases = await _inAppPurchase.isAvailable();
    if (canMakePruchases) {
      log("Can make purchases".toUpperCase());
    } else {
      log("Can't make purchases".toUpperCase());
    }

    return canMakePruchases;
  }

  Future<void> buy({
    required ProductDetails product,
    required NtfController nftController,
    required TransactionController transactionController,
    required NotificationController notificationController,
    required String location,
    required Position position,
    required DateTime? date,
    required String name,
    required String currency,
    required File image,
    required double amount,
  }) async {
    try {
      lastPurchasedProduct = product;
      changeBuyingState(state: true);
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      bool result = await InAppPurchase.instance
          .buyConsumable(purchaseParam: purchaseParam);
      Get.dialog(
        const Center(child: LoadingAnimation()),
        barrierDismissible: false,
      );

      if (result) {
        cacheImage = CacheImage(
            currency: currency,
            receiverAddress: '',
            type: 1,
            isCouponApplied: false,
            ntfController: nftController,
            notificationController: notificationController,
            transactionController: transactionController,
            amount: amount,
            image: image,
            name: name,
            position: position,
            location: location,
            date: date);
        log('Bought ${product.id}');
      }
      changeBuyingState(state: false);
    } catch (error) {
      Get.back();
      changeBuyingState(state: false);
      log(error.toString());
    }
  }

  Future<void> buyBackNft({
    required ProductDetails product,
    required NtfController nftController,
    required TransactionController transactionController,
    required NotificationController notificationController,
    required MintedImage image,
    required double amount,
    required String receiverAddress,
    required String currency,
  }) async {
    try {
      log(amount.toString());

      lastPurchasedProduct = product;
      changeBuyingState(state: true);
      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);
      bool result = await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: purchaseParam);
      Get.dialog(
        const Center(child: LoadingAnimation()),
        barrierDismissible: false,
      );

      if (result) {
        cacheImage = CacheImage(
          currency: currency,
          receiverAddress: receiverAddress,
          mintedImage: image,
          isCouponApplied: false,
          ntfController: nftController,
          notificationController: notificationController,
          transactionController: transactionController,
          amount: amount,
          type: 2,
        );
        log('Bought ${product.id}');
        log('Cached Image Ammount ${cacheImage!.amount}');
      }
      changeBuyingState(state: false);
    } catch (error) {
      changeBuyingState(state: false);
      log(error.toString());
    }
  }

  Future _onPurchaseUpdate(dynamic purchaseDetailsList) async {
    try {
      List<PurchaseDetails> data = purchaseDetailsList;
      Get.dialog(
        const Center(child: LoadingAnimation()),
        barrierDismissible: false,
      );

      log(data.length.toString());
      await Future.wait(data.map((element) async {
        if (element.pendingCompletePurchase) {
          log('Has pending products');

          await _inAppPurchase.completePurchase(element);
          if (lastPurchasedProduct != null &&
              lastPurchasedProduct?.id == element.productID) {
            changeBuyingState(state: false);
          }
        }

        if (element.status == PurchaseStatus.purchased ||
            element.status == PurchaseStatus.restored) {
          changeBuyingState(state: false);
          log('Purchase Completed');
          Get.back();
          handleSuccessfulPurchases(purchase: element);
        } else {
          log(element.status.toString());
          if (element.status == PurchaseStatus.canceled) {
            Get.back();
          }
        }
      }));
      Get.back();
    } catch (error) {
      Get.back();
      changeBuyingState(state: false);
      log(error.toString());
    }
  }

  Future getProducts() async {
    try {
      changeLoadingPurchaseState(state: true);
      bool canBuy = await checkCanMakePurchases();
      if (canBuy) {
        Set<String> productIds = {
          '1234',
          '2X3C4V5B6',
          'TCMINTFREE01',
          'TCBUYBACKFREE01'
        };
        final ProductDetailsResponse productsResponse =
            await _inAppPurchase.queryProductDetails(productIds);
        products = productsResponse.productDetails;

        log("products => $products");
        notifyListeners();
      }

      changeLoadingPurchaseState(state: false);
    } catch (error) {
      log(error.toString());
    }
  }

  Future handleSuccessfulPurchases({required PurchaseDetails purchase}) async {
    final String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (token != null) {
      if (cacheImage != null && cacheImage!.type == 1) {
        await cacheImage!.ntfController.mintNft(
          amount: cacheImage!.amount,
          name: cacheImage!.name!,
          notificationController: cacheImage!.notificationController,
          ntfController: cacheImage!.ntfController,
          position: cacheImage!.position!,
          stripeTransactionId: '',
          transactionController: cacheImage!.transactionController,
          applePaymentTransactionId: purchase.purchaseID,
          currency: cacheImage!.currency!,
          date: cacheImage!.date!,
          image: cacheImage!.image!,
          isCouponApplied: cacheImage!.isCouponApplied,
          location: cacheImage!.location!,
        );
        Get.back();
      } else if (cacheImage != null && cacheImage!.type == 2) {
        log('Amount in transfer ${cacheImage!.amount}');
        await cacheImage!.ntfController.transferNft(
            currency: cacheImage!.currency!,
            amount: cacheImage!.amount,
            image: cacheImage!.mintedImage!,
            applePaymentTransactionId: purchase.productID,
            isCouponApplied: cacheImage!.isCouponApplied,
            nftController: cacheImage!.ntfController,
            notificationController: cacheImage!.notificationController,
            stripeTransactionId: '',
            receiverAddress: cacheImage!.receiverAddress);
        Get.back();
      } else {
        log('cache image is null');
      }
    }

    // purchase.
  }

  void _updateStreamOnDone() {
    log('stream done listening');
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    log('Error in purchasing product => $error');
    Get.back();

    Fluttertoast.showToast(msg: error.toString());
  }
}

class CacheImage {
  final bool isCouponApplied;
  final NtfController ntfController;
  final NotificationController notificationController;
  final TransactionController transactionController;
  final double amount;
  final int type;
  final File? image;
  final MintedImage? mintedImage;
  final String? name;
  final String? currency;
  final String receiverAddress;
  final String? location;
  final Position? position;
  final DateTime? date;
  CacheImage({
    required this.isCouponApplied,
    required this.ntfController,
    required this.notificationController,
    required this.transactionController,
    required this.amount,
    required this.type,
    required this.currency,
    this.location,
    this.image,
    this.mintedImage,
    this.name,
    required this.receiverAddress,
    this.position,
    this.date,
  });

  CacheImage copyWith({
    bool? isCouponApplied,
    NtfController? ntfController,
    NotificationController? notificationController,
    TransactionController? transactionController,
    double? amount,
    int? type,
    File? image,
    MintedImage? mintedImage,
    String? name,
    String? receiverAddress,
    String? location,
    Position? position,
    DateTime? date,
  }) {
    return CacheImage(
      isCouponApplied: isCouponApplied ?? this.isCouponApplied,
      currency: currency,
      ntfController: ntfController ?? this.ntfController,
      notificationController:
          notificationController ?? this.notificationController,
      transactionController:
          transactionController ?? this.transactionController,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      image: image ?? this.image,
      mintedImage: mintedImage ?? this.mintedImage,
      name: name ?? this.name,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      location: location ?? this.location,
      position: position ?? this.position,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isCouponApplied': isCouponApplied,
      'ntfController': ntfController,
      'notificationController': notificationController,
      'transactionController': transactionController,
      'amount': amount,
      'type': type,
      'mintedImage': mintedImage,
      'image': image,
      'name': name,
      'receiverAddress': receiverAddress,
      'position': position,
      'location': location,
      'date': date,
    };
  }

  factory CacheImage.fromMap(Map<String, dynamic> map) {
    return CacheImage(
      isCouponApplied: map['isCouponApplied'] ?? false,
      ntfController: map['ntfController'],
      currency: map['currency'],
      notificationController: map['notificationController'],
      transactionController: map['transactionController'],
      amount: map['amount']?.toInt() ?? 0,
      type: map['type']?.toInt() ?? 0,
      image: map['image'],
      mintedImage: map['mintedImage'],
      name: map['name'] ?? '',
      receiverAddress: map['receiverAddress'] ?? '',
      position: map['position'],
      location: map['location'],
      date: DateTime.parse(map['date']),
    );
  }

  String toJson() => json.encode(toMap());

  factory CacheImage.fromJson(String source) =>
      CacheImage.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CacheImage(isCouponApplied: $isCouponApplied, ntfController: $ntfController, notificationController: $notificationController, transactionController: $transactionController, amount: $amount, image: $image, name: $name, position: $position, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CacheImage &&
        other.isCouponApplied == isCouponApplied &&
        other.ntfController == ntfController &&
        other.notificationController == notificationController &&
        other.transactionController == transactionController &&
        other.amount == amount &&
        other.image == image &&
        other.name == name &&
        other.position == position &&
        other.date == date;
  }

  @override
  int get hashCode {
    return isCouponApplied.hashCode ^
        ntfController.hashCode ^
        notificationController.hashCode ^
        transactionController.hashCode ^
        amount.hashCode ^
        image.hashCode ^
        name.hashCode ^
        position.hashCode ^
        date.hashCode;
  }
}
