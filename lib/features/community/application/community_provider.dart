import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/community_repository.dart';
import '../data/mock_community_repository.dart';
import '../domain/models/community_user.dart';
import '../domain/models/friendship.dart';
import '../domain/models/sharing_permission.dart';

/// Провайдер репозитория Сообщества.
/// Сейчас — мок. Когда подключим Supabase, поменяется ТОЛЬКО эта строка
/// (на SupabaseCommunityRepository) — весь остальной код фичи не тронется.
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return MockCommunityRepository();
});

/// Счётчик изменений — увеличивается после любого действия
/// (заявка/принятие/удаление/смена permission), чтобы обновить зависимые
/// списки. Тот же паттерн, что entriesChangedProvider в Timer.
final communityChangedProvider = StateProvider<int>((ref) => 0);

/// Мой профиль в Сообществе.
final meProvider = FutureProvider<CommunityUser>((ref) async {
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getMe();
});

/// Список друзей (принятые заявки) + мои правила доступа для каждого.
final friendsProvider = FutureProvider<List<Friendship>>((ref) async {
  ref.watch(communityChangedProvider);
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getFriends();
});

/// Входящие заявки в друзья.
final incomingRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  ref.watch(communityChangedProvider);
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getIncomingRequests();
});

/// Исходящие заявки (жду ответа).
final outgoingRequestsProvider = FutureProvider<List<Friendship>>((ref) async {
  ref.watch(communityChangedProvider);
  final repo = ref.watch(communityRepositoryProvider);
  return repo.getOutgoingRequests();
});

/// Результаты поиска пользователей по username.
/// family — параметризован строкой запроса, autoDispose — чтобы не
/// накапливать кэш на каждый введённый символ.
final userSearchProvider = FutureProvider.family
    .autoDispose<List<CommunityUser>, String>((ref, query) async {
      final repo = ref.watch(communityRepositoryProvider);
      return repo.searchUsers(query);
    });

/// Live-статус конкретного друга (что мне разрешено видеть).
/// family — один и тот же провайдер переиспользуется на каждую карточку друга.
final friendActivityStatusProvider =
    FutureProvider.family<FriendActivityStatus?, String>((ref, friendId) async {
      ref.watch(communityChangedProvider);
      final repo = ref.watch(communityRepositoryProvider);
      return repo.getFriendActivityStatus(friendId);
    });

/// Контроллер действий Сообщества — все мутации + оповещение об изменениях.
class CommunityController {
  CommunityController(this._ref);

  final Ref _ref;

  CommunityRepository get _repo => _ref.read(communityRepositoryProvider);

  Future<void> sendFriendRequest(String userId) async {
    await _repo.sendFriendRequest(userId);
    _bump();
  }

  Future<void> acceptFriendRequest(String userId) async {
    await _repo.acceptFriendRequest(userId);
    _bump();
  }

  Future<void> declineFriendRequest(String userId) async {
    await _repo.declineFriendRequest(userId);
    _bump();
  }

  Future<void> removeFriend(String userId) async {
    await _repo.removeFriend(userId);
    _bump();
  }

  Future<void> updateSharingPermission(SharingPermission permission) async {
    await _repo.updateSharingPermission(permission);
    _bump();
  }

  void _bump() {
    _ref.read(communityChangedProvider.notifier).state++;
  }
}

final communityControllerProvider = Provider<CommunityController>((ref) {
  return CommunityController(ref);
});
