import 'package:asr/features/community/community_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/friendship.dart';
import 'sharing_settings_screen.dart';
import '../widgets/community_avatar.dart';
import '../widgets/activity_status_pill.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.friendship});

  final Friendship friendship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(
      friendActivityStatusProvider(friendship.friend.id),
    );

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  Text(
                    friendship.friend.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: CommunityAvatar(
                name: friendship.friend.displayName,
                radius: 40,
                showOnlineDot: true,
                isOnline: statusAsync.valueOrNull != null,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '@${friendship.friend.username}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: statusAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: CommunityTheme.accentColor,
                  ),
                ),
                error: (e, _) => _InfoCard(
                  text: 'community.failed_load_status'.tr(),
                  color: Colors.white38,
                ),
                data: (status) {
                  if (status == null) {
                    return _InfoCard(
                      text: 'community.not_sharing'.tr(),
                      color: Colors.white38,
                    );
                  }
                  return ActivityStatusPill(
                    activityName: status.activityName,
                    categoryKey: status.categoryKey,
                    startedAt: status.startedAt,
                  );
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SharingSettingsScreen(
                              friendship: friendship,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.tune,
                        color: CommunityTheme.accentColor,
                        size: 18,
                      ),
                      label: Text(
                        'community.configure_access'.tr(),
                        style: const TextStyle(color: CommunityTheme.accentColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                          color: CommunityTheme.accentColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      final shouldRemove = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: const Color(0xFF242323),
                          title: Text(
                            'community.remove_friend_title'.tr(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            'community.remove_friend_desc'.tr(args: [friendship.friend.displayName]),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: Text('common.cancel'.tr()),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                              child: Text('common.delete'.tr()),
                            ),
                          ],
                        ),
                      );
                      if (shouldRemove != true || !context.mounted) return;
                      await ref
                          .read(communityControllerProvider)
                          .removeFriend(friendship.friend.id);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: Text('community.remove_friend_button'.tr()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
