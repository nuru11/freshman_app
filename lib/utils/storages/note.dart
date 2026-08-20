import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/utils/storages/base.dart';
import 'package:vector_academy/utils/offline_content_access.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveNoteStorage extends BaseObjectStorage<List<Note>> {
  final String _boxName = 'noteStorage';
  static late Box<List<dynamic>> _box;
  @override
  Future<void> init() async {
    Hive.registerAdapter<Note>(NoteTypeAdapter());
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<List<dynamic>>(_boxName);
    } else {
      _box = Hive.box<List<dynamic>>(_boxName);
    }
  }

  @override
  Future<void> clear() {
    return Hive.box<List<Note>>(_boxName).clear();
  }

  @override
  void listen(void Function(List<Note>) callback, String key) {
    Hive.box<List<Note>>(
      _boxName,
    ).watch(key: key).listen((event) => callback(event.value));
  }

  @override
  Future<List<Note>?> read(String key) async {
    return Hive.box<List<Note>>(_boxName).get(key) ?? [];
  }

  @override
  Future<void> write(String key, List<Note> value) {
    return Hive.box<List<Note>>(_boxName).put(key, value);
  }

  Future<void> setNotes(int chapterId, List<Note> notes) {
    return _box.put('notes_$chapterId', notes);
  }

  Future<void> setAllNotes(List<Note> notes) {
    return _box.put('notes', notes);
  }

  Future<List<Note>> getNotes(int chapterId) async {
    final value = _box.get('notes_$chapterId') ?? [];
    final list = value.cast<Note>();
    final downloadedNotes = await getDownloadedNotes();
    await hydrateNoteListDownloadState(list, downloadedNotes);
    return list;
  }

  Future<List<Note>> getAllNotes() async {
    final value = _box.get('notes') ?? [];
    final list = value.cast<Note>();
    final downloadedNotes = await getDownloadedNotes();
    await hydrateNoteListDownloadState(list, downloadedNotes);
    return list;
  }

  // Add these new methods for downloaded notes
  Future<void> addDownloadedNote(int id, String filePath) async {
    final notes = List<dynamic>.from(_box.get('downloaded_notes') ?? []);
    notes.removeWhere((element) => downloadedEntryHasId(element, id));
    notes.add({'id': id, 'file_path': filePath});
    _box.put('downloaded_notes', notes);
  }

  Future<List<Map<String, dynamic>>> getDownloadedNotes() async {
    final value = _box.get('downloaded_notes') ?? [];
    return value
        .cast<Map<dynamic, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> setDownloadedNotes(List<Map<String, dynamic>> notes) async {
    _box.put('downloaded_notes', notes);
  }

  Future<void> removeDownloadedNote(int id) async {
    final notes = List<dynamic>.from(_box.get('downloaded_notes') ?? []);
    notes.removeWhere((element) => downloadedEntryHasId(element, id));
    _box.put('downloaded_notes', notes);
  }

  Future<void> removeAllDownloadedNotes() async {
    _box.put('downloaded_notes', []);
  }
}
