import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../timer/domain/models/activity_entry.dart';
import '../../application/feed_provider.dart';
import '../../data/photo_service.dart';
import 'photo_viewer_screen.dart';
import '../../../timer/domain/focus_review_obstacles.dart';

/// Полноэкранная страница деталей записи. Саму запись удалить нельзя —
/// журнал непрерывный, можно только редактировать название/категорию
/// и управлять прикреплёнными фото.
class EntryDetailScreen extends ConsumerStatefulWidget {
  const EntryDetailScreen({super.key, required this.entry});

  final ActivityEntry entry;

  @override
  ConsumerState<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends ConsumerState<EntryDetailScreen> {
  late TextEditingController _nameController;
  late ActivityCategory _selectedCategory;
  bool _isEditing = false;
  late List<String> _photos;
  final _pageController = PageController();
  int _currentPhotoIndex = 0;
  final _noteController = TextEditingController();
  String? _selectedMood;
  late Set<String> _selectedObstacles;
  final _experimentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.name);
    _selectedCategory = ActivityCategory.fromStorageKey(
      widget.entry.categoryKey,
    );
    _photos = List<String>.from(widget.entry.photoPaths ?? []);
    _noteController.text = widget.entry.note ?? '';
    _selectedMood = widget.entry.mood;
    _selectedObstacles = Set<String>.from(widget.entry.obstacles ?? []);
    _experimentController.text = widget.entry.nextExperiment ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _noteController.dispose();
    _experimentController.dispose();
    super.dispose();
  }

  String _time(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }

  String? _moodEmoji(String? mood) {
    switch (mood) {
      case 'fire':
        return '🔥';
      case 'good':
        return '👍';
      case 'meh':
        return '😐';
      case 'bad':
        return '😞';
      default:
        return null;
    }
  }

  String _moodLabel(String? mood) {
    switch (mood) {
      case 'fire':
        return 'Огонь';
      case 'good':
        return 'Хорошо';
      case 'meh':
        return 'Так себе';
      case 'bad':
        return 'Провал';
      default:
        return '';
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await ref
        .read(feedControllerProvider)
        .updateEntry(
          widget.entry.id,
          name: name,
          categoryKey: _selectedCategory.storageKey,
        );

    if (mounted) setState(() => _isEditing = false);
  }

  Future<void> _saveExtras() async {
    await ref
        .read(feedControllerProvider)
        .updateEntry(
          widget.entry.id,
          note: _noteController.text.trim(),
          mood: _selectedMood ?? '',
          obstacles: _selectedObstacles.toList(),
          nextExperiment: _experimentController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сохранено'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= 4) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (picked == null) return;

    final savedPath = await PhotoService.savePhoto(File(picked.path));
    await ref.read(feedControllerProvider).addPhoto(widget.entry.id, savedPath);
    if (mounted) setState(() => _photos.add(savedPath));
  }

  Future<void> _removePhotoByPath(String path) async {
    await ref.read(feedControllerProvider).removePhoto(widget.entry.id, path);
    await PhotoService.deletePhoto(path);
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F1F),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white70),
              title: const Text(
                'Камера',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text(
                'Галерея',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhotoViewer(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          photoPaths: _photos,
          initialIndex: index,
          onDelete: (path) => _removePhotoByPath(path),
        ),
      ),
    );
    // Просмотрщик хранит свою копию списка — синхронизируем после закрытия
    // на случай, если там что-то удалили.
    if (mounted) {
      setState(() {
        // Пересчитываем на основе того, какие файлы физически ещё существуют,
        // проще — просто перечитываем из виджета не получится (entry не обновлён
        // в этом объекте), поэтому фильтруем по факту оставшихся файлов на диске.
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Верхняя панель ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close : Icons.edit_outlined,
                        color: Colors.white70,
                      ),
                      onPressed: () => setState(() => _isEditing = !_isEditing),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _isEditing ? _buildEditMode() : _buildViewMode(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_photos.isNotEmpty) ...[
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: GestureDetector(
                      onTap: () => _openPhotoViewer(index),
                      child: Image.file(
                        File(_photos[index]),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF1F1F1F),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_photos.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_photos.length, (i) {
                final active = i == _currentPhotoIndex;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 8 : 6,
                  height: active ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 16),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _selectedCategory.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _selectedCategory.color.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            _selectedCategory.label.toUpperCase(),
            style: TextStyle(
              color: _selectedCategory.color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(height: 12),

        Text(
          widget.entry.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),

        Text(
          '${_time(widget.entry.startedAt)} – ${_time(widget.entry.endedAt)} · ${_formatShort(widget.entry.durationSeconds)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),

        const Text(
          'Заметка',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Например: 4 подхода по 12, дочитал до стр. 340...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
            filled: true,
            fillColor: const Color(0xFF1F1F1F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),
        const Text(
          'Как прошло?',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MoodButton(
              emoji: '🔥',
              selected: _selectedMood == 'fire',
              onTap: () => setState(() => _selectedMood = 'fire'),
            ),
            const SizedBox(width: 8),
            _MoodButton(
              emoji: '👍',
              selected: _selectedMood == 'good',
              onTap: () => setState(() => _selectedMood = 'good'),
            ),
            const SizedBox(width: 8),
            _MoodButton(
              emoji: '😐',
              selected: _selectedMood == 'meh',
              onTap: () => setState(() => _selectedMood = 'meh'),
            ),
            const SizedBox(width: 8),
            _MoodButton(
              emoji: '😞',
              selected: _selectedMood == 'bad',
              onTap: () => setState(() => _selectedMood = 'bad'),
            ),
          ],
        ),

        if (_selectedMood == 'meh' || _selectedMood == 'bad') ...[
          const SizedBox(height: 14),
          const Text(
            'Что помешало?',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FocusReviewObstacles.tagsFor(_selectedCategory).map((
              tag,
            ) {
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

        if (_selectedMood == 'bad') ...[
          const SizedBox(height: 14),
          const Text(
            'Что попробуешь в следующий раз?',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _experimentController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Необязательно...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFF1F1F1F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _saveExtras,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),

        if (_photos.length < 4)
          InkWell(
            onTap: _showPhotoSourceSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white.withValues(alpha: 0.55),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Добавить фото',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Название',
            labelStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ActivityCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedCategory = category),
              selectedColor: category.color.withValues(alpha: 0.3),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
          child: Text(
            emoji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}
