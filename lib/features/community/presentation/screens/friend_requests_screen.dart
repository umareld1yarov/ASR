import 'package:asr/features/community/community_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/friendship.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAsync = ref.watch(incomingRequestsProvider);
    final outgoingAsync = ref.watch(outgoingRequestsProvider);
    final controller = ref.read(communityControllerProvider);

    return AppBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  Text(
                    'community.friend_requests_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _SectionLabel('community.incoming_requests'.tr()),
                  incomingAsync.when(
                    loading: () => const _Loading(),
                    error: (e, _) => const _ErrorText(),
                    data: (list) => list.isEmpty
                        ? _EmptyLine('community.no_incoming_requests'.tr())
                        : Column(
                            children: list
                                .map(
                                  (f) => _IncomingTile(
                                    friendship: f,
                                    onAccept: () => controller
                                        .acceptFriendRequest(f.friend.id),
                                    onDecline: () => controller
                                        .declineFriendRequest(f.friend.id),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('community.outgoing_requests'.tr()),
                  outgoingAsync.when(
                    loading: () => const _Loading(),
                    error: (e, _) => const _ErrorText(),
                    data: (list) => list.isEmpty
                        ? _EmptyLine('community.no_outgoing_requests'.tr())
                        : Column(
                            children: list
                                .map(
                                  (f) => _OutgoingTile(
                                    friendship: f,
                                    onCancel: () => controller
                                        .declineFriendRequest(f.friend.id),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({
    required this.friendship,
    required this.onAccept,
    required this.onDecline,
  });

  final Friendship friendship;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              friendship.friend.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
            ),
          ),
          IconButton(
            onPressed: onDecline,
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
          ),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(
              Icons.check_circle,
              color: CommunityTheme.accentColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutgoingTile extends StatelessWidget {
  const _OutgoingTile({required this.friendship, required this.onCancel});

  final Friendship friendship;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              friendship.friend.displayName,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
            ),
          ),
          Text(
            'community.waiting_status'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12.5,
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38),
    ),
  );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText();
  @override
  Widget build(BuildContext context) => Text(
    'community.load_error'.tr(),
    style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
  );
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 13,
      ),
    ),
  );
}
