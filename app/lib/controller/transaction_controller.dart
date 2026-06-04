import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/models/transaction.dart';

class TransactionController extends ChangeNotifier {
  TransactionController() {
    // attachController();
    getTransactions();
  }

  final ScrollController controller = ScrollController();
  List<Transaction> transactions = [];
  bool isFetchingMoreTransactions = false;
  bool areTransactionsReachedEnd = false;
  int pageKey = 10;
  int pageSize = 0;

  void attachController() {
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        log('readhed end load more');
        if (!areTransactionsReachedEnd) {
          getTransactions();
        }
      }
    });
  }

  void changeIsFetchingMoreTransactionsState({required bool state}) {
    isFetchingMoreTransactions = state;
    notifyListeners();
  }

  Future refreshTransactions() async {
    try {
      // areTransactionsReachedEnd = false;
      // pageSize = 0;
      // transactions.clear();
      await getTransactions();
    } catch (error) {
      log(error.toString());
    }
  }

  Future getTransactions() async {
    try {
      if (transactions.isEmpty) {
        changeIsFetchingMoreTransactionsState(state: true);
      }
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        http.Response response = await http.get(
          Uri.parse('$baseUrl/transactions'),
          // Uri.parse('$baseUrl/transactions?perPage=$pageKey&skip=$pageSize'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          log('Transactions fetched successfully');
          Map data = jsonDecode(response.body) as Map;

          List<Transaction> newTransactions = List.from((data['content'] ?? []))
              .map((e) => Transaction.fromMap(e))
              .toList();

          // if (newTransactions.length < pageKey) {
          //   transactions.addAll(newTransactions);
          //   areTransactionsReachedEnd = true;
          // } else {
          //   transactions.addAll(newTransactions);
          //   pageSize = transactions.length;
          // }
          transactions = List.from(newTransactions);
          notifyListeners();
          // transactions.clear();
          log('Got Transactions ${transactions.length}');
        } else {
          toastMessage(response.body);
        }
      }
      changeIsFetchingMoreTransactionsState(state: false);
    } catch (error) {
      changeIsFetchingMoreTransactionsState(state: false);
      toastMessage(error.toString());
    }
  }
}
