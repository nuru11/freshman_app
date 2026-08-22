import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vector_academy/models/reading_premium.dart';
import 'package:vector_academy/services/api/exceptions.dart';
import 'package:vector_academy/services/api/reading_plan.dart';
import 'package:vector_academy/services/auth.dart';
import 'package:vector_academy/utils/snackbar_utils.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/views/views.dart';

class ReadingPlanController extends GetxController {
  final ReadingPlanService _service = Get.find<ReadingPlanService>();

  bool isLoading = false;
  List<ReadingPlanDocument> documents = [];
  String telegramHandle = '';
  bool savingTelegram = false;
  late final TextEditingController telegramController;

  @override
  void onInit() {
    super.onInit();
    telegramHandle =
        Get.find<AuthService>().user.value?.telegramHandle ?? '';
    telegramController = TextEditingController(text: telegramHandle);
    load();
  }

  @override
  void onClose() {
    telegramController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading = true;
    update();
    try {
      documents = await _service.listDocuments();
    } catch (e) {
      logger.e('Failed to load reading plans: $e');
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to load reading plans',
      );
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> saveTelegram() async {
    savingTelegram = true;
    update();
    try {
      final cleaned = telegramController.text.replaceAll('@', '').trim();
      final result = await _service.updateTelegramHandle(cleaned);
      telegramHandle = result.handle;
      final auth = Get.find<AuthService>();
      final user = auth.user.value;
      if (user != null) {
        await auth.saveUser(user.copyWith(telegramHandle: telegramHandle));
      }
      AppSnackbar.showSuccess('Saved', 'Admin can now find you on Telegram');
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to save Telegram',
      );
    } finally {
      savingTelegram = false;
      update();
    }
  }

  Future<void> openDocument(ReadingPlanDocument doc) async {
    try {
      AppSnackbar.showInfo('Opening', 'Preparing ${doc.title}');
      final path = await _service.downloadForReading(doc.id);
      Get.to(
        () => PDFReaderScreen(
          pdfUrl: path,
          pdfTitle: doc.title,
          pdfId: ReadingPlanService.cacheId(doc.id),
          protectContent: true,
        ),
      );
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Could not open the PDF',
      );
    }
  }

  Future<void> markRead(ReadingPlanDocument doc) async {
    try {
      final updated = await _service.markRead(doc.id);
      final index = documents.indexWhere((d) => d.id == doc.id);
      if (index != -1) {
        documents[index] = updated;
        update();
      }
    } catch (e) {
      AppSnackbar.showError(
        'Error',
        e is ApiException ? e.message : 'Failed to mark as read',
      );
    }
  }
}
