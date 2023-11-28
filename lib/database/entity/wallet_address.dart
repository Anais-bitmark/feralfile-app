import 'package:autonomy_flutter/database/entity/persona.dart';
import 'package:floor/floor.dart';
import 'package:nft_collection/models/address_index.dart';

@entity
class WalletAddress {
  @primaryKey
  final String address;
  @ForeignKey(
      childColumns: ['uuid'],
      parentColumns: ['uuid'],
      entity: Persona,
      onDelete: ForeignKeyAction.cascade)
  final String uuid;
  final int index;
  final String cryptoType;
  final DateTime createdAt;
  final bool isHidden;
  final String? name;

  WalletAddress(
      {required this.address,
      required this.uuid,
      required this.index,
      required this.cryptoType,
      required this.createdAt,
      this.isHidden = false,
      this.name});

  WalletAddress copyWith({
    String? address,
    String? uuid,
    int? index,
    String? cryptoType,
    DateTime? createdAt,
    bool? isHidden,
    String? name,
  }) =>
      WalletAddress(
        address: address ?? this.address,
        uuid: uuid ?? this.uuid,
        index: index ?? this.index,
        cryptoType: cryptoType ?? this.cryptoType,
        createdAt: createdAt ?? this.createdAt,
        isHidden: isHidden ?? this.isHidden,
        name: name ?? this.name,
      );

  AddressIndex get addressIndex =>
      AddressIndex(address: address, createdAt: createdAt);

  // from Json
  factory WalletAddress.fromJson(Map<String, dynamic> json) => WalletAddress(
        address: json['address'],
        uuid: json['uuid'],
        index: json['index'],
        cryptoType: json['cryptoType'],
        createdAt: DateTime.parse(json['createdAt']),
        isHidden: json['isHidden'],
        name: json['name'],
      );

  // to Json
  Map<String, dynamic> toJson() => {
        'address': address,
        'uuid': uuid,
        'index': index,
        'cryptoType': cryptoType,
        'createdAt': createdAt.toIso8601String(),
        'isHidden': isHidden,
        'name': name,
      };
}
