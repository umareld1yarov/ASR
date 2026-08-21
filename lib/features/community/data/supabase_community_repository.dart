import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';
import '../domain/models/community_user.dart';
import '../domain/models/friendship.dart';
import '../domain/models/sharing_permission.dart';
import 'community_repository.dart';

/// Реализация Сообщества поверх Supabase PostgreSQL + Realtime.
class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository();

  SupabaseClient? get _client => SupabaseService.client;
  User? get _currentUser => _client?.auth.currentUser;

  String get _myId {
    final user = _currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }
    return user.id;
  }

  @override
  Future<CommunityUser> getMe() async {
    final client = _client;
    if (client == null) throw Exception('Supabase не инициализирован');

    final userId = _myId;
    final res = await client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (res != null) {
      return CommunityUser(
        id: userId,
        username: res['username'] ?? 'user_${userId.substring(0, 5)}',
        displayName: res['display_name'] ?? res['name'] ?? 'ASR User',
        avatarUrl: res['avatar_url'],
      );
    }

    // Если профиль ещё не создан триггером, создаём его
    final emailName = _currentUser?.email?.split('@').first ?? 'user';
    final defaultUsername = '${emailName}_${userId.substring(0, 4)}'
        .toLowerCase();
    final defaultDisplayName =
        _currentUser?.userMetadata?['name'] ??
        _currentUser?.userMetadata?['full_name'] ??
        emailName;

    await client.from('user_profiles').upsert({
      'id': userId,
      'username': defaultUsername,
      'display_name': defaultDisplayName,
      'avatar_url': _currentUser?.userMetadata?['avatar_url'],
      'updated_at': DateTime.now().toIso8601String(),
    });

    return CommunityUser(
      id: userId,
      username: defaultUsername,
      displayName: defaultDisplayName,
      avatarUrl: _currentUser?.userMetadata?['avatar_url'],
    );
  }

  @override
  Future<List<Friendship>> getFriends() async {
    final client = _client;
    if (client == null) return [];

    final userId = _myId;

    // 1. Получаем все принятые дружбы (где я отправитель или получатель)
    final friendshipsData = await client
        .from('friendships')
        .select()
        .or('user_id.eq.$userId,friend_id.eq.$userId')
        .eq('status', 'accepted');

    if (friendshipsData.isEmpty) return [];

    // Список ID всех друзей
    final friendIds = <String>[];
    for (final row in friendshipsData) {
      final uId = row['user_id'] as String;
      final fId = row['friend_id'] as String;
      friendIds.add(uId == userId ? fId : uId);
    }

    if (friendIds.isEmpty) return [];

    // 2. Получаем профили друзей
    final profilesData = await client
        .from('user_profiles')
        .select()
        .inFilter('id', friendIds);

    final profilesMap = <String, CommunityUser>{};
    for (final row in profilesData) {
      final id = row['id'] as String;
      profilesMap[id] = CommunityUser(
        id: id,
        username: row['username'] ?? 'user_${id.substring(0, 4)}',
        displayName: row['display_name'] ?? row['name'] ?? 'Friend',
        avatarUrl: row['avatar_url'],
      );
    }

    // 3. Получаем мои настройки видимости для каждого друга
    final permissionsData = await client
        .from('sharing_permissions')
        .select()
        .eq('owner_id', userId)
        .inFilter('friend_id', friendIds);

    final permissionsMap = <String, SharingPermission>{};
    for (final row in permissionsData) {
      final fId = row['friend_id'] as String;
      permissionsMap[fId] = SharingPermission.fromJson(row);
    }

    // 4. Собираем итоговый список
    return friendIds.map((fId) {
      final friendUser =
          profilesMap[fId] ??
          CommunityUser(
            id: fId,
            username: 'user_${fId.substring(0, 4)}',
            displayName: 'Friend',
          );
      final permission =
          permissionsMap[fId] ??
          SharingPermission(friendId: fId, scope: SharingScope.none);

      return Friendship(
        friend: friendUser,
        status: FriendshipStatus.accepted,
        myPermissionForFriend: permission,
      );
    }).toList();
  }

  @override
  Future<List<Friendship>> getIncomingRequests() async {
    final client = _client;
    if (client == null) return [];

    final userId = _myId;

    final requests = await client
        .from('friendships')
        .select()
        .eq('friend_id', userId)
        .eq('status', 'pending');

    if (requests.isEmpty) return [];

    final senderIds = requests.map((r) => r['user_id'] as String).toList();
    final profilesData = await client
        .from('user_profiles')
        .select()
        .inFilter('id', senderIds);

    final profilesMap = {
      for (final r in profilesData)
        r['id'] as String: CommunityUser(
          id: r['id'] as String,
          username:
              r['username'] ?? 'user_${(r['id'] as String).substring(0, 4)}',
          displayName: r['display_name'] ?? r['name'] ?? 'User',
          avatarUrl: r['avatar_url'],
        ),
    };

    return senderIds.map((senderId) {
      final user =
          profilesMap[senderId] ??
          CommunityUser(
            id: senderId,
            username: 'user_${senderId.substring(0, 4)}',
            displayName: 'User',
          );
      return Friendship(
        friend: user,
        status: FriendshipStatus.incomingPending,
        myPermissionForFriend: SharingPermission(
          friendId: senderId,
          scope: SharingScope.none,
        ),
      );
    }).toList();
  }

  @override
  Future<List<Friendship>> getOutgoingRequests() async {
    final client = _client;
    if (client == null) return [];

    final userId = _myId;

    final requests = await client
        .from('friendships')
        .select()
        .eq('user_id', userId)
        .eq('status', 'pending');

    if (requests.isEmpty) return [];

    final targetIds = requests.map((r) => r['friend_id'] as String).toList();
    final profilesData = await client
        .from('user_profiles')
        .select()
        .inFilter('id', targetIds);

    final profilesMap = {
      for (final r in profilesData)
        r['id'] as String: CommunityUser(
          id: r['id'] as String,
          username:
              r['username'] ?? 'user_${(r['id'] as String).substring(0, 4)}',
          displayName: r['display_name'] ?? r['name'] ?? 'User',
          avatarUrl: r['avatar_url'],
        ),
    };

    return targetIds.map((targetId) {
      final user =
          profilesMap[targetId] ??
          CommunityUser(
            id: targetId,
            username: 'user_${targetId.substring(0, 4)}',
            displayName: 'User',
          );
      return Friendship(
        friend: user,
        status: FriendshipStatus.outgoingPending,
        myPermissionForFriend: SharingPermission(
          friendId: targetId,
          scope: SharingScope.none,
        ),
      );
    }).toList();
  }

  @override
  Future<List<CommunityUser>> searchUsers(String query) async {
    final client = _client;
    if (client == null || query.trim().isEmpty) return [];

    final cleanQuery = query.trim().replaceAll('@', '');
    final userId = _myId;

    // Поиск по username или display_name
    final res = await client
        .from('user_profiles')
        .select()
        .neq('id', userId)
        .or('username.ilike.%$cleanQuery%,display_name.ilike.%$cleanQuery%')
        .limit(20);

    // Получаем текущие связи, чтобы исключить уже добавленных
    final existingRelations = await client
        .from('friendships')
        .select('user_id, friend_id')
        .or('user_id.eq.$userId,friend_id.eq.$userId');

    final excludedIds = <String>{userId};
    for (final rel in existingRelations) {
      excludedIds.add(rel['user_id'] as String);
      excludedIds.add(rel['friend_id'] as String);
    }

    return res
        .where((row) => !excludedIds.contains(row['id']))
        .map(
          (row) => CommunityUser(
            id: row['id'] as String,
            username:
                row['username'] ??
                'user_${(row['id'] as String).substring(0, 4)}',
            displayName: row['display_name'] ?? row['name'] ?? 'ASR User',
            avatarUrl: row['avatar_url'],
          ),
        )
        .toList();
  }

  @override
  Future<void> sendFriendRequest(String userId) async {
    final client = _client;
    if (client == null) return;

    final myId = _myId;

    await client.from('friendships').upsert({
      'user_id': myId,
      'friend_id': userId,
      'status': 'pending',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, friend_id');
  }

  @override
  Future<void> acceptFriendRequest(String userId) async {
    final client = _client;
    if (client == null) return;

    final myId = _myId;

    // Обновляем статус заявки на accepted
    await client
        .from('friendships')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('friend_id', myId);

    // Создаем дефолтное разрешение доступа (категория)
    await client.from('sharing_permissions').upsert({
      'owner_id': myId,
      'friend_id': userId,
      'scope': SharingScope.category.name,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'owner_id, friend_id');
  }

  @override
  Future<void> declineFriendRequest(String userId) async {
    final client = _client;
    if (client == null) return;

    final myId = _myId;

    await client
        .from('friendships')
        .delete()
        .or(
          'and(user_id.eq.$userId,friend_id.eq.$myId),and(user_id.eq.$myId,friend_id.eq.$userId)',
        );
  }

  @override
  Future<void> removeFriend(String userId) async {
    final client = _client;
    if (client == null) return;

    final myId = _myId;

    await client
        .from('friendships')
        .delete()
        .or(
          'and(user_id.eq.$userId,friend_id.eq.$myId),and(user_id.eq.$myId,friend_id.eq.$userId)',
        );

    await client
        .from('sharing_permissions')
        .delete()
        .or(
          'and(owner_id.eq.$myId,friend_id.eq.$userId),and(owner_id.eq.$userId,friend_id.eq.$myId)',
        );
  }

  @override
  Future<void> updateSharingPermission(SharingPermission permission) async {
    final client = _client;
    if (client == null) return;

    final myId = _myId;

    await client.from('sharing_permissions').upsert({
      'owner_id': myId,
      'friend_id': permission.friendId,
      'scope': permission.scope.name,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'owner_id, friend_id');
  }

  @override
  Future<FriendActivityStatus?> getFriendActivityStatus(String friendId) async {
    final client = _client;
    if (client == null) return null;

    final myId = _myId;

    // 1. Получаем правило видимости, которое друг установил для МЕНЯ
    final permissionRes = await client
        .from('sharing_permissions')
        .select()
        .eq('owner_id', friendId)
        .eq('friend_id', myId)
        .maybeSingle();

    final scopeName = permissionRes?['scope'] as String? ?? 'none';
    final scope = SharingScope.values.firstWhere(
      (s) => s.name == scopeName,
      orElse: () => SharingScope.none,
    );

    if (scope == SharingScope.none) return null;

    // 2. Получаем live presence друга
    final presence = await client
        .from('live_presence')
        .select()
        .eq('user_id', friendId)
        .maybeSingle();

    if (presence == null) return null;

    final startedAt = presence['started_at'] as int?;
    final categoryKey = presence['category_key'] as String?;
    final activityName = presence['activity_name'] as String?;

    if (categoryKey == null || startedAt == null) return null;

    // Проверяем, не устарела ли активность (например, не более 12 часов)
    final startedDateTime = DateTime.fromMillisecondsSinceEpoch(startedAt);
    if (DateTime.now().difference(startedDateTime).inHours > 12) {
      return null;
    }

    return FriendActivityStatus(
      friendId: friendId,
      categoryKey: categoryKey,
      activityName: scope == SharingScope.fullActivity ? activityName : null,
      startedAt: startedAt,
    );
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    final client = _client;
    if (client == null) return false;

    final clean = username.trim().replaceAll('@', '').toLowerCase();
    if (clean.length < 3 || clean.length > 30) return false;

    // Instagram style: letters, numbers, underscores, dots (no consecutive dots or starting/ending with dot)
    final regex = RegExp(
      r'^(?!.*\.\.)(?!.*\.$)[a-z0-9_][a-z0-9_\.]{1,28}[a-z0-9_]$',
    );
    if (!regex.hasMatch(clean)) return false;

    final myId = _currentUser?.id;
    var query = client.from('user_profiles').select('id').eq('username', clean);
    if (myId != null) {
      query = query.neq('id', myId);
    }

    final res = await query.maybeSingle();
    return res == null;
  }

  @override
  Future<void> updateUsername(String newUsername) async {
    final client = _client;
    if (client == null) throw Exception('Supabase не инициализирован');

    final clean = newUsername.trim().replaceAll('@', '').toLowerCase();
    if (clean.length < 3 || clean.length > 30) {
      throw Exception('Никнейм должен содержать от 3 до 30 символов');
    }

    final regex = RegExp(
      r'^(?!.*\.\.)(?!.*\.$)[a-z0-9_][a-z0-9_\.]{1,28}[a-z0-9_]$',
    );
    if (!regex.hasMatch(clean)) {
      throw Exception('community.username_invalid'.tr());
    }

    final isAvailable = await checkUsernameAvailable(clean);
    if (!isAvailable) {
      throw Exception('community.username_taken'.tr());
    }

    final userId = _myId;
    await client
        .from('user_profiles')
        .update({
          'username': clean,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  @override
  Future<void> sendReaction({
    required String friendId,
    required String emoji,
  }) async {
    final client = _client;
    if (client == null) return;

    final myId = _myId;
    final channel = client.channel('community_reactions_$friendId');
    await channel.sendBroadcastMessage(
      event: 'reaction',
      payload: {
        'from_user_id': myId,
        'emoji': emoji,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }
}
