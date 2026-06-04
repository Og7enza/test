import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constant.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  // List<Map<String, dynamic>> questions = [
  //   {
  //     'question':
  //         'Can I sell or transfer the NFTs created with the application?',
  //     'answer':
  //         'Yes, absolutely! Our application empowers users to freely sell or transfer the NFTs they create. Once you\'ve generated an NFT through our platform, you have full ownership and control over your digital assets. Whether you want to sell your NFTs to interested buyers or transfer them to other users, our application provides a seamless and secure process for managing the transactions. Just explore the user-friendly features within the application to initiate the selling or transferring process for your NFTs.',
  //     'selected': false,
  //   },
  //   {
  //     'question': 'What fees are associated with NFT creation?',
  //     'answer':
  //         """Our NFT creation process is designed to be transparent and user-friendly. However, it's essential to note that there may be fees associated with the creation of NFTs. These fees typically cover the costs related to minting, processing, and storing your digital assets on the blockchain.

  //         The specific fees can vary based on factors such as the blockchain used, the complexity of the NFT creation process, and any additional features or services provided by the platform. Before proceeding with NFT creation, we recommend checking the fee structure within the application or platform to ensure you have a clear understanding of any associated costs.

  //         Rest assured, we strive to keep our fee structures competitive and reasonable, providing you with a valuable and accessible NFT creation experience. Feel free to explore the application for detailed information on associated fees and any potential cost breakdowns.""",
  //     'selected': false,
  //   },
  //   {
  //     'question': 'Are there any restrictions on content for NFT creation?',
  //     'answer':
  //         """While we aim to provide users with creative freedom, there are some guidelines and restrictions on the content that can be used for NFT creation. These restrictions are in place to ensure compliance with legal and ethical standards. Here are some common considerations:

  // 1. No Offensive or Illegal Content:

  //     Content that is offensive, illegal, or violates our community standards is not allow
  //     ed to be uploaded and will result in immediate removal of your account. We reserve the right to remove any content at any time without notice.

  // 2. Respect Copyright and Intellectual Property:

  //     Users must respect the copyright and intellectual property rights of others. Avoid using content that you do not have the right to u

  // 3. No Harmful or Malicious Content:

  //     Content that may cause harm or is intended for malicious purposes is strictly prohibit

  // 4. Complianze with Platform Policies:

  //     Ensure that your content complies with the specific policies and guidelines of our platfom

  // 5. No Misrepresentation:

  //     Do not create NFTs that misrepresent your identity, affiliation, or any other detai

  // 6. Compliance with Applicable Laws:

  //     Adhere to all applicable laws and regulations regarding content creation.

  // Before creating an NFT, we recommend reviewing the platform's terms of service and content guidelines to ensure that your content aligns with our policies. Failure to comply with these guidelines may result in the removal of content or other appropriate actions to maintain a safe and respectful community environment. If you have any specific questions about content restrictions, our support team is here to assist you.""",
  //     'selected': false,
  //   },
  //   {
  //     'question': 'How can I view and manage my NFT collection?',
  //     'answer':
  //         """Managing and viewing your NFT collection is a straightforward process within our application. Here's a step-by-step guide:

  // 1. Login to Your Account:

  //   Ensure that you are logged in to your account on the application.

  // 2. Navigate to "Gallery":

  //   Look for a dedicated section labeled "Gallery" .This section is where you can view and manage your NFTs""",
  //     'selected': false,
  //   },
  //   {
  //     'question': 'Can I customize metadata for my NFTs?',
  //     'answer':
  //         "Within the editing interface, you may find various metadata fields such as title, description, tags, and more. Modify these fields according to your preferences",
  //     'selected': false,
  //   },
  //   {
  //     'question':
  //         'How does the application handle copyright and intellectual property concerns?',
  //     'answer':
  //         'Our application takes copyright and intellectual property concerns seriously and has implemented measures to address these issues responsibly. Here\'s an overview of how we handle copyright and intellectual property concerns',
  //     'selected': false,
  //   },
  // ];

  List<Map<String, dynamic>> questions = [
    {
      "question": "What is the use of TruthCatcher? ",
      "answer":
          "The primary utility of Truth Cather is as the name says, to catch the truth in a moment or a situation as captured. A user can use this application as a platform for authenticity and integrity in Images."
    },
    {
      "question": "What can I do with the images that I mint on TruthCatcher ",
      "answer":
          "You can store those images in your gallery inside the application, share with your friends, business partners, family, colleagues etc to validate the truth. You can buy back those NFTs and share/transfer to your business partners, friends, family, colleagues etc."
    },
    {
      "question":
          "Where can I see all the Images that I clicked via truth catcher?",
      "answer":
          "In the gallery section in the TruthCatcher application, additionally you can move the selected images to your private folder in the profile section "
    },
    {
      "question": "Can I customize the information of the Image? ",
      "answer":
          "No, since the objective is to validate the Truth in the moment, you can’t customize any information except the name of the image. Once an NFT is minted, you can’t change the name as well. "
    },
    {
      "question": "What fees are associated with minting an NFT for the image.",
      "answer":
          "We are charging as little as €0.59 to mint an NFT out of your moment of Truth. This is less than choco croissant or a cup of Capuccino, which we charge only deliver you with the best experience on Truth Catcher "
    },
    {
      "question": "Is my data on TC safe and secure? ",
      "answer":
          "Yes, we take data concerns very seriously and abide by the global data regulation standards. We maintain extreme integrity of the image information and other data associated to users following the start of the art data security and privacy measures."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        elevation: 0,
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
        centerTitle: false,
        backgroundColor: kBackgroundColor,
        title: Text(
          'Help',
          style: GoogleFonts.montserrat(
            fontSize: 20,
            color: kPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently asked questions',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            ListView.separated(
              itemBuilder: (context, index) =>
                  helpTile(index: index, question: questions[index]),
              separatorBuilder: (context, index) => const Divider(),
              itemCount: questions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
            ),
            const SizedBox(height: 50),
            Center(
              child: CustomButton(
                callBack: () {
                  final Uri emailLauncherUri = Uri(
                    scheme: 'mailto',
                    path: 'truthcatchertheapp@gmail.com',
                    query: jsonEncode(<String, String>{
                      'subject': 'Example Subject & Symbols are allowed!'
                    }),
                  );
                  launchUrl(emailLauncherUri);
                },
                title: 'Write Us',
                child: null,
                height: 45,
                width: Get.width * 0.5,
                enabled: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget helpTile({
    required int index,
    required Map<String, dynamic> question,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                question['question'],
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        iconColor: kPrimaryColor,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Text(
            question['answer'],
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}
