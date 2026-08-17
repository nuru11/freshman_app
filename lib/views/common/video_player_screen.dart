import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vector_academy/controllers/controllers.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final int videoId;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final CustomVideoPlayerController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CustomVideoPlayerController>()) {
      Get.delete<CustomVideoPlayerController>(force: true);
    }
    controller = Get.put(CustomVideoPlayerController());
    controller.initializeVideo(
      widget.videoUrl,
      widget.videoTitle,
      widget.videoId,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<CustomVideoPlayerController>()) {
      Get.delete<CustomVideoPlayerController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Obx(() {
                if (controller.isInitialized.value) {
                  return AspectRatio(
                    aspectRatio: controller.videoController.value.aspectRatio,
                    child: VideoPlayer(controller.videoController),
                  );
                }
                return _buildStatusOverlay(theme);
              }),
            ),
            Obx(
              () => controller.isInitialized.value
                  ? Positioned.fill(
                      child: GestureDetector(
                        onTap: controller.toggleControls,
                        child: Obx(
                          () => AnimatedOpacity(
                            opacity: controller.showControls.value ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.7),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildTopControls(
                                    theme,
                                    showFullscreen: true,
                                  ),
                                  _buildCenterPlayButton(),
                                  _buildBottomControls(theme, context),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildTopControls(theme, showFullscreen: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOverlay(ThemeData theme) {
    return Obx(() {
      final failed = controller.hasError.value;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        color: Colors.grey[900],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (failed)
              const Icon(Icons.error_outline, color: Colors.white, size: 48)
            else
              CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              failed
                  ? (controller.errorMessage.value.isEmpty
                        ? 'Failed to load video'
                        : controller.errorMessage.value)
                  : 'Loading video...',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            if (failed) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: controller.retryInitialize,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTopControls(ThemeData theme, {required bool showFullscreen}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.goBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          ),
          Expanded(
            child: Text(
              widget.videoTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showFullscreen)
            Obx(
              () => IconButton(
                onPressed: controller.toggleFullscreen,
                icon: Icon(
                  controller.isFullscreen.value
                      ? Icons.fullscreen_exit
                      : Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterPlayButton() {
    return Expanded(
      child: Center(
        child: Obx(
          () => IconButton(
            onPressed: controller.togglePlayPause,
            icon: Icon(
              controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: theme.colorScheme.primary,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
              thumbColor: theme.colorScheme.primary,
              overlayColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Obx(() {
              final duration = controller.duration.value.inMilliseconds
                  .toDouble();
              final position = controller.position.value.inMilliseconds
                  .toDouble();

              return Slider(
                value: duration > 0 ? position.clamp(0.0, duration) : 0.0,
                max: duration > 0 ? duration : 1.0,
                onChanged: (value) {
                  controller.seekTo(Duration(milliseconds: value.toInt()));
                },
              );
            }),
          ),
          Row(
            children: [
              Obx(
                () => Text(
                  controller.formatDuration(controller.position.value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Obx(
                () => Text(
                  controller.formatDuration(controller.duration.value),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Obx(() {
                final canDecrease = controller.canDecreaseSpeed;
                final canIncrease = controller.canIncreaseSpeed;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: canDecrease ? controller.decreaseSpeed : null,
                      icon: Icon(
                        Icons.remove,
                        color: Colors.white.withValues(
                          alpha: canDecrease ? 1.0 : 0.4,
                        ),
                        size: 22,
                      ),
                    ),
                    Text(
                      controller.formattedPlaybackSpeed,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: canIncrease ? controller.increaseSpeed : null,
                      icon: Icon(
                        Icons.add,
                        color: Colors.white.withValues(
                          alpha: canIncrease ? 1.0 : 0.4,
                        ),
                        size: 22,
                      ),
                    ),
                  ],
                );
              }),
              Obx(
                () => IconButton(
                  onPressed: controller.togglePlayPause,
                  icon: Icon(
                    controller.isPlaying.value ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
