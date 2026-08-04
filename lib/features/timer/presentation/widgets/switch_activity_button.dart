import 'package:flutter/material.dart';

import '../../../../shared/widgets/glass_pill_button.dart';
import 'category_picker_sheet.dart';

/// Кнопка "Сменить активность" — стеклянная таблетка, тот же материал,
/// что и карточка таймера.
class SwitchActivityButton extends StatelessWidget {
  const SwitchActivityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPillButton(
      onTap: () => CategoryPickerSheet.show(context),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            'Сменить активность',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
