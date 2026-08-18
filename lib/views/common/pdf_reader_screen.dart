import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:vector_academy/components/components.dart';
import '../../controllers/misc/pdf_reader_controller.dart';
import 'dart:io';

class PDFReaderScreen extends StatefulWidget {
  final String pdfUrl;
  final String pdfTitle;
  final int pdfId;
  final bool showShareButton;
  final String? certificateNumber;
  final bool protectContent;
  final bool enableListen;

  const PDFReaderScreen({
    super.key,
    required this.pdfUrl,
    required this.pdfTitle,
    required this.pdfId,
    this.showShareButton = false,
    this.certificateNumber,
    this.protectContent = false,
    this.enableListen = false,
  });

  @override
  State<PDFReaderScreen> createState() => _PDFReaderScreenState();
}

class _PDFReaderScreenState extends State<PDFReaderScreen> {
  late final PDFReaderController _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<PDFReaderController>()) {
      Get.delete<PDFReaderController>(force: true);
    }
    _controller = Get.put(PDFReaderController());
    _controller.initialize(
      widget.pdfUrl,
      widget.pdfTitle,
      widget.pdfId,
      certificateNumber: widget.certificateNumber,
      protectContent: widget.protectContent,
      enableListen: widget.enableListen,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<PDFReaderController>()) {
      Get.delete<PDFReaderController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      return Semantics(
        container: true,
        label: _controller.isReady
            ? _controller.pageStatusLabel
            : 'Opening ${widget.pdfTitle}',
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: _controller.isReadMode
              ? null
              : _buildAppBar(context, _controller, theme, widget.showShareButton),
          body: Column(
            children: [
              if (_controller.announcement.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  container: true,
                  label: _controller.announcement,
                  child: const SizedBox.shrink(),
                ),
              Expanded(child: _PDFReaderBody(controller: _controller)),
            ],
          ),
          bottomNavigationBar: _controller.isReadMode
              ? null
              : _PDFReaderBottomNavigation(
                  controller: _controller,
                  enableListen: widget.enableListen,
                ),
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PDFReaderController controller,
    ThemeData theme,
    bool showShareButton,
  ) {
    return AppBar(
      leading: const AppBackLeading(),
      title: Semantics(
        header: true,
        label: controller.pageStatusLabel,
        child: Text(
          widget.pdfTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      actions: [
        if (widget.enableListen)
          Obx(() {
            return IconButton(
              onPressed: controller.toggleTextMode,
              tooltip: controller.isTextMode
                  ? 'Show PDF pages'
                  : 'Show readable text',
              icon: Icon(
                controller.isTextMode
                    ? Icons.picture_as_pdf_outlined
                    : Icons.text_snippet_outlined,
                semanticLabel: controller.isTextMode
                    ? 'Show PDF pages'
                    : 'Show readable text',
              ),
            );
          }),
        if (showShareButton && !widget.protectContent)
          Obx(() {
            return IconButton(
              onPressed: controller.hasLocalPath && controller.isReady
                  ? () => controller.showDownloadOptions(context)
                  : null,
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Download certificate',
            );
          }),
        IconButton(
          onPressed: controller.toggleReadMode,
          icon: const Icon(
            Icons.lock_open,
            semanticLabel: 'Enter read mode',
          ),
          tooltip: 'Lock / Read Mode',
        ),
        Obx(() {
          return IconButton(
            onPressed: controller.toggleOrientation,
            icon: Icon(
              controller.isLandscape
                  ? Icons.stay_current_portrait
                  : Icons.stay_current_landscape,
              semanticLabel: controller.isLandscape
                  ? 'Switch to portrait'
                  : 'Switch to landscape',
            ),
            tooltip: controller.isLandscape
                ? 'Switch to Portrait'
                : 'Switch to Landscape',
          );
        }),
        Obx(() {
          if (controller.isReady && controller.totalPages > 0) {
            return Semantics(
              label:
                  'Page ${controller.currentPage + 1} of ${controller.totalPages}',
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${controller.currentPage + 1} / ${controller.totalPages}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return SizedBox.shrink();
        }),
      ],
    );
  }
}

class _PDFReaderBody extends StatelessWidget {
  final PDFReaderController controller;

  const _PDFReaderBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (controller.isLoading || controller.isDownloading) {
        return _LoadingView(controller: controller, theme: theme);
      }

      if (controller.hasError) {
        return _ErrorView(controller: controller, theme: theme);
      }

      if (!controller.hasLocalPath) {
        return _NoContentView(theme: theme);
      }

      if (controller.isTextMode) {
        return _TextModeView(controller: controller, theme: theme);
      }

      return _PDFView(controller: controller);
    });
  }
}

class _LoadingView extends StatelessWidget {
  final PDFReaderController controller;
  final ThemeData theme;

  const _LoadingView({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    final label = controller.isDownloading ? 'Opening PDF' : 'Loading PDF';
    return Semantics(
      liveRegion: true,
      label: label,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            SizedBox(height: 16),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final PDFReaderController controller;
  final ThemeData theme;

  const _ErrorView({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            SizedBox(height: 16),
            Text(
              'Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Semantics(
              button: true,
              label: 'Retry opening PDF',
              child: ElevatedButton.icon(
                onPressed: controller.retryInitialization,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoContentView extends StatelessWidget {
  final ThemeData theme;

  const _NoContentView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'PDF not available',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TextModeView extends StatelessWidget {
  final PDFReaderController controller;
  final ThemeData theme;

  const _TextModeView({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final text = controller.currentPageText.trim();
      final display = text.isEmpty
          ? 'This page has no readable text. Image-only PDFs cannot be read aloud.'
          : text;
      return Semantics(
        label: display,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            display,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ),
      );
    });
  }
}

class _PDFView extends StatelessWidget {
  final PDFReaderController controller;

  const _PDFView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.localPath.isEmpty) {
        return Center(child: Text('PDF not available'));
      }

      final file = File(controller.localPath);
      if (!file.existsSync()) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('PDF file not found'),
            ],
          ),
        );
      }

      final isLandscape = controller.isLandscape;
      final fitPolicy = isLandscape ? FitPolicy.WIDTH : FitPolicy.BOTH;

      return Stack(
        children: [
          ExcludeSemantics(
            child: GestureDetector(
              onTap: controller.isReadMode ? controller.toggleReadMode : null,
              child: PDFView(
                key: ValueKey('pdf_${isLandscape ? "landscape" : "portrait"}'),
                filePath: controller.localPath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                pageSnap: true,
                onRender: controller.onRender,
                onViewCreated: controller.onViewCreated,
                onPageChanged: controller.onPageChanged,
                onError: controller.onError,
                backgroundColor: Colors.white,
                defaultPage: controller.currentPage,
                fitPolicy: fitPolicy,
                preventLinkNavigation: true,
              ),
            ),
          ),
          if (controller.isReadMode)
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: controller.toggleReadMode,
                      tooltip: 'Unlock / Exit read mode',
                      icon: const Icon(
                        Icons.lock_open,
                        color: Colors.white,
                        semanticLabel: 'Exit read mode',
                      ),
                    ),
                  ),
                  if (controller.showReadModeHint) ...[
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      opacity: controller.showReadModeHint ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 500),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Tap to exit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _PDFReaderBottomNavigation extends StatelessWidget {
  final PDFReaderController controller;
  final bool enableListen;

  const _PDFReaderBottomNavigation({
    required this.controller,
    required this.enableListen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (!controller.isReady ||
          controller.totalPages == 0 ||
          controller.hasError) {
        return SizedBox.shrink();
      }

      return SafeArea(
        top: false,
        child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Semantics(
                  button: true,
                  label: 'Previous page',
                  child: IconButton(
                    onPressed: controller.currentPage > 0
                        ? controller.goToPreviousPage
                        : null,
                    tooltip: 'Previous page',
                    icon: Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: controller.currentPage.toDouble(),
                    max: (controller.totalPages - 1).toDouble(),
                    divisions: controller.totalPages > 1
                        ? controller.totalPages - 1
                        : null,
                    label:
                        'Page ${controller.currentPage + 1} of ${controller.totalPages}',
                    onChanged: (value) {
                      controller.goToPage(value.toInt());
                    },
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Next page',
                  child: IconButton(
                    onPressed:
                        controller.currentPage < controller.totalPages - 1
                        ? controller.goToNextPage
                        : null,
                    tooltip: 'Next page',
                    icon: Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ),
              ],
            ),
            if (enableListen) ...[
              SizedBox(height: 4),
              _ListenBar(controller: controller, theme: theme),
            ],
          ],
        ),
        ),
      );
    });
  }
}

class _ListenBar extends StatelessWidget {
  final PDFReaderController controller;
  final ThemeData theme;

  const _ListenBar({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final playing = controller.isSpeaking && !controller.isListenPaused;
      return Semantics(
        container: true,
        label: 'Listen controls',
        child: Column(
          children: [
            if (!controller.currentPageHasText && !controller.isExtractingText)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'This page has no readable text',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Semantics(
                  button: true,
                  label: playing ? 'Pause listening' : 'Play note',
                  child: IconButton(
                    onPressed: controller.toggleListen,
                    tooltip: playing ? 'Pause' : 'Play',
                    iconSize: 28,
                    icon: Icon(
                      playing ? Icons.pause_circle : Icons.play_circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Stop listening',
                  child: IconButton(
                    onPressed: controller.stopListen,
                    tooltip: 'Stop',
                    iconSize: 28,
                    icon: Icon(
                      Icons.stop_circle_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Previous page',
                  child: IconButton(
                    onPressed: controller.currentPage > 0
                        ? controller.goToPreviousPage
                        : null,
                    tooltip: 'Previous page',
                    iconSize: 28,
                    icon: const Icon(Icons.skip_previous),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Next page',
                  child: IconButton(
                    onPressed:
                        controller.currentPage < controller.totalPages - 1
                        ? controller.goToNextPage
                        : null,
                    tooltip: 'Next page',
                    iconSize: 28,
                    icon: const Icon(Icons.skip_next),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Speech speed ${controller.speechRateLabel}',
                  child: TextButton(
                    onPressed: controller.cycleSpeechRate,
                    child: Text(
                      controller.speechRateLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
