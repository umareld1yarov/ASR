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

    final remaining = PickerHelpButton._maxShows - count;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: Color(0xFFFACC15), size: 24),
            SizedBox(width: 10),
            Text(
              'Как это работает',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Выберите категорию, а затем нужную активность из списка подсказок или создайте новую с помощью кнопки «+ Новая активность».\n\n'
          'Нажатие на карточку подсказки сразу запускает отслеживание времени для выбранной активности.\n\n'
          '${remaining > 0 ? "Эта подсказка автоматически скроется через $remaining ${remaining == 1 ? 'показ' : 'показов'}." : "Это была последняя подсказка."}',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Понятно'),
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
    if (_hidden) return const SizedBox.shrink();

    return IconButton(
      onPressed: _showHelp,
      tooltip: 'Как пользоваться',
      icon: const Icon(
        Icons.lightbulb_outline,
        size: 22,
        color: Color(0xFFFACC15),
      ),
    );
  }
}
