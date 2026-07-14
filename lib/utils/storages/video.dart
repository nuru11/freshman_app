import 'package:vector_academy/utils/storages/base.dart';
import 'package:vector_academy/models/models.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveVideoStorage extends BaseObjectStorage<List<Video>> {
  final String _boxName = 'videoStorage';
  static Box<List<dynamic>>? _box;

  @override
  Future<void> init() async {
    Hive.registerAdapter<Video>(VideoTypeAdapter());
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<List<dynamic>>(_boxName);
    } else {
      _box = Hive.box<List<dynamic>>(_boxName);
    }
  }

  @override
  Future<void> clear() async {
    await _box?.clear();
  }

  @override
  void listen(void Function(List<Video> p1) callback, String key) {
    _box?.watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<List<Video>> read(String key) async {
    final videos = _box?.get(key) ?? [];
    return videos.cast<Video>();
  }

  @override
  Future<void> write(String key, List<Video> value) async {
    return _box?.put(key, value);
  }

  Future<void> setVideos(int chapterId, List<Video> videos) async {
    _box?.put('videos_$chapterId', videos);
  }

  Future<List<Video>> getAllVideos() async {
    final videos = _box?.get('videos') ?? [];
    final downloadedVideos = await getDownloadedVideos();
    for (var video in videos) {
      final downloadedVideo = downloadedVideos.firstWhere(
        (element) => element['id'] == video.id,
        orElse: () => {},
      );
      video.filePath = downloadedVideo['file_path'];
      if (video.filePath != null) {
        video.isDownloaded = true;
      }
    }
    return videos.cast<Video>();
  }

  Future<void> setAllVideos(List<Video> videos) async {
    _box?.put('videos', videos);
  }

  Future<List<Video>> getVideos(int chapterId) async {
    final videos = await read('videos_$chapterId');
    final downloadedVideos = await getDownloadedVideos();

    for (var video in videos) {
      final downloadedVideo = downloadedVideos.firstWhere(
        (element) => element['id'] == video.id,
        orElse: () => {},
      );
      video.filePath = downloadedVideo['file_path'];
      if (video.filePath != null) {
        video.isDownloaded = true;
      }
    }
    return videos.cast<Video>();
  }

  Future<List<Map<String, dynamic>>> getDownloadedVideos() async {
    final videos = _box?.get('downloaded_videos') ?? [];
    return videos
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> setDownloadedVideos(List<Map<String, dynamic>> videos) async {
    _box?.put('downloaded_videos', videos);
  }

  Future<void> addDownloadedVideo(int id, String filePath) async {
    final videos = _box?.get('downloaded_videos') ?? [];
    videos.add({'id': id, 'file_path': filePath});
    _box?.put('downloaded_videos', videos);
  }

  Future<void> removeDownloadedVideo(int id) async {
    final videos = _box?.get('downloaded_videos') ?? [];
    videos.removeWhere((element) => element['id'] == id);
    _box?.put('downloaded_videos', videos);
  }

  Future<void> removeAllDownloadedVideos() async {
    _box?.put('downloaded_videos', []);
  }
}
