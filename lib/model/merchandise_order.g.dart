// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchandise_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchandiseOrder _$MerchandiseOrderFromJson(Map<String, dynamic> json) =>
    MerchandiseOrder(
      id: json['id'] as String,
      paymentStatus: json['payment_status'] as String,
      orderStatus: json['order_status'] as String,
      data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MerchandiseOrderToJson(MerchandiseOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'payment_status': instance.paymentStatus,
      'order_status': instance.orderStatus,
      'data': instance.data,
    };

OrderData _$OrderDataFromJson(Map<String, dynamic> json) => OrderData(
      token: Token.fromJson(json['token'] as Map<String, dynamic>),
      variants: (json['variants'] as List<dynamic>)
          .map((e) => Variant.fromJson(e as Map<String, dynamic>))
          .toList(),
      recipient: Recipient.fromJson(json['recipient'] as Map<String, dynamic>),
      totalCosts: (json['total_costs'] as num).toDouble(),
    );

Map<String, dynamic> _$OrderDataToJson(OrderData instance) => <String, dynamic>{
      'token': instance.token,
      'variants': instance.variants,
      'recipient': instance.recipient,
      'total_costs': instance.totalCosts,
    };

Token _$TokenFromJson(Map<String, dynamic> json) => Token(
      indexId: json['index_id'] as String,
      imageUrl: json['image_url'] as String,
      previewUrl: json['preview_url'] as String,
    );

Map<String, dynamic> _$TokenToJson(Token instance) => <String, dynamic>{
      'index_id': instance.indexId,
      'image_url': instance.imageUrl,
      'preview_url': instance.previewUrl,
    };

Variant _$VariantFromJson(Map<String, dynamic> json) => Variant(
      item: Item.fromJson(json['item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );

Map<String, dynamic> _$VariantToJson(Variant instance) => <String, dynamic>{
      'item': instance.item,
      'quantity': instance.quantity,
    };

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'price': instance.price,
      'product': instance.product,
    };

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'image_url': instance.imageUrl,
      'description': instance.description,
    };

Recipient _$RecipientFromJson(Map<String, dynamic> json) => Recipient(
      zip: json['zip'] as String,
      city: json['city'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      company: json['company'] as String,
      addressOne: json['address1'] as String,
      addressTwo: json['address2'] as String,
      stateCode: json['state_code'] as String,
      stateName: json['state_name'] as String,
      taxNumber: json['tax_number'] as String,
      countryCode: json['country_code'] as String,
      countryName: json['country_name'] as String,
    );

Map<String, dynamic> _$RecipientToJson(Recipient instance) => <String, dynamic>{
      'zip': instance.zip,
      'city': instance.city,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'company': instance.company,
      'address1': instance.addressOne,
      'address2': instance.addressTwo,
      'state_code': instance.stateCode,
      'state_name': instance.stateName,
      'tax_number': instance.taxNumber,
      'country_code': instance.countryCode,
      'country_name': instance.countryName,
    };
