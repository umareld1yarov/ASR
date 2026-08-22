import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../../../data/isar_service.dart';
import '../../feed/data/photo_cache_service.dart';
import '../../profile/domain/models/goal.dart';
import '../../profile/domain/models/user_profile.dart';
import '../../timer/domain/models/activity_entry.dart';
import 'sync_ownership_store.dart';
import 'sync_remote_gateway.dart';

class SyncResult {
  final bool isSuccess;
  final int syncedEntries;
  final int syncedGoals;
  final String? message;

  const SyncResult({
    required this.isSuccess,
    this.syncedEntries = 0,
    this.syncedGoals = 0,
    this.message,
  });
}

abstract interface class SyncService {
  Future<SyncResult> performFullSync();
}

/// Сервис фоновой оффлайн-первой синхронизации между Isar DB и Supabase.
class CloudSyncService implements SyncService {
  CloudSyncService({
    SyncRemoteGateway? remoteGateway,
    Isar? isar,
    SyncOwnershipStore? ownershipStore,
    PhotoCacheService? photoCacheService,
  }) : _remote = remoteGateway ?? SupabaseSyncRemoteGateway(),
       _providedIsar = isar,
       _ownershipStore =
           ownershipStore ?? SharedPreferencesSyncOwnershipStore(),
       _photoCacheService = photoCacheService ?? PhotoCacheService.instance;

  final SyncRemoteGateway _remote;
  final Isar? _providedIsar;
  final SyncOwnershipStore _ownershipStore;
  final PhotoCacheService _photoCacheService;

  Isar get _isar => _providedIsar ?? IsarService.instance;

  /// Запуск полного цикла двусторонней синхронизации.
  @override
  Future<SyncResult> performFullSync() async {
    if (!_remote.isAvailable) {
      return SyncResult(isSuccess: false, message: 'sync.not_initialized'.tr());
    }

    final userId = _remote.currentUserId;
    if (userId == null) {
      return SyncResult(
        isSuccess: false,
        message: 'sync.not_authenticated'.tr(),
      );
    }

    try {
      final ownerId = await _ownershipStore.readOwnerId();
      if (ownerId != null && ownerId != userId) {
        return SyncResult(
          isSuccess: false,
          message: 'sync.account_mismatch'.tr(),
        );
      }
      if (ownerId == null) {
        // Привязываем до первого сетевого изменения: даже частично успешная
        // синхронизация не должна позволить затем отправить базу в другой аккаунт.
        await _ownershipStore.bindTo(userId);
      }

      // 1. Выгрузка и загрузка записей активностей (ActivityEntry)
      final syncedEntriesCount = await _syncActivityEntries(userId);

      // 2. Выгрузка и загрузка целей (Goal)
      final syncedGoalsCount = await _syncGoals(userId);

      // 3. Синхронизация профиля пользователя (UserProfile)
      await _syncUserProfile(userId);

      return SyncResult(
        isSuccess: true,
        syncedEntries: syncedEntriesCount,
        syncedGoals: syncedGoalsCount,
        message: 'sync.success'.tr(),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CloudSyncService] Ошибка синхронизации: $e\n$stack');
      }
      return SyncResult(
        isSuccess: false,
        message: 'sync.error'.tr(args: ['$e']),
      );
    }
  }

  /// Синхронизация записей активностей (ActivityEntry)
  Future<int> _syncActivityEntries(String userId) async {
    var localEntries = await _isar.activityEntrys.where().findAll();
    final remoteData = await _remote.fetchActivityEntries(userId);

    int remoteUpdatedAt(Map<String, dynamic> row) =>
        DateTime.tryParse(
          row['updated_at']?.toString() ?? '',
        )?.millisecondsSinceEpoch ??
        0;

    final remoteBySyncId = <String, Map<String, dynamic>>{
      for (final raw in remoteData)
        if ((raw['sync_id']?.toString() ?? '').isNotEmpty)
          raw['sync_id'].toString(): Map<String, dynamic>.from(raw),
    };

    // Одноразовая совместимость со старыми данными: после SQL-миграции облачная
    // строка уже имеет UUID, а старая локальная запись получила свой UUID.
    // Если прежний числовой id и сам интервал совпадают, принимаем облачный UUID.
    await _isar.writeTxn(() async {
      for (final local in localEntries) {
        if (remoteBySyncId.containsKey(local.syncId)) continue;
        final legacyMatch = remoteData.cast<Map<String, dynamic>?>().firstWhere(
          (row) =>
              row != null &&
              row['id'] == local.id &&
              row['started_at'] == local.startedAt &&
              row['ended_at'] == local.endedAt &&
              (row['sync_id']?.toString() ?? '').isNotEmpty,
          orElse: () => null,
        );
        if (legacyMatch != null) {
          local.syncId = legacyMatch['sync_id'].toString();
          await _isar.activityEntrys.put(local);
        }
      }
    });
    localEntries = await _isar.activityEntrys.where().findAll();
    final localBySyncId = {for (final e in localEntries) e.syncId: e};
    final removedRemotePhotoUrls = <String>{};

    // Сначала применяем отсутствующие или более новые облачные версии.
    await _isar.writeTxn(() async {
      for (final raw in remoteData) {
        final row = Map<String, dynamic>.from(raw);
        final syncId = row['sync_id']?.toString() ?? '';
        if (syncId.isEmpty) continue;
        var entry = localBySyncId[syncId];
        if (entry != null && entry.updatedAt >= remoteUpdatedAt(row)) continue;
        entry ??= ActivityEntry()..syncId = syncId;
        entry.name = row['name'] ?? '';
        entry.categoryKey = row['category_key'] ?? '';
        entry.startedAt = row['started_at'] ?? 0;
        entry.endedAt = row['ended_at'] ?? 0;
        entry.durationSeconds = row['duration_seconds'] ?? 0;
        entry.dateKey = row['date_key'] ?? '';
        entry.isDeleted = row['is_deleted'] ?? false;
        entry.mood = row['mood'];
        entry.obstacles = (row['obstacles'] as List?)?.cast<String>();
        entry.nextExperiment = row['next_experiment'];
        entry.note = row['note'];
        entry.updatedAt = remoteUpdatedAt(row);
        final previousPhotos = List<String>.from(entry.photoPaths ?? const []);
        final remotePhotos =
            (row['photo_urls'] as List?)?.cast<String>() ?? <String>[];
        entry.photoPaths = remotePhotos;
        removedRemotePhotoUrls.addAll(
          previousPhotos.where(
            (photo) =>
                PhotoCacheService.isRemoteSource(photo) &&
                !remotePhotos.contains(photo),
          ),
        );
        await _isar.activityEntrys.put(entry);
      }
    });
    for (final removedUrl in removedRemotePhotoUrls) {
      await _photoCacheService.deleteCachedCopy(removedUrl);
    }

    // Затем выгружаем только новые или действительно более свежие локальные
    // версии. Сама синхронизация updatedAt не меняет.
    localEntries = await _isar.activityEntrys.where().findAll();
    final payload = <Map<String, dynamic>>[];
    final normalizedPhotosByEntryId = <int, List<String>>{};
    var hadPhotoUploadFailure = false;
    for (final e in localEntries) {
      final remote = remoteBySyncId[e.syncId];
      if (remote != null && e.updatedAt <= remoteUpdatedAt(remote)) continue;
      List<String>? remotePhotoUrls = e.photoPaths != null
          ? List<String>.from(e.photoPaths!)
          : null;
      var photoUploadFailed = false;

      // Если есть локальные фото, пробуем загрузить новые в Supabase Storage
      if (remotePhotoUrls != null && remotePhotoUrls.isNotEmpty) {
        final updatedUrls = <String>[];
        for (final path in remotePhotoUrls) {
          if (path.startsWith('http://') || path.startsWith('https://')) {
            updatedUrls.add(path);
          } else {
            final file = File(path);
            if (file.existsSync()) {
              final cloudUrl = await uploadPhoto(file, userId);
              if (cloudUrl == null) {
                photoUploadFailed = true;
                break;
              }
              await _photoCacheService.seed(cloudUrl, file);
              updatedUrls.add(cloudUrl);
            } else {
              // Локальный путь другого устройства нельзя сохранять в облаке.
              // Оставляем запись несинхронизированной, чтобы повторить попытку
              // после восстановления файла или сети.
              photoUploadFailed = true;
              break;
            }
          }
        }
        remotePhotoUrls = updatedUrls;
      }

      if (photoUploadFailed) {
        hadPhotoUploadFailure = true;
        continue;
      }

      if (remotePhotoUrls != null &&
          !listEquals(remotePhotoUrls, e.photoPaths)) {
        normalizedPhotosByEntryId[e.id] = remotePhotoUrls;
      }

      payload.add({
        'sync_id': e.syncId,
        'id': e.id,
        'user_id': userId,
        'name': e.name,
        'category_key': e.categoryKey,
        'started_at': e.startedAt,
        'ended_at': e.endedAt,
        'duration_seconds': e.durationSeconds,
        'date_key': e.dateKey,
        'is_deleted': e.isDeleted,
        'mood': e.mood,
        'obstacles': e.obstacles,
        'next_experiment': e.nextExperiment,
        'note': e.note,
        'photo_urls': remotePhotoUrls,
        'updated_at': DateTime.fromMillisecondsSinceEpoch(
          e.updatedAt,
          isUtc: true,
        ).toIso8601String(),
      });
    }
    if (payload.isNotEmpty) {
      await _remote.upsertActivityEntries(userId, payload);
      if (normalizedPhotosByEntryId.isNotEmpty) {
        await _isar.writeTxn(() async {
          for (final item in normalizedPhotosByEntryId.entries) {
            final entry = await _isar.activityEntrys.get(item.key);
            if (entry == null) continue;
            entry.photoPaths = item.value;
            // updatedAt намеренно не меняется: путь был нормализован самой
            // синхронизацией, пользовательские данные не редактировались.
            await _isar.activityEntrys.put(entry);
          }
        });
      }
    }

    // Удаление файла из Storage отделено от удаления ссылки из записи.
    // Очередь остаётся в Isar до подтверждённого ответа облака и переживает
    // отсутствие сети, перезапуск приложения и частично успешный sync.
    final entriesWithPendingDeletes = await _isar.activityEntrys
        .filter()
        .pendingPhotoDeleteUrlsIsNotEmpty()
        .findAll();
    final urlsToDelete = <String>{};
    final resolvedPendingByEntryId = <int, Set<String>>{};
    for (final entry in entriesWithPendingDeletes) {
      final referencedPhotos = entry.photoPaths ?? const <String>[];
      for (final url in entry.pendingPhotoDeleteUrls ?? const <String>[]) {
        resolvedPendingByEntryId
            .putIfAbsent(entry.id, () => <String>{})
            .add(url);
        if (!referencedPhotos.contains(url)) urlsToDelete.add(url);
      }
    }
    if (urlsToDelete.isNotEmpty) {
      await _remote.deleteActivityPhotos(userId, urlsToDelete.toList());
      for (final url in urlsToDelete) {
        await _photoCacheService.deleteCachedCopy(url);
      }
    }
    if (resolvedPendingByEntryId.isNotEmpty) {
      await _isar.writeTxn(() async {
        for (final item in resolvedPendingByEntryId.entries) {
          final entry = await _isar.activityEntrys.get(item.key);
          if (entry == null) continue;
          final pending = List<String>.from(
            entry.pendingPhotoDeleteUrls ?? const [],
          )..removeWhere(item.value.contains);
          entry.pendingPhotoDeleteUrls = pending;
          await _isar.activityEntrys.put(entry);
        }
      });
    }
    if (hadPhotoUploadFailure) {
      throw StateError('One or more activity photos could not be uploaded');
    }

    return localEntries.length;
  }

  /// Синхронизация целей (Goal)
  Future<int> _syncGoals(String userId) async {
    final localGoals = await _isar.goals.where().findAll();

    if (localGoals.isNotEmpty) {
      final payload = localGoals.map((g) {
        return {
          'id': g.id,
          'user_id': userId,
          'category_key': g.categoryKey,
          'activity_name': g.activityName,
          'target_seconds': g.targetSeconds,
          'period_type': g.periodType,
          'created_at': g.createdAt,
          'is_archived': g.isArchived,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      await _remote.upsertGoals(userId, payload);
    }

    final remoteGoals = await _remote.fetchGoals(userId);

    if (remoteGoals.isNotEmpty) {
      await _isar.writeTxn(() async {
        for (final row in remoteGoals) {
          final id = row['id'] as int;
          var goal = await _isar.goals.get(id);
          goal ??= Goal()..id = id;

          goal.categoryKey = row['category_key'] ?? '';
          goal.activityName = row['activity_name'];
          goal.targetSeconds = row['target_seconds'] ?? 0;
          goal.periodType = row['period_type'] ?? 'month';
          goal.createdAt = row['created_at'] ?? 0;
          goal.isArchived = row['is_archived'] ?? false;

          await _isar.goals.put(goal);
        }
      });
    }

    return localGoals.length;
  }

  /// Синхронизация профиля пользователя (UserProfile)
  Future<void> _syncUserProfile(String userId) async {
    final profile = await _isar.userProfiles.get(0);
    if (profile != null) {
      await _remote.upsertUserProfile(userId, {
        'id': userId,
        'display_name': profile.name,
        'avatar_url': profile.avatarPath,
        'mission_statement': profile.missionStatement,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Загрузка фото в Supabase Storage (Private / Public Bucket)
  Future<String?> uploadPhoto(File file, String userId) async {
    try {
      return await _remote.uploadActivityPhoto(file, userId);
    } catch (e) {
      if (kDebugMode) {
        print('[CloudSyncService] Ошибка загрузки фото: $e');
      }
      return null;
    }
  }
}
