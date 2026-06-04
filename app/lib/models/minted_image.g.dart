// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'minted_image.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MintedImageAdapter extends TypeAdapter<MintedImage> {
  @override
  final int typeId = 1;

  @override
  MintedImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MintedImage(
      id: fields[0] as String,
      userId: fields[1] as String,
      matricule: fields[2] as String,
      name: fields[3] as String,
      image: fields[4] as String,
      time: fields[5] as String?,
      v: fields[6] as int,
      transactionId: fields[7] as String,
      location: fields[8] as String,
      nftTransferHash: fields[9] as String?,
      transferedAt: fields[10] as DateTime,
      contractAddress: fields[14] as String?,
      tokenId: fields[13] as String?,
      status: fields[11] as String,
      isArchived: fields[12] as bool,
      createdAt: fields[15] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MintedImage obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.matricule)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.image)
      ..writeByte(5)
      ..write(obj.time)
      ..writeByte(6)
      ..write(obj.v)
      ..writeByte(7)
      ..write(obj.transactionId)
      ..writeByte(8)
      ..write(obj.location)
      ..writeByte(9)
      ..write(obj.nftTransferHash)
      ..writeByte(10)
      ..write(obj.transferedAt)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.tokenId)
      ..writeByte(14)
      ..write(obj.contractAddress)
      ..writeByte(12)
      ..write(obj.isArchived)
      ..writeByte(15)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MintedImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
