import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../../../data/isar_service.dart';
import '../../profile/domain/models/goal.dart';
import '../../profile/domain/models/user_profile.dart';
import '../../timer/domain/models/activity_entry.dart';

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

/// Сервис фоновой оффлайн-первой синхронизации между Isar DB и Supabase.
class CloudSyncService {
  CloudSyncService();

  SupabaseClient? get _supabase => SupabaseService.client;
  Isar get _isar => IsarService.instance;

  /// Запуск полного цикла двусторонней синхронизации.
  Future<SyncResult> performFullSync() async {
    final client = _supabase;
    if (client == null) {
      return const SyncResult(
        isSuccess: false,
        message: 'Supabase не инициализирован (проверьте .env)',
      );
    }

    final currentUser =
        client.auth.currentUser ?? client.auth.currentSession?.user;
    if (currentUser == null) {
      return const SyncResult(
        isSuccess: false,
        message:
            'Пользователь не авторизован в облаке (войдите по Email и Паролю)',
      );
    }

    try {
      final userId = currentUser.id;

      // 1. Выгрузка и загрузка записей активностей (ActivityEntry)
      final syncedEntriesCount = await _syncActivityEntries(client, userId);

      // 2. Выгрузка и загрузка целей (Goal)
      final syncedGoalsCount = await _syncGoals(client, userId);

      // 3. Синхронизация профиля пользователя (UserProfile)
      await _syncUserProfile(client, userId);

      return SyncResult(
        isSuccess: true,
        syncedEntries: syncedEntriesCount,
        syncedGoals: syncedGoalsCount,
        message: 'Синхронизация завершена успешно!',
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('[CloudSyncService] Ошибка синхронизации: $e\n$stack');
      }
      return SyncResult(isSuccess: false, message: 'Ошибка синхронизации: $e');
    }
  }

  /// Синхронизация записей активностей (ActivityEntry)
  Future<int> _syncActivityEntries(SupabaseClient client, String userId) async {
    var localEntries = await _isar.activityEntrys.where().findAll();
    final remoteData = await client
        .from('activity_entries')
        .select()
        .eq('user_id', userId);

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
        if (row['photo_urls'] != null) {
          entry.photoPaths = (row['photo_urls'] as List?)?.cast<String>();
        }
        await _isar.activityEntrys.put(entry);
      }
    });

    // Затем выгружаем только новые или действительно более свежие локальные
    // версии. Сама синхронизация updatedAt не меняет.
    localEntries = await _isar.activityEntrys.where().findAll();
    final payload = <Map<String, dynamic>>[];
    for (final e in localEntries) {
      final remote = remoteBySyncId[e.syncId];
      if (remote != null && e.updatedAt <= remoteUpdatedAt(remote)) continue;
      List<String>? remotePhotoUrls = e.photoPaths != null
          ? List<String>.from(e.photoPaths!)
          : null;

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
              updatedUrls.add(cloudUrl ?? path);
            } else {
              updatedUrls.add(path);
            }
          }
        }
        remotePhotoUrls = updatedUrls;
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
      await client
          .from('activity_entries')
          .upsert(payload, onConflict: 'user_id,sync_id');
    }

    return localEntries.length;
  }

  /// Синхронизация целей (Goal)
  Future<int> _syncGoals(SupabaseClient client, String userId) async {
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

      await client.from('goals').upsert(payload, onConflict: 'id, user_id');
    }

    final remoteGoals = await client
        .from('goals')
        .select()
        .eq('user_id', userId);

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
  Future<void> _syncUserProfile(SupabaseClient client, String userId) async {
    final profile = await _isar.userProfiles.get(0);
    if (profile != null) {
      await client.from('user_profiles').upsert({
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
    final client = _supabase;
    if (client == null) return null;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    try {
      await client.storage
          .from('activity_photos')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));
      return client.storage.from('activity_photos').getPublicUrl(path);
    } catch (e) {
      if (kDebugMode) {
        print('[CloudSyncService] Ошибка загрузки фото: $e');
      }
      return null;
    }
  }
}
