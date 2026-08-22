import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SyncOwnershipStore {
  Future<String?> readOwnerId();

  Future<void> bindTo(String userId);
}

/// Привязка защищает единую локальную базу приложения от случайной выгрузки
/// в другой аккаунт после выхода и повторного входа.
class SharedPreferencesSyncOwnershipStore implements SyncOwnershipStore {
  static const key = 'cloud_sync_owner_id';

  @override
  Future<String?> readOwnerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> bindTo(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, userId);
  }
}
