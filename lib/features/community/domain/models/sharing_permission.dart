/// Что именно я разрешаю видеть конкретному другу.
/// Правило одностороннее: у каждой стороны дружбы своё SharingPermission
/// (я решаю, что видно другу; он решает, что видно мне).
enum SharingScope {
  /// Ничего о текущей активности не показываю.
  none,

  /// Показываю категорию и время с начала, без названия активности.
  category,

  /// Показываю категорию, название активности и время с начала.
  fullActivity,
}

/// Настройка доступа для одного друга.
/// В будущей таблице Supabase `sharing_permissions` — одна строка
/// на пару (owner_id, friend_id).
class SharingPermission {
  const SharingPermission({
    required this.friendId,
    this.scope = SharingScope.none,
  });

  /// id друга, к которому применяется это правило.
  final String friendId;

  final SharingScope scope;

  SharingPermission copyWith({
    String? friendId,
    SharingScope? scope,
  }) {
    return SharingPermission(
      friendId: friendId ?? this.friendId,
      scope: scope ?? this.scope,
    );
  }

  factory SharingPermission.fromJson(Map<String, dynamic> json) {
    return SharingPermission(
      friendId: json['friend_id'] as String,
      scope: SharingScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => SharingScope.none,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': friendId,
      'scope': scope.name,
    };
  }
}
