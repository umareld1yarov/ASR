import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';

class CategorySelectionGrid extends StatelessWidget {
  const CategorySelectionGrid({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<ActivityCategory> onSelected;

  static const _leftColumn = [
    ActivityCategory.finance,
    ActivityCategory.family,
    ActivityCategory.rest,
    ActivityCategory.waste,
  ];

  static const _rightColumn = [
    ActivityCategory.religion,
    ActivityCategory.work,
    ActivityCategory.growth,
    ActivityCategory.base,
  ];

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Column(
      children: [
        for (var index = 0; index < _leftColumn.length; index++) ...[
          Row(
            children: [
              Expanded(
                child: _CategoryButton(
                  category: _leftColumn[index],
                  onTap: onSelected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CategoryButton(
                  category: _rightColumn[index],
                  onTap: onSelected,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: 170,
          child: _CategoryButton(
            category: ActivityCategory.sport,
            onTap: onSelected,
          ),
        ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({required this.category, required this.onTap});

  final ActivityCategory category;
  final ValueChanged<ActivityCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(category),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: category.color.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
