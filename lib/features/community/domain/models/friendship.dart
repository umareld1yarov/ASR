import 'community_user.dart';
import 'sharing_permission.dart';

/// Статус связи между мной и другим пользователем.
enum FriendshipStatus {
  /// Я отправил заявку, друг ещё не ответил.
  outgoingPending,

  /// Друг отправил мне заявку, я ещё не ответил.
  incomingPending,

  /// Заявка принята — мы друзья.
  accepted,
}

/// Дружба + то, что я разрешаю видеть этому другу.
/// В будущем это будет "склейка" двух таблиц Supabase:
/// `friendships` (status) + `sharing_permissions` (моё правило для него).
class Friendship {
  const Friendship({
    required this.friend,
    required this.status,
    required this.myPermissionForFriend,
  });

  /// Профиль друга (или того, с кем идёт переписка по заявке).
  final CommunityUser friend;

  final FriendshipStatus status;

  /// Что Я разрешаю видеть ЭТОМУ другу.
  /// Что он разрешает видеть мне — придёт отдельным полем/запросом
  /// (permission друга нам предоставляет сервер, а не мы её задаём).
  final SharingPermission myPermissionForFriend;

  Friendship copyWith({
    CommunityUser? friend,
    FriendshipStatus? status,
    SharingPermission? myPermissionForFriend,
  }) {
    return Friendship(
      friend: friend ?? this.friend,
      status: status ?? this.status,
      myPermissionForFriend:
          myPermissionForFriend ?? this.myPermissionForFriend,
    );
  }
}
