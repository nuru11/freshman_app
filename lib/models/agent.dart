import 'package:json_annotation/json_annotation.dart';

part 'agent.g.dart';

@JsonSerializable()
class Agent {
  final int id;
  @JsonKey(name: 'user_phone')
  final String userPhone;
  @JsonKey(name: 'user_name')
  final String userName;
  final int coins;
  final double? earnings;
  @JsonKey(name: 'is_approved')
  final bool isApproved;
  @JsonKey(name: 'approved_at')
  final DateTime? approvedAt;
  @JsonKey(name: 'rejected_at')
  final DateTime? rejectedAt;
  @JsonKey(name: 'rejected_reason')
  final String? rejectedReason;
  @JsonKey(name: 'bank_name')
  final String? bankName;
  @JsonKey(name: 'bank_account_number')
  final String? bankAccountNumber;
  @JsonKey(name: 'account_name')
  final String? accountName;
  @JsonKey(name: 'referral_code')
  final String? referralCode;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Agent({
    required this.id,
    required this.userPhone,
    required this.userName,
    required this.coins,
    this.earnings,
    required this.isApproved,
    this.approvedAt,
    this.rejectedAt,
    this.rejectedReason,
    this.bankName,
    this.bankAccountNumber,
    this.accountName,
    this.referralCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
  Map<String, dynamic> toJson() => _$AgentToJson(this);
}
