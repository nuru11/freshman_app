import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:vector_academy/utils/utils.dart';
import 'package:vector_academy/services/api/exceptions.dart';

class CustomVideoPlayerController extends GetxController {
  VideoPlayerController? _controller;
  VideoPlayerController get videoController {
    final player = _controller;
    if (player == null) {
      throw StateError('Video player is not initialized');
    }
    return player;
  }

  final RxBool isInitialized = false.obs;
  final RxBool isPlaying = false.obs;
  final RxBool showControls = true.obs;
  final Rx<Duration> position = Duration.zero.obs;
  final Rx<Duration> duration = Duration.zero.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isFullscreen = false.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  static const List<double> speedOptions = [
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  static const Duration _initializeTimeout = Duration(seconds: 20);

  String videoUrl = '';
  String videoTitle = '';
  int videoId = 0;

  bool _isInitializing = false;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
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
    _closed = true;
    _disposePlayer();
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
    int videoId, {
    bool force = false,
  }) async {
    if (_closed) return;

    if (!force &&
        _isInitializing &&
        this.videoUrl == videoUrl &&
        isLoading.value) {
      return;
    }
    if (!force &&
        isInitialized.value &&
        this.videoUrl == videoUrl &&
        _controller != null) {
      return;
    }

    this.videoUrl = videoUrl;
    this.videoTitle = videoTitle;
    this.videoId = videoId;

    _isInitializing = true;
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';
    isInitialized.value = false;
    isPlaying.value = false;

    logger.d('Video URL: $videoUrl');

    _disposePlayer();

    VideoPlayerController? player;
    try {
      player = await _createPlayer(videoUrl);
      if (_closed) {
        await player.dispose();
        return;
      }

      _controller = player;
      await player.initialize().timeout(_initializeTimeout);
      if (_closed) return;

      player.addListener(_videoListener);

      playbackSpeed.value = 1.0;
      await player.setPlaybackSpeed(playbackSpeed.value);

      isInitialized.value = true;
      isLoading.value = false;
    } catch (e) {
      logger.e('Failed to load video: $e');
      if (player != null) {
        try {
          await player.dispose();
        } catch (_) {}
        if (_controller == player) {
          _controller = null;
        }
      }
      if (_closed) return;

      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = _errorText(e);
      AppSnackbar.showError('Error', errorMessage.value);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> retryInitialize() {
    return initializeVideo(videoUrl, videoTitle, videoId, force: true);
  }

  Future<VideoPlayerController> _createPlayer(String source) async {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return VideoPlayerController.networkUrl(Uri.parse(source));
    }

    var path = source;
    if (path.startsWith('file://')) {
      path = Uri.parse(path).toFilePath();
    }

    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException(
        'The downloaded video file could not be found',
        path,
      );
    }
    return VideoPlayerController.file(file);
  }

  String _errorText(Object e) {
    if (e is TimeoutException) {
      return 'This device is taking too long to load the video. Please try again.';
    }
    if (e is FileSystemException) {
      return 'The downloaded video file could not be found. Please download again.';
    }
    return ApiErrorMessage.from(e, fallback: 'Failed to load video');
  }

  void _disposePlayer() {
    final player = _controller;
    _controller = null;
    if (player == null) return;
    player.removeListener(_videoListener);
    player.dispose();
  }

  void _videoListener() {
    final player = _controller;
    if (player == null || !player.value.isInitialized) return;
    position.value = player.value.position;
    duration.value = player.value.duration;
    isPlaying.value = player.value.isPlaying;
  }

  void togglePlayPause() {
    final player = _controller;
    if (player == null || !isInitialized.value) return;
    if (isPlaying.value) {
      player.pause();
    } else {
      player.play();
    }
  }

  void seekTo(Duration position) {
    final player = _controller;
    if (player == null || !isInitialized.value) return;
    player.seekTo(position);
  }

  void toggleControls() {
    showControls.value = !showControls.value;
  }

  bool get canDecreaseSpeed => playbackSpeed.value > speedOptions.first;
  bool get canIncreaseSpeed => playbackSpeed.value < speedOptions.last;

  String get formattedPlaybackSpeed {
    final speed = playbackSpeed.value;
    final text = speed == speed.truncateToDouble()
        ? speed.toStringAsFixed(1)
        : speed.toString();
    return '${text}x';
  }

  void increaseSpeed() {
    final currentIndex = speedOptions.indexOf(playbackSpeed.value);
    if (currentIndex == -1 || currentIndex >= speedOptions.length - 1) {
      return;
    }
    _applyPlaybackSpeed(speedOptions[currentIndex + 1]);
  }

  void decreaseSpeed() {
    final currentIndex = speedOptions.indexOf(playbackSpeed.value);
    if (currentIndex <= 0) {
      return;
    }
    _applyPlaybackSpeed(speedOptions[currentIndex - 1]);
  }

  Future<void> _applyPlaybackSpeed(double speed) async {
    playbackSpeed.value = speed;
    final player = _controller;
    if (isInitialized.value && player != null) {
      await player.setPlaybackSpeed(speed);
    }
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
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
