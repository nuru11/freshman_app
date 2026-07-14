class ReferralValidationResult {
  final bool valid;
  final int discountPercent;
  final double originalPrice;
  final double discountedAmount;
  final double amountToPay;

  ReferralValidationResult({
    required this.valid,
    required this.discountPercent,
    required this.originalPrice,
    required this.discountedAmount,
    required this.amountToPay,
  });

  factory ReferralValidationResult.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) =>
        double.parse(value.toString());

    return ReferralValidationResult(
      valid: json['valid'] as bool? ?? false,
      discountPercent: json['discount_percent'] as int? ?? 0,
      originalPrice: parseAmount(json['original_price']),
      discountedAmount: parseAmount(json['discounted_amount']),
      amountToPay: parseAmount(json['amount_to_pay']),
    );
  }
}
