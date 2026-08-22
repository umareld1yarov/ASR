import 'dart:io';

import 'package:path_provider/path_provider.dart';

typedef PhotoCacheDirectoryProvider = Future<Directory> Function();
typedef PhotoBytesDownloader = Future<List<int>> Function(Uri uri);

/// Превращает локальный путь или облачную ссылку фотографии в доступный
/// локальный файл. Облачные файлы сохраняются в постоянный кеш приложения,
/// поэтому после первой загрузки доступны без сети.
class PhotoCacheService {
  PhotoCacheService({
    PhotoCacheDirectoryProvider? directoryProvider,
    PhotoBytesDownloader? downloader,
  }) : _directoryProvider = directoryProvider ?? _defaultDirectory,
       _downloader = downloader ?? _download;

  static final instance = PhotoCacheService();

  static const _folderName = 'synced_photo_cache';
  final PhotoCacheDirectoryProvider _directoryProvider;
  final PhotoBytesDownloader _downloader;
  final Map<String, Future<File?>> _pending = {};

  static bool isRemoteSource(String source) {
    final uri = Uri.tryParse(source);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<File?> resolve(String source) {
    if (!isRemoteSource(source)) {
      final file = File(source);
      return file.exists().then((exists) => exists ? file : null);
    }
    return _pending.putIfAbsent(source, () async {
      try {
        final target = await _cachedFile(source);
        if (await target.exists() && await target.length() > 0) return target;

        final bytes = await _downloader(Uri.parse(source));
        if (bytes.isEmpty) return null;
        await target.parent.create(recursive: true);
        final part = File('${target.path}.part');
        await part.writeAsBytes(bytes, flush: true);
        if (await target.exists()) await target.delete();
        return part.rename(target.path);
      } catch (_) {
        return null;
      } finally {
        _pending.remove(source);
      }
    });
  }

  /// Сохраняет уже имеющийся локальный оригинал под ключом облачной ссылки.
  /// Телефону, который загрузил фото, не приходится скачивать его обратно.
  Future<void> seed(String remoteUrl, File localFile) async {
    if (!isRemoteSource(remoteUrl) || !await localFile.exists()) return;
    final target = await _cachedFile(remoteUrl);
    await target.parent.create(recursive: true);
    if (await target.exists()) await target.delete();
    await localFile.copy(target.path);
  }

  Future<void> deleteCachedCopy(String source) async {
    if (!isRemoteSource(source)) return;
    try {
      final target = await _cachedFile(source);
      if (await target.exists()) await target.delete();
    } catch (_) {
      // Очистка локального кеша — best effort. Ошибка файловой системы не
      // должна отменять уже выполненное удаление фото из облака и оставлять
      // запись в бесконечной очереди повторов.
    }
  }

  Future<File> _cachedFile(String source) async {
    final root = await _directoryProvider();
    final cacheDir = Directory(
      '${root.path}${Platform.pathSeparator}$_folderName',
    );
    final extension = _safeExtension(Uri.parse(source).path);
    return File(
      '${cacheDir.path}${Platform.pathSeparator}${_stableHash(source)}$extension',
    );
  }

  static Future<Directory> _defaultDirectory() async {
    return getApplicationDocumentsDirectory();
  }

  static Future<List<int>> _download(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Photo download failed: ${response.statusCode}',
          uri: uri,
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }

  static String _safeExtension(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final extension = name.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(extension)
        ? extension
        : '.jpg';
  }

  static String _stableHash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
