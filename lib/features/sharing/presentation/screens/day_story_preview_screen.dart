import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../stats/application/stats_provider.dart';
import '../../application/day_story_provider.dart';
import '../widgets/day_story_card.dart';
import '../widgets/month_story_card.dart';
import '../widgets/week_story_card.dart';
import '../widgets/year_story_card.dart';

/// Экран превью Сторис (9:16) перед шерингом.
/// Поддерживает как дневные истории (с фотографиями и заметками), так и
/// сводные открытки за периоды Неделя, Месяц и Год.
class DayStoryPreviewScreen extends ConsumerStatefulWidget {
  const DayStoryPreviewScreen({
    super.key,
    required this.dateKey,
    this.periodType = StatsPeriodType.day,
    this.range,
  });

  final String dateKey;
  final StatsPeriodType periodType;
  final StatsPeriodRange? range;

  @override
  ConsumerState<DayStoryPreviewScreen> createState() =>
      _DayStoryPreviewScreenState();
}

class _DayStoryPreviewScreenState extends ConsumerState<DayStoryPreviewScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // pixelRatio 3.0 при логическом размере карточки 360×640 даёт 1080×1920
      // (стандарт сторис Instagram / Telegram / TikTok).
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/asr_story_${widget.dateKey}.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(dayStorySelectionProvider);
    final controller = ref.read(dayStorySelectionProvider.notifier);

    final isSingleDay =
        widget.periodType == StatsPeriodType.day || widget.range == null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Заголовок и кнопка закрытия
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      'sharing.story_preview_title'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Фильтры и темы доступны для дневных сторис
            if (isSingleDay) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ThemeChip(
                        label: 'sharing.theme_journal'.tr(),
                        isSelected: selection.theme == DayStoryTheme.journal,
                        onTap: () => controller.setTheme(DayStoryTheme.journal),
                      ),
                      const SizedBox(width: 8),
                      _ThemeChip(
                        label: 'sharing.theme_dark_focus'.tr(),
                        isSelected: selection.theme == DayStoryTheme.darkFocus,
                        onTap: () =>
                            controller.setTheme(DayStoryTheme.darkFocus),
                      ),
                      const SizedBox(width: 8),
                      _ThemeChip(
                        label: 'sharing.theme_minimal'.tr(),
                        isSelected:
                            selection.theme == DayStoryTheme.minimalQuote,
                        onTap: () =>
                            controller.setTheme(DayStoryTheme.minimalQuote),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ToggleFilterChip(
                      label: 'nav.stats'.tr(),
                      icon: Icons.bar_chart_outlined,
                      isActive: selection.showStats,
                      onTap: controller.toggleShowStats,
                    ),
                    const SizedBox(width: 10),
                    _ToggleFilterChip(
                      label: 'feed.note'.tr(),
                      icon: Icons.edit_note,
                      isActive: selection.showNotes,
                      onTap: controller.toggleShowNotes,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),

            // Область рендеринга карточки в 9:16
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: _captureKey,
                  child: isSingleDay
                      ? DayStoryCard(dateKey: widget.dateKey)
                      : _buildPeriodStoryWidget(
                          widget.periodType,
                          widget.range!,
                        ),
                ),
              ),
            ),

            // Кнопка экспорта в системный шер
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _share,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  icon: _isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.ios_share, size: 20),
                  label: Text(
                    _isSharing
                        ? 'sharing.preparing_story'.tr()
                        : 'sharing.share_story'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodStoryWidget(
    StatsPeriodType periodType,
    StatsPeriodRange range,
  ) {
    final periodDataAsync = ref.watch(periodStoryDataProvider(range));

    return periodDataAsync.when(
      loading: () => const SizedBox(
        width: 360,
        height: 640,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
        ),
      ),
      error: (e, _) => SizedBox(
        width: 360,
        height: 640,
        child: Center(
          child: Text(
            '${"common.error".tr()}: $e',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
      data: (periodData) {
        switch (periodType) {
          case StatsPeriodType.week:
            return WeekStoryCard(data: periodData);
          case StatsPeriodType.month:
            return MonthStoryCard(data: periodData);
          case StatsPeriodType.year:
            return YearStoryCard(data: periodData);
          case StatsPeriodType.day:
            return DayStoryCard(dateKey: widget.dateKey);
        }
      },
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06B6D4)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ToggleFilterChip extends StatelessWidget {
  const _ToggleFilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF06B6D4) : Colors.white38,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
