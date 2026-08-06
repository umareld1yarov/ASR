import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/profile_provider.dart';

/// Форма создания цели: категория → целевые часы → период.
class AddGoalSheet extends ConsumerStatefulWidget {
  const AddGoalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AddGoalSheet(),
    );
  }

  @override
  ConsumerState<AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<AddGoalSheet> {
  ActivityCategory? _selectedCategory;
  final _hoursController = TextEditingController();
  String _selectedPeriod = 'week';

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final hours = double.tryParse(_hoursController.text.trim());
    if (_selectedCategory == null || hours == null || hours <= 0) return;

    await ref
        .read(goalsControllerProvider)
        .addGoal(
          categoryKey: _selectedCategory!.storageKey,
          targetSeconds: (hours * 3600).round(),
          periodType: _selectedPeriod,
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Новая цель',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.25,
            children: ActivityCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return InkWell(
                onTap: () => setState(() => _selectedCategory = category),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: category.color.withValues(
                      alpha: isSelected ? 0.18 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: category.color.withValues(
                        alpha: isSelected ? 0.9 : 0.18,
                      ),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 19),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          TextField(
            controller: _hoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Часов',
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              _PeriodChip(
                label: 'Неделя',
                selected: _selectedPeriod == 'week',
                onTap: () => setState(() => _selectedPeriod = 'week'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Месяц',
                selected: _selectedPeriod == 'month',
                onTap: () => setState(() => _selectedPeriod = 'month'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Всё время',
                selected: _selectedPeriod == 'all',
                onTap: () => setState(() => _selectedPeriod = 'all'),
              ),
            ],
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _create,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Создать цель'),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Colors.white54 : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
