import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Кнопка-подсказка "как пользоваться" — исчезает после 5 просмотров.
class PickerHelpButton extends StatefulWidget {
  const PickerHelpButton({super.key});

  static const _prefsKey = 'picker_help_shown_count';
  static const _maxShows = 5;

  @override
  State<PickerHelpButton> createState() => _PickerHelpButtonState();
}

class _PickerHelpButtonState extends State<PickerHelpButton> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(PickerHelpButton._prefsKey) ?? 0;
    if (count >= PickerHelpButton._maxShows && mounted) {
      setState(() => _hidden = true);
    }
  }

  Future<void> _showHelp() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(PickerHelpButton._prefsKey) ?? 0) + 1;
    await prefs.setInt(PickerHelpButton._prefsKey, count);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Row(
          children: [
            const Icon(Icons.lightbulb, color: Color(0xFFFACC15), size: 24),
            const SizedBox(width: 10),
            Text(
              'timer.how_it_works'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          '${"timer.picker_help_text".tr()}\n\n${"timer.picker_help_auto_hide".tr()}',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.got_it'.tr()),
          ),
        ],
      ),
    );

    if (count >= PickerHelpButton._maxShows && mounted) {
      setState(() => _hidden = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    if (_hidden) return const SizedBox.shrink();

    return IconButton(
      onPressed: _showHelp,
      tooltip: 'timer.how_to_use'.tr(),
      icon: const Icon(
        Icons.lightbulb_outline,
        size: 22,
        color: Color(0xFFFACC15),
      ),
    );
  }
}
