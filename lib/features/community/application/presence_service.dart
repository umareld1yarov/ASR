import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../timer/application/timer_provider.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Сервис трансляции текущего фокуса пользователя в облако Supabase для друзей.
class PresenceService {
  PresenceService(this._ref) {
    _init();
  }

  final Ref _ref;
  Timer? _heartbeatTimer;

  void _init() {
    // Слушаем изменение текущей активности таймера
    _ref.listen(currentActivityProvider, (_, next) {
      next.whenData((activity) {
        if (activity != null) {
          _updatePresence(
            activityName: activity.name,
            categoryKey: activity.categoryKey,
            startedAt: activity.startedAt,
          );
        }
      });
    });

    // Периодический heartbeat раз в 5 минут
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final curr = _ref.read(currentActivityProvider).asData?.value;
      if (curr != null) {
        _updatePresence(
          activityName: curr.name,
          categoryKey: curr.categoryKey,
          startedAt: curr.startedAt,
        );
      }
    });
  }

  Future<void> _updatePresence({
    required String activityName,
    required String categoryKey,
    required int startedAt,
  }) async {
    final client = SupabaseService.client;
    if (client == null) return;

    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      await client.from('live_presence').upsert({
        'user_id': user.id,
        'activity_name': activityName,
        'category_key': categoryKey,
        'started_at': startedAt,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('[PresenceService] Ошибка обновления Live Presence: $e');
      }
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
  }
}
