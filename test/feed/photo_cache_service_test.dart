import 'dart:io';

import 'package:asr/features/feed/data/photo_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoCacheService', () {
    late Directory tempDir;
    late int downloadCalls;
    late PhotoCacheService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('asr_photo_cache_test_');
      downloadCalls = 0;
      service = PhotoCacheService(
        directoryProvider: () async => tempDir,
        downloader: (uri) async {
          downloadCalls++;
          return [1, 2, 3, 4];
        },
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('локальный путь возвращает существующий файл без сети', () async {
      final local = File('${tempDir.path}${Platform.pathSeparator}local.jpg');
      await local.writeAsBytes([7, 8, 9]);

      final resolved = await service.resolve(local.path);

      expect(resolved?.path, local.path);
      expect(downloadCalls, 0);
    });

    test(
      'облачное фото скачивается один раз и затем читается из кеша',
      () async {
        const url = 'https://example.test/user/photo.jpg';

        final first = await service.resolve(url);
        final second = await service.resolve(url);

        expect(first, isNotNull);
        expect(await first!.readAsBytes(), [1, 2, 3, 4]);
        expect(second?.path, first.path);
        expect(downloadCalls, 1);
      },
    );

    test('кеш работает без сети после первого скачивания', () async {
      const url = 'https://example.test/user/offline.jpg';
      final cached = await service.resolve(url);

      final offlineService = PhotoCacheService(
        directoryProvider: () async => tempDir,
        downloader: (uri) => throw const SocketException('offline'),
      );
      final offlineResult = await offlineService.resolve(url);

      expect(offlineResult?.path, cached?.path);
      expect(await offlineResult!.readAsBytes(), [1, 2, 3, 4]);
    });

    test(
      'seed сохраняет оригинал загрузившего телефона без скачивания',
      () async {
        const url = 'https://example.test/user/seeded.jpg';
        final original = File(
          '${tempDir.path}${Platform.pathSeparator}original.jpg',
        );
        await original.writeAsBytes([9, 8, 7]);

        await service.seed(url, original);
        final resolved = await service.resolve(url);

        expect(await resolved!.readAsBytes(), [9, 8, 7]);
        expect(downloadCalls, 0);
      },
    );

    test(
      'ошибка загрузки возвращает null и допускает повторную попытку',
      () async {
        var shouldFail = true;
        final retryService = PhotoCacheService(
          directoryProvider: () async => tempDir,
          downloader: (uri) async {
            if (shouldFail) throw const SocketException('offline');
            return [5, 5, 5];
          },
        );
        const url = 'https://example.test/user/retry.jpg';

        expect(await retryService.resolve(url), isNull);
        shouldFail = false;
        expect(await retryService.resolve(url), isNotNull);
      },
    );

    test('удаление облачного фото очищает локальную кеш-копию', () async {
      const url = 'https://example.test/user/delete.jpg';
      final cached = await service.resolve(url);
      expect(await cached!.exists(), isTrue);

      await service.deleteCachedCopy(url);

      expect(await cached.exists(), isFalse);
    });
  });
}
