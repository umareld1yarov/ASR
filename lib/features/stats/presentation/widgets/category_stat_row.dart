import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/stats_provider.dart';

/// Раскрывающаяся строка категории (Expandable Accordion).
/// При нажатии плавно разворачивает список конкретных сохранённых
/// активностей (тегов) с их индивидуальным временем и процентами.
class CategoryStatRow extends ConsumerStatefulWidget {
  const CategoryStatRow({
    super.key,
    required this.category,
    required this.seconds,
    required this.totalSeconds,
  });

  final ActivityCategory category;
  final int seconds;
  final int totalSeconds;

  @override
  ConsumerState<CategoryStatRow> createState() => _CategoryStatRowState();
}

class _CategoryStatRowState extends ConsumerState<CategoryStatRow> {
  bool _isExpanded = false;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
    return '$mм';
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final live = ref.watch(liveCategorySecondsProvider(category.storageKey));
    final displaySeconds = widget.seconds + live;
    final displayTotal = widget.totalSeconds + live;
    final percent = displayTotal > 0 ? displaySeconds / displayTotal : 0.0;

    final activitiesAsync = _isExpanded
        ? ref.watch(activityBreakdownProvider(category.storageKey))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: _isExpanded ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.color.withValues(
            alpha: _isExpanded ? 0.35 : 0.12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Шапка категории (кликабельная)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${_formatDuration(displaySeconds)} · ${(percent * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Colors.white54,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation(category.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Раскрывающаяся секция конкретных дел
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(color: Colors.white10, height: 12),
                  activitiesAsync?.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'Нет индивидуальных записей за этот период',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white38,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: category.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${_formatDuration(item.seconds)} · ${(item.ratio * 100).round()}%',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                            color: category.color.withValues(
                                              alpha: 0.9,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: item.ratio.clamp(0.0, 1.0),
                                        minHeight: 4,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.05),
                                        color: category.color.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                      ) ??
                      const SizedBox.shrink(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
