import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/features/profile/data/profile_repository.dart';
import 'package:asr/features/profile/domain/models/user_profile.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('ProfileRepository', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late ProfileRepository repository;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'profile_repo_test');
      isar = dbHandle.isar;
      repository = ProfileRepository(isar);
    });

    tearDown(() async {
      await dbHandle.dispose();
    });

    test('getProfile возвращает дефолтный UserProfile при пустой базе', () async {
      final profile = await repository.getProfile();
      expect(profile.name, equals('User'));
      expect(profile.avatarPath, isNull);
      expect(profile.missionStatement, isNull);
      expect(profile.isPro, isFalse);
    });

    test('updateProfile создаёт и обновляет запись профиля', () async {
      await repository.updateProfile(
        name: 'Алихан',
        avatarPath: 'avatars/me.jpg',
        missionStatement: 'Стать лучшей версией себя',
      );

      var profile = await repository.getProfile();
      expect(profile.name, equals('Алихан'));
      expect(profile.avatarPath, equals('avatars/me.jpg'));
      expect(profile.missionStatement, equals('Стать лучшей версией себя'));

      // Частичное обновление
      await repository.updateProfile(name: 'Алихан Обновленный');

      profile = await repository.getProfile();
      expect(profile.name, equals('Алихан Обновленный'));
      expect(profile.avatarPath, equals('avatars/me.jpg')); // avatar не стёрся
      expect(profile.missionStatement, equals('Стать лучшей версией себя'));

      // В базе ровно одна запись с id 0
      final count = await isar.userProfiles.where().count();
      expect(count, equals(1));
    });
  });
}
