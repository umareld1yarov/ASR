import 'package:isar_community/isar.dart';

import '../domain/models/user_profile.dart';

/// Репозиторий локального профиля — ровно одна запись, как CurrentActivity.
class ProfileRepository {
  ProfileRepository(this._isar);

  final Isar _isar;

  Future<UserProfile> getProfile() async {
    final profile = await _isar.userProfiles.get(0);
    return profile ?? UserProfile();
  }

  Future<void> updateProfile({
    String? name,
    String? avatarPath,
    String? missionStatement,
  }) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.userProfiles.get(0);
      final profile = existing ?? UserProfile();
      if (name != null) profile.name = name;
      if (avatarPath != null) profile.avatarPath = avatarPath;
      if (missionStatement != null) profile.missionStatement = missionStatement;
      await _isar.userProfiles.put(profile);
    });
  }
}
