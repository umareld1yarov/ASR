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
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    final _ = context.locale;
    final category = _selectedCategory;
    final suggestionsAsync = category != null
        ? ref.watch(activitySuggestionsProvider(category.storageKey))
        : null;

    final activeColor = category?.color ?? const Color(0xFF06B6D4);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'profile.new_goal'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1. Выбор категории
          Text(
            'profile.step_1_category'.tr(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.35,
            children: ActivityCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return InkWell(
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _selectedActivityName = null;
                }),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(
                      alpha: isSelected ? 0.22 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: cat.color.withValues(
                        alpha: isSelected ? 1.0 : 0.15,
                      ),
                      width: isSelected ? 1.8 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cat.color.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: -2,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat.emoji, style: const TextStyle(fontSize: 20)),
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
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // 2. Детали при выборе категории
          if (category != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.step_2_scope'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ModeTab(
                        label: 'profile.entire_category'.tr(),
                        isSelected: !_isSpecificActivity,
                        activeColor: activeColor,
                        onTap: () => setState(() => _isSpecificActivity = false),
                      ),
                      const SizedBox(width: 8),
                      _ModeTab(
                        label: 'profile.specific_activity'.tr(),
                        isSelected: _isSpecificActivity,
                        activeColor: activeColor,
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
                                              _selectedActivityName =
                                                  selected ? item.name : null;
                                              _customActivityController.clear();
                                            });
                                          },
                                          selectedColor: activeColor.withValues(alpha: 0.3),
                                          backgroundColor: const Color(0xFF222224),
                                          labelStyle: TextStyle(
                                            color: _selectedActivityName == item.name
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 12.5,
                                            fontWeight: _selectedActivityName == item.name
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                TextField(
                                  controller: _customActivityController,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
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
                                    fillColor: const Color(0xFF222224),
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
              ),
            ),
          ],

          const SizedBox(height: 20),
          // 3. Период и Шаг 4: Часы
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.step_3_period'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PeriodChip(
                      label: 'profile.for_week'.tr(),
                      selected: _selectedPeriod == 'week',
                      activeColor: activeColor,
                      onTap: () => setState(() => _selectedPeriod = 'week'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'profile.for_month'.tr(),
                      selected: _selectedPeriod == 'month',
                      activeColor: activeColor,
                      onTap: () => setState(() => _selectedPeriod = 'month'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  'profile.step_4_target'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final h in [2, 5, 10, 15, 20])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _hoursController.text = '$h'),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _hoursController.text == '$h'
                                    ? activeColor.withValues(alpha: 0.25)
                                    : const Color(0xFF222224),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hoursController.text == '$h'
                                      ? activeColor
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '$h ${'milestones.units.h'.tr()}',
                                style: TextStyle(
                                  color: _hoursController.text == '$h'
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hoursController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'profile.type_hours_hint'.tr(),
                    suffixText: 'profile.hours_per_period'.tr(args: [
                      _selectedPeriod == "week" ? "profile.week".tr() : "profile.month".tr(),
                    ]),
                    suffixStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF222224),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedCategory == null ? null : _create,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedCategory != null ? activeColor : Colors.white24,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(52),
              elevation: 4,
              shadowColor: activeColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'profile.save_goal'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
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
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.2)
                : const Color(0xFF222224),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: 0.2)
                : const Color(0xFF222224),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
