import 'package:flutter/material.dart';

import '../../domain/models/activity_suggestion.dart';

class ActivitySuggestionsList extends StatelessWidget {
  const ActivitySuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<ActivitySuggestion> suggestions;
  final ValueChanged<String> onSelected;

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
              onTap: () => onSelected(suggestion.name),
            ),
          ),
        ],
        if (others.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _SectionLabel('ВСЕ АКТИВНОСТИ'),
          ...others.map(
            (suggestion) => _ActivityRow(
              suggestion: suggestion,
              onTap: () => onSelected(suggestion.name),
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
  const _ActivityRow({required this.suggestion, required this.onTap});
  final ActivitySuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Icon(Icons.play_circle_outline, color: Colors.white.withValues(alpha: 0.56)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                suggestion.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.28)),
          ],
        ),
      ),
    ),
  );
}
