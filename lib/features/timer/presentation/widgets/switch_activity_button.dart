import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/glass_pill_button.dart';
import 'category_picker_sheet.dart';

/// Кнопка "Сменить активность" — стеклянная таблетка.
class SwitchActivityButton extends StatelessWidget {
  const SwitchActivityButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassPillButton(
      onTap: () => CategoryPickerSheet.show(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'timer.select_category'.tr(),
            style: const TextStyle(
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
