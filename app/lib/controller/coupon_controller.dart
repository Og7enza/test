import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/models/coupon.dart';

mixin CouponController on ChangeNotifier {
  List<Coupon> coupons = [];
  Coupon? appliedCoupon;
  bool isVerifingCoupon = false;
  bool isFetchingCoupon = false;
  void changeVerifingCouponState({required bool state}) {
    isVerifingCoupon = state;
    notifyListeners();
  }

  void changeFetchingCouponState({required bool state}) {
    isFetchingCoupon = state;
    notifyListeners();
  }

  void applyCoupon({required Coupon? coupon}) {
    appliedCoupon = coupon;
    notifyListeners();
  }

  Future getCoupons() async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        changeFetchingCouponState(state: true);
        http.Response response = await http.get(
          Uri.parse('$baseUrl/coupons/getCoupons'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );
        log("response body => ${response.body}");
        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body) as Map;
          coupons = List.from(data['content'] ?? [])
              .map((e) => Coupon.fromJson(e))
              .toList();

          changeFetchingCouponState(state: false);
        }
      }
    } catch (error) {
      log('Error in Coupons $error');
    }
  }

  Future verifyCoupon({required String code}) async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        changeVerifingCouponState(state: true);

        http.Response response = await http.get(
          Uri.parse('$baseUrl/coupons/verify?coupon_code=$code'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        log(response.body.toString());

        if (response.statusCode == 200) {
          Map data = jsonDecode(response.body) as Map;
          List<Coupon> coupons = List.from((data['content'] ?? []))
              .map((e) => Coupon.fromJson(e))
              .toList();
          changeVerifingCouponState(state: false);

          log(coupons.length.toString());

          if (coupons.isEmpty) {
            Fluttertoast.showToast(msg: 'Coupon Not Found!');
            changeVerifingCouponState(state: false);
            return false;
          }

          appliedCoupon = coupons.first;
          Fluttertoast.showToast(msg: 'Coupon applied successfully.');
          changeVerifingCouponState(state: false);

          return true;
        } else if (response.statusCode == 404) {
          Fluttertoast.showToast(msg: 'Coupon is invalid or has expired.');
          changeVerifingCouponState(state: false);
          return false;
        }
      }
    } catch (error) {
      changeVerifingCouponState(state: false);

      Fluttertoast.showToast(msg: error.toString());
    }
  }
}
