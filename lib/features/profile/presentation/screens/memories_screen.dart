import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../../../shared/widgets/app_background.dart';
import '../../application/profile_provider.dart';

class _MemoryPhoto {
  const _MemoryPhoto({
    required this.path,
    required this.name,
    required this.categoryKey,
    required this.startedAt,
  });

  final String path;
  final String name;
  final String categoryKey;
  final int startedAt;
}

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allMemoriesProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: entriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
            data: (entries) {
              final photos = <_MemoryPhoto>[
                for (final e in entries)
                  for (final path in e.photoPaths ?? <String>[])
                    _MemoryPhoto(
                      path: path,
                      name: e.name,
                      categoryKey: e.categoryKey,
                      startedAt: e.startedAt,
                    ),
              ];

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Воспоминания',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: photos.isEmpty
                          ? const Center(
                              child: Text(
                                'Пока нет фото — добавь их к записям в Ленте',
                                style: TextStyle(color: Colors.white38),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 6,
                                    crossAxisSpacing: 6,
                                  ),
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                final photo = photos[index];
                                return GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => _MemoryViewerScreen(
                                        photos: photos,
                                        initialIndex: index,
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(photo.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MemoryViewerScreen extends StatefulWidget {
  const _MemoryViewerScreen({required this.photos, required this.initialIndex});

  final List<_MemoryPhoto> photos;
  final int initialIndex;

  @override
  State<_MemoryViewerScreen> createState() => _MemoryViewerScreenState();
}

class _MemoryViewerScreenState extends State<_MemoryViewerScreen> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    final category = ActivityCategory.fromStorageKey(photo.categoryKey);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Center(
                    child: Image.file(File(widget.photos[index].path)),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          photo.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          du.DateUtils.formatShortRu(
                            DateTime.fromMillisecondsSinceEpoch(
                              photo.startedAt,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
