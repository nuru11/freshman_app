import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'dart:io'; // Added for File
import 'package:vector_academy/utils/utils.dart';

class CustomVideoPlayerController extends GetxController {
  late VideoPlayerController _controller;
  VideoPlayerController get videoController => _controller;

  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showControls = true.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxBool isLoading = true.obs;
  final RxBool isFullscreen = false.obs; // Add fullscreen state

  String videoUrl = '';
  String videoTitle = '';
  int videoId = 0;

  @override
  void onInit() {
    super.onInit();
    // Get arguments passed to the controller
    final args = Get.arguments;
    if (args != null) {
      videoUrl = args['videoUrl'] ?? '';
      videoTitle = args['videoTitle'] ?? '';
      videoId = args['videoId'] ?? 0;
    }

    _setupOrientations();
  }

  @override
  void onClose() {
    _controller.dispose();
    // Reset orientation and system UI when leaving
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  void _setupOrientations() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> initializeVideo(
    String videoUrl,
    String videoTitle,
    int videoId,
  ) async {
    try {
      isLoading.value = true;

      logger.d('Video URL: $videoUrl');

      // Check if videoUrl is a local file path or remote URL
      if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
        // Remote URL
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      } else {
        // Local file path
        _controller = VideoPlayerController.file(File(videoUrl));
      }

      await _controller.initialize();
      _controller.addListener(_videoListener);

      isInitialized.value = true;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to load video: $e');
    }
  }

  void _videoListener() {
    if (_controller.value.isInitialized) {
      position.value = _controller.value.position;
      duration.value = _controller.value.duration;
      isPlaying.value = _controller.value.isPlaying;
    }
  }

  void togglePlayPause() {
    if (isPlaying.value) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void seekTo(Duration position) {
    _controller.seekTo(position);
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  void goBack() {
    Get.back();
  }

  void toggleFullscreen() {
    isFullscreen.value = !isFullscreen.value;

    if (isFullscreen.value) {
      // Enter fullscreen - landscape orientation
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      // Hide system UI for fullscreen experience
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Exit fullscreen - portrait orientation
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      // Show system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
