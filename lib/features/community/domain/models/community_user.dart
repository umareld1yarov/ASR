/// Публичный профиль пользователя в Сообществе.
/// В отличие от локального UserProfile (Isar, singleton id=0) — это
/// представление ЛЮБОГО пользователя приложения, включая друзей.
/// Пока данные моковые (in-memory), но модель уже 1-в-1 ляжет на будущую
/// таблицу Supabase `profiles` (id = auth.uid()).
class CommunityUser {
  const CommunityUser({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  /// Уникальный id пользователя. Сейчас — просто строка для моков,
  /// после подключения Supabase будет совпадать с auth.uid() (UUID).
  final String id;

  /// Уникальный "юзернейм" для поиска друзей (аналог @handle).
  final String username;

  /// Отображаемое имя.
  final String displayName;

  /// Ссылка на аватар (после Supabase — публичный URL из Storage).
  /// Пока может быть null — покажем дефолтную иконку/инициалы.
  final String? avatarUrl;

  CommunityUser copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
  }) {
    return CommunityUser(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }
}
