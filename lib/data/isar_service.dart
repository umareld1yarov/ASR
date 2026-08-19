import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../features/profile/domain/models/goal.dart';
import '../features/profile/domain/models/user_profile.dart';
import '../features/timer/domain/models/activity_entry.dart';
import '../features/timer/domain/models/current_activity.dart';

/// Единая точка инициализации Isar.
/// Аналог getDb() из storage.js — там тоже был синглтон-промис на всё приложение.
class IsarService {
  IsarService._();

  static Isar? _instance;

  /// Открыть (или вернуть уже открытую) базу.
  /// Вызывается один раз при старте приложения, до runApp.
  static Future<Isar> open() async {
    if (_instance != null) return _instance!;

    final dir = await getApplicationDocumentsDirectory();

    _instance = await Isar.open([
      ActivityEntrySchema,
      CurrentActivitySchema,
      UserProfileSchema,
      GoalSchema,
    ], directory: dir.path);

    // Ленивая локальная миграция: старые записи получают глобальный UUID и
    // реальное время изменения без потери существующих данных.
    final entries = await _instance!.activityEntrys.where().findAll();
    final needsMigration = entries.any(
      (entry) => entry.syncId.isEmpty || entry.updatedAt == 0,
    );
    if (needsMigration) {
      const uuid = Uuid();
      await _instance!.writeTxn(() async {
        for (final entry in entries) {
          if (entry.syncId.isEmpty) entry.syncId = uuid.v4();
          if (entry.updatedAt == 0) {
            entry.updatedAt = entry.endedAt > 0
                ? entry.endedAt
                : DateTime.now().millisecondsSinceEpoch;
          }
          await _instance!.activityEntrys.put(entry);
        }
      });
    }

    return _instance!;
  }

  /// Доступ к уже открытой базе — бросит исключение, если open() не вызывался.
  static Isar get instance {
    if (_instance == null) {
      throw StateError(
        'Isar не инициализирован. Вызови IsarService.open() перед стартом приложения.',
      );
    }
    return _instance!;
  }
}
