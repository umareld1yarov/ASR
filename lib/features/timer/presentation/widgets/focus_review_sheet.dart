import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/timer_provider.dart';
import '../../domain/focus_review_obstacles.dart';

/// Шторка рефлексии после сессии в категориях с включённым Focus Review
/// (Работа, Развитие, Спорт, Религия). Показывается ПЕРЕД переключением
/// на новую активность — само переключение происходит из этой шторки.
class FocusReviewSheet extends ConsumerStatefulWidget {
  const FocusReviewSheet({
    super.key,
    required this.previousActivityName,
    required this.previousCategory,
    required this.nextActivityName,
    required this.nextCategoryKey,
  });

  final String previousActivityName;
  final ActivityCategory previousCategory;
  final String nextActivityName;
  final String nextCategoryKey;

  static Future<void> show(
    BuildContext context, {
    required String previousActivityName,
    required ActivityCategory previousCategory,
    required String nextActivityName,
    required String nextCategoryKey,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FocusReviewSheet(
        previousActivityName: previousActivityName,
        previousCategory: previousCategory,
        nextActivityName: nextActivityName,
        nextCategoryKey: nextCategoryKey,
      ),
    );
  }

  @override
  ConsumerState<FocusReviewSheet> createState() => _FocusReviewSheetState();
}

class _FocusReviewSheetState extends ConsumerState<FocusReviewSheet> {
  String? _mood;
  final Set<String> _selectedObstacles = {};
  final _experimentController = TextEditingController();

  @override
  void dispose() {
    _experimentController.dispose();
    super.dispose();
  }

  bool get _needsObstacles => _mood == 'meh' || _mood == 'bad';
  bool get _needsExperiment => _mood == 'bad';

  Future<void> _finish() async {
    await ref
        .read(timerControllerProvider)
        .switchActivity(
          name: widget.nextActivityName,
          categoryKey: widget.nextCategoryKey,
          reviewMood: _mood,
          reviewObstacles: _selectedObstacles.isEmpty
              ? null
              : _selectedObstacles.toList(),
          reviewNextExperiment: _experimentController.text.trim().isEmpty
              ? null
              : _experimentController.text.trim(),
        );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tags = FocusReviewObstacles.tagsFor(widget.previousCategory);

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
          Text(
            'Как прошло: ${widget.previousActivityName}?',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ── Кнопки настроения ──
          Row(
            children: [
              _MoodButton(
                emoji: '🔥',
                label: 'Огонь',
                selected: _mood == 'fire',
                onTap: () => setState(() => _mood = 'fire'),
              ),
              const SizedBox(width: 8),
              _MoodButton(
                emoji: '👍',
                label: 'Хорошо',
                selected: _mood == 'good',
                onTap: () => setState(() => _mood = 'good'),
              ),
              const SizedBox(width: 8),
              _MoodButton(
                emoji: '😐',
                label: 'Так себе',
                selected: _mood == 'meh',
                onTap: () => setState(() => _mood = 'meh'),
              ),
              const SizedBox(width: 8),
              _MoodButton(
                emoji: '😞',
                label: 'Провал',
                selected: _mood == 'bad',
                onTap: () => setState(() => _mood = 'bad'),
              ),
            ],
          ),

          // ── Теги "что помешало" — только для meh/bad ──
          if (_needsObstacles) ...[
            const SizedBox(height: 20),
            const Text(
              'Что помешало?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = _selectedObstacles.contains(tag);
                return ChoiceChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (isSelected) {
                        _selectedObstacles.remove(tag);
                      } else {
                        _selectedObstacles.add(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],

          // ── Следующий эксперимент — только для bad ──
          if (_needsExperiment) ...[
            const SizedBox(height: 20),
            const Text(
              'Что попробуешь в следующий раз?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _experimentController,
              decoration: InputDecoration(
                hintText: 'Необязательно...',
                filled: true,
                fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _mood == null ? null : _finish,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Готово →'),
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.white54 : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
