import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/domain/models/activity_entry.dart';
import '../../application/feed_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../data/photo_service.dart';

/// Шторка деталей записи: просмотр + редактирование + удаление.
/// Аналог #detail-modal-overlay из index.html (PWA).
class EntryDetailSheet extends ConsumerStatefulWidget {
  const EntryDetailSheet({super.key, required this.entry});

  final ActivityEntry entry;

  static Future<void> show(BuildContext context, ActivityEntry entry) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EntryDetailSheet(entry: entry),
    );
  }

  @override
  ConsumerState<EntryDetailSheet> createState() => _EntryDetailSheetState();
}

class _EntryDetailSheetState extends ConsumerState<EntryDetailSheet> {
  late TextEditingController _nameController;
  late ActivityCategory _selectedCategory;
  bool _isEditing = false;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.name);
    _selectedCategory = ActivityCategory.fromStorageKey(
      widget.entry.categoryKey,
    );
    _photos = List<String>.from(widget.entry.photoPaths ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _time(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч $mм';
    return '$mм';
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

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Удалить запись?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(feedControllerProvider).deleteEntry(widget.entry.id);
      if (mounted) Navigator.of(context).pop();
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

  Future<void> _removePhoto(String path) async {
    await ref.read(feedControllerProvider).removePhoto(widget.entry.id, path);
    await PhotoService.deletePhoto(path);
    if (mounted) setState(() => _photos.remove(path));
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
            'Детали активности',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (!_isEditing) ...[
            // ── Режим просмотра ──
            _DetailRow(label: 'Название:', value: widget.entry.name),
            _DetailRow(label: 'Категория:', value: _selectedCategory.label),
            _DetailRow(
              label: 'Интервал:',
              value:
                  '${_time(widget.entry.startedAt)} – ${_time(widget.entry.endedAt)}',
            ),
            _DetailRow(
              label: 'Длительность:',
              value: _formatShort(widget.entry.durationSeconds),
            ),
            if (widget.entry.mood != null) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _moodEmoji(widget.entry.mood)!,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _moodLabel(widget.entry.mood),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              if (widget.entry.obstacles != null &&
                  widget.entry.obstacles!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.entry.obstacles!.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (widget.entry.nextExperiment != null &&
                  widget.entry.nextExperiment!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '💡 Следующий раз: ${widget.entry.nextExperiment}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Row(
              children: [
                ..._photos.map(
                  (path) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(path),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFF1F1F1F),
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white24,
                                  size: 22,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => _removePhoto(path),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_photos.length < 4)
                  InkWell(
                    onTap: _showPhotoSourceSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    child: const Text('Редактировать'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _delete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Удалить'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // ── Режим редактирования ──
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
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
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                  selectedColor: category.color.withValues(alpha: 0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
