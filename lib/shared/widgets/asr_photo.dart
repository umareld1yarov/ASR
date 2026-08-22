import 'dart:io';

import 'package:flutter/material.dart';

import '../../features/feed/data/photo_cache_service.dart';

class AsrPhoto extends StatefulWidget {
  const AsrPhoto({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.cacheService,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final PhotoCacheService? cacheService;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? errorBuilder;

  @override
  State<AsrPhoto> createState() => _AsrPhotoState();
}

class _AsrPhotoState extends State<AsrPhoto> {
  late Future<File?> _resolved;

  PhotoCacheService get _service =>
      widget.cacheService ?? PhotoCacheService.instance;

  @override
  void initState() {
    super.initState();
    _resolved = _service.resolve(widget.source);
  }

  @override
  void didUpdateWidget(covariant AsrPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.cacheService != widget.cacheService) {
      _resolved = _service.resolve(widget.source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: _resolved,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child:
                widget.loadingBuilder?.call(context) ??
                const ColoredBox(
                  color: Color(0xFF1F1F1F),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
          );
        }

        final file = snapshot.data;
        if (file == null) return _error(context);
        return Image.file(
          file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          errorBuilder: (context, _, _) => _error(context),
        );
      },
    );
  }

  Widget _error(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child:
          widget.errorBuilder?.call(context) ??
          const ColoredBox(
            color: Color(0xFF1F1F1F),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white24,
                size: 24,
              ),
            ),
          ),
    );
  }
}
