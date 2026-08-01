import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/feed_provider.dart';
import '../widgets/day_navigator_bar.dart';
import '../widgets/log_item_tile.dart';
import '../../../timer/domain/models/activity_entry.dart';
import '../widgets/entry_detail_sheet.dart';

/// Экран 2 — Лента. Хронологическая история активностей за выбранный день.
/// Аналог #screen-log из index.html (PWA).
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(feedEntriesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const Text(
              'Лента',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const DayNavigatorBar(),
            const SizedBox(height: 8),
            const Divider(color: Colors.white12),

            Expanded(
              child: entriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'Записей за этот день нет',
                        style: TextStyle(color: Colors.white38),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return LogItemTile(
                        entry: entry,
                        onTap: () => _showEntryDetail(context, ref, entry),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Ошибка: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetail(
    BuildContext context,
    WidgetRef ref,
    ActivityEntry entry,
  ) {
    EntryDetailSheet.show(context, entry);
  }
}
