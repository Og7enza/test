import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/screens/gallery/image_details.dart';

class SearchPage extends StatelessWidget {
  final MintedImage image;
  const SearchPage({required this.image, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        titleSpacing: 0.0,
        centerTitle: false,
        title: Text(
          'Search',
          style: TextStyle(
            fontSize: 20,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          splashRadius: 20,
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Iconsax.arrow_left,
            color: kPrimaryColor,
          ),
        ),
      ),
      body: SearchWidget(image: image),
    );
  }
}

class SearchWidget extends StatelessWidget {
  const SearchWidget({
    super.key,
    required this.image,
  });

  final MintedImage image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                NftImageWidget(image: image),
                MatriculeWidget(selectedImage: image),
              ],
            ),
            const SizedBox(height: 16),
            Entry(
              child: Row(
                children: [
                  SvgPicture.asset('assets/icons/gallery_icon.svg'),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: Get.width * 0.5,
                    child: Text(
                      image.name,
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
                      if (image.time != null)
                        Text(
                          DateFormat()
                              .add_jm()
                              .format(DateTime.parse(image.time!)),
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
            if (image.time != null) const SizedBox(height: 16),
            if (image.time != null)
              Entry(
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/calendar_icon.svg',
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        DateFormat()
                            .add_yMd()
                            .format(DateTime.parse(image.time!).toLocal()),
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
                      image.location,
                      textAlign: TextAlign.start,

                      maxLines: 3,
                      // overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class NftImageWidgetParallax extends StatelessWidget {
  NftImageWidgetParallax({
    super.key,
    required this.image,
  });

  final MintedImage image;
  final GlobalKey _backgroundImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Container(
            margin: EdgeInsets.only(bottom: Get.height * 0.03),
            width: Get.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              child: Flow(
                clipBehavior: Clip.antiAlias,
                delegate: ParallaxFlowDelegate(
                  maxHeight: constraints.maxHeight,
                  scrollable: Scrollable.of(context),
                  listItemContext: context,
                  backgroundImageKey: _backgroundImageKey,
                ),
                children: [
                  CachedNetworkImage(
                    key: _backgroundImageKey,
                    placeholder: (context, url) => ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: SizedBox(
                        height: 250,
                        width: Get.width,
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        color: kPrimaryAccentColor,
                        height: 250,
                        width: Get.width,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/broken_image.svg',
                            height: 48.0,
                          ),
                        ),
                      ),
                    ),
                    imageUrl: image.image,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class NftImageWidget extends StatelessWidget {
  NftImageWidget({
    super.key,
    required this.image,
  });

  final MintedImage image;
  final GlobalKey _backgroundImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(bottom: Get.height * 0.03),
              constraints: BoxConstraints(maxHeight: Get.height * 0.6),
              width: Get.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  key: _backgroundImageKey,
                  placeholder: (context, url) => ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: SizedBox(
                      height: 250,
                      width: Get.width,
                      child: const Center(
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      color: kPrimaryAccentColor,
                      height: 250,
                      width: Get.width,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/broken_image.svg',
                          height: 48.0,
                        ),
                      ),
                    ),
                  ),
                  imageUrl: image.image,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Get.to(() => PinchZoomWidget(image: image));
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.rectangle),
                      height: 36,
                      width: 36,
                      child: const Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        fill: 0.8,
                        weight: 5,
                        size: 20,
                      ),
                    ),
                  ),
                ))
          ],
        ),
      ),
    );
  }
}

class PinchZoomWidget extends StatefulWidget {
  const PinchZoomWidget({super.key, required this.image});
  final MintedImage image;

  @override
  State<PinchZoomWidget> createState() => _PinchZoomWidgetState();
}

class _PinchZoomWidgetState extends State<PinchZoomWidget> {
  late Timer timer;
  bool isActive = true;
  @override
  void initState() {
    // TODO: implement initState

    WidgetsBinding.instance.addPostFrameCallback((timestamp) {
      timer = Timer(const Duration(milliseconds: 1500), () {
        isActive = false;
        setState(() {});
        timer.cancel();
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
          backgroundColor: kBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0.0,
          titleSpacing: 0.0,
          centerTitle: false,
          title: Text(
            "Image",
            style: GoogleFonts.montserrat(
              fontSize: 20,
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          iconTheme: IconThemeData(color: kPrimaryColor)),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          InteractiveViewer(
            panEnabled: true,
            maxScale: 5.5,
            child: SizedBox(
              child: CachedNetworkImage(
                placeholder: (context, url) => SizedBox(
                  height: 250,
                  width: Get.width,
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 1.5,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    color: kPrimaryAccentColor,
                    height: 250,
                    width: Get.width,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/broken_image.svg',
                        height: 48.0,
                      ),
                    ),
                  ),
                ),
                fit: BoxFit.contain,
                imageUrl: widget.image.image,
              ),
            ),
          ),
          // if (isActive)
          //   Positioned(
          //       top: 0,
          //       bottom: 0,
          //       left: 0,
          //       right: 0,
          //       child: Center(
          //           child: Lottie.asset("assets/lottie/pinch_zoom.json",
          //               animate: true, repeat: true, height: 150)))
        ],
      ),
    );
  }
}

class ParallaxFlowDelegate extends FlowDelegate {
  ParallaxFlowDelegate({
    required this.scrollable,
    required this.maxHeight,
    required this.listItemContext,
    required this.backgroundImageKey,
  }) : super(repaint: scrollable.position);

  final ScrollableState scrollable;
  final double maxHeight;
  final BuildContext listItemContext;
  final GlobalKey backgroundImageKey;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(
        width: constraints.maxWidth, height: maxHeight + 70);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    if (backgroundImageKey.currentContext != null) {
      // Calculate the position of this list item within the viewport.
      final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
      final listItemBox = listItemContext.findRenderObject() as RenderBox;
      final listItemOffset = listItemBox.localToGlobal(
          listItemBox.size.centerLeft(Offset.zero),
          ancestor: scrollableBox);
      final viewportDimension = scrollable.position.viewportDimension;
      final scrollFraction =
          (listItemOffset.dy / viewportDimension).clamp(0.0, 1.0);
      final verticalAlignment = Alignment(0.0, scrollFraction * 2 - 1);
      final backgroundSize =
          (backgroundImageKey.currentContext?.findRenderObject() as RenderBox)
              .size;
      final listItemSize = context.size;
      final childRect = verticalAlignment.inscribe(
          backgroundSize, Offset.zero & listItemSize);
      context.paintChild(
        0,
        transform:
            Transform.translate(offset: Offset(0.0, childRect.top)).transform,
      );
    } else {
      context.paintChild(
        0,
        transform:
            Transform.translate(offset: const Offset(0.0, 0.9)).transform,
      );
    }
  }

  @override
  bool shouldRepaint(ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        backgroundImageKey != oldDelegate.backgroundImageKey;
  }
}
