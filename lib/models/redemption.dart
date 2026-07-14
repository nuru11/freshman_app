enum RedemptionStatus { pending, approved, rejected }

extension RedemptionStatusExtension on RedemptionStatus {
  String get displayName {
    switch (this) {
      case RedemptionStatus.pending:
        return 'Pending';
      case RedemptionStatus.approved:
        return 'Approved';
      case RedemptionStatus.rejected:
        return 'Rejected';
    }
  }

  static RedemptionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RedemptionStatus.pending;
      case 'approved':
        return RedemptionStatus.approved;
      case 'rejected':
        return RedemptionStatus.rejected;
      default:
        return RedemptionStatus.pending;
    }
  }
}

class Redemption {
  final int agent;
  final int coinsRedeemed;
  final int birrAmount;
  final RedemptionStatus status;
  final String? notes;
  final int? processedBy;

  Redemption({
    required this.agent,
    required this.coinsRedeemed,
    required this.birrAmount,
    required this.status,
    this.notes,
    this.processedBy,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    // Convert status string to enum
    final statusString = json['status'] as String? ?? 'pending';
    final status = RedemptionStatusExtension.fromString(statusString);
    
    return Redemption(
      agent: (json['agent'] as num).toInt(),
      coinsRedeemed: (json['coins_redeemed'] as num).toInt(),
      birrAmount: (json['birr_amount'] as num).toInt(),
      status: status,
      notes: json['notes'] as String?,
      processedBy: json['processed_by'] != null 
          ? (json['processed_by'] as num).toInt() 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'agent': agent,
        'coins_redeemed': coinsRedeemed,
        'birr_amount': birrAmount,
        'status': status.name,
        'notes': notes,
        'processed_by': processedBy,
      };
}

