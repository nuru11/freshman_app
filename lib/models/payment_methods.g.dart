// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_methods.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentMethod _$PaymentMethodFromJson(Map<String, dynamic> json) =>
    PaymentMethod(
      id: (json['id'] as num).toInt(),
      bankName: json['bank_name'] as String,
      accountName: json['account_name'] as String,
      accountNumber: json['account_number'] as String,
      image: json['image'] as String?,
    );

Map<String, dynamic> _$PaymentMethodToJson(PaymentMethod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bank_name': instance.bankName,
      'account_name': instance.accountName,
      'account_number': instance.accountNumber,
      'image': instance.image,
    };
