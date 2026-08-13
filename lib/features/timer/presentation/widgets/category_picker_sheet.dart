import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/timer_provider.dart';
import 'activity_suggestions_list.dart';
import 'category_selection_grid.dart';
import 'new_activity_form.dart';

/// Two-step flow for switching an activity: category, then a reusable name.
class CategoryPickerSheet extends ConsumerStatefulWidget {
  const CategoryPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const CategoryPickerSheet(),
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
  bool _isCreatingNew = false;
  bool _isStarting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _selectCategory(ActivityCategory category) {
    setState(() {
      _selectedCategory = category;
      _isCreatingNew = false;
    });
  }

  void _showNewActivityForm() {
    setState(() => _isCreatingNew = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _nameFocusNode.requestFocus());
  }

  Future<void> _startActivity(String name) async {
    final category = _selectedCategory;
    final trimmedName = name.trim();
    if (category == null || trimmedName.isEmpty || _isStarting) return;

    setState(() => _isStarting = true);
    await ref.read(timerControllerProvider).switchActivity(
          name: trimmedName,
          categoryKey: category.storageKey,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7D7D89), Color(0xFF1A1919)],
          stops: [0.0, 0.4],
        ),
      ),
      child: AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: _selectedCategory == null
              ? _CategoryStep(onSelected: _selectCategory)
              : _ActivityStep(
                  category: _selectedCategory!,
                  isCreatingNew: _isCreatingNew,
                  isStarting: _isStarting,
                  nameController: _nameController,
                  nameFocusNode: _nameFocusNode,
                  onBack: () => setState(() {
                    _selectedCategory = null;
                    _isCreatingNew = false;
                  }),
                  onNewActivity: _showNewActivityForm,
                  onStart: () => _startActivity(_nameController.text),
                  onSuggestionSelected: _startActivity,
                ),
        ),
      ),
      ),
    );
  }
}

class _CategoryStep extends StatelessWidget {
  const _CategoryStep({required this.onSelected});
  final ValueChanged<ActivityCategory> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DragHandle(),
        const SizedBox(height: 18),
        const Text(
          'Чем занимаешься?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Выбери категорию',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.48), fontSize: 14),
        ),
        const SizedBox(height: 22),
        CategorySelectionGrid(onSelected: onSelected),
      ],
    ),
  );
}

class _ActivityStep extends ConsumerWidget {
  const _ActivityStep({
    required this.category,
    required this.isCreatingNew,
    required this.isStarting,
    required this.nameController,
    required this.nameFocusNode,
    required this.onBack,
    required this.onNewActivity,
    required this.onStart,
    required this.onSuggestionSelected,
  });

  final ActivityCategory category;
  final bool isCreatingNew;
  final bool isStarting;
  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final VoidCallback onBack;
  final VoidCallback onNewActivity;
  final VoidCallback onStart;
  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(activitySuggestionsProvider(category.storageKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DragHandle(),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: category.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: TextStyle(
                color: category.color,
                fontSize: 21,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: isCreatingNew
              ? SingleChildScrollView(
                  child: NewActivityForm(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    onStart: onStart,
                  ),
                )
              : suggestions.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(color: category.color),
                  ),
                  error: (_, _) => _SuggestionsError(onNewActivity: onNewActivity),
                  data: (items) => ListView(
                    children: [
                      if (items.isEmpty)
                        _NoSuggestions(onNewActivity: onNewActivity)
                      else ...[
                        ActivitySuggestionsList(
                          suggestions: items,
                          onSelected: onSuggestionSelected,
                        ),
                        const SizedBox(height: 16),
                        _NewActivityButton(onTap: onNewActivity),
                      ],
                    ],
                  ),
                ),
        ),
        if (isStarting)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: LinearProgressIndicator(color: category.color),
          ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _NewActivityButton extends StatelessWidget {
  const _NewActivityButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.add, size: 19),
    label: const Text('Новая активность'),
    style: TextButton.styleFrom(
      foregroundColor: Colors.white70,
      minimumSize: const Size.fromHeight(48),
      alignment: Alignment.centerLeft,
    ),
  );
}

class _NoSuggestions extends StatelessWidget {
  const _NoSuggestions({required this.onNewActivity});
  final VoidCallback onNewActivity;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Здесь пока нет сохранённых активностей.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
        const SizedBox(height: 12),
        _NewActivityButton(onTap: onNewActivity),
      ],
    ),
  );
}

class _SuggestionsError extends StatelessWidget {
  const _SuggestionsError({required this.onNewActivity});
  final VoidCallback onNewActivity;
  @override
  Widget build(BuildContext context) => _NoSuggestions(onNewActivity: onNewActivity);
}
