import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_pill_button.dart';
import '../../../timer/domain/models/activity_entry.dart';
import '../../application/feed_provider.dart';
import '../../data/photo_service.dart';
import 'photo_viewer_screen.dart';
import 'split_entry_screen.dart';

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
  final _noteFocusNode = FocusNode();
  bool _isEditingNote = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry.name);
    _selectedCategory = ActivityCategory.fromStorageKey(
      widget.entry.categoryKey,
    );
    _photos = List<String>.from(widget.entry.photoPaths ?? []);
    _noteController.text = widget.entry.note ?? '';

    _noteFocusNode.addListener(() {
      if (!_noteFocusNode.hasFocus && _isEditingNote) {
        _saveNote();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pageController.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  String _time(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatShort(int seconds) {
    return formatDuration(seconds);
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

  Future<void> _splitEntry() async {
    final result = await Navigator.of(context).push<SplitEntryResult>(
      MaterialPageRoute(builder: (_) => SplitEntryScreen(entry: widget.entry)),
    );
    if (result == null || !mounted) return;

    await ref
        .read(feedControllerProvider)
        .splitEntry(
          widget.entry.id,
          splitAt: result.splitAt,
          firstName: result.firstName,
          firstCategoryKey: result.firstCategory.storageKey,
          secondName: result.secondName,
          secondCategoryKey: result.secondCategory.storageKey,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('feed.split_success'.tr())));
  }

  void _startEditingNote() {
    setState(() => _isEditingNote = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _noteFocusNode.requestFocus();
    });
  }

  Future<void> _saveNote() async {
    await ref
        .read(feedControllerProvider)
        .updateEntry(widget.entry.id, note: _noteController.text.trim());
    if (!mounted) return;
    setState(() => _isEditingNote = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('common.saved'.tr()),
        duration: const Duration(seconds: 1),
      ),
    );
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
              title: Text(
                'common.camera'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: Text(
                'common.gallery'.tr(),
                style: const TextStyle(color: Colors.white),
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
          const SizedBox(height: 10),
        ],

        if (_photos.length < 4)
          InkWell(
            onTap: _showPhotoSourceSheet,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'timer.photo_add'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

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
        const SizedBox(height: 14),

        _buildNoteSection(),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNoteSection() {
    if (_isEditingNote) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'feed.note'.tr(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            focusNode: _noteFocusNode,
            autofocus: true,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'feed.note_hint'.tr(),
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saveNote,
              child: Text('common.done'.tr()),
            ),
          ),
        ],
      );
    }

    final hasNote = _noteController.text.trim().isNotEmpty;

    return InkWell(
      onTap: _startEditingNote,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              'feed.note'.tr(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasNote ? _noteController.text.trim() : 'feed.add_note'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasNote
                      ? Colors.white70
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                  fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'feed.name_label'.tr(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'feed.name_label'.tr(),
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: _selectedCategory.color.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _selectedCategory.color.withValues(alpha: 0.45),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _selectedCategory.color,
                width: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'feed.category_label'.tr(),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.82,
          children: ActivityCategory.values.map(_buildCategoryTile).toList(),
        ),
        const SizedBox(height: 26),
        GlassPillButton(
          onTap: _save,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'feed.save_changes'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassPillButton(
          onTap: _splitEntry,
          subtle: true,
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.call_split_rounded,
                color: Colors.white70,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'feed.split_action'.tr(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCategoryTile(ActivityCategory category) {
    final selected = _selectedCategory == category;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = category),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: selected ? 0.25 : 0.08),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: category.color.withValues(alpha: selected ? 0.9 : 0.3),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: category.color.withValues(alpha: 0.16),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 1),
                    Text(
                      category.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontSize: 10,
                        height: 1,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: category.color,
                    size: 13,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
