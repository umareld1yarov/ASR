import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'photo_cache_service.dart';

/// Сервис работы с фото, прикреплёнными к записям.
/// Файлы хранятся в подпапке документов приложения — path_provider уже
/// используется в проекте для Isar, здесь та же папка, но другая подпапка.
class PhotoService {
  PhotoService._();

  static const _folderName = 'entry_photos';

  /// Копирует временный файл (из image_picker) в постоянную папку
  /// приложения и возвращает новый путь. Оригинальный временный файл
  /// image_picker сам может удалить позже — нам нужна своя копия.
  static Future<String> savePhoto(File tempFile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/$_folderName');

    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = '${photosDir.path}/$fileName';

    await tempFile.copy(newPath);
    return newPath;
  }

  /// Удаляет файл фото с диска (вызывается при удалении фото из записи).
  static Future<void> deletePhoto(String path) async {
    if (PhotoCacheService.isRemoteSource(path)) {
      await PhotoCacheService.instance.deleteCachedCopy(path);
      return;
    }
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
