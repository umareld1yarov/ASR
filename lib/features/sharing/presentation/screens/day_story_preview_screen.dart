import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/day_story_card.dart';

/// Экран превью "Дневника дня" перед шером — показывает карточку 1:1
/// с тем, что попадёт в итоговое изображение (тап по фото/подписи меняет
/// выбор через dayStorySelectionProvider), кнопка "Поделиться" рендерит
/// виджет в PNG и открывает системное меню шеринга.
class DayStoryPreviewScreen extends StatefulWidget {
  const DayStoryPreviewScreen({super.key, required this.dateKey});

  final String dateKey;

  @override
  State<DayStoryPreviewScreen> createState() => _DayStoryPreviewScreenState();
}

class _DayStoryPreviewScreenState extends State<DayStoryPreviewScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // pixelRatio 3.0 при логическом размере карточки 360×640 даёт ровно
      // 1080×1920 — стандартное разрешение сторис Instagram/TikTok.
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/asr_day_story_${widget.dateKey}.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'Дневник дня',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // баланс под кнопку закрытия
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Тапни по фото, чтобы сменить кадр · тапни по подписи, чтобы скрыть',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _captureKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: DayStoryCard(dateKey: widget.dateKey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _share,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(_isSharing ? 'Готовим...' : 'Поделиться'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
