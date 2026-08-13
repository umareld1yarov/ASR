import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../application/profile_provider.dart';
import '../widgets/add_goal_sheet.dart';
import '../widgets/goal_card.dart';

/// Полноэкранный центр управления целями с фильтрами периода и категорий.
class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedPeriodFilter = 'all'; // 'all', 'week', 'month'
  ActivityCategory? _selectedCategoryFilter;

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Верхняя панель навигации
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Мои цели',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => AddGoalSheet.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Цель',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 1. Фильтр периода (Все / Неделя / Месяц)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    _PeriodFilterTab(
                      label: 'Все периоды',
                      isSelected: _selectedPeriodFilter == 'all',
                      onTap: () => setState(() => _selectedPeriodFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterTab(
                      label: '📅 Неделя',
                      isSelected: _selectedPeriodFilter == 'week',
                      onTap: () => setState(() => _selectedPeriodFilter = 'week'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterTab(
                      label: '🗓️ Месяц',
                      isSelected: _selectedPeriodFilter == 'month',
                      onTap: () => setState(() => _selectedPeriodFilter = 'month'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Горизонтальный фильтр по категориям
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _CategoryFilterChip(
                      label: 'Все категории',
                      isSelected: _selectedCategoryFilter == null,
                      onTap: () => setState(() => _selectedCategoryFilter = null),
                    ),
                    for (final cat in ActivityCategory.values) ...[
                      const SizedBox(width: 8),
                      _CategoryFilterChip(
                        label: '${cat.emoji} ${cat.label}',
                        color: cat.color,
                        isSelected: _selectedCategoryFilter == cat,
                        onTap: () => setState(() => _selectedCategoryFilter = cat),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Список целей
              Expanded(
                child: goalsAsync.when(
                  data: (goals) {
                    // Применяем фильтры
                    final filtered = goals.where((g) {
                      if (_selectedPeriodFilter != 'all' && g.periodType != _selectedPeriodFilter) {
                        return false;
                      }
                      if (_selectedCategoryFilter != null && g.categoryKey != _selectedCategoryFilter!.storageKey) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.track_changes_outlined,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                goals.isEmpty
                                    ? 'У вас пока нет активных целей'
                                    : 'По выбранным фильтрам целей не найдено',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => AddGoalSheet.show(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF06B6D4),
                                  side: const BorderSide(color: Color(0xFF06B6D4)),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Поставить первую цель'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return GoalCard(goal: filtered[index]);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                  ),
                  error: (e, _) => Center(
                    child: Text('Ошибка загрузки целей: $e', style: const TextStyle(color: Colors.white54)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodFilterTab extends StatelessWidget {
  const _PeriodFilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF06B6D4);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? chipColor : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
