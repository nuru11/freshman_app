// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Agent _$AgentFromJson(Map<String, dynamic> json) => Agent(
  id: (json['id'] as num).toInt(),
  userPhone: json['user_phone'] as String,
  userName: json['user_name'] as String,
  coins: (json['coins'] as num).toInt(),
  earnings: (json['earnings'] as num?)?.toDouble(),
  isApproved: json['is_approved'] as bool,
  approvedAt: json['approved_at'] == null
      ? null
      : DateTime.parse(json['approved_at'] as String),
  rejectedAt: json['rejected_at'] == null
      ? null
      : DateTime.parse(json['rejected_at'] as String),
  rejectedReason: json['rejected_reason'] as String?,
  bankName: json['bank_name'] as String?,
  bankAccountNumber: json['bank_account_number'] as String?,
  accountName: json['account_name'] as String?,
  referralCode: json['referral_code'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AgentToJson(Agent instance) => <String, dynamic>{
  'id': instance.id,
  'user_phone': instance.userPhone,
  'user_name': instance.userName,
  'coins': instance.coins,
  'earnings': instance.earnings,
  'is_approved': instance.isApproved,
  'approved_at': instance.approvedAt?.toIso8601String(),
  'rejected_at': instance.rejectedAt?.toIso8601String(),
  'rejected_reason': instance.rejectedReason,
  'bank_name': instance.bankName,
  'bank_account_number': instance.bankAccountNumber,
  'account_name': instance.accountName,
  'referral_code': instance.referralCode,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
