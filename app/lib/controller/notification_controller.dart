import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/models/notifications.dart';

class NotificationController extends ChangeNotifier {
  NotificationController() {
    getNotifications(isRefreshing: false);
    attachController();
  }
  List<Notifications> notifications = [];

  final ScrollController controller = ScrollController();
  final TextEditingController searchController = TextEditingController();
  String query = '';

  bool isFetchingMoreNotifications = false;
  bool areNotificationsReachedEnd = false;
  int pageKey = 10;
  int pageSize = 0;

  List<String> selectedNotifications = [];
  bool isDeleting = false;
  bool isSearching = false;

  void toggleIsDeleting() {
    isDeleting = !isDeleting;
    isSearching = false;
    notifyListeners();
  }

  void updateQuery({required String val}) {
    query = val;
    notifyListeners();
  }

  void toggleSearching() {
    isSearching = !isSearching;
    notifyListeners();
  }

  void selectNotification({required String notificationId}) {
    selectedNotifications.add(notificationId);
    notifyListeners();
  }

  void clearSelectedNotifications() {
    selectedNotifications.clear();
    isSearching = false;
    isDeleting = false;
    notifyListeners();
  }

  void unSelectNotification({required String notificationId}) {
    selectedNotifications.remove(notificationId);
    if (selectedNotifications.isEmpty) {
      isDeleting = false;
    }
    notifyListeners();
  }

  void attachController() {
    controller.addListener(() {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        log('readhed end load more');
        if (!areNotificationsReachedEnd) {
          getNotifications(isRefreshing: false);
        }
      }
    });
  }

  void changeIsFetchingMoreTransactionsState({required bool state}) {
    isFetchingMoreNotifications = state;
    notifyListeners();
  }

  Future refreshNotifications() async {
    try {
      // areNotificationsReachedEnd = false;
      // pageSize = 0;
      // selectedNotifications.clear();
      await getNotifications(isRefreshing: true);
    } catch (error) {
      log(error.toString());
    }
  }

  Future getNotifications({required bool isRefreshing}) async {
    try {
      changeIsFetchingMoreTransactionsState(state: true);
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();

      if (token != null) {
        http.Response response = await http.get(
          Uri.parse('$baseUrl/notifications'),
          // Uri.parse('$baseUrl/notifications?perPage=$pageKey&skip=$pageSize'),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          final Map data = jsonDecode(response.body) as Map;
          List<Notifications> newNotifications =
              List.from(data['content'] ?? [])
                  .map((e) => Notifications.fromMap(e))
                  .toList();

          // if (newNotifications.length < pageKey) {
          //   if (isRefreshing) {
          //     notifications = newNotifications;
          //   } else {
          //     notifications.addAll(newNotifications);
          //   }
          //   areNotificationsReachedEnd = true;
          // } else {
          //   if (isRefreshing) {
          //     notifications = newNotifications;
          //   } else {
          //     notifications.addAll(newNotifications);
          //   }
          //   pageSize = notifications.length;
          // }

          notifications = List.from(newNotifications);
        } else {
          log('Error fetching notifications => ${response.body}');
        }
      }
      changeIsFetchingMoreTransactionsState(state: false);
    } catch (error) {
      changeIsFetchingMoreTransactionsState(state: false);
      log(error.toString());
      Fluttertoast.showToast(msg: error.toString());
    }
  }

  Future archiveNotifications() async {
    try {
      final String? token =
          await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        http.Response response = await http.patch(
          Uri.parse('$baseUrl/notifications/archive'),
          body: jsonEncode({'archivedNotificationIds': selectedNotifications}),
          headers: {
            'authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          notifications = List.from(notifications.map((notification) {
            if (selectedNotifications.contains(notification.id)) {
              notification.isArchived = true;
              return notification;
            }
            return notification;
          }));

          clearSelectedNotifications();
        }
      }
    } catch (error) {
      Fluttertoast.showToast(msg: error.toString());
      log(error.toString());
    }
  }
}
