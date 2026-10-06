import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vector_academy/services/api/app_version.dart';
import 'package:vector_academy/utils/utils.dart';

/// Checks the admin version policy once after the first frame.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  static bool _started = false;

  @override
  void initState() {
    super.initState();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showIfNeeded();
    });
  }

  Future<void> _showIfNeeded() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final decision = await AppVersionService().check(
        appPackage: backendAppPackage,
        platform: platform,
        version: info.version,
      );
      if (!mounted || decision == null) return;
      if (!decision.isRequired && !decision.isOptional) return;

      final title = decision.title.isNotEmpty
          ? decision.title
          : (decision.isRequired ? 'Update required' : 'Update available');
      final message = decision.message.isNotEmpty
          ? decision.message
          : (decision.isRequired
                ? 'This version is no longer supported. Please update to continue.'
                : 'A new version is available. You can update now or later.');

      await Get.dialog<void>(
        PopScope(
          canPop: !decision.isRequired,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              if (decision.isOptional)
                TextButton(
                  onPressed: Get.back,
                  child: const Text('Update later'),
                ),
              FilledButton(
                onPressed: () => _openStore(decision.storeUrl),
                child: const Text('Update'),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      logger.w('Failed to check app version: $e');
    }
  }

  Future<void> _openStore(String storeUrl) async {
    final uri = Uri.tryParse(storeUrl);
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
