import 'dart:developer';

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
import 'package:truthcatcher/controller/notification_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/models/notifications.dart';
import 'package:truthcatcher/screens/gallery/image_details.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationController>(
        builder: (context, NotificationController notificationController, _) {
      final List<Notifications> notifications =
          notificationController.notifications;

      List<Notifications> unArchivedNotifications;
      final String query = notificationController.query;
      final bool isDeleting = notificationController.isDeleting;
      final bool isSearching = notificationController.isSearching;

      if (query.isNotEmpty && isSearching) {
        unArchivedNotifications = List.from(notifications
            .where((element) => element.matricule!.contains(query)));
      } else {
        unArchivedNotifications = List.from(
            notifications.where((element) => element.isArchived == false));
      }
      unArchivedNotifications = List.from(unArchivedNotifications.reversed);

      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          leadingWidth: 0,
          leading: const SizedBox(width: 8),
          scrolledUnderElevation: 0.0,
          actions: [
            if (isDeleting)
              Entry(
                scale: 0.3,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                child: Stack(
                  children: [
                    IconButton(
                        onPressed: () {
                          if (isDeleting) {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                      surfaceTintColor: kWhiteColor,
                                      scrollable: true,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0)),
                                      backgroundColor: kWhiteColor,
                                      content: Container(
                                        decoration: BoxDecoration(
                                            color: kWhiteColor,
                                            borderRadius:
                                                BorderRadius.circular(12.0)),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Are you sure you want to delete selected notifications!',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                OutlinedButton(
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                          side: BorderSide(
                                                              color:
                                                                  kPrimaryColor),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        56.0),
                                                          )),
                                                  onPressed: () async {
                                                    Get.back();
                                                  },
                                                  child: Text(
                                                    'Cancel',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                            color:
                                                                kPrimaryColor),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              kPrimaryColor,
                                                          side: BorderSide(
                                                              color:
                                                                  kPrimaryColor),
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        56.0),
                                                          )),
                                                  onPressed: () async {
                                                    await notificationController
                                                        .archiveNotifications();
                                                    Get.back();
                                                  },
                                                  child: Text(
                                                    'Delete',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                            color:
                                                                Colors.white),
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ));
                                });
                          } else {
                            notificationController.toggleIsDeleting();
                          }
                        },
                        icon: const Icon(Iconsax.trash)),
                    Positioned(
                      right: 5,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red),
                        child: Text(
                          notificationController.selectedNotifications.length
                              .toString(),
                          style: GoogleFonts.montserrat(
                              fontSize: 8.0, color: kWhiteColor),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            if (isDeleting)
              Entry(
                scale: 0.3,
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutBack,
                child: IconButton(
                    onPressed: () {
                      notificationController.toggleIsDeleting();
                      notificationController.selectedNotifications.clear();
                    },
                    icon: Icon(
                        isDeleting ? Iconsax.close_square : Iconsax.trash)),
              ),
            if (isDeleting) const SizedBox(width: 6),
            if (!isDeleting)
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                onPressed: () {
                  if (isSearching) {
                    notificationController.updateQuery(val: '');
                    notificationController.toggleSearching();
                  } else {
                    notificationController.toggleSearching();
                  }
                },
                style: const ButtonStyle(
                    padding:
                        WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero)),
                icon: Icon(notificationController.isSearching
                    ? Iconsax.close_square
                    : Iconsax.search_normal),
              ),
            if (!isDeleting) const SizedBox(width: 15.0)
          ],
          titleSpacing: 8.0,
          centerTitle: false,
          backgroundColor: kBackgroundColor,
          title: notificationController.isSearching
              ? Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Center(
                    child: TextFormField(
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.top,
                      // cursorHeight: 16,
                      onChanged: (val) {
                        notificationController.updateQuery(val: val);
                      },
                      cursorHeight:
                          20.0, // Adjust based on the fontSize and padding

                      autofocus: isSearching ? true : false,
                      controller: notificationController.searchController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 10.0),
                          constraints: const BoxConstraints(
                            maxHeight: 36,
                          ),
                          isDense: true,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          )),
                    ),
                  ),
                )
              : Text(
                  'Notifications',
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        body: LiquidPullToRefresh(
          color: kPrimaryColor,
          onRefresh: () async {
            await notificationController.refreshNotifications();
          },
          showChildOpacityTransition: false,
          child: Builder(builder: (context) {
            if (unArchivedNotifications.isEmpty) {
              return const EmptyNotificationsWidget();
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: notificationController.controller,
              padding: EdgeInsets.only(
                  top: 16, bottom: Get.height * 0.1, right: 16, left: 16.0),
              itemBuilder: (context, index) {
                final Notifications currentNotification =
                    unArchivedNotifications[index];
                final int duration =
                    ((index + 1) * 150) > 800 ? 800 : (index + 1) * 150;
                return Entry(
                  duration: Duration(milliseconds: duration),
                  scale: 0.6,
                  key: ValueKey(currentNotification.id),
                  child: notificationTile(
                      notificationController: notificationController,
                      isDeleting: isDeleting,
                      notification: currentNotification,
                      context: context),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: unArchivedNotifications.length,
              // shrinkWrap: true,
            );
          }),
        ),
      );
    });
  }

  // if (isDeleting)
  Widget notificationTile({
    required Notifications notification,
    required BuildContext context,
    required bool isDeleting,
    required NotificationController notificationController,
  }) {
    final bool isSelected =
        notificationController.selectedNotifications.contains(notification.id);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: isSelected ? kPrimaryAccentColor : kWhiteColor,
      ),
      child: ListTile(
        dense: true,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        style: ListTileStyle.list,
        onLongPress: () {
          if (isDeleting) {
            return;
          } else {
            notificationController.toggleIsDeleting();
            notificationController.selectNotification(
                notificationId: notification.id);
          }
        },
        onTap: isDeleting
            ? () {
                if (isSelected) {
                  notificationController.unSelectNotification(
                      notificationId: notification.id);
                } else {
                  notificationController.selectNotification(
                      notificationId: notification.id);
                }
              }
            : () {
                Clipboard.setData(
                    ClipboardData(text: notification.matricule ?? "NA"));
                Fluttertoast.showToast(msg: 'Copied to clipboard');
              },
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                notification.matricule != null
                    ? "${notification.title} (${notification.matricule!})"
                    : notification.title,
                maxLines: isDeleting ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF464648),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Text(
              // timeago.format(notification.date, locale: 'en_short'),
              DateFormat('EEE, dd MMM hh:mm a')
                  .format(notification.date.toLocal()),
              style: GoogleFonts.montserrat(
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: SizedBox(
                width: Get.width * 0.6,
                child: Text(
                  notification.message,
                  maxLines: isDeleting ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF464648),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (notification.matricule != null) {
                  List<MintedImage> images =
                      Provider.of<NtfController>(context, listen: false).images;
                  List<MintedImage> archivedImages =
                      Provider.of<NtfController>(context, listen: false)
                          .archivedImages;
                  if (images.any((element) =>
                      element.matricule == notification.matricule)) {
                    final MintedImage mintedImage = images.firstWhere(
                        (element) =>
                            element.matricule == notification.matricule);
                    Provider.of<NtfController>(context, listen: false)
                        .selectedImage = mintedImage;
                    Get.to(() => ImageDetails(
                          image: mintedImage,
                          isArchived: false,
                          fromNotifications: true,
                        ));
                  } else if (archivedImages.any((element) =>
                      element.matricule == notification.matricule)) {
                    final MintedImage archivedImage = archivedImages.firstWhere(
                        (element) =>
                            element.matricule == notification.matricule);
                    Provider.of<NtfController>(context, listen: false)
                        .selectedImage = archivedImage;
                    Get.to(() => ImageDetails(
                          image: archivedImage,
                          isArchived: true,
                          fromNotifications: true,
                        ));
                  } else {
                    Provider.of<NtfController>(context, listen: false)
                        .getMintedNfts();
                    log('No image is available with this matricule');
                  }
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View',
                style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: kPrimaryColor,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.only(left: 12, right: 12.0),
      ),
    );
  }
}

class EmptyNotificationsWidget extends StatelessWidget {
  const EmptyNotificationsWidget({
    super.key,
  });

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
              SizedBox(height: Get.height * 0.23),
              FloatingWidget(
                verticalSpace: 4,
                duration: const Duration(seconds: 2),
                reverseDuration: const Duration(seconds: 2),
                child: SvgPicture.asset('assets/icons/nonoti.svg',
                    height: Get.height * 0.13),
              ),
              const SizedBox(height: 8.0),
              Center(
                  child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No Notifications yet. Stay tuned for updates and exciting news!.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 15),
                ),
              )),
            ],
          ),
        ));
  }
}
