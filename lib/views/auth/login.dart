import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/controllers/on_boarding/login_controller.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/flavors/flavor_config.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        children: [
          SizedBox(
            height: size.height * 0.34,
            width: double.infinity,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            FlavorConfig.logoAsset,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          FlavorConfig.appTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'University courses\nfor freshman year',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue your first-year studies.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: GetBuilder<LoginController>(
                  builder: (controller) => Form(
                    key: controller.formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your phone and password',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PhoneTextField(controller: controller.phoneController),
                        const SizedBox(height: 14),
                        PasswordTextField(
                          controller: controller.passwordController,
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: 'Sign in',
                          onPressed: () => controller.login(),
                          isLoading: controller.isLoading,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'New to Freshman?',
                              style: theme.textTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () =>
                                  Get.toNamed(VIEWS.register.path),
                              child: Text(
                                'Create account',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: secondaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(
                                text: 'By continuing you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap =
                                      () => TermsAndConditionsDialog.show(),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => PrivacyPolicyDialog.show(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
