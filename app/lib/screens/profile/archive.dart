import 'package:animated_floating_widget/widgets/floating_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:provider/provider.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_grid_view.dart';
import 'package:staggered_grid_view_flutter/widgets/staggered_tile.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/screens/gallery/image_details.dart';

class Archive extends StatelessWidget {
  const Archive({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NtfController>(
        builder: (context, NtfController nftController, _) {
      List<MintedImage> archivedImages = nftController.archivedImages;

      final String archivedImagesLength = archivedImages.length.addPrefixZero();
      return Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
            scrolledUnderElevation: 0.0,
            elevation: 0,
            iconTheme: IconThemeData(color: kPrimaryColor),
            centerTitle: false,
            backgroundColor: kBackgroundColor,
            titleSpacing: 0.0,
            title: Text(
              'Private Images ($archivedImagesLength)',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            )),
        body: LiquidPullToRefresh(
          showChildOpacityTransition: false,
          color: kPrimaryColor,
          onRefresh: () async {
            await nftController.refreshArchivedImages();
          },
          child: Builder(builder: (context) {
            if (archivedImages.isEmpty) {
              return const EmptyPrivateImagesWidget();
            }
            return Column(
              children: [
                Expanded(
                  child: StaggeredGridView.countBuilder(
                    controller: nftController.archivedImageScrollController,
                    padding: const EdgeInsets.all(16.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    crossAxisCount: 2, // Number of columns
                    itemCount: archivedImages.length, // Total number of items
                    itemBuilder: (BuildContext context, int index) {
                      return ArchivedImageCard(
                        image: archivedImages[index],
                        nftController: nftController,
                      );
                    },
                    staggeredTileBuilder: (int index) {
                      final double mainAxisCellCount =
                          (index.isEven && 4 % (index + 1) == 0)
                              ? 0.8
                              : index.isOdd
                                  ? 1.5
                                  : index % 3 == 0
                                      ? 1.8
                                      : 1.2;
                      return StaggeredTile.count(
                          1, mainAxisCellCount); // Item height varies
                    },
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                  ),
                ),
                if (nftController.isFetchingMoreArchivedImages)
                  Column(
                    children: [
                      const SizedBox(height: 16.0),
                      CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                      ),
                    ],
                  ),
              ],
            );
          }),
        ),
      );
    });
  }
}

class EmptyPrivateImagesWidget extends StatelessWidget {
  const EmptyPrivateImagesWidget({
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
          children: [
            SizedBox(height: Get.height * 0.25),
            FloatingWidget(
              verticalSpace: 4,
              duration: const Duration(seconds: 2),
              reverseDuration: const Duration(seconds: 2),
              child: SvgPicture.asset('assets/icons/no_archives.svg',
                  height: Get.height * 0.13),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No private images yet. Start uploading and securing your memories!',
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

class ArchivedImageCard extends StatelessWidget {
  const ArchivedImageCard({
    super.key,
    required this.image,
    required this.nftController,
  });

  final MintedImage image;
  final NtfController nftController;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          nftController.setSelectedImage(image: image);
          Get.to(() => ImageDetails(
                image: image,
                isArchived: true,
                fromNotifications: false,
              ));
        },
        child: Hero(
          tag: image.id,
          child: Container(
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: image.image,
                  fit: BoxFit.cover,
                  width: Get.width,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 1.5,
                    ),
                  ),
                  errorWidget: (context, url, error) => ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/broken_image.svg',
                        height: 32.0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: Get.width,
                    decoration: BoxDecoration(
                        color: kPrimaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        )),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/archive_white.svg',
                          height: 14.0,
                        ),
                        const SizedBox(width: 8),
                        if (image.time != null)
                          Text(
                            DateFormat()
                                .add_yMd()
                                .format(DateTime.parse(image.time!).toLocal()),
                            style: textTheme.displayMedium?.copyWith(
                              fontSize: 13,
                              color: kWhiteColor,
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

extension IntWithPrefixZero on int {
  String addPrefixZero() {
    if (this == 0) {
      return 0.toString();
    }
    return this < 10 ? '0$this' : toString();
  }
}
