import 'dart:convert';
import 'dart:developer';

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:truthcatcher/controller/coupon_controller.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/purchases_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';

import '../constant.dart';
import 'transaction_controller.dart';

class StripeController extends ChangeNotifier
    with InAppPurchasesController, CouponController {
  StripeController() {
    super.init();
  }

  Map? paymentIntent;
  bool isMakingPayment = false;
  bool ifFetchingBuyBackPrice = false;

  int? buyBackPrice;

  Future createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      http.Response response = await http.post(
        Uri.parse(kStripeBaseUrl),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET_LIVE']}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      log("Payment intent => ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }

      Map responseData = json.decode(response.body) as Map;
      if (responseData.containsKey('error')) {
        Map error = Map.from(responseData['error'] ?? {});
        if (error.containsKey('code')) {
          Fluttertoast.showToast(msg: error['code']);
          return;
        }
      }
      Fluttertoast.showToast(msg: response.body.toString());
      return null;
    } catch (err) {
      Fluttertoast.showToast(msg: err.toString());
      log(err.toString());
      // throw Exception(err.toString());
    }
  }





  Future<void> makePayment(
      {required NtfController ntfController,
      required NotificationController notificationController,
      required TransactionController transactionController,
      required File image,
      required bool isCouponApplied,
      required String name,
      required String location,
      required Position position,
      required DateTime? date,
      required double amount}) async {
    try {
      //STEP 1: Create Payment Intent
      log('Creating Payment Intent...');

      paymentIntent =
          await createPaymentIntent((amount * 100).toInt().toString(), 'EUR');

      if (paymentIntent != null) {
        log('Intent Created');

        //STEP 2: Initialize Payment Sheet
        log('Initialize Payment Sheet');
        await Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                    customerEphemeralKeySecret: paymentIntent!['ephemeralKey'],
                    paymentIntentClientSecret: paymentIntent!['client_secret'],
                    setupIntentClientSecret: paymentIntent!['client_secret'],
                    style: ThemeMode.dark,
                    customerId: paymentIntent!['customer'],
                    allowsDelayedPaymentMethods: true,
                    merchantDisplayName: 'TruthCatcher'))
            .then((value) {
          //STEP 3: Display Payment sheet
          log('Init payment sheet value $value');
          log('Display Payment sheet');
          displayPaymentSheet(
              currency: '€',
              isCouponApplied: isCouponApplied,
              ntfController: ntfController,
              notificationController: notificationController,
              transactionController: transactionController,
              image: image,
              date: date,
              location: location,
              amount: amount,
              name: name,
              position: position);
        });
      } else {
        log('Payment intent is not created');
      }
    } catch (err) {
      log(err.toString());
    }
  }

  Future<int> getBuyBackPrice() async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        ifFetchingBuyBackPrice = true;
        notifyListeners();
        http.Response response = await http.get(
          Uri.parse('$baseUrl/images/get_current_buyback'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body) as Map;
          buyBackPrice = data['content'] ?? 1;
          ifFetchingBuyBackPrice = false;
          notifyListeners();
          return buyBackPrice!;
        }
      }
      ifFetchingBuyBackPrice = false;
      buyBackPrice = null;
      notifyListeners();
      return 0;
    } catch (err) {
      ifFetchingBuyBackPrice = false;
      buyBackPrice = null;
      notifyListeners();
      Fluttertoast.showToast(msg: err.toString());
      return 0;
    }
  }

  Future<void> buyNft({
    required NtfController ntfController,
    required NotificationController notificationController,
    required MintedImage image,
    required bool isCouponApplied,
    required String receiverAddress,
  }) async {
    try {
      isMakingPayment = true;
      notifyListeners();
      log('Creating Payment Intent...');

      // get amount

      int buyBackPrice = (await getBuyBackPrice()) * 100;
      paymentIntent = await createPaymentIntent(buyBackPrice.toString(), 'EUR');
      if (paymentIntent != null) {
        log('Intent Created');

        //STEP 2: Initialize Payment Sheet
        log('Initialize Payment Sheet');
        await Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: SetupPaymentSheetParameters(
                    customerEphemeralKeySecret: paymentIntent!['ephemeralKey'],
                    paymentIntentClientSecret: paymentIntent!['client_secret'],
                    setupIntentClientSecret: paymentIntent!['client_secret'],
                    style: ThemeMode.dark,
                    customerId: paymentIntent!['customer'],
                    allowsDelayedPaymentMethods: true,
                    merchantDisplayName: 'TruthCatcher'))
            .then((value) {
          //STEP 3: Display Payment sheet
          log('Init payment sheet value $value');
          log('Display Payment sheet');

          presentPaymentSheet(
            receiverAddress: receiverAddress,
            amount: buyBackPrice,
            image: image,
            isCouponApplied: isCouponApplied,
            ntfController: ntfController,
            notificationController: notificationController,
          );
          isMakingPayment = false;
          notifyListeners();
          Get.back();
        });
      } else {
        log('Payment intent is not created');
        isMakingPayment = false;
        notifyListeners();
      }
    } catch (err) {
      log(err.toString());
      isMakingPayment = false;
      notifyListeners();
    }
  }

  displayPaymentSheet({
    required NtfController ntfController,
    required NotificationController notificationController,
    required TransactionController transactionController,
    required File image,
    required String name,
    required bool isCouponApplied,
    required String location,
    required String currency,
    required Position position,
    required DateTime? date,
    required double amount,
  }) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {
        PaymentIntent paymentIntentResponse = await Stripe.instance
            .retrievePaymentIntent(paymentIntent!['client_secret']);
        if (paymentIntentResponse.status == PaymentIntentsStatus.Succeeded) {
          paymentIntentResponse.amount;
          await ntfController.mintNft(
              isCouponApplied: isCouponApplied,
              ntfController: ntfController,
              notificationController: notificationController,
              transactionController: transactionController,
              amount: amount,
              stripeTransactionId: paymentIntentResponse.id,
              currency: currency,
              image: image,
              name: name,
              location: location,
              position: position,
              date: date);

          paymentIntent = null;
        }
      }).onError((error, stackTrace) {
        log(error.toString());
        // throw Exception(error);
      });
    } on StripeException catch (exception) {
      log(exception.toString());
      Fluttertoast.showToast(msg: exception.error.localizedMessage.toString());
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
      log(error.toString());
    }
  }

  Future presentPaymentSheet({
    required NtfController ntfController,
    required NotificationController notificationController,
    required MintedImage image,
    required int amount,
    required bool isCouponApplied,
    required String receiverAddress,
  }) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {
        PaymentIntent paymentIntentResponse = await Stripe.instance
            .retrievePaymentIntent(paymentIntent!['client_secret']);

        if (paymentIntentResponse.status == PaymentIntentsStatus.Succeeded) {
          paymentIntentResponse.amount;
          await ntfController.transferNft(
            applePaymentTransactionId: '',
            isCouponApplied: isCouponApplied,
            image: image,
            currency: "€",
            amount: buyBackPrice!.toDouble(),
            nftController: ntfController,
            notificationController: notificationController,
            stripeTransactionId: paymentIntentResponse.id,
            receiverAddress: receiverAddress,
          );

          paymentIntent = null;
        }
      }).onError((error, stackTrace) {
        log(error.toString());
      });
    } on StripeException catch (exception) {
      log(exception.toString());
      Fluttertoast.showToast(msg: exception.error.localizedMessage.toString());
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
      log(error.toString());
    }
  }
}





