import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';

String? activityPhotoStoragePathFromUrl(String rawUrl, String userId) {
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  final segments = uri.pathSegments;
  final bucketIndex = segments.indexOf('activity_photos');
  if (bucketIndex == -1 || bucketIndex + 2 >= segments.length) return null;
  final storageSegments = segments.sublist(bucketIndex + 1);
  if (storageSegments.first != userId) return null;
  return storageSegments.join('/');
}

/// Минимальный контракт облака, необходимый синхронизации.
///
/// Production-реализация использует Supabase, а тесты подменяют этот шлюз
/// полностью локальной fake-реализацией без сети и реальных аккаунтов.
abstract interface class SyncRemoteGateway {
  bool get isAvailable;

  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchActivityEntries(String userId);

  Future<void> upsertActivityEntries(
    String userId,
    List<Map<String, dynamic>> payload,
  );

  Future<List<Map<String, dynamic>>> fetchGoals(String userId);

  Future<void> upsertGoals(String userId, List<Map<String, dynamic>> payload);

  Future<void> upsertUserProfile(String userId, Map<String, dynamic> payload);

  Future<String?> uploadActivityPhoto(File file, String userId);

  Future<void> deleteActivityPhotos(String userId, List<String> remoteUrls);
}

class SupabaseSyncRemoteGateway implements SyncRemoteGateway {
  SupabaseClient? get _client => SupabaseService.client;

  SupabaseClient get _requiredClient {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }
    return client;
  }

  @override
  bool get isAvailable => _client != null;

  @override
  String? get currentUserId =>
      _client?.auth.currentUser?.id ?? _client?.auth.currentSession?.user.id;

  @override
  Future<List<Map<String, dynamic>>> fetchActivityEntries(String userId) async {
    final rows = await _requiredClient
        .from('activity_entries')
        .select()
        .eq('user_id', userId);
    return [for (final row in rows) Map<String, dynamic>.from(row)];
  }

  @override
  Future<void> upsertActivityEntries(
    String userId,
    List<Map<String, dynamic>> payload,
  ) async {
    if (payload.isEmpty) return;
    await _requiredClient
        .from('activity_entries')
        .upsert(payload, onConflict: 'user_id,sync_id');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGoals(String userId) async {
    final rows = await _requiredClient
        .from('goals')
        .select()
        .eq('user_id', userId);
    return [for (final row in rows) Map<String, dynamic>.from(row)];
  }

  @override
  Future<void> upsertGoals(
    String userId,
    List<Map<String, dynamic>> payload,
  ) async {
    if (payload.isEmpty) return;
    await _requiredClient
        .from('goals')
        .upsert(payload, onConflict: 'id, user_id');
  }

  @override
  Future<void> upsertUserProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    await _requiredClient.from('user_profiles').upsert(payload);
  }

  @override
  Future<String?> uploadActivityPhoto(File file, String userId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';
    final storage = _requiredClient.storage.from('activity_photos');
    await storage.upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );
    return storage.getPublicUrl(path);
  }

  @override
  Future<void> deleteActivityPhotos(
    String userId,
    List<String> remoteUrls,
  ) async {
    final paths = <String>[];
    for (final rawUrl in remoteUrls) {
      final storagePath = activityPhotoStoragePathFromUrl(rawUrl, userId);
      if (storagePath != null) paths.add(storagePath);
    }
    if (paths.isEmpty) return;
    await _requiredClient.storage.from('activity_photos').remove(paths);
  }
}
