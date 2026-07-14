import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import '../../utils/utils.dart'; // Import logger

class PDFReaderController extends GetxController {
  // Observable properties
  final RxString _localPath = RxString('');
  final RxBool _isLoading = RxBool(true);
  final RxBool _isDownloading = RxBool(false);
  final RxInt _currentPage = RxInt(0);
  final RxInt _totalPages = RxInt(0);
  final RxBool _isReady = RxBool(false);
  final RxString _errorMessage = RxString('');
  final RxBool _isLandscape = RxBool(false);
  final RxBool _isReadMode = RxBool(false);
  final RxBool _showReadModeHint = RxBool(true);

  // PDF details
  late String pdfUrl;
  late String pdfTitle;
  late int pdfId;

  // PDF Controller
  PDFViewController? _pdfViewController;

  // Timer for hiding hint
  Timer? _hintTimer;

  // Getters
  String get localPath => _localPath.value;
  bool get isLoading => _isLoading.value;
  bool get isDownloading => _isDownloading.value;
  int get currentPage => _currentPage.value;
  int get totalPages => _totalPages.value;
  bool get isReady => _isReady.value;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _errorMessage.value.isNotEmpty;
  bool get hasLocalPath => _localPath.value.isNotEmpty;
  bool get isLandscape => _isLandscape.value;
  bool get isReadMode => _isReadMode.value;
  bool get showReadModeHint => _showReadModeHint.value;

  void initialize(String url, String title, int id) {
    logger.d('Initializing PDF Reader with URL: $url, Title: $title, ID: $id');
    pdfUrl = url;
    pdfTitle = title;
    pdfId = id;
    _setupOrientations();
    _initializePDF();
  }

  void _setupOrientations() {
    // Allow both portrait and landscape initially
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePDF() async {
    logger.d('Starting PDF initialization for URL: $pdfUrl');

    // Check if the URL is valid
    if (pdfUrl.isEmpty || pdfUrl.toLowerCase() == 'pdf') {
      _setError(
        'Invalid PDF URL: $pdfUrl. The content field contains only file type, not the actual URL.',
      );
      logger.e('Invalid PDF URL provided: $pdfUrl');
      return;
    }

    if (_isLocalFile(pdfUrl)) {
      logger.d('Handling as local file: $pdfUrl');
      _handleLocalFile();
    } else {
      logger.d('Handling as remote file, downloading: $pdfUrl');
      await _downloadPDF();
    }
  }

  bool _isLocalFile(String url) {
    final isLocal =
        url.startsWith('/') ||
        url.startsWith('file://') ||
        (url.contains(':') && !url.startsWith('http'));
    logger.d('URL $url is local file: $isLocal');
    return isLocal;
  }

  void _handleLocalFile() {
    try {
      _setLoading(true);
      _clearError();

      String filePath = pdfUrl;
      logger.d('Processing local file path: $filePath');

      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7); // Remove 'file://' prefix
        logger.d('Cleaned file path: $filePath');
      }

      final file = File(filePath);
      logger.d('Checking if file exists: ${file.path}');

      if (file.existsSync()) {
        logger.d('File exists, setting local path: $filePath');
        _localPath.value = filePath;
        _setLoading(false);
      } else {
        final errorMsg = 'Local file not found: $filePath';
        logger.e(errorMsg);
        _setLoading(false);
        _setError(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Failed to load local file: $e';
      logger.e(errorMsg);
      _setLoading(false);
      _setError(errorMsg);
    }
  }

  Future<void> _downloadPDF() async {
    try {
      logger.d('Starting PDF download from: $pdfUrl');
      _isDownloading.value = true;
      _clearError();

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${pdfId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      logger.d('Downloading to: $filePath');

      await dio.download(pdfUrl, filePath);

      // Verify the downloaded file exists and has content
      final file = File(filePath);
      if (file.existsSync()) {
        final fileSize = await file.length();
        logger.d('Download completed. File size: $fileSize bytes');

        if (fileSize > 0) {
          _localPath.value = filePath;
          _isDownloading.value = false;
          _setLoading(false);
        } else {
          throw Exception('Downloaded file is empty');
        }
      } else {
        throw Exception('Downloaded file does not exist');
      }
    } catch (e) {
      final errorMsg = 'Failed to download PDF: $e';
      logger.e(errorMsg);
      _isDownloading.value = false;
      _setLoading(false);
      _setError(errorMsg);
    }
  }

  void onPageChanged(int? page, int? total) {
    logger.d('Page changed - Page: $page, Total: $total');
    if (page != null) _currentPage.value = page;
    if (total != null) _totalPages.value = total;
  }

  void onViewCreated(PDFViewController controller) {
    logger.d('PDF View created');
    _pdfViewController = controller;
    _isReady.value = true;
  }

  void onRender(int? pages) {
    logger.d('PDF rendered with pages: $pages');
    if (pages != null) _totalPages.value = pages;
  }

  void onError(dynamic error) {
    final errorMsg = 'Failed to load PDF: $error';
    logger.e(errorMsg);
    _setError(errorMsg);
  }

  Future<void> goToPreviousPage() async {
    if (_pdfViewController != null && _currentPage.value > 0) {
      await _pdfViewController!.setPage(_currentPage.value - 1);
    }
  }

  Future<void> goToNextPage() async {
    if (_pdfViewController != null &&
        _currentPage.value < _totalPages.value - 1) {
      await _pdfViewController!.setPage(_currentPage.value + 1);
    }
  }

  Future<void> goToPage(int page) async {
    if (_pdfViewController != null && page >= 0 && page < _totalPages.value) {
      await _pdfViewController!.setPage(page);
    }
  }

  void sharePDF() {
    // TODO: Implement PDF sharing
    Get.snackbar('Info', 'Share functionality will be implemented');
  }

  Future<void> retryInitialization() async {
    logger.d('Retrying PDF initialization');
    _clearError();
    await _initializePDF();
  }

  void _setLoading(bool loading) {
    logger.d('Setting loading state: $loading');
    _isLoading.value = loading;
  }

  void _setError(String error) {
    logger.e('Setting error: $error');
    _errorMessage.value = error;
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void toggleOrientation() {
    _isLandscape.value = !_isLandscape.value;

    if (_isLandscape.value) {
      // Switch to landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Switch to portrait
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    logger.d(
      'Orientation toggled to: ${_isLandscape.value ? "landscape" : "portrait"}',
    );
  }

  void toggleReadMode() {
    _isReadMode.value = !_isReadMode.value;

    if (_isReadMode.value) {
      // Hide system UI in read mode for immersive experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Show hint initially
      _showReadModeHint.value = true;
      // Hide hint after 3 seconds
      _hintTimer?.cancel();
      _hintTimer = Timer(Duration(seconds: 3), () {
        _showReadModeHint.value = false;
      });
    } else {
      // Show system UI when exiting read mode
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _hintTimer?.cancel();
    }

    logger.d('Read mode: ${_isReadMode.value ? "enabled" : "disabled"}');
  }

  @override
  void onClose() {
    logger.d('Closing PDF Reader Controller');
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hintTimer?.cancel();
    _pdfViewController = null;
    super.onClose();
  }
}
