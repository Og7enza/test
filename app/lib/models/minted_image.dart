import 'package:hive_flutter/adapters.dart';
import 'package:truthcatcher/hive_helper/hive_adapters.dart';

import '../hive_helper/fields/minted_image_fields.dart';
import '../hive_helper/hive_types.dart';

part 'minted_image.g.dart';

@HiveType(typeId: HiveTypes.mintedImage, adapterName: HiveAdapters.mintedImage)
class MintedImage extends HiveObject {
  @HiveField(MintedImageFields.id)
  final String id;
  @HiveField(MintedImageFields.userId)
  final String userId;
  @HiveField(MintedImageFields.matricule)
  final String matricule;
  @HiveField(MintedImageFields.name)
  final String name;
  @HiveField(MintedImageFields.image)
  final String image;
  @HiveField(MintedImageFields.time)
  final String? time;
  @HiveField(MintedImageFields.v)
  final int v;
  @HiveField(MintedImageFields.transactionId)
  final String transactionId;
  @HiveField(MintedImageFields.location)
  final String location;
  @HiveField(MintedImageFields.nftTransferHash)
  final String? nftTransferHash;
  @HiveField(MintedImageFields.transferedAt)
  final DateTime transferedAt;
  @HiveField(MintedImageFields.status)
  final String status;
  @HiveField(MintedImageFields.tokenId)
  final String? tokenId;
  @HiveField(MintedImageFields.contractAddress)
  final String? contractAddress;
  @HiveField(MintedImageFields.isArchived)
  final bool isArchived;
  @HiveField(MintedImageFields.createdAt)
  final DateTime createdAt;

  MintedImage({
    required this.id,
    required this.userId,
    required this.matricule,
    required this.name,
    required this.image,
    required this.time,
    required this.v,
    required this.transactionId,
    required this.location,
    required this.nftTransferHash,
    required this.transferedAt,
    required this.contractAddress,
    required this.tokenId,
    required this.status,
    required this.isArchived,
    required this.createdAt,
  });

  factory MintedImage.fromJson(Map json) {
    return MintedImage(
      id: json['_id'],
      userId: json['userId'],
      matricule: json['matricule'],
      name: json['name'],
      image: json['image'],
      time: json['time'],
      v: json['__v'] ?? 0,
      transactionId: json['transactionId'] ?? "NA",
      location: json['location'],
      nftTransferHash: json['nftTransferHash'],
      status: json['status'],
      tokenId: json['tokenId'],
      contractAddress: json['contractAddress'],
      isArchived: json['isArchived'],
      createdAt: DateTime.parse(
          json['createdAt'] ?? json['time'] ?? DateTime.now().toString()),
      transferedAt: json['transferedAt'] ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'matricule': matricule,
      'name': name,
      'image': image,
      'time': time,
      '__v': v,
      'transactionId': transactionId,
      'location': location,
      'nftTransferHash': nftTransferHash,
      'transferedAt': transferedAt,
    };
  }

  MintedImage copyWith({
    String? id,
    String? userId,
    String? matricule,
    String? name,
    String? image,
    String? time,
    int? v,
    String? transactionId,
    String? location,
    String? nftTransferHash,
    DateTime? transferedAt,
    String? status,
    String? contractAddress,
    String? tokenId,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return MintedImage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      matricule: matricule ?? this.matricule,
      name: name ?? this.name,
      image: image ?? this.image,
      time: time ?? this.time,
      status: status ?? this.status,
      contractAddress: contractAddress ?? this.contractAddress,
      isArchived: isArchived ?? this.isArchived,
      tokenId: tokenId ?? this.tokenId,
      v: v ?? this.v,
      transactionId: transactionId ?? this.transactionId,
      location: location ?? this.location,
      nftTransferHash: nftTransferHash ?? this.nftTransferHash,
      transferedAt: transferedAt ?? this.transferedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'matricule': matricule,
      'name': name,
      'image': image,
      'time': time,
      'v': v,
      'transactionId': transactionId,
      'location': location,
      'nftTransferHash': nftTransferHash,
      'transferedAt': transferedAt,
    };
  }

  factory MintedImage.fromMap(Map map) {
    return MintedImage(
      id: map['_id'] ?? '',
      createdAt: map['createdAt'] ?? map['time'] ?? DateTime.now(),
      userId: map['userId'] ?? '',
      matricule: map['matricule'] ?? '',
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      time: map['time'] ?? '',
      v: map['v']?.toInt() ?? 0,
      transactionId: map['transactionId'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? '',
      contractAddress: map['contractAddresson'] ?? '',
      isArchived: map['isArchived'] ?? false,
      tokenId: map['tokenId'] ?? '',
      nftTransferHash: map['nftTransferHash'] ?? '',
      transferedAt: map['transferedAt'] ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'MintedImage(id: $id, userId: $userId, matricule: $matricule, name: $name, image: $image, time: $time, v: $v, transactionId: $transactionId, location: $location, isUserOwned: $transferedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MintedImage &&
        other.id == id &&
        other.userId == userId &&
        other.matricule == matricule &&
        other.name == name &&
        other.image == image &&
        other.time == time &&
        other.v == v &&
        other.transactionId == transactionId &&
        other.location == location &&
        other.nftTransferHash == nftTransferHash &&
        other.transferedAt == transferedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        matricule.hashCode ^
        name.hashCode ^
        image.hashCode ^
        time.hashCode ^
        v.hashCode ^
        transactionId.hashCode ^
        location.hashCode ^
        nftTransferHash.hashCode ^
        transferedAt.hashCode;
  }
}
