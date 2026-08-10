/// Что именно я разрешаю видеть конкретному другу.
/// Правило одностороннее: у каждой стороны дружбы своё SharingPermission
/// (я решаю, что видно другу; он решает, что видно мне).
enum SharingScope {
  /// Ничего не показываю (друг видит, что я оффлайн/скрыт).
  none,

  /// Только "чем занят прямо сейчас" (live-статус, CurrentActivity).
  live,

  /// Только определённые категории — как live, так и завершённые записи
  /// по этим категориям (см. allowedCategoryKeys).
  category,

  /// Полный день — вся лента активностей за сегодня (все категории).
  fullDay,
}

/// Настройка доступа для одного друга.
/// В будущей таблице Supabase `sharing_permissions` — одна строка
/// на пару (owner_id, friend_id).
class SharingPermission {
  const SharingPermission({
    required this.friendId,
    this.scope = SharingScope.none,
    this.allowedCategoryKeys = const [],
  });

  /// id друга, к которому применяется это правило.
  final String friendId;

  final SharingScope scope;

  /// Используется только когда scope == SharingScope.category.
  /// Список categoryKey (см. ActivityCategory.storageKey), которые
  /// разрешено видеть этому другу.
  final List<String> allowedCategoryKeys;

  SharingPermission copyWith({
    String? friendId,
    SharingScope? scope,
    List<String>? allowedCategoryKeys,
  }) {
    return SharingPermission(
      friendId: friendId ?? this.friendId,
      scope: scope ?? this.scope,
      allowedCategoryKeys: allowedCategoryKeys ?? this.allowedCategoryKeys,
    );
  }

  factory SharingPermission.fromJson(Map<String, dynamic> json) {
    return SharingPermission(
      friendId: json['friend_id'] as String,
      scope: SharingScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => SharingScope.none,
      ),
      allowedCategoryKeys:
          (json['allowed_category_keys'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friend_id': friendId,
      'scope': scope.name,
      'allowed_category_keys': allowedCategoryKeys,
    };
  }
}
