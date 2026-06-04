import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:entry/entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:truthcatcher/constant.dart';
import 'package:truthcatcher/controller/nft_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(color: kPrimaryColor, width: 1),
    borderRadius: BorderRadius.circular(50),
  );
  final TextEditingController searchController = TextEditingController();
  String get matricule => searchController.text.trim();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      Provider.of<NtfController>(context, listen: false).getMintedNfts();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> images = [
    'assets/frame1.svg',
    'assets/frame2.svg',
    'assets/frame3.svg',
  ];
  List<String> titles = [
    'Catch an instant',
    'Immortalize a situation ',
    'Prove the moment ',
  ];
  List<String> subTitles = [
    'Prove deepfakes, thanks to blockchain',
    'Protect yourselves against fake news',
    'Assess the reality in a living instant, if it really happened.',
  ];
  int position = 1;
  final CarouselSliderController _carouselController = CarouselSliderController();
  @override
  Widget build(BuildContext context) {
    return Consumer<NtfController>(
        builder: (context, NtfController nftController, _) {
      return SafeArea(
        child: Scaffold(
            backgroundColor: kBackgroundColor,
            body: SingleChildScrollView(
              // padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: Get.height * 0.05),
                  CarouselSlider(
                    carouselController: _carouselController,
                    options: CarouselOptions(
                      onPageChanged:
                          (int index, CarouselPageChangedReason reason) {
                        setState(() {
                          position = index;
                        });
                      },
                      enlargeCenterPage: false,
                      height: Get.height * 0.4,
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      viewportFraction: 1,
                    ),
                    items: [0, 1, 2].map((i) {
                      return Column(children: [
                        SvgPicture.asset(
                          images[i],
                          fit: BoxFit.cover,
                          height: Get.height * 0.25,
                          width: Get.width,
                        ),
                        const SizedBox(height: 24),
                        FadeInRight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  titles[i],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  subTitles[i],
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: const Color(0xFF2B2B2B),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),

                  const SizedBox(height: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Entry(
                            scale: 0.7,
                            key: position == 0 ? UniqueKey() : null,
                            child: Container(
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(
                                  color: position == 0
                                      ? kPrimaryColor
                                      : kWhiteColor,
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Entry(
                            scale: 0.7,
                            key: position == 1 ? UniqueKey() : null,
                            child: Container(
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(
                                  color: position == 1
                                      ? kPrimaryColor
                                      : kWhiteColor,
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Entry(
                            scale: 0.7,
                            key: position == 2 ? UniqueKey() : null,
                            child: Container(
                              height: 8,
                              width: 8,
                              decoration: BoxDecoration(
                                  color: position == 2
                                      ? kPrimaryColor
                                      : kWhiteColor,
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Entry.scale(
                  //   scale: 0.7,
                  //   curve: Curves.easeInOutBack,
                  //   duration: const Duration(milliseconds: 500),
                  //   child: Image.asset(
                  //     'assets/images/home.png',
                  //     colorBlendMode: BlendMode.lighten,
                  //   ),
                  // ),
                  SizedBox(height: Get.height * 0.05),
                  Text('Verify the moment',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        color: const Color(0xFF2A2A2A),
                        fontWeight: FontWeight.w400,
                      )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: Get.width * 0.85,
                    child: TextFormField(
                      controller: searchController,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.visiblePassword,
                      onTapOutside: (vl) {
                        FocusManager.instance.primaryFocus!.unfocus();
                      },
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(8),
                      ],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: const Color(0xFF2B2B2B),
                        fontWeight: FontWeight.w400,
                      ),
                      onChanged: (val) {
                        setState(() {});
                        if (val.length >= 8) {
                          FocusManager.instance.primaryFocus!.unfocus();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Type Matricule Number',
                        hintStyle: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: const Color(0xFF2B2B2B),
                          fontWeight: FontWeight.w400,
                        ),
                        fillColor: kWhiteColor,
                        filled: true,
                        border: border,
                        errorBorder: border,
                        enabledBorder: border,
                        focusedBorder: border,
                        disabledBorder: border,
                        focusedErrorBorder: border,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed:
                          matricule.isNotEmpty && !nftController.isSearching
                              ? () async {
                                  await nftController.searchNft(
                                      matricule: matricule);
                                  searchController.clear();
                                }
                              : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          disabledBackgroundColor: kPrimaryAccentColor,
                          fixedSize: Size(Get.width * 0.5, 56.0)),
                      child: nftController.isSearching
                          ? Center(
                              child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator.adaptive(
                                valueColor:
                                    AlwaysStoppedAnimation(kPrimaryColor),
                                strokeWidth: 2,
                              ),
                            ))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.search_normal_1,
                                    color: kWhiteColor),
                                const SizedBox(width: 16),
                                Text(
                                  'SEARCH',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: kWhiteColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            )),
      );
    });
  }
}

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
