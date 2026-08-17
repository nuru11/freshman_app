import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:vector_academy/utils/utils.dart';

/// Private encrypted on-disk cache for PDF notes.
///
/// Files live under the app support directory with opaque names and are
/// decrypted to a short-lived temp PDF only while the in-app reader is open.
class NoteFileCache {
  NoteFileCache._();

  static final NoteFileCache instance = NoteFileCache._();

  static const _cacheFolder = 'note_cache';
  static const _keyFileName = '.note_aes_key';

  Future<Directory> _cacheDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}/$_cacheFolder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> cacheFilePath(int noteId) async {
    final dir = await _cacheDir();
    return '${dir.path}/note_$noteId.dat';
  }

  Future<String> viewFilePath(int noteId) async {
    final temp = await getTemporaryDirectory();
    return '${temp.path}/note_${noteId}_view.pdf';
  }

  Future<enc.Key> _aesKey() async {
    final support = await getApplicationSupportDirectory();
    final keyFile = File('${support.path}/$_keyFileName');
    if (await keyFile.exists()) {
      final bytes = await keyFile.readAsBytes();
      if (bytes.length == 32) {
        return enc.Key(Uint8List.fromList(bytes));
      }
    }
    final key = enc.Key.fromSecureRandom(32);
    await keyFile.writeAsBytes(key.bytes, flush: true);
    return key;
  }

  Future<bool> hasCache(int noteId, {String? storedPath}) async {
    final canonical = File(await cacheFilePath(noteId));
    if (await canonical.exists()) return true;
    if (storedPath != null && storedPath.isNotEmpty) {
      return File(storedPath).existsSync();
    }
    return false;
  }

  /// Encrypts a plaintext PDF into the private cache and returns the cache path.
  Future<String> storeFromPlaintext(int noteId, String plaintextPdfPath) async {
    final source = File(plaintextPdfPath);
    if (!await source.exists()) {
      throw StateError('Note PDF was not downloaded');
    }
    final plain = await source.readAsBytes();
    if (plain.isEmpty) {
      throw StateError('Note PDF is empty');
    }

    final key = await _aesKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plain, iv: iv);

    final destPath = await cacheFilePath(noteId);
    final dest = File(destPath);
    await dest.writeAsBytes(
      Uint8List.fromList([...iv.bytes, ...encrypted.bytes]),
      flush: true,
    );
    return destPath;
  }

  /// Decrypts the cached note to a temp PDF for the in-app reader.
  Future<String> prepareViewFile(int noteId, {String? storedPath}) async {
    var encryptedPath = await cacheFilePath(noteId);
    var encryptedFile = File(encryptedPath);

    if (!await encryptedFile.exists() &&
        storedPath != null &&
        storedPath.isNotEmpty) {
      final stored = File(storedPath);
      if (await stored.exists()) {
        if (storedPath.toLowerCase().endsWith('.pdf')) {
          encryptedPath = await storeFromPlaintext(noteId, storedPath);
          try {
            await stored.delete();
          } catch (e) {
            logger.w('Could not delete legacy plaintext note: $e');
          }
          encryptedFile = File(encryptedPath);
        } else {
          encryptedPath = storedPath;
          encryptedFile = stored;
        }
      }
    }

    if (!await encryptedFile.exists()) {
      throw StateError('Note is not available offline');
    }

    final data = await encryptedFile.readAsBytes();
    if (data.length <= 16) {
      throw StateError('Note cache is corrupt');
    }

    final key = await _aesKey();
    final iv = enc.IV(Uint8List.fromList(data.sublist(0, 16)));
    final cipher = enc.Encrypted(Uint8List.fromList(data.sublist(16)));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(cipher, iv: iv);

    final viewPath = await viewFilePath(noteId);
    final viewFile = File(viewPath);
    await viewFile.writeAsBytes(Uint8List.fromList(decrypted), flush: true);
    return viewPath;
  }

  Future<void> deleteViewFile(int noteId) async {
    try {
      final view = File(await viewFilePath(noteId));
      if (await view.exists()) {
        await view.delete();
      }
    } catch (e) {
      logger.w('Could not delete note view file: $e');
    }
  }

  Future<void> deleteCache(int noteId, {String? storedPath}) async {
    await deleteViewFile(noteId);
    try {
      final canonical = File(await cacheFilePath(noteId));
      if (await canonical.exists()) {
        await canonical.delete();
      }
    } catch (e) {
      logger.w('Could not delete note cache: $e');
    }
    if (storedPath != null && storedPath.isNotEmpty) {
      try {
        final stored = File(storedPath);
        if (await stored.exists()) {
          await stored.delete();
        }
      } catch (e) {
        logger.w('Could not delete stored note file: $e');
      }
    }
  }

  Future<void> deleteAllCaches() async {
    try {
      final dir = await _cacheDir();
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      }
    } catch (e) {
      logger.w('Could not clear note cache directory: $e');
    }
  }
}
