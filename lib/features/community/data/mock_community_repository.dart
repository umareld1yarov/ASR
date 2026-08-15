import 'dart:async';

import '../domain/models/community_user.dart';
import '../domain/models/friendship.dart';
import '../domain/models/sharing_permission.dart';
import 'community_repository.dart';

/// Реализация на in-memory моках — чтобы собрать и обкатать весь UI
/// Сообщества до подключения Supabase. Данные живут только в рамках
/// сессии приложения (сбрасываются при перезапуске).
class MockCommunityRepository implements CommunityRepository {
  final CommunityUser _me = const CommunityUser(
    id: 'me',
    username: 'me',
    displayName: 'Я',
  );

  final List<CommunityUser> _allUsers = const [
    CommunityUser(id: 'u1', username: 'anna_k', displayName: 'Анна'),
    CommunityUser(id: 'u2', username: 'max_dev', displayName: 'Максим'),
    CommunityUser(id: 'u3', username: 'lena_run', displayName: 'Лена'),
    CommunityUser(id: 'u4', username: 'dmitry_r', displayName: 'Дмитрий'),
  ];

  final Map<String, FriendshipStatus> _statuses = {
    'u1': FriendshipStatus.accepted,
    'u2': FriendshipStatus.accepted,
    'u3': FriendshipStatus.incomingPending,
  };

  final Map<String, SharingPermission> _myPermissions = {
    'u1': const SharingPermission(
      friendId: 'u1',
      scope: SharingScope.fullActivity,
    ),
    'u2': const SharingPermission(
      friendId: 'u2',
      scope: SharingScope.category,
    ),
  };

  @override
  Future<CommunityUser> getMe() async => _me;

  @override
  Future<List<Friendship>> getFriends() async {
    return _statuses.entries
        .where((e) => e.value == FriendshipStatus.accepted)
        .map((e) => _buildFriendship(e.key, e.value))
        .toList();
  }

  @override
  Future<List<Friendship>> getIncomingRequests() async {
    return _statuses.entries
        .where((e) => e.value == FriendshipStatus.incomingPending)
        .map((e) => _buildFriendship(e.key, e.value))
        .toList();
  }

  @override
  Future<List<Friendship>> getOutgoingRequests() async {
    return _statuses.entries
        .where((e) => e.value == FriendshipStatus.outgoingPending)
        .map((e) => _buildFriendship(e.key, e.value))
        .toList();
  }

  Friendship _buildFriendship(String userId, FriendshipStatus status) {
    final user = _allUsers.firstWhere((u) => u.id == userId);
    final permission =
        _myPermissions[userId] ??
        SharingPermission(friendId: userId, scope: SharingScope.none);
    return Friendship(
      friend: user,
      status: status,
      myPermissionForFriend: permission,
    );
  }

  @override
  Future<List<CommunityUser>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    return _allUsers
        .where(
          (u) =>
              u.username.toLowerCase().contains(lower) ||
              u.displayName.toLowerCase().contains(lower),
        )
        .where((u) => !_statuses.containsKey(u.id)) // скрыть уже друзей/заявки
        .toList();
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    _statuses[userId] = FriendshipStatus.outgoingPending;
  }

  @override
  Future<void> acceptFriendRequest(String userId) async {
    _statuses[userId] = FriendshipStatus.accepted;
    _myPermissions.putIfAbsent(
      userId,
      () => SharingPermission(friendId: userId, scope: SharingScope.none),
    );
  }

  @override
  Future<void> declineFriendRequest(String userId) async {
    _statuses.remove(userId);
  }

  @override
  Future<void> removeFriend(String userId) async {
    _statuses.remove(userId);
    _myPermissions.remove(userId);
  }

  @override
  Future<void> updateSharingPermission(SharingPermission permission) async {
    _myPermissions[permission.friendId] = permission;
  }

  @override
  Future<FriendActivityStatus?> getFriendActivityStatus(String friendId) async {
    // Моки: у "u1" (Анна, live) — фейковая активность прямо сейчас.
    if (friendId == 'u1') {
      return FriendActivityStatus(
        friendId: friendId,
        activityName: 'Читает книгу',
        categoryKey: 'growth',
        startedAt: DateTime.now()
            .subtract(const Duration(minutes: 27))
            .millisecondsSinceEpoch,
      );
    }
    // "u2" (Максим, category-доступ) — активность есть, но без имени,
    // только категория (имитация того, что сервер уже применил правило).
    if (friendId == 'u2') {
      return FriendActivityStatus(
        friendId: friendId,
        categoryKey: 'work',
        startedAt: DateTime.now()
            .subtract(const Duration(hours: 1, minutes: 5))
            .millisecondsSinceEpoch,
      );
    }
    return null;
  }

  @override
  Future<void> sendReaction({
    required String friendId,
    required String emoji,
  }) async {
    // В будущем тут вызов Supabase / Realtime сигнала
    return;
  }
}
