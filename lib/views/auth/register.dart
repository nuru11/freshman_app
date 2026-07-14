import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/on_boarding/register_controller.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/config/app_config.dart';
import 'package:vector_academy/flavors/flavor_config.dart';
import 'package:vector_academy/utils/navigation_utils.dart';

class Register extends StatelessWidget {
  const Register({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => safePop(context: context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      FlavorConfig.logoAsset,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Join ${FlavorConfig.appTitle}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Create your university student account',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: GetBuilder<RegisterController>(
                  builder: (controller) {
                    return Form(
                      key: controller.formKey,
                      autovalidateMode: AutovalidateMode.onUnfocus,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Create account',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tell us about your freshman program',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: controller.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: controller.selectedGrade?.name,
                            decoration: InputDecoration(
                              labelText: gradeLabel,
                              prefixIcon: const Icon(Icons.school_outlined),
                            ),
                            items: controller.gradeOptions.map((Grade grade) {
                              return DropdownMenuItem<String>(
                                value: grade.name,
                                child: Text(grade.name),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              controller.setSelectedGrade(
                                controller.gradeOptions.firstWhere(
                                  (grade) => grade.name == newValue,
                                ),
                              );
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '$gradeLabel is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                              prefixText: '0',
                            ),
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Phone Number is required';
                              }
                              if (value.length != 9) {
                                return 'Phone Number must be 9 digits';
                              }
                              final pattern = RegExp(r'^(7|9)\d{8}$');
                              if (pattern.hasMatch(value)) {
                                return null;
                              }
                              return 'Phone Number must start with 7 or 9';
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: controller.passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            ),
                            obscureText: !controller.isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              if (value.length < 4) {
                                return 'Password must be at least 4 characters';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: controller.confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isConfirmPasswordVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed:
                                    controller.toggleConfirmPasswordVisibility,
                              ),
                            ),
                            obscureText: !controller.isConfirmPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm Password is required';
                              }
                              if (value != controller.passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: controller.hasAcceptedPrivacyPolicy,
                                onChanged:
                                    controller.togglePrivacyPolicyAcceptance,
                                activeColor: primaryColor,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: RichText(
                                    text: TextSpan(
                                      style: theme.textTheme.bodySmall,
                                      children: [
                                        const TextSpan(
                                          text: 'I agree to the ',
                                        ),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: primaryColor,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap =
                                                () => PrivacyPolicyDialog.show(),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Terms',
                                          style: TextStyle(
                                            color: primaryColor,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () =>
                                                TermsAndConditionsDialog.show(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          PrimaryButton(
                            text: 'Create account',
                            onPressed: () => controller.register(),
                            isLoading: controller.isLoading,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
