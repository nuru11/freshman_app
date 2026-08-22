import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/utils/navigation_utils.dart';
import 'package:vector_academy/utils/pricing.dart';
import 'package:vector_academy/utils/utils.dart';

Widget buildPackagePriceLabel({
  required Package package,
  required PaymentController controller,
  TextStyle? priceStyle,
  bool showPerYear = false,
}) {
  final hasDiscount = controller.hasReferralDiscountForPackage(package.id);
  final displayAmount = controller.displayAmountForPackage(package);
  final defaultPriceStyle = priceStyle ??
      const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (hasDiscount) ...[
        Text(
          '${formatEtbAmount(package.price)} ETB',
          style: TextStyle(
            fontSize: (defaultPriceStyle.fontSize ?? 24) * 0.75,
            color: Colors.grey.shade600,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatEtbAmount(displayAmount)} ETB',
          style: defaultPriceStyle.copyWith(color: Colors.green.shade700),
        ),
      ] else
        Text(
          '${formatEtbAmount(displayAmount)} ETB',
          style: defaultPriceStyle,
        ),
      if (showPerYear)
        const Text(
          'per year',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
    ],
  );
}

Widget buildReferralCodeSection({
  required PaymentController controller,
  TextEditingController? textController,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Referral Code (Optional)',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 4),
      const SizedBox(height: 4),
      TextFormField(
        controller: textController,
        initialValue: textController == null ? controller.referralCode : null,
        decoration: InputDecoration(
          hintText: 'ABC12',
          prefixIcon: const Icon(Icons.local_offer),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
          suffixIcon: controller.referralValidationStatus ==
                  ReferralValidationStatus.loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : controller.referralValidationStatus ==
                      ReferralValidationStatus.valid
                  ? Icon(Icons.check_circle, color: Colors.green.shade600)
                  : controller.referralValidationStatus ==
                          ReferralValidationStatus.invalid
                      ? Icon(Icons.error_outline, color: Colors.red.shade400)
                      : null,
        ),
        textCapitalization: TextCapitalization.characters,
        maxLength: 5,
        onChanged: controller.setReferralCode,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
        ],
      ),
      if (controller.referralValidationStatus ==
          ReferralValidationStatus.invalid)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Invalid or unapproved referral code. Full price applies.',
            style: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
        ),
    ],
  );
}

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  // Helper method to get actual Subject objects from subject IDs
  List<Subject> _getPackageSubjects(Package package) {
    try {
      final coreService = Get.find<CoreService>();
      return package.subjects
          .map(
            (subjectId) => coreService.subjects.firstWhere(
              (subject) => subject.id == subjectId,
              orElse: () => Subject(
                id: subjectId,
                name: 'Subject $subjectId',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                chapters: [],
              ),
            ),
          )
          .toList();
    } catch (e) {
      // Fallback if CoreService is not available
      return package.subjects
          .map(
            (subjectId) => Subject(
              id: subjectId,
              name: 'Subject $subjectId',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              chapters: [],
            ),
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final dynamic rawSubjectId = args is Map ? args['subjectId'] : null;
    final int? targetSubjectId = rawSubjectId is int
        ? rawSubjectId
        : int.tryParse(rawSubjectId?.toString() ?? '');
    final String? targetSubjectName = args is Map
        ? args['subjectName'] as String?
        : null;
    final bool prioritizePlanner =
        args is Map && args['prioritizePlanner'] == true;

    Get.put(PaymentController());
    return GetBuilder<PaymentController>(
      builder: (controller) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildModernTopBar(
                  context,
                  targetSubjectName,
                  prioritizePlanner: prioritizePlanner,
                ),
                Expanded(
                  child: _buildPackageSelection(
                    context,
                    controller,
                    targetSubjectId: targetSubjectId,
                    targetSubjectName: targetSubjectName,
                    prioritizePlanner: prioritizePlanner,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTopBar(
    BuildContext context,
    String? targetSubjectName, {
    bool prioritizePlanner = false,
  }) {
    final title = prioritizePlanner
        ? 'Unlock Planner'
        : targetSubjectName == null || targetSubjectName.isEmpty
            ? 'Choose Package'
            : 'Unlock $targetSubjectName';
    final subtitle = prioritizePlanner
        ? 'Select a planner package to continue'
        : targetSubjectName == null || targetSubjectName.isEmpty
            ? 'Select and pay for your subscription'
            : 'Pay once to unlock all chapters';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Modern Back Button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => safePop(context: context),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Title with Modern Typography
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),

          // Decorative Element
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSelection(
    BuildContext context,
    PaymentController controller,
    {int? targetSubjectId, String? targetSubjectName, bool prioritizePlanner = false}
  ) {
    if (controller.isLoading) {
      return _buildLoadingState();
    }

    List<Package> packagesToShow = controller.packages;
    if (targetSubjectId != null) {
      packagesToShow = _prioritizeTargetSubjectPackages(
        packagesToShow,
        targetSubjectId,
      );
    }
    if (prioritizePlanner) {
      packagesToShow = _plannerPackagesForUpgrade(packagesToShow);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Available Packages
          // Text(
          //   targetSubjectName == null || targetSubjectName.isEmpty
          //       ? 'Available Packages'
          //       : 'Recommended for $targetSubjectName',
          //   style: const TextStyle(
          //     fontSize: 22,
          //     fontWeight: FontWeight.w700,
          //     color: Colors.white,
          //   ),
          // ),
          // if (targetSubjectId != null)
          //   Padding(
          //     padding: const EdgeInsets.only(top: 4),
          //     child: Text(
          //       'Showing $targetSubjectName first, then all other subjects/packages.',
          //       style: TextStyle(
          //         color: Colors.white.withValues(alpha: 0.85),
          //         fontSize: 13,
          //         fontWeight: FontWeight.w500,
          //       ),
          //     ),
          //   ),
          // const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildReferralCodeSection(
                  controller: controller,
                  textController: controller.referralTextController,
                ),
                if (controller.referralValidationStatus ==
                    ReferralValidationStatus.valid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '10% off applies to all packages below',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: packagesToShow.isEmpty && prioritizePlanner
                ? _buildPlannerPackagesEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: packagesToShow.length,
                    itemBuilder: (context, index) {
                      final package = packagesToShow[index];
                      return _buildModernPackageCard(
                        context,
                        package,
                        controller,
                        index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Package> _prioritizeTargetSubjectPackages(
    List<Package> packages,
    int targetSubjectId,
  ) {
    final targetPackages = packages
        .where((package) => package.subjects.contains(targetSubjectId))
        .toList();
    final otherPackages = packages
        .where((package) => !package.subjects.contains(targetSubjectId))
        .toList();

    return [...targetPackages, ...otherPackages];
  }

  List<Package> _plannerPackagesForUpgrade(List<Package> packages) {
    final plannerPackages =
        packages.where((package) => package.includesPlanner).toList();
    plannerPackages.sort((a, b) {
      final aPlannerOnly = a.subjects.isEmpty;
      final bPlannerOnly = b.subjects.isEmpty;
      if (aPlannerOnly == bPlannerOnly) return 0;
      return aPlannerOnly ? -1 : 1;
    });
    return plannerPackages;
  }

  Widget _buildPlannerPackagesEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          'No planner packages are available for your grade yet. '
          'Please try again later.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading packages...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernPackageCard(
    BuildContext context,
    Package package,
    PaymentController controller,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: package.isLocked
                      ? () => _navigateToPaymentMethod(package, controller)
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Package Header
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: package.isLocked
                                      ? [
                                          const Color(0xFF0F766E),
                                          const Color(0xFF0D9488),
                                        ]
                                      : [
                                          Colors.green.shade400,
                                          Colors.green.shade600,
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                package.isLocked
                                    ? Icons.star_rounded
                                    : Icons.check_circle,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    package.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    package.description,

                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (package.includesPlanner) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F766E)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Includes Planner',
                                        style: TextStyle(
                                          color: Color(0xFF0F766E),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (!package.isLocked)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'PAID',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Package Features
                        if (package.subjects.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Includes:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._getPackageSubjects(package)
                                  .take(3)
                                  .map(
                                    (subject) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade500,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            subject.name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (package.subjects.length > 3)
                                Text(
                                  '+ ${package.subjects.length - 3} more subjects',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),

                        const SizedBox(height: 20),

                        // Price and Action
                        Row(
                          children: [
                            Expanded(
                              child: buildPackagePriceLabel(
                                package: package,
                                controller: controller,
                                showPerYear: true,
                              ),
                            ),
                            if (package.isLocked)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0F766E),
                                      Color(0xFF0D9488),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _navigateToPaymentMethod(
                                      package,
                                      controller,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Subscribe',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToPaymentMethod(Package package, PaymentController controller) {
    controller.beginCheckout(package);
    Get.to(() => _PaymentMethodPage(package: package, controller: controller));
  }
}

class _PaymentMethodPage extends StatefulWidget {
  final Package package;
  final PaymentController controller;

  const _PaymentMethodPage({required this.package, required this.controller});

  @override
  State<_PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<_PaymentMethodPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safePop(context: context),
          mouseCursor: SystemMouseCursors.click,
        ),
        title: const Text('Payment Method'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: GetBuilder<PaymentController>(
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Package Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.package.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          buildPackagePriceLabel(
                            package: widget.package,
                            controller: controller,
                            priceStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            showPerYear: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Payment Methods
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: RadioGroup<PaymentMethod>(
                  groupValue: controller.selectedPaymentMethod,
                  onChanged: (value) {
                    if (value != null) {
                      controller.changeSelectedPaymentMethod(value);
                    }
                  },
                  child: ListView.builder(
                    itemCount: controller.paymentMethods.length,
                    itemBuilder: (context, index) {
                      final method = controller.paymentMethods[index];
                      final isSelected =
                          controller.selectedPaymentMethod?.id == method.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.shade600
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Radio<PaymentMethod>(
                            value: method,
                            activeColor: Colors.blue.shade600,
                          ),
                          title: Text(method.bankName),
                          subtitle: Text(
                            '${method.accountName} - ${method.accountNumber}',
                          ),
                          onTap: () {
                            controller.changeSelectedPaymentMethod(method);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: controller.selectedPaymentMethod != null
                      ? () => _navigateToReceiptUpload()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReceiptUpload() {
    Get.to(
      () => _ReceiptUploadPage(
        package: widget.package,
        controller: widget.controller,
      ),
    );
  }
}

class _ReceiptUploadPage extends StatefulWidget {
  final Package package;
  final PaymentController controller;

  const _ReceiptUploadPage({required this.package, required this.controller});

  @override
  State<_ReceiptUploadPage> createState() => _ReceiptUploadPageState();
}

class _ReceiptUploadPageState extends State<_ReceiptUploadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safePop(context: context),
          mouseCursor: SystemMouseCursors.click,
        ),
        title: const Text('Upload Receipt'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: GetBuilder<PaymentController>(
        builder: (controller) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Package Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.package.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              buildPackagePriceLabel(
                                package: widget.package,
                                controller: controller,
                                priceStyle: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                showPerYear: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Payment Method: ${controller.selectedPaymentMethod?.bankName ?? 'Not selected'}',
                              style: TextStyle(color: Colors.grey.shade700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upload Receipt Section
              const Text(
                'Upload Payment Receipt',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Please upload a clear photo of your payment receipt',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // Receipt Upload Area
              GestureDetector(
                onTap: () => _pickReceiptImage(),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.selectedReceiptImage != null
                          ? Colors.green.shade400
                          : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                    color: controller.selectedReceiptImage != null
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                  ),
                  child: controller.selectedReceiptImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                controller.selectedReceiptImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                color: Colors.grey,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Tap to upload receipt',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'JPG, PNG or PDF files',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // buildReferralCodeSection(
              //   controller: controller,
              //   textController: controller.referralTextController,
              // ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      controller.selectedReceiptImage != null &&
                          !controller.isCreatingPayment
                      ? () => _submitPayment()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isCreatingPayment
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Processing...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Submit Payment'),
                            SizedBox(width: 8),
                            Icon(Icons.send, size: 18),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final controller = widget.controller;
    final picker = ImagePicker();

    final image = await ImagePickerPermissions.pickImage(
      picker: picker,
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      controller.selectedReceiptImage = File(image.path);
      controller.update();
    }
  }

  void _submitPayment() async {
    final controller = widget.controller;
    await controller.createPayment(
      widget.package.id,
      referralCode: controller.referralCode,
    );
  }
}
