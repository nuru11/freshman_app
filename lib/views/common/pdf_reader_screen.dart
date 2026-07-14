import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:vector_academy/components/components.dart';
import '../../controllers/misc/pdf_reader_controller.dart';
import '../../controllers/controllers.dart';
import 'dart:io';

class PDFReaderScreen extends StatelessWidget {
  final String pdfUrl;
  final String pdfTitle;
  final int pdfId;

  const PDFReaderScreen({
    super.key,
    required this.pdfUrl,
    required this.pdfTitle,
    required this.pdfId,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(PDFReaderController());
    controller.initialize(pdfUrl, pdfTitle, pdfId);

    final theme = Theme.of(context);

    return Obx(() {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: controller.isReadMode ? null : _buildAppBar(controller, theme),
        body: _PDFReaderBody(controller: controller),
        bottomNavigationBar: controller.isReadMode
            ? null
            : _PDFReaderBottomNavigation(controller: controller),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(
    PDFReaderController controller,
    ThemeData theme,
  ) {
    return AppBar(
      leading: const AppBackLeading(),
      title: Text(
        pdfTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      actions: [
        // Read mode toggle button
        Obx(() {
          return IconButton(
            onPressed: controller.toggleReadMode,
            icon: Icon(
              controller.isReadMode
                  ? Icons.chrome_reader_mode
                  : Icons.chrome_reader_mode_outlined,
            ),
            tooltip: controller.isReadMode
                ? 'Exit Read Mode'
                : 'Enter Read Mode',
          );
        }),
        // Orientation toggle button
        Obx(() {
          return IconButton(
            onPressed: controller.toggleOrientation,
            icon: Icon(
              controller.isLandscape
                  ? Icons.screen_lock_landscape
                  : Icons.screen_lock_portrait,
            ),
            tooltip: controller.isLandscape
                ? 'Switch to Portrait'
                : 'Switch to Landscape',
          );
        }),
        Obx(() {
          if (controller.isReady && controller.totalPages > 0) {
            return Container(
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          SizedBox(height: 16),
          Text(
            controller.isDownloading ? 'Downloading PDF...' : 'Loading PDF...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
          ElevatedButton.icon(
            onPressed: controller.retryInitialization,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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

class _PDFView extends StatelessWidget {
  final PDFReaderController controller;

  const _PDFView({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Add debugging info
      if (controller.localPath.isEmpty) {
        return Center(child: Text('No local path available'));
      }

      // Check if file actually exists
      final file = File(controller.localPath);
      if (!file.existsSync()) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('PDF file not found'),
              SizedBox(height: 8),
              Text(
                'Path: ${controller.localPath}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      final isLandscape = controller.isLandscape;
      // Use WIDTH fit in landscape for better zoom, BOTH in portrait
      final fitPolicy = isLandscape ? FitPolicy.WIDTH : FitPolicy.BOTH;

      return Stack(
        children: [
          GestureDetector(
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
              preventLinkNavigation: false,
            ),
          ),
          // Show a hint in read mode with fade animation
          if (controller.isReadMode && controller.showReadModeHint)
            Positioned(
              top: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: controller.showReadModeHint ? 1.0 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Tap to exit',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _PDFReaderBottomNavigation extends StatelessWidget {
  final PDFReaderController controller;

  const _PDFReaderBottomNavigation({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      // Only show navigation if PDF is actually ready AND has pages
      if (!controller.isReady ||
          controller.totalPages == 0 ||
          controller.hasError) {
        return SizedBox.shrink();
      }

      return Container(
        padding: EdgeInsets.all(16),
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
            SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: controller.currentPage > 0
                      ? controller.goToPreviousPage
                      : null,
                  icon: Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
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
                    onChanged: (value) {
                      controller.goToPage(value.toInt());
                    },
                  ),
                ),
                IconButton(
                  onPressed: controller.currentPage < controller.totalPages - 1
                      ? controller.goToNextPage
                      : null,
                  icon: Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.1,
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
