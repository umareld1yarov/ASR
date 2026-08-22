import 'dart:io';

import 'package:asr/features/backup/data/sync_ownership_store.dart';
import 'package:asr/features/backup/data/sync_remote_gateway.dart';

class FakeSyncRemoteGateway implements SyncRemoteGateway {
  @override
  bool isAvailable = true;

  @override
  String? currentUserId = 'user-a';

  final List<Map<String, dynamic>> activityEntries = [];
  final List<Map<String, dynamic>> goals = [];
  final List<Map<String, dynamic>> uploadedActivityPayloads = [];
  final List<Map<String, dynamic>> uploadedGoalPayloads = [];
  Map<String, dynamic>? uploadedProfile;

  int fetchActivityCalls = 0;
  int upsertActivityCalls = 0;
  int fetchGoalsCalls = 0;
  int upsertGoalsCalls = 0;
  int uploadPhotoCalls = 0;
  int deletePhotoCalls = 0;
  final List<String> deletedPhotoUrls = [];

  Object? fetchActivityError;
  Object? upsertActivityError;
  bool failPhotoUpload = false;
  bool failPhotoDelete = false;

  @override
  Future<List<Map<String, dynamic>>> fetchActivityEntries(String userId) async {
    fetchActivityCalls++;
    if (fetchActivityError != null) throw fetchActivityError!;
    return [for (final row in activityEntries) Map<String, dynamic>.from(row)];
  }

  @override
  Future<void> upsertActivityEntries(
    String userId,
    List<Map<String, dynamic>> payload,
  ) async {
    upsertActivityCalls++;
    if (upsertActivityError != null) throw upsertActivityError!;
    for (final raw in payload) {
      final row = Map<String, dynamic>.from(raw);
      uploadedActivityPayloads.add(row);
      final index = activityEntries.indexWhere(
        (existing) =>
            existing['user_id'] == userId &&
            existing['sync_id'] == row['sync_id'],
      );
      if (index == -1) {
        activityEntries.add(row);
      } else {
        activityEntries[index] = row;
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchGoals(String userId) async {
    fetchGoalsCalls++;
    return [for (final row in goals) Map<String, dynamic>.from(row)];
  }

  @override
  Future<void> upsertGoals(
    String userId,
    List<Map<String, dynamic>> payload,
  ) async {
    upsertGoalsCalls++;
    uploadedGoalPayloads.addAll(
      payload.map((row) => Map<String, dynamic>.from(row)),
    );
  }

  @override
  Future<void> upsertUserProfile(
    String userId,
    Map<String, dynamic> payload,
  ) async {
    uploadedProfile = Map<String, dynamic>.from(payload);
  }

  @override
  Future<String?> uploadActivityPhoto(File file, String userId) async {
    uploadPhotoCalls++;
    if (failPhotoUpload) return null;
    return 'https://example.test/$userId/${file.uri.pathSegments.last}';
  }

  @override
  Future<void> deleteActivityPhotos(
    String userId,
    List<String> remoteUrls,
  ) async {
    deletePhotoCalls++;
    if (failPhotoDelete) throw Exception('photo delete failed');
    deletedPhotoUrls.addAll(remoteUrls);
  }
}

class MemorySyncOwnershipStore implements SyncOwnershipStore {
  String? ownerId;
  int bindCalls = 0;

  MemorySyncOwnershipStore({this.ownerId});

  @override
  Future<String?> readOwnerId() async => ownerId;

  @override
  Future<void> bindTo(String userId) async {
    bindCalls++;
    ownerId = userId;
  }
}
