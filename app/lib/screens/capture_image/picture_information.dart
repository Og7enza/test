import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/controller/stripe_controller.dart';
import 'package:truthcatcher/screens/capture_image/payment_summary.dart';
import 'package:vpn_connection_detector/vpn_connection_detector.dart';

import 'image_preview.dart';

class PictureInformation extends StatefulWidget {
  final File file;
  final DateTime date;
  const PictureInformation({required this.file, super.key, required this.date});

  @override
  State<PictureInformation> createState() => _PictureInformationState();
}

class _PictureInformationState extends State<PictureInformation>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormFieldState> _nameKey = GlobalKey<FormFieldState>();

  String get name => _nameController.text.trim();

  OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryColor),
    borderRadius: BorderRadius.circular(16),
  );
  bool isNameSelected = true;
  bool isDateSelected = true;
  bool isAddressSelected = true;

  final VpnConnectionDetector vpnDetector = VpnConnectionDetector();

  String? location;
  Position? position;
  Placemark? placeMark;
  bool serviceEnabled = false;
  LocationPermission? permission;

  bool hasStreet = true;
  bool hasCity = true;
  bool hasAdmistristrativeArea = true;
  List<Placemark> placemarks = [];
  bool isVpnEnabled = false;
  bool isLoadingLocation = false;
  bool isPriciseLocation = true;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Provider.of<StripeController>(context, listen: false).getProducts();
      WidgetsBinding.instance.addObserver(this);
      _controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      )..repeat(reverse: false);

      _animation = Tween<double>(begin: 24, end: 150).animate(_controller)
        ..addListener(() {
          setState(() {});
        });
      await getLocation();
    });
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _controller.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && state.name == "resumed") {
      // App has resumed from the background
      if (!isPriciseLocation) {
        log('App is resumed');
        getAccuracy();
      }
      // You can put your code here to handle the app being resumed
    }
  }

  Future getAccuracy() async {
    try {
      await Geolocator.getCurrentPosition(
              forceAndroidLocationManager: true,
              desiredAccuracy: LocationAccuracy.best)
          .then((value) async {
        log("accuracy => ${value.accuracy}");
        if (value.accuracy > 100) {
          Fluttertoast.showToast(
            msg:
                'Location accuracy is insufficient. Please enable high accuracy.',
            toastLength: Toast.LENGTH_LONG,
          );
          if (isPriciseLocation == true) {
            isPriciseLocation = false;
            setState(() {});
          }

          // Optionally, direct user to location settings
          return;
        } else {
          isPriciseLocation = true;
        }
        setState(() {
          position = value;
          log(position!.latitude.toString());
          log(position!.longitude.toString());
          getPlacemarkers();
        });
      }).onError(
        (error, stackTrace) {
          log(error.toString());
        },
      );
    } catch (error) {}
  }

  Future getLocation() async {
    try {
      // openAppSettings();
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      permission = await Geolocator.checkPermission();
      if (isPriciseLocation) {
        setState(() {});
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
            msg:
                'Location Permissions are permanantly denied, Please enable the location permissions in the settings',
            toastLength: Toast.LENGTH_LONG);
      } else if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Please enable the location services');
        }
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        await Geolocator.requestPermission();

        await Permission.locationWhenInUse.request();

        await Geolocator.getCurrentPosition(
                // forceAndroidLocationManager: true,
                // desiredAccuracy: LocationAccuracy.best
                )
            .then((value) async {
          log("accuracy => ${value.accuracy}");
          if (value.accuracy > 100) {
            Fluttertoast.showToast(
              msg:
                  'Location accuracy is insufficient. Please enable high accuracy.',
              toastLength: Toast.LENGTH_LONG,
            );
            if (isPriciseLocation == true) {
              isPriciseLocation = false;
              setState(() {});
            }

            // Optionally, direct user to location settings
            return;
          } else {
            isPriciseLocation = true;
          }
          setState(() {
            position = value;
            log(position!.latitude.toString());
            log(position!.longitude.toString());
            getPlacemarkers();
          });
        }).onError(
          (error, stackTrace) {
            log(error.toString());
          },
        );
      }
    } catch (error) {
      log('Error in fetching location $error');
      if (error
          .toString()
          .contains('The location service on the device is disabled.')) {
        Fluttertoast.showToast(msg: 'Please enable the location services');
      }
    }
  }

  Future<void> openLocationSettings() async {
    if (await Permission.location.serviceStatus.isEnabled) {
      await openAppSettings();
    } else {
      Fluttertoast.showToast(
          msg: 'Please enable location services in settings.',
          toastLength: Toast.LENGTH_LONG);
    }
  }

  Future getPlacemarkers() async {
    List<Placemark> tempPlacemarks = await placemarkFromCoordinates(
      position!.latitude,
      position!.longitude,
    );

    setState(() {
      placemarks = tempPlacemarks;
    });
    if (placemarks.isNotEmpty) {
      log(placemarks.toString());
      placeMark = placemarks.last;
      if (placeMark != null) {
        updateLocation();
      }
    }
  }

  void updateLocation() {
    setState(() {
      if (hasStreet && hasCity && hasAdmistristrativeArea) {
        location =
            '${placeMark!.street} ${placeMark!.subLocality} ${placeMark!.locality} ${placeMark!.administrativeArea} ${placeMark!.isoCountryCode}.';
      } else if (hasStreet && hasCity) {
        location =
            '${placeMark!.street} ${placeMark!.subLocality} ${placeMark!.locality} ${placeMark!.isoCountryCode}.';
      } else if (hasStreet && hasAdmistristrativeArea) {
        location =
            '${placeMark!.street} ${placeMark!.administrativeArea} ${placeMark!.isoCountryCode}.';
      } else if (hasCity && hasAdmistristrativeArea) {
        location =
            '${placeMark!.subLocality} ${placeMark!.locality} ${placeMark!.administrativeArea} ${placeMark!.isoCountryCode}.';
      } else if (hasStreet) {
        location = '${placeMark!.street} ${placeMark!.isoCountryCode}.';
      } else if (hasCity) {
        location =
            '${placeMark!.subLocality} ${placeMark!.locality} ${placeMark!.isoCountryCode}.';
      } else if (hasAdmistristrativeArea) {
        location =
            '${placeMark!.administrativeArea} ${placeMark!.isoCountryCode}.';
      } else {
        location = 'NA';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final DateTime dateTime = widget.date;

    bool hasLocationPermissions = (permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.0,
        titleSpacing: 0.0,
        centerTitle: false,
        iconTheme: IconThemeData(color: kPrimaryColor),
        backgroundColor: kBackgroundColor,
        title: Text(
          'Picture Information',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Consumer<NtfController>(
          builder: (context, NtfController nftController, _) {
        bool isValid = nftController.isValid;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Hero(
                  tag: widget.file.path,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                        constraints:
                            BoxConstraints(maxHeight: Get.height * 0.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        width: Get.width,
                        child: Image.file(
                          widget.file,
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.cover,
                        )),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isValid)
                  Column(
                    children: [
                      SizedBox(height: Get.height * 0.03),
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
                        DateFormat("dd/mm/yyyy, h:mm a").format(DateTime.now()),
                        style: GoogleFonts.montserrat(),
                      ),
                      SizedBox(height: Get.height * 0.03),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              fixedSize: Size(Get.width * 0.5, 54),
                              backgroundColor: kPrimaryColor),
                          onPressed: () async {
                            SettingsUtil.openDateTimeSettings();
                          },
                          child: Text("Adjust",
                              style: GoogleFonts.montserrat(
                                  color: kWhiteColor,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                if (isValid)
                  Column(
                    children: [
                      SizedBox(
                        child: TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                          onTapOutside: (value) {
                            FocusManager.instance.primaryFocus!.unfocus();
                          },
                          // autofocus: true,
                          validator: (val) => val.toString().isEmpty
                              ? 'Please enter a valid name'
                              : null,
                          key: _nameKey,
                          decoration: InputDecoration(
                            hintText: 'NFT Name',
                            fillColor: kWhiteColor,
                            filled: true,
                            border: border,
                            errorBorder: border,
                            enabledBorder: border,
                            focusedBorder: border,
                            disabledBorder: border,
                            focusedErrorBorder: border,
                            prefixIcon: Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kBackgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                height: 26,
                                width: 26,
                                padding: const EdgeInsets.all(6),
                                child: SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: SvgPicture.asset(
                                    'assets/icons/gallery_icon.svg',
                                    height: 16,
                                    width: 16,
                                  ),
                                ),
                              ),
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: MaterialButton(
                                    elevation: 0,
                                    height: 20,
                                    minWidth: 20,
                                    onPressed: () {
                                      setState(() {
                                        isNameSelected = !isNameSelected;
                                        if (!isNameSelected) {
                                          _nameKey.currentState!.reset();
                                        }
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    shape: const StadiumBorder(),
                                    color: isNameSelected
                                        ? kPrimaryColor
                                        : Colors.grey.withOpacity(0.5),
                                    child: Icon(
                                      Icons.check,
                                      size: 18,
                                      color: kWhiteColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 56,
                        width: Get.width,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: kBackgroundColor,
                                shape: BoxShape.circle,
                              ),
                              height: 26,
                              width: 26,
                              padding: const EdgeInsets.all(4),
                              child: SizedBox(
                                height: 16,
                                width: 16,
                                child: SvgPicture.asset(
                                  'assets/icons/calendar_icon.svg',
                                  height: 16,
                                  width: 16,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(dateTime),
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.black,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: MaterialButton(
                                elevation: 0,
                                onPressed: () {
                                  setState(() {
                                    isDateSelected = !isDateSelected;
                                  });
                                },
                                padding: EdgeInsets.zero,
                                shape: const StadiumBorder(),
                                color: isDateSelected
                                    ? kPrimaryColor
                                    : Colors.grey.withOpacity(0.5),
                                child: Icon(
                                  Icons.check,
                                  size: 18,
                                  color: kWhiteColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      //location
                      Container(
                        width: Get.width,
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          color: kWhiteColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryColor,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ExpansionTile(
                            tilePadding:
                                const EdgeInsets.only(left: 16, right: 14),
                            trailing: !isPriciseLocation
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: SizedBox(
                                      width: 60,
                                      height: 40,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor
                                                  .withOpacity(0.2),
                                            ),
                                            width: 150,
                                            height: 150,
                                          ),
                                          Container(
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: kPrimaryColor
                                                  .withOpacity(0.0),
                                            ),
                                            width: _animation.value - 15,
                                            height: 150,
                                          ),
                                          Switch.adaptive(
                                              value: false,
                                              onChanged: (val) {
                                                openAppSettings();
                                              }),
                                        ],
                                      ),
                                    ),
                                  )
                                : hasLocationPermissions
                                    ? const SizedBox()
                                    : null,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0)),
                            controlAffinity: ListTileControlAffinity.platform,
                            initiallyExpanded: false,
                            title: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: kBackgroundColor,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: SvgPicture.asset(
                                          'assets/icons/location_icon.svg',
                                          height: 16,
                                          width: 16,
                                        ),
                                      ),
                                    ),
                                    // if (placemarks.length > 1)
                                    //   Positioned(
                                    //       right: -6,
                                    //       top: -10,
                                    //       child: Container(
                                    //         padding: const EdgeInsets.all(6.0),
                                    //         decoration: BoxDecoration(
                                    //             color: kPrimaryColor,
                                    //             shape: BoxShape.circle),
                                    //         child: Text(
                                    //           placemarks.length.toString(),
                                    //           textAlign: TextAlign.center,
                                    //           style: GoogleFonts.montserrat(
                                    //               color: kWhiteColor,
                                    //               fontSize: 10.0),
                                    //         ),
                                    //       )),
                                  ],
                                ),
                                const SizedBox(width: 12.0),
                                !isPriciseLocation
                                    ? const Flexible(
                                        child: Text(
                                            "Precise Location is required"))
                                    : permission ==
                                                LocationPermission
                                                    .deniedForever ||
                                            permission ==
                                                LocationPermission.denied
                                        ? Flexible(
                                            child: Text(
                                              "Location permission denied",
                                              style: GoogleFonts.montserrat(
                                                  color: Colors.red),
                                            ),
                                          )
                                        : location != null
                                            ? Flexible(
                                                child: Text(
                                                  location.toString(),
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              )
                                            : Shimmer(
                                                gradient:
                                                    LinearGradient(colors: [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade100,
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade100,
                                                ]),
                                                child: Container(
                                                  height: 20,
                                                  width: Get.width * 0.5,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      color: kWhiteColor),
                                                ),
                                              ),
                              ],
                            ),
                            childrenPadding: const EdgeInsets.all(12),
                            children: [
                              if (placeMark != null)
                                InkWell(
                                  onTap: () {
                                    hasStreet = !hasStreet;
                                    updateLocation();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'Around: ',
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: placeMark!.street,
                                                  style: textTheme.titleSmall,
                                                )
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(56.0),
                                            color: hasStreet &&
                                                    (placeMark!.street ?? '')
                                                        .isNotEmpty
                                                ? kPrimaryColor
                                                : Colors.grey.withOpacity(0.5),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            size: 16,
                                            color: kWhiteColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (placeMark != null)
                                InkWell(
                                  onTap: () {
                                    hasCity = !hasCity;
                                    updateLocation();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'City: ',
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text:
                                                      '${placeMark!.subLocality} ${placeMark!.locality}',
                                                  style: textTheme.titleSmall,
                                                )
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(56.0),
                                            color: hasCity &&
                                                    ((placeMark!.subLocality ??
                                                                '')
                                                            .isNotEmpty ||
                                                        (placeMark!.locality ??
                                                                '')
                                                            .isNotEmpty)
                                                ? kPrimaryColor
                                                : Colors.grey.withOpacity(0.5),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            size: 16,
                                            color: kWhiteColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (placeMark != null)
                                InkWell(
                                  onTap: () {
                                    hasAdmistristrativeArea =
                                        !hasAdmistristrativeArea;
                                    updateLocation();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          flex: 3,
                                          child: Text.rich(
                                            TextSpan(
                                              text: 'Area: ',
                                              style: textTheme.titleSmall
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: placeMark!
                                                      .administrativeArea,
                                                  style: textTheme.titleSmall,
                                                )
                                              ],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          height: 20,
                                          width: 20,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(56.0),
                                            color: hasAdmistristrativeArea &&
                                                    (placeMark!.administrativeArea ??
                                                            "")
                                                        .isNotEmpty
                                                ? kPrimaryColor
                                                : Colors.grey.withOpacity(0.5),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            size: 16,
                                            color: kWhiteColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Container(
                      //   width: Get.width,
                      //   padding: const EdgeInsets.symmetric(
                      //     horizontal: 20,
                      //     vertical: 10,
                      //   ),
                      //   decoration: BoxDecoration(
                      //     color: kWhiteColor,
                      //     borderRadius: BorderRadius.circular(16),
                      //     border: Border.all(
                      //       color: kPrimaryColor,
                      //     ),
                      //   ),
                      //   child: Row(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Container(
                      //         decoration: BoxDecoration(
                      //           color: kBackgroundColor,
                      //           shape: BoxShape.circle,
                      //         ),
                      //         height: 26,
                      //         width: 26,
                      //         padding: const EdgeInsets.all(4),
                      //         child: SizedBox(
                      //           height: 16,
                      //           width: 16,
                      //           child: SvgPicture.asset(
                      //             'assets/icons/location_icon.svg',
                      //             height: 16,
                      //             width: 16,
                      //           ),
                      //         ),
                      //       ),
                      //       const SizedBox(width: 10),
                      //       const Spacer(),
                      //       SizedBox(
                      //         height: 20,
                      //         width: 20,
                      //         child: MaterialButton(
                      //           elevation: 0,
                      //           onPressed: () {
                      //             setState(() {
                      //               addressValue = !addressValue;
                      //             });
                      //           },
                      //           padding: EdgeInsets.zero,
                      //           shape: const StadiumBorder(),
                      //           color: addressValue
                      //               ? kPrimaryColor
                      //               : Colors.grey.withOpacity(0.5),
                      //           child: const Icon(
                      //             Icons.check,
                      //             size: 18,
                      //             color: kWhiteColor,
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      SizedBox(height: Get.height * 0.03),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const StadiumBorder(),
                            backgroundColor: kPrimaryColor,
                            fixedSize: Size(
                              Get.width * 0.45,
                              52.0,
                            ),
                            disabledBackgroundColor:
                                kPrimaryColor.withOpacity(.3)),
                        onPressed: permission ==
                                    LocationPermission.deniedForever ||
                                (location == null)
                            ? null
                            : () {
                                if (isNameSelected) {
                                  if (_nameKey.currentState!.validate()) {
                                    if (position != null && location != null) {
                                      Get.to(
                                        () => PaymentSummary(
                                          name: name,
                                          file: widget.file,
                                          location: location!,
                                          position: position!,
                                          dateTime:
                                              isDateSelected ? dateTime : null,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  if (position != null && (location != null)) {
                                    Get.to(
                                      () => PaymentSummary(
                                        name: name,
                                        file: widget.file,
                                        location: location!,
                                        position: position!,
                                        dateTime:
                                            isDateSelected ? dateTime : null,
                                      ),
                                    );
                                  } else {
                                    Fluttertoast.showToast(
                                        msg:
                                            'Please enable to location services');
                                  }
                                }
                              },
                        child: Text(
                          'CONFIRM',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: kWhiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // cancle button
                      MaterialButton(
                        padding: EdgeInsets.zero,
                        height: 30,
                        onPressed: () {
                          Get.back();
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
