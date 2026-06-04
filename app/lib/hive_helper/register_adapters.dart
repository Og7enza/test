import 'package:hive/hive.dart';
import 'package:truthcatcher/models/minted_image.dart';
import 'package:truthcatcher/models/user_model.dart';

void registerAdapters() {
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(MintedImageAdapter());
}
