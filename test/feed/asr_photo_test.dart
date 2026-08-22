import 'dart:io';

import 'package:asr/features/feed/data/photo_cache_service.dart';
import 'package:asr/shared/widgets/asr_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingPhotoCacheService extends PhotoCacheService {
  String? receivedSource;

  @override
  Future<File?> resolve(String source) async {
    receivedSource = source;
    return null;
  }
}

void main() {
  testWidgets('облачная ссылка передаётся resolver и не открывается как File(url)', (
    tester,
  ) async {
    final service = _RecordingPhotoCacheService();
    const url = 'https://example.test/photo.png';

    await tester.pumpWidget(
      MaterialApp(home: AsrPhoto(source: url, cacheService: service)),
    );
    await tester.pump();

    expect(service.receivedSource, url);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });
}
