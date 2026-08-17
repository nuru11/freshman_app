import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:vector_academy/views/home/home.dart';
import 'package:vector_academy/views/views.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:get/get.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/components/components.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/flavors/flavor_config.dart';

void main() async {
  // Remove debug banner
  WidgetsFlutterBinding.ensureInitialized();
  await _registerAndroidVideoBackend();
  await initialize();

  try {
    final appBranding = await AppBrandingService().getAppBranding(
      backendAppPackage,
    );
    applyDynamicPalette(appBranding);
  } catch (e) {
    logger.w('Failed to fetch app branding, using defaults: $e');
  }

  // Initialize deep link service
  DeepLinkService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final service = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: FlavorConfig.appTitle,
      theme: lightTheme(context),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(builder: (_) => child ?? const SizedBox.shrink()),
          ],
        );
      },
      getPages: [
        GetPage(
          name: VIEWS.login.path,
          page: () => Login(),
          bindings: [
            BindingsBuilder(() {
              Get.put(LoginController(), permanent: true);
            }),
            BindingsBuilder(() {
              Get.lazyPut(() => MainNavigationController());
            }),
          ],
        ),
        GetPage(
          name: VIEWS.home.path,
          page: () => const Home(),
          binding: BindingsBuilder(() {
            Get.put(MainNavigationController(), permanent: true);
            Get.put(HomeDashboardController(), permanent: true);
            Get.put(ProfileController(), permanent: true);
            Get.put(ExamController(), permanent: true);
            Get.put(NewsController(), permanent: true);
            Get.put(DownloadsController(), permanent: true);
            Get.put(StudyPlannerService(), permanent: true);
            Get.put(StudyPlannerController(), permanent: true);
          }),
        ),
        GetPage(
          name: VIEWS.register.path,
          page: () => Register(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => RegisterController());
          }),
        ),
        GetPage(name: VIEWS.verifyPhone.path, page: () => VerifyPhone()),
        GetPage(name: VIEWS.payments.path, page: () => PaymentPage()),
        GetPage(
          name: VIEWS.paymentHistory.path,
          page: () => PaymentHistoryScreen(),
        ),
        GetPage(name: VIEWS.subjectDetail.path, page: () => SubjectDetail()),
        GetPage(name: VIEWS.chapterDetail.path, page: () => ChapterDetail()),
        GetPage(name: VIEWS.editProfile.path, page: () => EditProfilePage()),
        GetPage(name: VIEWS.subjects.path, page: () => SubjectPage()),
        GetPage(name: VIEWS.downloads.path, page: () => DownloadsPage()),
        GetPage(name: VIEWS.support.path, page: () => SupportPage()),
        GetPage(name: VIEWS.about.path, page: () => AboutPage()),
        GetPage(
          name: VIEWS.newsDetail.path,
          page: () {
            return NewsDetailPage();
          },
        ),
        GetPage(
          name: VIEWS.faq.path,
          page: () => FAQPage(),
          binding: BindingsBuilder(() {
            Get.put(FAQController());
          }),
        ),
        GetPage(
          name: VIEWS.successStories.path,
          page: () => SuccessStoriesPage(),
          binding: BindingsBuilder(() {
            Get.put(SuccessStoriesController());
          }),
        ),
        GetPage(
          name: VIEWS.successStoryDetail.path,
          page: () {
            final args = Get.arguments;
            if (args is SuccessStory) {
              return SuccessStoryDetailPage(story: args);
            }
            final params = Get.parameters;
            if (params['id'] != null) {
              final id = int.tryParse(params['id']!);
              if (id != null) {
                return SuccessStoryDetailPage(storyId: id);
              }
            }
            return SuccessStoryDetailPage();
          },
        ),
        GetPage(
          name: VIEWS.userScore.path,
          page: () => const UserScorePage(),
          binding: BindingsBuilder(() {
            Get.put(UserScoreController());
          }),
        ),
        GetPage(
          name: VIEWS.agentApply.path,
          page: () => const AgentApplyPage(),
          binding: BindingsBuilder(() {
            Get.put(AgentController());
          }),
        ),
        GetPage(
          name: VIEWS.agentStatus.path,
          page: () => const AgentStatusPage(),
          binding: BindingsBuilder(() {
            Get.put(AgentController());
          }),
        ),

        GetPage(
          name: '/add-plan',
          page: () => AddPlanPage(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => AddPlanController());
          }),
        ),
      ],
      initialRoute: service.isAuthenticated
          ? VIEWS.home.path
          : VIEWS.login.path,
    );
  }
}

Future<void> _registerAndroidVideoBackend() async {
  if (!Platform.isAndroid) return;

  try {
    final info = await DeviceInfoPlugin().androidInfo;
    final fingerprint = [
      info.manufacturer,
      info.brand,
      info.model,
      info.hardware,
      info.board,
      info.device,
    ].join(' ').toLowerCase();
    const lowEndMarkers = [
      'itel',
      'tecno',
      'infinix',
      'unisoc',
      'spreadtrum',
      'sc98',
      'sc83',
    ];
    final useSoftwareFirst =
        info.isLowRamDevice ||
        (info.physicalRamSize > 0 && info.physicalRamSize <= 3072) ||
        lowEndMarkers.any(fingerprint.contains);

    fvp.registerWith(
      options: {
        'platforms': ['android'],
        'video.decoders': useSoftwareFirst
            ? ['FFmpeg', 'AMediaCodec']
            : ['AMediaCodec', 'FFmpeg'],
      },
    );
    logger.d('Registered fvp video backend (softwareFirst=$useSoftwareFirst)');
  } catch (e) {
    fvp.registerWith(
      options: {
        'platforms': ['android'],
        'video.decoders': ['AMediaCodec', 'FFmpeg'],
      },
    );
    logger.w('Failed to detect device for video backend, using default: $e');
  }
}
