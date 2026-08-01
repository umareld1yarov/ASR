import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

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
    ], directory: dir.path);

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
