import 'package:flutter/material.dart';

class NewActivityForm extends StatelessWidget {
  const NewActivityForm({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onStart,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'НОВАЯ АКТИВНОСТЬ',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 50,
        textInputAction: TextInputAction.go,
        onSubmitted: (_) => onStart(),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Например, математика',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      const SizedBox(height: 4),
      FilledButton(
        onPressed: onStart,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('Начать →', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    ],
  );
}
