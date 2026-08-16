import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/application/timer_provider.dart';
import '../../application/profile_provider.dart';

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
  bool _isSpecificActivity = false;
  String? _selectedActivityName;
  final _customActivityController = TextEditingController();

  final _hoursController = TextEditingController(text: '5');
  String _selectedPeriod = 'week';

  @override
  void dispose() {
    _customActivityController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final hours = double.tryParse(_hoursController.text.trim());
    if (_selectedCategory == null || hours == null || hours <= 0) return;

    String? finalActivityName;
    if (_isSpecificActivity) {
      if (_selectedActivityName != null && _selectedActivityName!.isNotEmpty) {
        finalActivityName = _selectedActivityName;
      } else if (_customActivityController.text.trim().isNotEmpty) {
        finalActivityName = _customActivityController.text.trim();
      }
    }

    await ref.read(goalsControllerProvider).addGoal(
      categoryKey: _selectedCategory!.storageKey,
      activityName: finalActivityName,
      targetSeconds: (hours * 3600).round(),
      periodType: _selectedPeriod,
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final category = _selectedCategory;
    final suggestionsAsync = category != null
        ? ref.watch(activitySuggestionsProvider(category.storageKey))
        : null;

    return SingleChildScrollView(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.new_goal'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Выбор категории
          Text(
            'profile.step_1_category'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: ActivityCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return InkWell(
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _selectedActivityName = null;
                }),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: cat.color.withValues(
                      alpha: isSelected ? 0.18 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cat.color.withValues(
                        alpha: isSelected ? 0.9 : 0.18,
                      ),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 3),
                      Text(
                        cat.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (category != null) ...[
            const SizedBox(height: 16),
            Text(
              'profile.step_2_scope'.tr(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ModeTab(
                  label: 'profile.entire_category'.tr(),
                  isSelected: !_isSpecificActivity,
                  onTap: () => setState(() => _isSpecificActivity = false),
                ),
                const SizedBox(width: 8),
                _ModeTab(
                  label: 'profile.specific_activity'.tr(),
                  isSelected: _isSpecificActivity,
                  onTap: () => setState(() => _isSpecificActivity = true),
                ),
              ],
            ),

            if (_isSpecificActivity) ...[
              const SizedBox(height: 12),
              suggestionsAsync?.when(
                    data: (items) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (items.isNotEmpty) ...[
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final item in items)
                                  ChoiceChip(
                                    label: Text(item.name),
                                    selected: _selectedActivityName == item.name,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedActivityName = selected ? item.name : null;
                                        _customActivityController.clear();
                                      });
                                    },
                                    selectedColor: category.color.withValues(alpha: 0.3),
                                    backgroundColor: const Color(0xFF1F1F1F),
                                    labelStyle: TextStyle(
                                      color: _selectedActivityName == item.name
                                          ? category.color
                                          : Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          TextField(
                            controller: _customActivityController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            onChanged: (_) {
                              if (_selectedActivityName != null) {
                                setState(() => _selectedActivityName = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: items.isNotEmpty
                                  ? 'profile.or_type_custom'.tr()
                                  : 'profile.type_custom_hint'.tr(),
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF1F1F1F),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ) ??
                  const SizedBox.shrink(),
            ],
          ],

          const SizedBox(height: 16),
          Text(
            'profile.step_3_period'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PeriodChip(
                label: 'profile.for_week'.tr(),
                selected: _selectedPeriod == 'week',
                onTap: () => setState(() => _selectedPeriod = 'week'),
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'profile.for_month'.tr(),
                selected: _selectedPeriod == 'month',
                onTap: () => setState(() => _selectedPeriod = 'month'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'profile.step_4_target'.tr(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final h in [2, 5, 10, 15, 20])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () => setState(() => _hoursController.text = '$h'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _hoursController.text == '$h'
                            ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                            : const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _hoursController.text == '$h'
                              ? const Color(0xFF06B6D4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '$h${'milestones.units.h'.tr()}',
                        style: TextStyle(
                          color: _hoursController.text == '$h'
                              ? Colors.white
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hoursController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'profile.type_hours_hint'.tr(),
              suffixText: 'profile.hours_per_period'.tr(args: [
                _selectedPeriod == "week" ? "profile.week".tr() : "profile.month".tr(),
              ]),
              suffixStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _selectedCategory == null ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              'profile.save_goal'.tr(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white54 : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF06B6D4).withValues(alpha: 0.2)
                : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF06B6D4) : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
