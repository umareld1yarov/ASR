import 'dart:io';

import 'package:flutter/material.dart';

/// Полноэкранный просмотр фото записи — перелистывание свайпом,
/// приближение жестом, счётчик "N / M" сверху.
/// Удаление доступно только отсюда (с подтверждением) — намеренно,
/// чтобы фото не терялось случайным тапом.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    super.key,
    required this.photoPaths,
    required this.initialIndex,
    this.onDelete,
  });

  final List<String> photoPaths;
  final int initialIndex;

  /// Вызывается при подтверждённом удалении с путём удалённого фото.
  final Future<void> Function(String path)? onDelete;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late final PageController _controller;
  late int _currentIndex;
  late List<String> _photos;

  @override
  void initState() {
    super.initState();
    _photos = List<String>.from(widget.photoPaths);
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Удалить фото?'),
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

    if (confirmed != true) return;

    final removedPath = _photos[_currentIndex];
    if (widget.onDelete != null) {
      await widget.onDelete!(removedPath);
    }

    if (!mounted) return;

    setState(() {
      _photos.removeAt(_currentIndex);
    });

    if (_photos.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_currentIndex >= _photos.length) {
      setState(() => _currentIndex = _photos.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _photos.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(
                    File(_photos[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  if (_photos.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${_photos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    const SizedBox(),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                    ),
                    onPressed: widget.onDelete != null ? _confirmDelete : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
