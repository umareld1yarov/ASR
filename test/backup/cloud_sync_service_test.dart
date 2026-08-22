import 'dart:io';

import 'package:asr/features/backup/data/cloud_sync_service.dart';
import 'package:asr/features/feed/data/feed_repository.dart';
import 'package:asr/features/feed/data/photo_cache_service.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../helpers/fake_sync_remote_gateway.dart';
import '../helpers/test_db_helper.dart';
import '../helpers/test_localization_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initTestLocalization);

  group('CloudSyncService — ActivityEntry', () {
    late TestDbHandle db;
    late FakeSyncRemoteGateway remote;
    late MemorySyncOwnershipStore ownership;
    late CloudSyncService service;

    setUp(() async {
      db = await createTestIsar(prefix: 'cloud_sync');
      remote = FakeSyncRemoteGateway();
      ownership = MemorySyncOwnershipStore();
      service = CloudSyncService(
        remoteGateway: remote,
        isar: db.isar,
        ownershipStore: ownership,
      );
    });

    tearDown(() => db.dispose());

    test('не обращается к данным, когда облако не инициализировано', () async {
      remote.isAvailable = false;

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
      expect(remote.fetchActivityCalls, 0);
      expect(ownership.ownerId, isNull);
    });

    test('не обращается к данным без авторизованного пользователя', () async {
      remote.currentUserId = null;

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
      expect(remote.fetchActivityCalls, 0);
      expect(ownership.ownerId, isNull);
    });

    test(
      'первая синхронизация привязывает базу и выгружает локальную запись',
      () async {
        await _putEntry(db.isar, syncId: 'local-1', updatedAt: 1000);

        final result = await service.performFullSync();

        expect(result.isSuccess, isTrue);
        expect(ownership.ownerId, 'user-a');
        expect(ownership.bindCalls, 1);
        expect(remote.activityEntries, hasLength(1));
        expect(remote.activityEntries.single['sync_id'], 'local-1');
        expect(remote.activityEntries.single['user_id'], 'user-a');
      },
    );

    test('другой аккаунт блокируется до чтения и выгрузки данных', () async {
      ownership.ownerId = 'user-a';
      remote.currentUserId = 'user-b';
      await _putEntry(db.isar, syncId: 'private-a', updatedAt: 1000);

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
      expect(remote.fetchActivityCalls, 0);
      expect(remote.upsertActivityCalls, 0);
      expect(remote.activityEntries, isEmpty);
      expect(ownership.ownerId, 'user-a');
    });

    test('новая облачная запись загружается локально с тем же UUID', () async {
      ownership.ownerId = 'user-a';
      remote.activityEntries.add(
        _remoteRow(syncId: 'remote-1', updatedAt: 2000, name: 'Из облака'),
      );

      final result = await service.performFullSync();

      expect(result.isSuccess, isTrue);
      final entries = await db.isar.activityEntrys.where().findAll();
      expect(entries, hasLength(1));
      expect(entries.single.syncId, 'remote-1');
      expect(entries.single.name, 'Из облака');
      expect(remote.upsertActivityCalls, 0);
    });

    test('более новая локальная версия побеждает облачную', () async {
      ownership.ownerId = 'user-a';
      await _putEntry(
        db.isar,
        syncId: 'same-id',
        updatedAt: 3000,
        name: 'Локальная',
      );
      remote.activityEntries.add(
        _remoteRow(syncId: 'same-id', updatedAt: 2000, name: 'Облачная'),
      );

      await service.performFullSync();

      expect(remote.activityEntries.single['name'], 'Локальная');
      final local = await db.isar.activityEntrys.where().findFirst();
      expect(local?.name, 'Локальная');
    });

    test('более новая облачная версия побеждает локальную', () async {
      ownership.ownerId = 'user-a';
      await _putEntry(
        db.isar,
        syncId: 'same-id',
        updatedAt: 2000,
        name: 'Локальная',
      );
      remote.activityEntries.add(
        _remoteRow(syncId: 'same-id', updatedAt: 3000, name: 'Облачная'),
      );

      await service.performFullSync();

      final local = await db.isar.activityEntrys.where().findFirst();
      expect(local?.name, 'Облачная');
      expect(local?.updatedAt, 3000);
      expect(remote.upsertActivityCalls, 0);
    });

    test(
      'разделение отправляет две непрерывные записи с разными UUID',
      () async {
        ownership.ownerId = 'user-a';
        final original = await _putEntry(
          db.isar,
          syncId: 'original-id',
          updatedAt: 1000,
          startedAt: 0,
          endedAt: 3 * Duration.millisecondsPerHour,
        );
        await FeedRepository(db.isar).splitEntry(
          original.id,
          splitAt: Duration.millisecondsPerHour,
          firstName: 'Семья',
          firstCategoryKey: 'family',
          secondName: 'Работа',
          secondCategoryKey: 'work',
        );

        await service.performFullSync();

        expect(remote.activityEntries, hasLength(2));
        final rows = [...remote.activityEntries]
          ..sort(
            (a, b) =>
                (a['started_at'] as int).compareTo(b['started_at'] as int),
          );
        expect(rows[0]['sync_id'], 'original-id');
        expect(rows[1]['sync_id'], isNot('original-id'));
        expect(rows[0]['ended_at'], rows[1]['started_at']);
        expect(rows[0]['started_at'], 0);
        expect(rows[1]['ended_at'], 3 * Duration.millisecondsPerHour);
      },
    );

    test('локальное мягкое удаление отправляется как tombstone', () async {
      ownership.ownerId = 'user-a';
      await _putEntry(
        db.isar,
        syncId: 'deleted-id',
        updatedAt: 4000,
        isDeleted: true,
      );

      await service.performFullSync();

      expect(remote.activityEntries.single['is_deleted'], isTrue);
    });

    test('новое облачное удаление скрывает локальную запись', () async {
      ownership.ownerId = 'user-a';
      await _putEntry(db.isar, syncId: 'deleted-id', updatedAt: 2000);
      remote.activityEntries.add(
        _remoteRow(syncId: 'deleted-id', updatedAt: 3000, isDeleted: true),
      );

      await service.performFullSync();

      final local = await db.isar.activityEntrys.where().findFirst();
      expect(local?.isDeleted, isTrue);
    });

    test('повторная синхронизация без изменений идемпотентна', () async {
      ownership.ownerId = 'user-a';
      await _putEntry(db.isar, syncId: 'stable-id', updatedAt: 2000);

      await service.performFullSync();
      final uploadsAfterFirstRun = remote.uploadedActivityPayloads.length;
      await service.performFullSync();

      expect(uploadsAfterFirstRun, 1);
      expect(remote.uploadedActivityPayloads, hasLength(1));
      expect(remote.activityEntries, hasLength(1));
    });

    test(
      'сетевая ошибка возвращает failure и не удаляет локальные данные',
      () async {
        ownership.ownerId = 'user-a';
        await _putEntry(db.isar, syncId: 'safe-local', updatedAt: 2000);
        remote.fetchActivityError = Exception('offline');

        final result = await service.performFullSync();

        expect(result.isSuccess, isFalse);
        final entries = await db.isar.activityEntrys.where().findAll();
        expect(entries.single.syncId, 'safe-local');
      },
    );

    test(
      'legacy-запись принимает облачный UUID без создания дубликата',
      () async {
        ownership.ownerId = 'user-a';
        final local = await _putEntry(
          db.isar,
          syncId: 'temporary-local-id',
          updatedAt: 2000,
          startedAt: 100,
          endedAt: 500,
        );
        remote.activityEntries.add(
          _remoteRow(
            id: local.id,
            syncId: 'cloud-uuid',
            updatedAt: 2000,
            startedAt: 100,
            endedAt: 500,
          ),
        );

        await service.performFullSync();

        final entries = await db.isar.activityEntrys.where().findAll();
        expect(entries, hasLength(1));
        expect(entries.single.syncId, 'cloud-uuid');
        expect(remote.activityEntries, hasLength(1));
      },
    );

    test('не отправляет локальный путь, если фото не загрузилось', () async {
      ownership.ownerId = 'user-a';
      final photo = File(
        '${db.directory.path}${Platform.pathSeparator}photo.jpg',
      );
      await photo.writeAsBytes([1, 2, 3]);
      await _putEntry(
        db.isar,
        syncId: 'photo-id',
        updatedAt: 2000,
        photoPaths: [photo.path],
      );
      remote.failPhotoUpload = true;

      final result = await service.performFullSync();

      expect(result.isSuccess, isFalse);
      expect(
        remote.activityEntries.expand(
          (row) => (row['photo_urls'] as List<dynamic>? ?? const []),
        ),
        isNot(contains(photo.path)),
      );
    });

    test(
      'после загрузки заменяет локальный путь URL и не грузит фото повторно',
      () async {
        ownership.ownerId = 'user-a';
        final photo = File(
          '${db.directory.path}${Platform.pathSeparator}persistent.jpg',
        );
        await photo.writeAsBytes([4, 3, 2, 1]);
        await _putEntry(
          db.isar,
          syncId: 'persistent-photo-id',
          updatedAt: 2500,
          photoPaths: [photo.path],
        );
        service = CloudSyncService(
          remoteGateway: remote,
          isar: db.isar,
          ownershipStore: ownership,
          photoCacheService: PhotoCacheService(
            directoryProvider: () async => db.directory,
            downloader: (uri) => throw const SocketException('not expected'),
          ),
        );

        final first = await service.performFullSync();
        final localAfterUpload = await db.isar.activityEntrys
            .where()
            .findFirst();
        final uploadedUrl = localAfterUpload!.photoPaths!.single;
        final uploadsAfterFirstSync = remote.uploadPhotoCalls;
        final second = await service.performFullSync();

        expect(first.isSuccess, isTrue);
        expect(second.isSuccess, isTrue);
        expect(PhotoCacheService.isRemoteSource(uploadedUrl), isTrue);
        expect(remote.activityEntries.single['photo_urls'], [uploadedUrl]);
        expect(uploadsAfterFirstSync, 1);
        expect(remote.uploadPhotoCalls, 1);
      },
    );

    test(
      'два устройства обмениваются фото через облако и сохраняют офлайн-кеш',
      () async {
        ownership.ownerId = 'user-a';
        final deviceB = await createTestIsar(prefix: 'cloud_sync_device_b');
        addTearDown(deviceB.dispose);
        final ownershipB = MemorySyncOwnershipStore(ownerId: 'user-a');

        final cacheA = PhotoCacheService(
          directoryProvider: () async => db.directory,
          downloader: (uri) => throw const SocketException('not expected on A'),
        );
        var deviceBDownloads = 0;
        final cacheB = PhotoCacheService(
          directoryProvider: () async => deviceB.directory,
          downloader: (uri) async {
            deviceBDownloads++;
            return [11, 22, 33, 44];
          },
        );
        final serviceA = CloudSyncService(
          remoteGateway: remote,
          isar: db.isar,
          ownershipStore: ownership,
          photoCacheService: cacheA,
        );
        final serviceB = CloudSyncService(
          remoteGateway: remote,
          isar: deviceB.isar,
          ownershipStore: ownershipB,
          photoCacheService: cacheB,
        );

        final appCopyOnA = File(
          '${db.directory.path}${Platform.pathSeparator}asr_copy.jpg',
        );
        await appCopyOnA.writeAsBytes([1, 2, 3, 4]);
        await _putEntry(
          db.isar,
          syncId: 'two-device-photo',
          updatedAt: 3000,
          name: 'Создано на A',
          photoPaths: [appCopyOnA.path],
        );

        final uploadFromA = await serviceA.performFullSync();
        final entryA = await db.isar.activityEntrys.where().findFirst();
        final cloudUrl = entryA!.photoPaths!.single;
        final downloadToB = await serviceB.performFullSync();
        final entryB = await deviceB.isar.activityEntrys.where().findFirst();
        final cachedOnB = await cacheB.resolve(entryB!.photoPaths!.single);

        expect(uploadFromA.isSuccess, isTrue);
        expect(downloadToB.isSuccess, isTrue);
        expect(PhotoCacheService.isRemoteSource(cloudUrl), isTrue);
        expect(entryB.syncId, 'two-device-photo');
        expect(entryB.photoPaths, [cloudUrl]);
        expect(await cachedOnB!.readAsBytes(), [11, 22, 33, 44]);
        expect(deviceBDownloads, 1);

        // После удаления исходной копии A устройство B открывает фото из кеша.
        await appCopyOnA.delete();
        final offlineCacheB = PhotoCacheService(
          directoryProvider: () async => deviceB.directory,
          downloader: (uri) => throw const SocketException('offline'),
        );
        final offlinePhoto = await offlineCacheB.resolve(cloudUrl);
        expect(await offlinePhoto!.readAsBytes(), [11, 22, 33, 44]);

        // Изменение текста на B возвращается на A без повторной загрузки фото.
        await deviceB.isar.writeTxn(() async {
          final updated = await deviceB.isar.activityEntrys.get(entryB.id);
          updated!
            ..name = 'Изменено на B'
            ..updatedAt = DateTime.now().millisecondsSinceEpoch;
          await deviceB.isar.activityEntrys.put(updated);
        });
        final uploadsBeforeEditSync = remote.uploadPhotoCalls;
        await serviceB.performFullSync();
        await serviceA.performFullSync();

        final updatedOnA = await db.isar.activityEntrys.where().findFirst();
        expect(updatedOnA?.name, 'Изменено на B');
        expect(updatedOnA?.photoPaths, [cloudUrl]);
        expect(remote.uploadPhotoCalls, uploadsBeforeEditSync);
        expect(remote.activityEntries, hasLength(1));

        final cachedCopyOnA = await cacheA.resolve(cloudUrl);
        expect(await cachedCopyOnA!.exists(), isTrue);
        await FeedRepository(deviceB.isar).removePhoto(entryB.id, cloudUrl);
        final deleteFromB = await serviceB.performFullSync();
        final receiveDeletionOnA = await serviceA.performFullSync();

        final afterDeletionOnA = await db.isar.activityEntrys
            .where()
            .findFirst();
        expect(deleteFromB.isSuccess, isTrue);
        expect(receiveDeletionOnA.isSuccess, isTrue);
        expect(afterDeletionOnA?.photoPaths, isEmpty);
        expect(await cachedCopyOnA.exists(), isFalse);
        expect(remote.deletedPhotoUrls, contains(cloudUrl));
        expect(remote.activityEntries.single['photo_urls'], isEmpty);
      },
    );

    test('успешное удаление Storage очищает постоянную очередь', () async {
      ownership.ownerId = 'user-a';
      const url = 'https://example.test/user-a/delete-me.jpg';
      await _putEntry(
        db.isar,
        syncId: 'delete-photo-id',
        updatedAt: 5000,
        photoPaths: [],
        pendingPhotoDeleteUrls: [url],
      );
      remote.activityEntries.add(
        _remoteRow(
          syncId: 'delete-photo-id',
          updatedAt: 4000,
          photoUrls: [url],
        ),
      );

      final result = await service.performFullSync();

      final local = await db.isar.activityEntrys.where().findFirst();
      expect(result.isSuccess, isTrue);
      expect(remote.deletedPhotoUrls, [url]);
      expect(remote.activityEntries.single['photo_urls'], isEmpty);
      expect(local?.pendingPhotoDeleteUrls, isEmpty);
    });

    test(
      'ошибка Storage сохраняет очередь и следующий sync повторяет удаление',
      () async {
        ownership.ownerId = 'user-a';
        const url = 'https://example.test/user-a/retry-delete.jpg';
        await _putEntry(
          db.isar,
          syncId: 'retry-delete-photo-id',
          updatedAt: 5000,
          photoPaths: [],
          pendingPhotoDeleteUrls: [url],
        );
        remote.activityEntries.add(
          _remoteRow(
            syncId: 'retry-delete-photo-id',
            updatedAt: 4000,
            photoUrls: [url],
          ),
        );
        remote.failPhotoDelete = true;

        final failed = await service.performFullSync();
        final afterFailure = await db.isar.activityEntrys.where().findFirst();
        remote.failPhotoDelete = false;
        final retried = await service.performFullSync();
        final afterRetry = await db.isar.activityEntrys.where().findFirst();

        expect(failed.isSuccess, isFalse);
        expect(afterFailure?.pendingPhotoDeleteUrls, [url]);
        expect(retried.isSuccess, isTrue);
        expect(remote.deletePhotoCalls, 2);
        expect(remote.deletedPhotoUrls, [url]);
        expect(afterRetry?.pendingPhotoDeleteUrls, isEmpty);
      },
    );
  });
}

Future<ActivityEntry> _putEntry(
  Isar isar, {
  required String syncId,
  required int updatedAt,
  String name = 'Работа',
  int startedAt = 0,
  int endedAt = 3600000,
  bool isDeleted = false,
  List<String>? photoPaths,
  List<String>? pendingPhotoDeleteUrls,
}) async {
  final entry = ActivityEntry()
    ..syncId = syncId
    ..updatedAt = updatedAt
    ..name = name
    ..categoryKey = 'work'
    ..startedAt = startedAt
    ..endedAt = endedAt
    ..durationSeconds = ((endedAt - startedAt) / 1000).floor()
    ..dateKey = '2026-01-01'
    ..isDeleted = isDeleted
    ..photoPaths = photoPaths
    ..pendingPhotoDeleteUrls = pendingPhotoDeleteUrls;
  await isar.writeTxn(() => isar.activityEntrys.put(entry));
  return entry;
}

Map<String, dynamic> _remoteRow({
  int id = 1,
  required String syncId,
  required int updatedAt,
  String name = 'Работа',
  int startedAt = 0,
  int endedAt = 3600000,
  bool isDeleted = false,
  List<String>? photoUrls,
}) {
  return {
    'id': id,
    'sync_id': syncId,
    'user_id': 'user-a',
    'name': name,
    'category_key': 'work',
    'started_at': startedAt,
    'ended_at': endedAt,
    'duration_seconds': ((endedAt - startedAt) / 1000).floor(),
    'date_key': '2026-01-01',
    'is_deleted': isDeleted,
    'photo_urls': photoUrls,
    'updated_at': DateTime.fromMillisecondsSinceEpoch(
      updatedAt,
      isUtc: true,
    ).toIso8601String(),
  };
}
