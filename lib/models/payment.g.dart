// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
  id: (json['id'] as num).toInt(),
  amount: (json['amount'] as num).toDouble(),
  successful: json['successful'] as bool,
  receipt: json['receipt'] as String,
  package: (json['package'] as num).toInt(),
  paymentMethod: json['payment_method'] == null
      ? null
      : PaymentMethod.fromJson(json['payment_method'] as Map<String, dynamic>),
  referralCode: json['referral_code'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
  'id': instance.id,
  'amount': instance.amount,
  'successful': instance.successful,
  'receipt': instance.receipt,
  'package': instance.package,
  'payment_method': instance.paymentMethod,
  'referral_code': instance.referralCode,
  'created_at': instance.createdAt.toIso8601String(),
};

PaymentCreateRequest _$PaymentCreateRequestFromJson(
  Map<String, dynamic> json,
) => PaymentCreateRequest(
  package: (json['package'] as num).toInt(),
  paymentMethod: (json['payment_method'] as num).toInt(),
  device: json['device'] as String,
  amount: (json['amount'] as num).toInt(),
  receipt: json['receipt'] as String,
  referralCode: json['referral_code'] as String?,
);

Map<String, dynamic> _$PaymentCreateRequestToJson(
  PaymentCreateRequest instance,
) => <String, dynamic>{
  'package': instance.package,
  'payment_method': instance.paymentMethod,
  'device': instance.device,
  'amount': instance.amount,
  'receipt': instance.receipt,
  'referral_code': instance.referralCode,
};
