import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vector_academy/controllers/controllers.dart';

class VideoPlayerScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Initialize controller with arguments
    final controller = Get.put(CustomVideoPlayerController());

    final theme = Theme.of(context);

    controller.initializeVideo(videoUrl, videoTitle, videoId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Player
            Center(
              child: Obx(
                () => controller.isInitialized.value
                    ? AspectRatio(
                        aspectRatio:
                            controller.videoController.value.aspectRatio,
                        child: VideoPlayer(controller.videoController),
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[900],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading video...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Video Controls
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
                                  // Top Controls
                                  _buildTopControls(theme, controller),

                                  // Center Play Button
                                  _buildCenterPlayButton(controller),

                                  // Bottom Controls
                                  _buildBottomControls(
                                    theme,
                                    context,
                                    controller,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls(
    ThemeData theme,
    CustomVideoPlayerController controller,
  ) {
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
              videoTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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

  Widget _buildCenterPlayButton(CustomVideoPlayerController controller) {
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

  Widget _buildBottomControls(
    ThemeData theme,
    BuildContext context,
    CustomVideoPlayerController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress Bar
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

          // Time and Controls
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
