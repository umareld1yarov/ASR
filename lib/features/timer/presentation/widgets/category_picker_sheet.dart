import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/timer_provider.dart';
import '../../domain/focus_review_obstacles.dart';
import 'focus_review_sheet.dart';

/// Модалка смены активности: выбор категории → ввод названия → запуск.
/// Аналог #modal-overlay из index.html (PWA).
class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({super.key, required this.outerContext});

  /// Контекст экрана, который открыл эту модалку — нужен, чтобы после
  /// закрытия этой шторки открыть следующую (Focus Review) поверх экрана,
  /// а не поверх уже закрытой модалки.
  final BuildContext outerContext;

  /// Удобный статический метод для вызова модалки откуда угодно.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryPickerSheet(outerContext: context),
    );
  }

  @override
  ConsumerState<CategoryPickerSheet> createState() =>
      _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends ConsumerState<CategoryPickerSheet> {
  ActivityCategory? _selectedCategory;
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  bool _showValidationError = false;

  static const _reviewMinDurationSeconds = 5; // 10 минут

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final name = _nameController.text.trim();

    if (_selectedCategory == null || name.isEmpty) {
      setState(() => _showValidationError = true);
      return;
    }

    final current = await ref.read(currentActivityProvider.future);

    if (!mounted) return;

    if (current != null) {
      final prevCategory = ActivityCategory.fromStorageKey(current.categoryKey);
      final elapsed =
          ((DateTime.now().millisecondsSinceEpoch - current.startedAt) / 1000)
              .floor();

      // Показываем рефлексию только если категория поддерживает её
      // и сессия была достаточно долгой, чтобы было что осмыслить.
      if (FocusReviewObstacles.appliesTo(prevCategory) &&
          elapsed >= _reviewMinDurationSeconds) {
        Navigator.of(context).pop(); // закрываем пикер категорий

        if (!widget.outerContext.mounted) return;

        FocusReviewSheet.show(
          widget.outerContext,
          previousActivityName: current.name,
          previousCategory: prevCategory,
          nextActivityName: name,
          nextCategoryKey: _selectedCategory!.storageKey,
        );
        return;
      }
    }

    // Короткая сессия или категория без рефлексии — переключаем сразу.
    await ref
        .read(timerControllerProvider)
        .switchActivity(name: name, categoryKey: _selectedCategory!.storageKey);

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
            'Чем занимаешься?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ── Сетка категорий ──
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: ActivityCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                    _showValidationError = false;
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    if (mounted) _nameFocusNode.requestFocus();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? category.color.withValues(alpha: 0.15)
                        : const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? category.color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category.label,
                      style: TextStyle(
                        color: isSelected ? category.color : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── Поле ввода названия ──
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            enabled: _selectedCategory != null,
            autofocus: false,
            decoration: InputDecoration(
              hintText: _selectedCategory == null
                  ? 'Сначала выбери категорию...'
                  : 'Например: Пишу код...',
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: _showValidationError
                    ? const BorderSide(color: Colors.red)
                    : BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _confirm(),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _confirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Запустить →'),
          ),
        ],
      ),
    );
  }
}
