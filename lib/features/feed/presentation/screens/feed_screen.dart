import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../../../shared/widgets/app_background.dart';
import '../../../sharing/presentation/screens/day_story_preview_screen.dart';
import '../../../timer/domain/models/activity_entry.dart';
import '../../application/feed_provider.dart';
import '../screens/entry_detail_screen.dart';
import '../widgets/day_navigator_bar.dart';
import '../widgets/log_item_tile.dart';
import '../widgets/timeline_entry.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(feedEntriesProvider);

    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(child: DayNavigatorBar()),
                  Consumer(
                    builder: (context, ref, _) {
                      final selectedDate = ref.watch(selectedDateProvider);
                      return IconButton(
                        icon: const Icon(Icons.ios_share, size: 20),
                        color: Colors.white70,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DayStoryPreviewScreen(
                              dateKey: du.DateUtils.dateKey(selectedDate),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: entriesAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          'feed.no_entries'.tr(),
                          style: const TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final category = ActivityCategory.fromStorageKey(
                          entry.categoryKey,
                        );
                        return TimelineEntry(
                          category: category,
                          isFirst: index == 0,
                          isLast: index == entries.length - 1,
                          child: LogItemTile(
                            entry: entry,
                            onTap: () => _showEntryDetail(context, ref, entry),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('${"common.error".tr()}: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(
    BuildContext context,
    WidgetRef ref,
    ActivityEntry entry,
  ) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)));
  }
}
