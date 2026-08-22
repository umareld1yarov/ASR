import 'package:asr/features/backup/data/sync_remote_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('activityPhotoStoragePathFromUrl', () {
    test('извлекает путь только из папки текущего пользователя', () {
      const url =
          'https://project.supabase.co/storage/v1/object/public/activity_photos/user-a/photo.jpg';

      expect(
        activityPhotoStoragePathFromUrl(url, 'user-a'),
        'user-a/photo.jpg',
      );
    });

    test('не разрешает удалить фотографию другого пользователя', () {
      const url =
          'https://project.supabase.co/storage/v1/object/public/activity_photos/user-b/private.jpg';

      expect(activityPhotoStoragePathFromUrl(url, 'user-a'), isNull);
    });

    test('отклоняет другой bucket и невалидные ссылки', () {
      expect(
        activityPhotoStoragePathFromUrl(
          'https://project.supabase.co/storage/v1/object/public/avatars/user-a/photo.jpg',
          'user-a',
        ),
        isNull,
      );
      expect(
        activityPhotoStoragePathFromUrl('local/photo.jpg', 'user-a'),
        isNull,
      );
    });
  });
}
