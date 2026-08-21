import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/features/profile/domain/models/goal.dart';
import 'package:asr/features/profile/domain/models/user_profile.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import 'package:asr/features/timer/domain/models/current_activity.dart';

int _testDbCounter = 0;
bool _isarCoreInitialized = false;

/// Находит путь к нативной библиотеке Isar (libisar.dll) из установленного пакета isar_community_flutter_libs.
String? _resolveIsarLibraryPath() {
  // 1. Пробуем прочитать путь из .dart_tool/package_config.json
  final packageConfigFile = File('.dart_tool/package_config.json');
  if (packageConfigFile.existsSync()) {
    try {
      final config = jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
      final packages = config['packages'] as List<dynamic>?;
      if (packages != null) {
        for (final pkg in packages) {
          if (pkg is Map<String, dynamic> && pkg['name'] == 'isar_community_flutter_libs') {
            final rootUriStr = pkg['rootUri'] as String? ?? '';
            final rootUri = Uri.parse(rootUriStr);
            final pkgPath = rootUri.toFilePath(windows: Platform.isWindows);

            if (Platform.isWindows) {
              final dllCandidate1 = File('$pkgPath\\windows\\libisar.dll');
              if (dllCandidate1.existsSync()) return dllCandidate1.absolute.path;
              final dllCandidate2 = File('$pkgPath\\windows\\isar.dll');
              if (dllCandidate2.existsSync()) return dllCandidate2.absolute.path;
            } else if (Platform.isLinux) {
              final soCandidate = File('$pkgPath/linux/libisar.so');
              if (soCandidate.existsSync()) return soCandidate.absolute.path;
            } else if (Platform.isMacOS) {
              final dylibCandidate = File('$pkgPath/macos/libisar.dylib');
              if (dylibCandidate.existsSync()) return dylibCandidate.absolute.path;
            }
          }
        }
      }
    } catch (_) {
      // Игнорируем ошибки парсинга и переходим к проверке локальных путей
    }
  }

  // 2. Проверка альтернативных локальных путей проекта
  final projectCandidates = [
    'windows/libisar.dll',
    'windows/isar.dll',
    'libisar.dll',
    'isar.dll',
  ];

  for (final candidate in projectCandidates) {
    final file = File(candidate);
    if (file.existsSync()) return file.absolute.path;
  }

  return null;
}

/// Инициализирует Isar Core локально без обращения к интернету.
Future<void> initTestIsarCore() async {
  if (_isarCoreInitialized) return;

  TestWidgetsFlutterBinding.ensureInitialized();

  final libraryPath = _resolveIsarLibraryPath();

  if (libraryPath == null) {
    throw StateError(
      'Локальная нативная библиотека Isar (libisar.dll / libisar.so) не найдена. '
      'Убедитесь, что выполнен `flutter pub get` и пакет `isar_community_flutter_libs: ^3.3.2` доступен. '
      'Автоматическое скачивание из сети отключено для изоляции тестов.',
    );
  }

  if (Platform.isWindows) {
    await Isar.initializeIsarCore(
      download: false,
      libraries: {
        Abi.windowsX64: libraryPath,
        Abi.windowsIA32: libraryPath,
        Abi.windowsArm64: libraryPath,
      },
    );
  } else if (Platform.isLinux) {
    await Isar.initializeIsarCore(
      download: false,
      libraries: {
        Abi.linuxX64: libraryPath,
        Abi.linuxArm64: libraryPath,
      },
    );
  } else if (Platform.isMacOS) {
    await Isar.initializeIsarCore(
      download: false,
      libraries: {
        Abi.macosX64: libraryPath,
        Abi.macosArm64: libraryPath,
      },
    );
  } else {
    await Isar.initializeIsarCore(download: false);
  }

  _isarCoreInitialized = true;
}

class TestDbHandle {
  final Isar isar;
  final Directory directory;

  TestDbHandle({required this.isar, required this.directory});

  /// Закрывает базу Isar и удаляет временный каталог с повторными попытками на Windows.
  Future<void> dispose() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }

    if (directory.existsSync()) {
      var deleted = false;
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          if (!directory.existsSync()) {
            deleted = true;
            break;
          }
          await directory.delete(recursive: true);
          deleted = true;
          break;
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      if (!deleted && directory.existsSync()) {
        stderr.writeln(
          'Предупреждение: не удалось удалить временную папку тестовой базы: ${directory.absolute.path}',
        );
      }
    }
  }
}

/// Создаёт изолированную базу Isar в отдельной временной папке для каждого теста.
Future<TestDbHandle> createTestIsar({String? prefix}) async {
  await initTestIsarCore();

  _testDbCounter++;
  final uniqueName = '${prefix ?? "test_db"}_${DateTime.now().microsecondsSinceEpoch}_$_testDbCounter';
  final tempDir = await Directory.systemTemp.createTemp('isar_${uniqueName}_');

  final isar = await Isar.open(
    [
      ActivityEntrySchema,
      CurrentActivitySchema,
      UserProfileSchema,
      GoalSchema,
    ],
    directory: tempDir.path,
    name: uniqueName,
  );

  return TestDbHandle(isar: isar, directory: tempDir);
}
