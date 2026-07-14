import 'package:get/get.dart';
import 'package:vector_academy/services/services.dart';
import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/utils.dart';

class FAQController extends GetxController {
  final FAQApiService _faqApiService = FAQApiService();

  bool isLoading = false;
  List<FAQ> faqs = [];

  Future<void> loadFaq() async {
    try {
      isLoading = true;
      update();
      faqs = await _faqApiService.getFAQs();
      faqs.sort((a, b) => a.question.compareTo(b.question));
      faqs = faqs;
    } catch (e) {
      logger.e(e);
      Get.snackbar('Error', 'Failed to load FAQs');
    } finally {
      isLoading = false;
      update();
    }
  }

  @override
  void onInit() {
    loadFaq();
    super.onInit();
  }

  Future<List<FAQ>> searchFaq(String query) async {
    return faqs
        .where(
          (faq) => faq.question.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
