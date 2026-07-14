import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/on_boarding/verify_phone_controller.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/flavors/flavor_config.dart';

class VerifyPhone extends StatelessWidget {
  const VerifyPhone({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(VerifyPhoneController());
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackLeading(),
        title: Text('Verify Phone'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: GetBuilder<VerifyPhoneController>(
          builder: (controller) => Form(
            key: controller.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 50),
                  Image.asset(FlavorConfig.logoAsset),
                  SizedBox(height: 30),
                  Text(
                    'Enter OTP',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'We sent a verification code to ${controller.phoneNumber}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  OTPTextField(controller: controller.otpController),
                  SizedBox(height: 20),
                  PrimaryButton(
                    text: 'Verify OTP',
                    onPressed: controller.verifyOTP,
                    isLoading: controller.isLoading,
                    icon: Icon(Icons.verified_user_outlined),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: controller.canResend
                            ? () => controller.resendOTP()
                            : null,
                        child: Text(
                          controller.canResend
                              ? 'Resend'
                              : 'Resend in ${controller.resendTimer}s',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: controller.canResend
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
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
    );
  }
}
