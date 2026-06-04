import 'dart:async'; // Make sure this import is present
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
// import 'package:image/image.dart' as img;
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/coupon_controller.dart';
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/controller/transaction_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/screens/capture_image/picture_confirm.dart';
import 'package:truthcatcher/screens/search/search.dart';

class NtfController extends ChangeNotifier with CouponController {
  NtfController() {
    getMintedNfts();
    getArchivedImages();
  }
  bool isLoading = false;
  MintedImage? selectedImage;
  MintedImage? deeplinkingSearchedImage;
  List<MintedImage> images = [];
  List<MintedImage> archivedImages = [];
  bool canDisplayBanner = true;
  bool canDisplayArchivedBanner = true;
  bool isFetchingMoreImages = false;
  bool areImagesReachedEnd = false;
  bool isFetchingMoreArchivedImages = false;
  bool areArchivedImagesReachedEnd = false;
  bool isSearching = false;
  int imagesPageSize = 0;
  int archivedImagesPageSize = 0;
  DateTime? imageTimestamp;
  Timer? timestampTimer;
  bool isValid = true;

  final int pageKey = 10;
  final ScrollController controller = ScrollController();
  final ScrollController archivedImageScrollController = ScrollController();

  void changeCandisplayBanner({required bool state}) {
    canDisplayBanner = state;
    notifyListeners();
  }

  void changeCandisplayArchivedBanner({required bool state}) {
    canDisplayArchivedBanner = state;
    notifyListeners();
  }

  void changeLoadingstatus() {
    isLoading = !isLoading;
    notifyListeners();
  }

  void setSelectedImage({required MintedImage image}) {
    selectedImage = image;
    notifyListeners();
  }

  void updateLocalData() {
    getMintedNfts();
  }

  void attachImagesController() {
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        log('images reached end loading more.....');
        if (!areImagesReachedEnd) {
          getMintedNfts();
        }
      }
    });
  }

  void attachArchivedImagesController() {
    archivedImageScrollController.addListener(() {
      if (archivedImageScrollController.position.pixels ==
          archivedImageScrollController.position.maxScrollExtent) {
        log('archived images reached end loading more....');
        if (!areArchivedImagesReachedEnd) {
          getArchivedImages();
        }
      }
    });
  }

  void changeIsFetchingMoreImagesState({required bool state}) {
    isFetchingMoreImages = state;
    notifyListeners();
  }

  void changeIsFetchingMoreArchivedImagesState({required bool state}) {
    isFetchingMoreArchivedImages = state;
    notifyListeners();
  }

  Future refreshImages() async {
    try {
      // areImagesReachedEnd = false;
      // canDisplayBanner = true;
      // imagesPageSize = 0;
      // images.clear();
      await getMintedNfts();
    } catch (error) {
      log(error.toString());
    }
  }

  void updateNftImages({required MintedImage image}) {
    images.add(image);
    notifyListeners();
  }

  Future refreshArchivedImages() async {
    try {
      getArchivedImages();
    } catch (error) {
      log(error.toString());
    }
  }

  Future getMintedNfts() async {
    try {
      changeIsFetchingMoreImagesState(state: true);
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        http.Response response = await http.get(
          Uri.parse("$baseUrl/images/all"),
          // "$baseUrl/images/all?perPage=$pageKey&skip=$imagesPageSize"),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body);
          List rawImages = data['content'] ?? [];
          List<MintedImage> newImages =
              rawImages.map((e) => MintedImage.fromJson(e)).toList();

          images = List.from(newImages);

          if (selectedImage != null) {
            selectedImage =
                images.firstWhere((element) => element.id == selectedImage!.id);
          }

          images.sort((a, b) => DateTime.parse(b.time ?? b.createdAt.toString())
              .toLocal()
              .compareTo(
                  DateTime.parse(a.time ?? b.createdAt.toString()).toLocal()));
        }
      } else {
        log('Token is null => getMintedNfts');
      }
      changeIsFetchingMoreImagesState(state: false);
    } catch (error) {
      changeIsFetchingMoreImagesState(state: false);
      log(error.toString());
    }
  }

  Future mintNft({
    required File image,
    required String name,
    required String location,
    required bool isCouponApplied,
    required Position position,
    required DateTime? date,
    required double amount,
    required String currency,
    required String? stripeTransactionId,
    String? applePaymentTransactionId,
    required NotificationController notificationController,
    required TransactionController transactionController,
    required NtfController ntfController,
  }) async {
    try {
      changeLoadingstatus();
      Get.dialog(
        const Center(child: LoadingAnimation()),
        barrierDismissible: false,
      );
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        http.MultipartRequest request =
            http.MultipartRequest('POST', Uri.parse('$baseUrl/images/upload'));

        request.headers.addAll({
          'authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        });

        http.MultipartFile file = await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: 'image.jpg',
        );
        if (isCouponApplied && super.appliedCoupon != null) {
          request.fields['coupon'] = super.appliedCoupon!.coupon;
          request.fields['couponId'] = super.appliedCoupon!.id;
        }
        request.files.add(file);
        request.fields['name'] = name;
        request.fields['amount'] = amount.toString();
        request.fields['currency'] = currency;
        request.fields['stripeTransactionId'] = stripeTransactionId!;
        request.fields['location'] = location;
        if (date != null) {
          request.fields['time'] = date.toLocal().toString();
        }

        http.StreamedResponse res = await request.send();
        String streamData = await res.stream.bytesToString();

        if (res.statusCode == 200) {
          stopTimer();

          Map data = jsonDecode(streamData) as Map;
          final MintedImage mintedImage = MintedImage.fromJson(data['content']);

          notificationController.getNotifications(isRefreshing: false);
          transactionController.getTransactions();
          await ntfController.getMintedNfts();

          await Get.offUntil(
              MaterialPageRoute(
                  maintainState: true,
                  builder: (_) =>
                      PictureConfirm(image: image, mintedImage: mintedImage)),
              (route) => route.isFirst);
          selectedImage = mintedImage;
          notifyListeners();
          // Get.to(() => ImageDetails(
          //     image: mintedImage, isArchived: false, fromNotifications: false));

          Fluttertoast.showToast(msg: 'Image Minted Successfully');
        } else {
          log(res.reasonPhrase.toString());
          Fluttertoast.showToast(msg: res.statusCode.toString());
          Fluttertoast.showToast(
              msg: 'Something went wrong, please try again later!');
        }
        stopTimer();
        changeLoadingstatus();
        Get.back();
      }
    } catch (error) {
      Get.back();
      changeLoadingstatus();
      Fluttertoast.showToast(msg: error.toString());
      log(error.toString());
    }
  }

  bool isWithinFiveMinutes(DateTime? givenTime) {
    if (givenTime == null) {
      return true;
    }
    DateTime now = DateTime.now();
    Duration allowedRange = const Duration(minutes: 1);

    // Calculate the start and end of the allowed time window
    DateTime startRange = now.subtract(allowedRange);
    DateTime endRange = now.add(allowedRange);

    // Check if the given time is within the range
    if (givenTime.isAfter(startRange) && givenTime.isBefore(endRange)) {
      return true; // The time is within 5 minutes before or after the current time
    } else {
      return false; // The time is outside the 5-minute range
    }
  }

  /// Timer to check device timestamp and current timestamp
  void startTimer() {
    log("Timer started");
    timestampTimer =
        Timer.periodic(const Duration(seconds: 1), (timestamp) async {
      if (timestampTimer == null || !(timestampTimer?.isActive ?? false)) {
        timestamp.cancel();
      }
      final DateTime? date = await getTimeFromTimezone(fromTimer: true);

      if (date != null) {
        bool isIntimeLimit = isWithinFiveMinutes(date);
        if (isValid != isIntimeLimit) {
          isValid = isIntimeLimit;

          notifyListeners();
        }
        log("isValid $isValid");
      } else {
        isValid = false;
        notifyListeners();
      }
      log("isValid $isValid");
    });
  }

  void stopTimer() {
    try {
      log("Timer stopped");
      timestampTimer?.cancel();
      imageTimestamp = null;
      isValid = true;
    } catch (error) {
      log(error.toString());
    }
  }

  Future<DateTime?> getTimeFromTimezone({bool fromTimer = false}) async {
    try {
      if (!fromTimer) {
        startTimer();
        imageTimestamp = null;
        notifyListeners();
      }

      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        http.Response response = await http.get(
          Uri.parse('$baseUrl/images/getTimeStamp'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );
        log(response.body.toString());
        Map data = jsonDecode(response.body) as Map;
        DateTime date = DateTime.parse(data['content']);
        if (!fromTimer) {
          imageTimestamp = date.toLocal();
          notifyListeners();
        }
        return date;
      }
    } catch (error) {
      log(error.toString());
    }
    return null;
  }

  Future archiveNft() async {
    try {
      changeLoadingstatus();
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null && selectedImage != null) {
        http.Response response = await http.post(
          Uri.parse('$baseUrl/images/archive/${selectedImage?.matricule}'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          Get.back();

          Map data = jsonDecode(response.body);
          Map rawImage = data['content'];
          archivedImages.add(MintedImage.fromJson(rawImage));
          Fluttertoast.showToast(msg: 'Archived image successfully.');
          images.removeWhere((element) => element.id == selectedImage?.id);
          getMintedNfts();

          if (images.isNotEmpty) {
            selectedImage = images.first;
          } else {
            Get.back();
          }
        } else {
          log(response.body);
          Map data = jsonDecode(response.body);
          Fluttertoast.showToast(
              msg: data['message'] ??
                  "Something went wrong, Please try again later");
        }

        changeLoadingstatus();
      }
    } catch (error) {
      changeLoadingstatus();
      Fluttertoast.showToast(msg: error.toString());
      log(error.toString());
    }
  }

  Future getArchivedImages() async {
    try {
      if (archivedImages.isEmpty) {
        changeIsFetchingMoreArchivedImagesState(state: true);
      }
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        http.Response response = await http.get(
          Uri.parse('$baseUrl/images/archive'),
          // Uri.parse(
          //     '$baseUrl/images/archive?perPage=$pageKey&skip=$archivedImagesPageSize'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body);
          List rawImages = data['content'] ?? [];
          List<MintedImage> newArchivedImages =
              rawImages.map((e) => MintedImage.fromJson(e)).toList();
          // if (newArchivedImages.length < pageKey) {
          //   archivedImages.addAll(newArchivedImages);
          //   areArchivedImagesReachedEnd = true;
          //   canDisplayArchivedBanner = true;
          // } else {
          //   archivedImages.addAll(newArchivedImages);
          //   archivedImagesPageSize = archivedImages.length;
          // }

          archivedImages = List.from(newArchivedImages);
        } else {
          Map data = jsonDecode(response.body);
          toastMessage(data['message']);
        }
        changeIsFetchingMoreArchivedImagesState(state: false);
      }
    } catch (error) {
      changeIsFetchingMoreArchivedImagesState(state: false);
      Fluttertoast.showToast(msg: error.toString());
      log(error.toString());
    }
  }

  Future searchNft(
      {required String matricule, bool fromDeepLinks = false}) async {
    try {
      log(matricule);
      deeplinkingSearchedImage = null;
      isSearching = true;
      notifyListeners();
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        http.Response response = await http.get(
          Uri.parse('$baseUrl/images/searchImage/$matricule'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );
        log(response.body);
        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body);
          MintedImage image = MintedImage.fromJson(data['content']);

          deeplinkingSearchedImage = image;
          if (!fromDeepLinks) {
            Get.to(() => SearchPage(image: image));
          }

          await Hive.box<String?>(kDeeplinlksBox).clear();
        } else {
          Map data = jsonDecode(response.body);
          if (fromDeepLinks) {
            Get.back();
          }
          Fluttertoast.showToast(msg: data['message'] ?? "Image Not Found!!");
        }
      }
      isSearching = false;
      notifyListeners();
    } catch (error) {
      isSearching = false;
      notifyListeners();
      if (fromDeepLinks) {
        Get.back();
      }
      toastMessage(error.toString());
    }
  }

  Future unArchiveNft({required MintedImage image}) async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        http.Response response = await http.patch(
          Uri.parse('$baseUrl/images/unArchive/${image.matricule}'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );
        if (response.statusCode == 200) {
          toastMessage('Image successfully unarchived');
          archivedImages.remove(image);
          if (archivedImages.isNotEmpty) {
            selectedImage = archivedImages.first;
          } else {
            Get.back();
          }
          Get.back();
          getMintedNfts();
        } else {
          log(response.body);
        }
      }
      notifyListeners();
    } catch (error) {
      log(error.toString());
    }
  }

  Future transferNft({
    required MintedImage image,
    required bool isCouponApplied,
    required NtfController nftController,
    required NotificationController notificationController,
    required String stripeTransactionId,
    required String applePaymentTransactionId,
    required String receiverAddress,
    required String currency,
    double? amount,
  }) async {
    try {
      Get.dialog(
        const Center(child: LoadingAnimation()),
        barrierDismissible: false,
      );

      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        Map couponData = {};

        if (isCouponApplied && super.appliedCoupon != null) {
          couponData['coupon'] = super.appliedCoupon!.coupon;
          couponData['couponId'] = super.appliedCoupon!.id;
        }

        log(jsonEncode({
          'receiverAddress': receiverAddress,
          'matricule': image.matricule,
          'stripeTransferId': stripeTransactionId,
          'applePaymentTransactionId': applePaymentTransactionId,
          'currency': currency,
          'amount': amount,
          if (isCouponApplied) ...couponData
        }));

        // return;
        http.Response response = await http.post(
          Uri.parse('$baseUrl/images/transferNft'),
          body: jsonEncode({
            'receiverAddress': receiverAddress,
            'matricule': image.matricule,
            'amount': amount,
            'stripeTransferId': stripeTransactionId,
            'applePaymentTransactionId': applePaymentTransactionId,
            'currency': currency,
            if (isCouponApplied) ...couponData
          }),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );
        if (response.statusCode == 200) {
          Get.back();
          Fluttertoast.showToast(msg: 'Purchase Successful');
          await nftController.refreshImages();
          await notificationController.getNotifications(isRefreshing: false);
        } else {
          log(response.body);
          Map responseData = jsonDecode(response.body) as Map;
          Fluttertoast.showToast(
              msg: responseData['message'] ??
                  "Unable to transfer nft right now, Please try again later.",
              toastLength: Toast.LENGTH_LONG);
          log(response.statusCode.toString());
          Get.back();
        }
      }
    } catch (error) {
      Get.back();
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  Future verifyWalletAddress({required String walletAddress}) async {
    try {
      http.Response response = await http.get(Uri.parse(
          'https://api-metadata.etherscan.io/v1/api.ashx?module=nametag&action=getaddresstag&address=$walletAddress&apikey=JY5XKD5B9UZGDPJQ8RZKI8PC8ZMPNWS582'));

      if (response.statusCode == 200) {
        log(response.body);
      } else {
        log(response.body);
      }
    } catch (error) {
      log(error.toString());
    }
  }
}
