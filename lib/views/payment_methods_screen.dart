import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/controllers/controllers.dart';
import '../models/models.dart';

class PaymentMethodsScreen extends StatelessWidget {
  final int subjectId;
  final int amount;
  final String subjectTitle;

  const PaymentMethodsScreen({
    super.key,
    required this.subjectId,
    required this.amount,
    required this.subjectTitle,
  });

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(PaymentController());

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackLeading(color: Colors.white),
        title: const Text('Payment Methods'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Payment Info Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject: $subjectTitle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Amount: ${amount.toString()} ETB',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Payment Methods List
            Expanded(
              child: controller.paymentMethods.isEmpty
                  ? const Center(
                      child: Text(
                        'No payment methods available',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = controller.paymentMethods[index];
                        return _buildPaymentMethodCard(
                          context,
                          controller,
                          method,
                        );
                      },
                    ),
            ),

            // Continue Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.selectedPaymentMethod != null
                      ? () => _navigateToReceiptUpload(context, controller)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildPaymentMethodCard(
    BuildContext context,
    PaymentController controller,
    PaymentMethod method,
  ) {
    return Obx(() {
      final isSelected = controller.selectedPaymentMethod?.id == method.id;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isSelected ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => controller.selectPaymentMethod(method),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Payment Method Icon/Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: method.image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            method.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.account_balance,
                              color: Theme.of(context).primaryColor,
                              size: 30,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.account_balance,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                ),
                const SizedBox(width: 16),

                // Payment Method Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.bankName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method.accountName,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Account: ${method.accountNumber}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _navigateToReceiptUpload(
    BuildContext context,
    PaymentController controller,
  ) {
    Get.toNamed(
      '/payment/receipt',
      arguments: {
        'subjectId': subjectId,
        'amount': amount,
        'subjectTitle': subjectTitle,
        'paymentMethod': controller.selectedPaymentMethod,
      },
    );
  }
}
