import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:vector_academy/services/note_file_cache.dart';
import 'dart:io';
import 'dart:async';
import '../../utils/utils.dart';

class PDFReaderController extends GetxController {
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
  final RxBool _isTextMode = RxBool(false);
  final RxBool _isSpeaking = RxBool(false);
  final RxBool _isListenPaused = RxBool(false);
  final RxDouble _speechRate = RxDouble(0.5);
  final RxList<String> _pageTexts = <String>[].obs;
  final RxString _announcement = RxString('');
  final RxBool _isExtractingText = RxBool(false);

  late String pdfUrl;
  late String pdfTitle;
  late int pdfId;
  String? certificateNumber;
  bool protectContent = false;
  bool enableListen = false;

  PDFViewController? _pdfViewController;
  Timer? _hintTimer;
  final FlutterTts _tts = FlutterTts();
  bool _closed = false;
  int? _sessionId;
  String? _sessionUrl;
  bool _listenSessionActive = false;
  bool _restartingSpeech = false;
  PdfDocument? _listenDocument;
  PdfTextExtractor? _extractor;
  Future<void> _extractChain = Future.value();
  final List<bool> _pageExtracted = [];
  bool _remainingQueued = false;

  static const List<double> _speechRates = [0.35, 0.5, 0.7];
  static const List<String> _speechRateLabels = ['Slow', 'Normal', 'Fast'];

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
  bool get isTextMode => _isTextMode.value;
  bool get isSpeaking => _isSpeaking.value;
  bool get isListenPaused => _isListenPaused.value;
  double get speechRate => _speechRate.value;
  String get announcement => _announcement.value;
  bool get isExtractingText => _isExtractingText.value;
  String get speechRateLabel {
    final index = _speechRates.indexOf(_speechRate.value);
    if (index < 0) return 'Normal';
    return _speechRateLabels[index];
  }

  String get currentPageText {
    if (_currentPage.value < 0 || _currentPage.value >= _pageTexts.length) {
      return '';
    }
    return _pageTexts[_currentPage.value];
  }

  bool get currentPageHasText => currentPageText.trim().isNotEmpty;

  bool get currentPageTextReady {
    final i = _currentPage.value;
    return i >= 0 && i < _pageExtracted.length && _pageExtracted[i];
  }

  String get pageStatusLabel {
    if (totalPages <= 0) return pdfTitle;
    return '$pdfTitle, PDF, page ${currentPage + 1} of $totalPages. Play to listen';
  }

  void initialize(
    String url,
    String title,
    int id, {
    String? certificateNumber,
    bool protectContent = false,
    bool enableListen = false,
  }) {
    if (_sessionId == id && _sessionUrl == url && hasLocalPath && !hasError) {
      this.protectContent = protectContent;
      this.enableListen = enableListen;
      return;
    }

    logger.d('Initializing PDF Reader with title: $title, ID: $id');
    pdfUrl = url;
    pdfTitle = title;
    pdfId = id;
    this.certificateNumber = certificateNumber;
    this.protectContent = protectContent;
    this.enableListen = enableListen;
    _sessionId = id;
    _sessionUrl = url;
    _currentPage.value = 0;
    _totalPages.value = 0;
    _isReady.value = false;
    _pageTexts.clear();
    _pageExtracted.clear();
    _remainingQueued = false;
    _extractChain = Future.value();
    _disposeListenDocument();
    _isExtractingText.value = false;
    _isTextMode.value = false;
    _stopListenInternal();
    _setupOrientations();
    _configureTts();
    _applyScreenProtection();
    _initializePDF();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setSpeechRate(_speechRate.value);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        if (_closed || !_listenSessionActive || _restartingSpeech) return;
        _advanceAfterPageSpoken();
      });
      _tts.setCancelHandler(() {
        if (_closed || _restartingSpeech) return;
        if (!_isListenPaused.value) {
          _isSpeaking.value = false;
          _listenSessionActive = false;
        }
      });
    } catch (e) {
      logger.e('Failed to configure TTS: $e');
    }
  }

  Future<void> _applyScreenProtection() async {
    if (!protectContent) return;
    try {
      await ScreenProtector.protectDataLeakageOn();
    } catch (e) {
      logger.w('Could not enable screen protection: $e');
    }
  }

  Future<void> _clearScreenProtection() async {
    if (!protectContent) return;
    try {
      await ScreenProtector.protectDataLeakageOff();
    } catch (e) {
      logger.w('Could not disable screen protection: $e');
    }
  }

  void _setupOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _initializePDF() async {
    logger.d('Starting PDF initialization');

    if (pdfUrl.isEmpty || pdfUrl.toLowerCase() == 'pdf') {
      logger.e('Invalid PDF URL provided');
      _setError('This PDF could not be opened. Please try again.');
      return;
    }

    if (_isLocalFile(pdfUrl)) {
      await _handleLocalFile();
    } else {
      if (protectContent) {
        _setError('This PDF could not be opened. Please try again.');
        return;
      }
      await _downloadPDF();
    }
  }

  bool _isLocalFile(String url) {
    return url.startsWith('/') ||
        url.startsWith('file://') ||
        (url.contains(':') && !url.startsWith('http'));
  }

  Future<void> _handleLocalFile() async {
    try {
      _setLoading(true);
      _clearError();

      String filePath = pdfUrl;
      if (filePath.startsWith('file://')) {
        filePath = filePath.substring(7);
      }

      if (protectContent) {
        filePath = await NoteFileCache.instance.prepareViewFile(
          pdfId,
          storedPath: filePath,
        );
        if (_closed) return;
      }

      final file = File(filePath);
      if (file.existsSync()) {
        _localPath.value = filePath;
        _setLoading(false);
        _announce('Opening $pdfTitle');
      } else {
        logger.e('Local PDF file not found');
        _setLoading(false);
        _setError('This PDF could not be opened. Please try again.');
      }
    } catch (e) {
      logger.e('Failed to load local file: $e');
      _setLoading(false);
      _setError('This PDF could not be opened. Please try again.');
    }
  }

  Future<void> _downloadPDF() async {
    try {
      _isDownloading.value = true;
      _clearError();
      _announce('Opening PDF');

      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = '${pdfId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      await dio.download(pdfUrl, filePath);

      final file = File(filePath);
      if (file.existsSync()) {
        final fileSize = await file.length();
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
      logger.e('Failed to download PDF: $e');
      _isDownloading.value = false;
      _setLoading(false);
      _setError('This PDF could not be opened. Please try again.');
    }
  }

  void _disposeListenDocument() {
    try {
      _listenDocument?.dispose();
    } catch (_) {}
    _listenDocument = null;
    _extractor = null;
  }

  void _ensurePageTextCapacity() {
    final count = _totalPages.value;
    if (count <= 0) return;
    while (_pageTexts.length < count) {
      _pageTexts.add('');
    }
    while (_pageExtracted.length < count) {
      _pageExtracted.add(false);
    }
  }

  Future<void> _ensurePageText(int pageIndex) {
    final next = _extractChain.then((_) => _extractOnePage(pageIndex));
    _extractChain = next.catchError((e, _) {
      logger.e('PDF text extract queue failed: $e');
    });
    return next;
  }

  Future<void> _extractOnePage(int pageIndex) async {
    if (!enableListen || _closed || _localPath.value.isEmpty) {
      _isExtractingText.value = false;
      return;
    }

    final isCurrent = pageIndex == _currentPage.value;
    if (isCurrent) _isExtractingText.value = true;
    try {
      if (_listenDocument == null) {
        final bytes = await File(_localPath.value).readAsBytes();
        if (_closed) return;
        _listenDocument = PdfDocument(inputBytes: bytes);
        _extractor = PdfTextExtractor(_listenDocument!);
        final count = _listenDocument!.pages.count;
        if (_totalPages.value <= 0) {
          _totalPages.value = count;
        }
      }

      _ensurePageTextCapacity();
      if (pageIndex < 0 || pageIndex >= _pageTexts.length) return;
      if (_pageExtracted[pageIndex]) return;

      final text = _extractor!
          .extractText(startPageIndex: pageIndex, endPageIndex: pageIndex)
          .trim();
      if (_closed) return;
      _pageTexts[pageIndex] = text;
      _pageExtracted[pageIndex] = true;
      _pageTexts.refresh();
    } catch (e) {
      logger.e('Failed to extract PDF text: $e');
      _ensurePageTextCapacity();
      if (pageIndex >= 0 && pageIndex < _pageExtracted.length) {
        _pageExtracted[pageIndex] = true;
        _pageTexts.refresh();
      }
    } finally {
      if (isCurrent) _isExtractingText.value = false;
    }
  }

  void _extractRemainingPagesInBackground() {
    if (_remainingQueued || !enableListen) return;
    _remainingQueued = true;
    _extractChain = _extractChain.then((_) async {
      final count = _pageExtracted.isNotEmpty
          ? _pageExtracted.length
          : _totalPages.value;
      for (var i = 0; i < count; i++) {
        if (_closed) return;
        await _extractOnePage(i);
        await Future<void>.delayed(Duration.zero);
      }
      _disposeListenDocument();
    }).catchError((e, _) {
      logger.e('Background PDF text extract failed: $e');
    });
  }

  void _announce(String message) {
    _announcement.value = message;
  }

  void onPageChanged(int? page, int? total) {
    if (page != null) _currentPage.value = page;
    if (total != null) {
      _totalPages.value = total;
      _ensurePageTextCapacity();
    }
    if (isReady && totalPages > 0) {
      _announce('Page ${currentPage + 1} of $totalPages');
    }
    if (enableListen && _isTextMode.value) {
      if (!currentPageTextReady) _isExtractingText.value = true;
      _ensurePageText(_currentPage.value);
    }
  }

  void onViewCreated(PDFViewController controller) {
    _pdfViewController = controller;
    _isReady.value = true;
    if (totalPages > 0) {
      _announce(pageStatusLabel);
    }
  }

  void onRender(int? pages) {
    if (pages != null) {
      _totalPages.value = pages;
      _ensurePageTextCapacity();
    }
    if (isReady && totalPages > 0) {
      _announce(pageStatusLabel);
    }
  }

  void onError(dynamic error) {
    logger.e('Failed to load PDF: $error');
    _setError('This PDF could not be opened. Please try again.');
  }

  Future<void> goToPreviousPage() async {
    if (_pdfViewController != null && _currentPage.value > 0) {
      final previous = _currentPage.value - 1;
      await _pdfViewController!.setPage(previous);
      _currentPage.value = previous;
      if (_isSpeaking.value || _listenSessionActive) {
        await speakCurrentPage();
      }
    }
  }

  Future<void> goToNextPage() async {
    if (_pdfViewController != null &&
        _currentPage.value < _totalPages.value - 1) {
      final next = _currentPage.value + 1;
      await _pdfViewController!.setPage(next);
      _currentPage.value = next;
      if (_isSpeaking.value || _listenSessionActive) {
        await speakCurrentPage();
      }
    }
  }

  Future<void> goToPage(int page) async {
    if (_pdfViewController != null && page >= 0 && page < _totalPages.value) {
      await _pdfViewController!.setPage(page);
    }
  }

  Future<void> toggleTextMode() async {
    _isTextMode.value = !_isTextMode.value;
    _announce(_isTextMode.value ? 'Text mode on' : 'Text mode off');
    if (_isTextMode.value) {
      if (!currentPageTextReady) _isExtractingText.value = true;
      await _ensurePageText(_currentPage.value);
      _extractRemainingPagesInBackground();
    }
  }

  Future<void> toggleListen() async {
    if (_isSpeaking.value && !_isListenPaused.value) {
      await pauseListen();
    } else {
      await speakCurrentPage();
    }
  }

  Future<void> speakCurrentPage() async {
    if (!enableListen) return;
    if (!currentPageTextReady) _isExtractingText.value = true;
    await _ensurePageText(_currentPage.value);
    _extractRemainingPagesInBackground();
    if (_closed) return;
    final text = currentPageText.trim();
    _listenSessionActive = true;
    _isListenPaused.value = false;
    _isSpeaking.value = true;
    try {
      _restartingSpeech = true;
      await _tts.stop();
      await _tts.setSpeechRate(_speechRate.value);
      _restartingSpeech = false;
      if (text.isEmpty) {
        await _tts.speak('This page has no readable text');
      } else {
        await _tts.speak(text);
      }
    } catch (e) {
      logger.e('TTS failed: $e');
      _restartingSpeech = false;
      _isSpeaking.value = false;
      _listenSessionActive = false;
    }
  }

  Future<void> pauseListen() async {
    _isListenPaused.value = true;
    _listenSessionActive = false;
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking.value = false;
    _announce('Paused');
  }

  Future<void> stopListen() async {
    await _stopListenInternal();
    _announce('Stopped');
  }

  Future<void> _stopListenInternal() async {
    _listenSessionActive = false;
    _isListenPaused.value = false;
    _isSpeaking.value = false;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> _advanceAfterPageSpoken() async {
    if (_closed || !_listenSessionActive) {
      _isSpeaking.value = false;
      return;
    }
    if (_currentPage.value < _totalPages.value - 1) {
      await goToNextPage();
    } else {
      _isSpeaking.value = false;
      _listenSessionActive = false;
      _announce('End of note');
    }
  }

  void cycleSpeechRate() {
    final index = _speechRates.indexOf(_speechRate.value);
    final next = (index + 1) % _speechRates.length;
    _speechRate.value = _speechRates[next];
    _announce('Speed $speechRateLabel');
    if (_isSpeaking.value) {
      speakCurrentPage();
    }
  }

  void showDownloadOptions(BuildContext context) {
    if (protectContent) return;
    if (!hasLocalPath || !isReady) {
      AppSnackbar.showError('Error', 'Certificate is not ready to download yet.');
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Download as PDF'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      downloadAsPdf(context);
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Download as Image'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      downloadAsImage(context);
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _safeFileName(String base, String ext) {
    final safeBase = base.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final name = safeBase.isEmpty ? 'zemen_certificate' : safeBase.replaceAll(' ', '_');
    return '$name.$ext';
  }

  Future<T> _withLoadingDialog<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    if (!context.mounted) {
      return action();
    }

    BuildContext? dialogContext;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        dialogContext = ctx;
        return const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );

    await Future<void>.delayed(Duration.zero);

    try {
      return await action();
    } finally {
      final loaderContext = dialogContext;
      if (loaderContext != null && loaderContext.mounted) {
        Navigator.of(loaderContext).pop();
      }
    }
  }

  Future<void> _presentFileToUser(File file, String displayName) async {
    await Share.shareXFiles(
      [XFile(file.path, name: displayName)],
      text: 'Zemen Academy Certificate — $pdfTitle',
    );
  }

  Future<File> _downloadCertificateImageFile(String certNumber) async {
    final imageUrl =
        '$defaultApiURL/app/certificates/verify/${Uri.encodeComponent(certNumber)}/image/';
    final tempDir = await getTemporaryDirectory();
    final fileName = _safeFileName(pdfTitle, 'png');
    final filePath = '${tempDir.path}/$fileName';

    final dio = Dio();
    await dio.download(
      imageUrl,
      filePath,
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    final file = File(filePath);
    if (!file.existsSync() || await file.length() == 0) {
      throw Exception('Downloaded image is empty');
    }
    return file;
  }

  Future<void> downloadAsPdf(BuildContext context) async {
    if (protectContent) return;
    if (!hasLocalPath) {
      AppSnackbar.showError('Error', 'Certificate is not ready to download yet.');
      return;
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      AppSnackbar.showError('Error', 'Certificate file not found.');
      return;
    }

    try {
      final fileName = _safeFileName(pdfTitle, 'pdf');
      await _presentFileToUser(file, fileName);
      AppSnackbar.showSuccess(
        'Ready',
        'Choose an app to save or share your certificate PDF',
      );
    } catch (e) {
      logger.e('Failed to download PDF: $e');
      AppSnackbar.showError('Download failed', e.toString());
    }
  }

  Future<void> downloadAsImage(BuildContext context) async {
    if (protectContent) return;
    final certNumber = certificateNumber?.trim();
    if (certNumber == null || certNumber.isEmpty) {
      AppSnackbar.showError('Error', 'Certificate ID not available.');
      return;
    }

    try {
      final file = await _withLoadingDialog(
        context,
        () => _downloadCertificateImageFile(certNumber),
      );
      final fileName = _safeFileName(pdfTitle, 'png');
      await _presentFileToUser(file, fileName);
      AppSnackbar.showSuccess(
        'Ready',
        'Choose an app to save or share your certificate image',
      );
    } catch (e) {
      logger.e('Failed to download image: $e');
      AppSnackbar.showError('Download failed', e.toString());
    }
  }

  void sharePDF() async {
    if (protectContent) return;
    if (!hasLocalPath) {
      AppSnackbar.showError('Error', 'Certificate is not ready to share yet.');
      return;
    }

    final file = File(localPath);
    if (!file.existsSync()) {
      AppSnackbar.showError('Error', 'Certificate file not found.');
      return;
    }

    try {
      final safeName = pdfTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final fileName = safeName.isEmpty
          ? 'zemen_certificate.pdf'
          : '${safeName.replaceAll(' ', '_')}.pdf';

      await Share.shareXFiles(
        [XFile(localPath, name: fileName)],
        text: 'Zemen Academy Certificate — $pdfTitle',
      );
    } catch (e) {
      logger.e('Failed to share PDF: $e');
      AppSnackbar.showError('Share failed', e.toString());
    }
  }

  Future<void> retryInitialization() async {
    _sessionId = null;
    _sessionUrl = null;
    _clearError();
    await _initializePDF();
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  void _setError(String error) {
    _errorMessage.value = error;
    _announce(error);
  }

  void _clearError() {
    _errorMessage.value = '';
  }

  void toggleOrientation() {
    _isLandscape.value = !_isLandscape.value;

    if (_isLandscape.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void toggleReadMode() {
    _isReadMode.value = !_isReadMode.value;

    if (_isReadMode.value) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _showReadModeHint.value = true;
      _hintTimer?.cancel();
      _hintTimer = Timer(Duration(seconds: 3), () {
        _showReadModeHint.value = false;
      });
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _hintTimer?.cancel();
    }
  }

  @override
  void onClose() {
    _closed = true;
    _stopListenInternal();
    _tts.stop();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _hintTimer?.cancel();
    _pdfViewController = null;
    _disposeListenDocument();
    _clearScreenProtection();
    if (protectContent) {
      NoteFileCache.instance.deleteViewFile(pdfId);
    }
    super.onClose();
  }
}
