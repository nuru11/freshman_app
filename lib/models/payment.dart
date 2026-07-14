import 'package:json_annotation/json_annotation.dart';
import 'package:vector_academy/models/models.dart';

part 'payment.g.dart';

enum PaymentStatus { pending, approved, rejected }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.rejected:
        return 'Rejected';
    }
  }
}

@JsonSerializable()
class Payment {
  final int id;
  final double amount;
  @JsonKey(name: 'successful')
  final bool successful;
  final String receipt;
  final int package;
  @JsonKey(name: 'payment_method')
  final PaymentMethod? paymentMethod;
  @JsonKey(name: 'referral_code')
  final String? referralCode;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.successful,
    required this.receipt,
    required this.package,
    this.paymentMethod,
    this.referralCode,
    required this.createdAt,
  });

  // Get payment status based on isCompleted and adminNotes
  PaymentStatus get status {
    if (successful) {
      return PaymentStatus.approved;
    } else {
      return PaymentStatus.pending;
    }
  }

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

@JsonSerializable()
class PaymentCreateRequest {
  final int package;
  @JsonKey(name: 'payment_method')
  final int paymentMethod;
  final String device;
  final int amount;
  final String receipt; // Changed from String to int (file ID)
  @JsonKey(name: 'referral_code')
  final String? referralCode;

  PaymentCreateRequest({
    required this.package,
    required this.paymentMethod,
    required this.device,
    required this.amount,
    required this.receipt,
    this.referralCode,
  });

  factory PaymentCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentCreateRequestToJson(this);
}
