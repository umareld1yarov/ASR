import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../feed/presentation/screens/entry_detail_screen.dart';
import '../../../feed/presentation/widgets/log_item_tile.dart';
import '../../application/timer_provider.dart';

/// Экран деталей категории — все записи этой категории за сегодня.
/// Аналог #screen-category-detail из index.html (PWA).
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final ActivityCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(
      categoryEntriesProvider(category.storageKey),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(category.label),
        foregroundColor: category.color,
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'Записей за сегодня нет',
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EntryDetailScreen(entry: entry),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}
