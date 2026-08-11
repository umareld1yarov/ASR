import 'package:asr/features/community/community_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/community_user.dart';

/// Экран поиска пользователей по username и отправки заявок в друзья.
class FindFriendsScreen extends ConsumerStatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  ConsumerState<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends ConsumerState<FindFriendsScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(userSearchProvider(_query));
    final controller = ref.read(communityControllerProvider);

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Поиск по username',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Text(
                        'Начни вводить username',
                        style: TextStyle(color: Colors.white.withOpacity(0.35)),
                      ),
                    )
                  : resultsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: CommunityTheme.accentColor,
                        ),
                      ),
                      error: (e, _) => Center(
                        child: Text(
                          'Ошибка поиска',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                      data: (users) => users.isEmpty
                          ? Center(
                              child: Text(
                                'Никого не найдено',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return _UserTile(
                                  user: user,
                                  onAdd: () async {
                                    await controller.sendFriendRequest(user.id);
                                    // Обновляем список после отправки заявки —
                                    // юзер должен исчезнуть из результатов поиска
                                    // (см. фильтр в MockCommunityRepository.searchUsers).
                                    ref.invalidate(userSearchProvider(_query));
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onAdd});

  final CommunityUser user;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(
              Icons.person_add,
              color: CommunityTheme.accentColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
