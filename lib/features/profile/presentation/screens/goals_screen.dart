import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../application/profile_provider.dart';
import '../widgets/add_goal_sheet.dart';
import '../widgets/goal_card.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedPeriodFilter = 'all';
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'profile.my_goals'.tr(),
                        style: const TextStyle(
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
                      label: Text(
                        'profile.goal'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    _PeriodFilterTab(
                      label: 'profile.all_periods'.tr(),
                      isSelected: _selectedPeriodFilter == 'all',
                      onTap: () => setState(() => _selectedPeriodFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterTab(
                      label: 'profile.for_week'.tr(),
                      isSelected: _selectedPeriodFilter == 'week',
                      onTap: () => setState(() => _selectedPeriodFilter = 'week'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodFilterTab(
                      label: 'profile.for_month'.tr(),
                      isSelected: _selectedPeriodFilter == 'month',
                      onTap: () => setState(() => _selectedPeriodFilter = 'month'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _CategoryFilterChip(
                      label: 'profile.all_categories'.tr(),
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

              Expanded(
                child: goalsAsync.when(
                  data: (goals) {
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
                                    ? 'profile.no_active_goals'.tr()
                                    : 'profile.no_matching_goals'.tr(),
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
                                label: Text('profile.set_first_goal'.tr()),
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
                    child: Text('${"common.error".tr()}: $e', style: const TextStyle(color: Colors.white54)),
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
