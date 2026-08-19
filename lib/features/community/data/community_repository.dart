import '../domain/models/community_user.dart';
import '../domain/models/friendship.dart';
import '../domain/models/sharing_permission.dart';

/// Абстракция доступа к данным Сообщества.
/// Сейчас единственная реализация — MockCommunityRepository (in-memory).
/// После подключения Supabase добавится SupabaseCommunityRepository,
/// реализующий тот же контракт — UI и провайдеры не изменятся.
abstract class CommunityRepository {
  /// Профиль текущего пользователя в Сообществе.
  /// Пока — фейковый юзер. После Supabase — из auth.currentUser + таблицы profiles.
  Future<CommunityUser> getMe();

  /// Список моих друзей (принятые заявки) вместе с моими правилами
  /// доступа для каждого.
  Future<List<Friendship>> getFriends();

  /// Входящие заявки в друзья (кто-то хочет добавить меня).
  Future<List<Friendship>> getIncomingRequests();

  /// Исходящие заявки (я отправил, жду ответа).
  Future<List<Friendship>> getOutgoingRequests();

  /// Поиск пользователей по username (для добавления в друзья).
  Future<List<CommunityUser>> searchUsers(String query);

  /// Отправить заявку в друзья.
  Future<void> sendFriendRequest(String userId);

  /// Принять входящую заявку.
  Future<void> acceptFriendRequest(String userId);

  /// Отклонить входящую заявку (или отменить исходящую).
  Future<void> declineFriendRequest(String userId);

  /// Удалить из друзей.
  Future<void> removeFriend(String userId);

  /// Обновить моё правило доступа для конкретного друга.
  Future<void> updateSharingPermission(SharingPermission permission);

  /// "Живой" статус конкретного друга — что он мне разрешил, спроецированное
  /// на реальные данные (имя текущей активности, категория, время начала).
  /// null внутри полей означает "не разрешено видеть".
  /// Возвращает null целиком, если друг сейчас не в сети / нет активности.
  Future<FriendActivityStatus?> getFriendActivityStatus(String friendId);

  /// Проверить, свободен ли юзернейм (уникальность, как в Instagram).
  Future<bool> checkUsernameAvailable(String username);

  /// Обновить свой юзернейм (@username).
  Future<void> updateUsername(String newUsername);

  /// Отправить тихую эмодзи-реакцию другу в поддержку его текущего фокуса.
  Future<void> sendReaction({required String friendId, required String emoji});
}

/// Проекция того, что мне разрешено видеть о текущей активности друга.
/// Строится сервером (или моком) с учётом SharingPermission друга для меня —
/// то есть клиент никогда не получает "сырые" данные друга в обход правил.
class FriendActivityStatus {
  const FriendActivityStatus({
    required this.friendId,
    this.activityName,
    this.categoryKey,
    this.startedAt,
  });

  final String friendId;

  /// Название активности — null, если friend разрешил только категорию
  /// без деталей, либо доступ закрыт.
  final String? activityName;

  final String? categoryKey;

  /// epoch millis начала активности — для отображения "уже 40 минут".
  final int? startedAt;
}
