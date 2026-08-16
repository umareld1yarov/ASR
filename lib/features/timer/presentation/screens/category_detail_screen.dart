import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../feed/presentation/screens/entry_detail_screen.dart';
import '../../../feed/presentation/widgets/log_item_tile.dart';
import '../../application/timer_provider.dart';
import '../../domain/models/activity_entry.dart';

/// All completed entries in one category for today.
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final ActivityCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
    final entriesAsync = ref.watch(
      categoryEntriesProvider(category.storageKey),
    );

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _CategoryHeader(category: category),
            Expanded(
              child: entriesAsync.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: category.color),
                ),
                error: (error, _) => _ErrorState(error: error.toString()),
                data: (entries) => entries.isEmpty
                    ? _EmptyCategoryState(category: category)
                    : _CategoryEntriesList(entries: entries),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category});

  final ActivityCategory category;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'timer.for_today'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.48),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryEntriesList extends StatelessWidget {
  const _CategoryEntriesList({required this.entries});

  final List<ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = entries.fold<int>(
      0,
      (total, entry) => total + entry.durationSeconds,
    );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: entries.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TotalDurationCard(
            totalSeconds: totalSeconds,
            entriesCount: entries.length,
          );
        }

        final entry = entries[index - 1];
        return LogItemTile(
          entry: entry,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)),
          ),
        );
      },
    );
  }
}

class _TotalDurationCard extends StatelessWidget {
  const _TotalDurationCard({
    required this.totalSeconds,
    required this.entriesCount,
  });

  final int totalSeconds;
  final int entriesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 9),
          Text(
            'timer.total_for_today'.tr(),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
          ),
          const Spacer(),
          Text(
            _formatDuration(totalSeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' · ${'feed.entry_count'.plural(entriesCount, args: ['$entriesCount'])}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.42)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    return formatDuration(seconds);
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.category});

  final ActivityCategory category;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 12),
            Text(
              'feed.no_entries'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'timer.no_entries_in_category'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '${"timer.failed_load_entries".tr()}\n$error',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
        ),
      ),
    );
  }
}
