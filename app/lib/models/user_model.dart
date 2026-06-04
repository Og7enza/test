import 'package:hive/hive.dart';
import 'package:truthcatcher/hive_helper/fields/user_model_fields.dart';
import 'package:truthcatcher/hive_helper/hive_adapters.dart';
import 'package:truthcatcher/hive_helper/hive_types.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveTypes.userModel, adapterName: HiveAdapters.userModel)
class UserModel extends HiveObject {
  @HiveField(UserModelFields.id)
  String id;
  @HiveField(UserModelFields.name)
  String name;
  @HiveField(UserModelFields.email)
  String email;
  @HiveField(UserModelFields.uid)
  String uid;
  @HiveField(UserModelFields.v)
  int v;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.uid,
    required this.v,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? uid,
    int? v,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        uid: uid ?? this.uid,
        v: v ?? this.v,
      );

  factory UserModel.fromMap(Map json) => UserModel(
        id: json["_id"],
        name: json["name"] ?? "",
        email: json["email"] ?? "",
        uid: json["uid"],
        v: json["__v"],
      );

  Map<String, dynamic> toMap() => {
        "_id": id,
        "name": name,
        "email": email,
        "uid": uid,
        "__v": v,
      };
}
