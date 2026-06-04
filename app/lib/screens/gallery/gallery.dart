import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/screens/gallery/image_details.dart';
import 'package:truthcatcher/screens/profile/archive.dart';

import '../search/search.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NtfController>(
        builder: (context, NtfController nftController, _) {
      List<MintedImage> images = nftController.images;

      // images = [...images, ...images];
      // images = [...images, ...images];
      // images = [...images, ...images];

      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          scrolledUnderElevation: 0.0,
          elevation: 0.0,
          centerTitle: false,
          backgroundColor: kBackgroundColor,
          titleSpacing: 15.0,
          title: Text(
            'Gallery (${nftController.images.length.addPrefixZero()})',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: LiquidPullToRefresh(
          showChildOpacityTransition: false,
          color: kPrimaryColor,
          onRefresh: () async {
            await nftController.refreshImages();
          },
          child: Builder(builder: (context) {
            if (images.isEmpty) {
              return const EmptyGalleryWidget();
            }
            return SizedBox(
              height: Get.height,
              child: Column(
                children: [
                  Expanded(
                    child: StaggeredGridView.countBuilder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      controller: nftController.controller,
                      padding: EdgeInsets.only(
                          bottom: Get.height * 0.1,
                          left: 16.0,
                          right: 16.0,
                          top: 16.0),
                      crossAxisCount: 2, // Number of columns
                      itemCount: images.length, // Total number of items
                      itemBuilder: (BuildContext context, int index) {
                        final int duration =
                            ((index + 1) * 150) > 800 ? 800 : (index + 1) * 150;

                        return Entry.scale(
                          scale: 0.7,
                          key: ValueKey(images[index].id),
                          duration: Duration(milliseconds: duration),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: GalleryImageWidget(
                                image: images[index],
                                nftController: nftController),
                          ),
                        );
                      },
                      staggeredTileBuilder: (int index) {
                        return StaggeredTile.count(
                            1,
                            (index.isOdd && index <= 2)
                                ? 0.7
                                : index % 3 == 0
                                    ? 1.5
                                    : index.isEven
                                        ? 1.2
                                        : 0.9); // Item height varies
                      },
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                    ),
                  ),
                  if (nftController.isFetchingMoreImages)
                    Column(
                      children: [
                        const SizedBox(height: 16.0),
                        CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ),
      );
    });
  }
}

class EmptyGalleryWidget extends StatelessWidget {
  const EmptyGalleryWidget({
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
            SizedBox(height: Get.height * 0.25),
            SvgPicture.asset('assets/icons/no_images.svg',
                height: Get.height * 0.13),
            const SizedBox(height: 16.0),
            Center(
              child: Text(
                'Your NFT Gallery is waiting to come alive! ',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 15),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Start creating unique NFTs, capture the moment, and let your art shine.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryImageWidget extends StatelessWidget {
  GalleryImageWidget({
    super.key,
    required this.image,
    required this.nftController,
  });

  final MintedImage image;
  final NtfController nftController;
  final GlobalKey _backgroundImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8.0),
      child: LayoutBuilder(builder: (context, constraints) {
        return InkWell(
          onTap: () {
            nftController.setSelectedImage(image: image);
            Get.to(
                () => ImageDetails(
                    image: image, isArchived: false, fromNotifications: false),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeIn);
          },
          child: Flow(
            delegate: ParallaxFlowDelegate(
              maxHeight: constraints.maxHeight,
              scrollable: Scrollable.of(context),
              listItemContext: context,
              backgroundImageKey: _backgroundImageKey,
            ),
            children: [
              Hero(
                tag: image.id,
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        key: _backgroundImageKey,
                        placeholder: (context, url) => ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                              width: Get.width,
                              color: kPrimaryAccentColor,
                              child: const Center(
                                  child: CircularProgressIndicator.adaptive(
                                strokeWidth: 1.5,
                              ))),
                        ),
                        errorWidget: (context, url, error) => ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: Get.width,
                            color: kPrimaryAccentColor,
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/icons/broken_image.svg',
                                height: 48.0,
                                width: 48.0,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                        imageUrl: image.image,
                        fit: BoxFit.cover,
                      ),
                    )),
              ),
            ],
          ),
        );
      }),
    );
  }
}
