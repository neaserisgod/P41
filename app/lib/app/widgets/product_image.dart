import 'dart:io';

import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.source,
    required this.fit,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.errorBuilder,
  });

  final String source;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  )?
  errorBuilder;

  @override
  Widget build(BuildContext context) {
    final normalized = source.trim();
    final provider = _resolveProvider(normalized);
    if (provider == null) {
      return errorBuilder?.call(
            context,
            StateError('image-source-empty'),
            null,
          ) ??
          const SizedBox.shrink();
    }

    return Image(
      image: provider,
      fit: fit,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );
  }

  ImageProvider<Object>? _resolveProvider(String normalized) {
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    if (normalized.startsWith('file://')) {
      return FileImage(File.fromUri(Uri.parse(normalized)));
    }
    final file = File(normalized);
    if (file.isAbsolute) {
      return FileImage(file);
    }
    return NetworkImage(normalized);
  }
}
