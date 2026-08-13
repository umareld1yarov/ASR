import 'package:flutter/material.dart';

import '../../domain/models/activity_suggestion.dart';

class ActivitySuggestionsList extends StatelessWidget {
  const ActivitySuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.categoryColor,
  });

  final List<ActivitySuggestion> suggestions;
  final ValueChanged<String> onSelected;
  final Color? categoryColor;

  @override
  Widget build(BuildContext context) {
    final frequent = suggestions.take(5).toList();
    final others = suggestions.skip(frequent.length).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (frequent.isNotEmpty) ...[
          const _SectionLabel('ЧАСТО ИСПОЛЬЗУЕМЫЕ'),
          ...frequent.map(
            (suggestion) => _ActivityRow(
              suggestion: suggestion,
              onSelected: onSelected,
              categoryColor: categoryColor,
            ),
          ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionLabel('ВСЕ АКТИВНОСТИ'),
          ...others.map(
            (suggestion) => _ActivityRow(
              suggestion: suggestion,
              onSelected: onSelected,
              categoryColor: categoryColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.42),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.suggestion,
    required this.onSelected,
    this.categoryColor,
  });

  final ActivitySuggestion suggestion;
  final ValueChanged<String> onSelected;
  final Color? categoryColor;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(suggestion.name),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    color: color.withValues(alpha: 0.9),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      suggestion.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
