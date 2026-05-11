import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RoomImage extends StatelessWidget {
  const RoomImage({
    super.key,
    this.imagePath,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = 0,
  });

  final String? imagePath;
  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();

    if (borderRadius <= 0) return image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }

  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return _ImagePlaceholder(height: height, width: width);
    }

    if (imagePath!.startsWith('http') || kIsWeb) {
      return Image.network(
        imagePath!,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _ImagePlaceholder(height: height, width: width),
      );
    }

    return Image.file(
      File(imagePath!),
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          _ImagePlaceholder(height: height, width: width),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.height, required this.width});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(gradient: AppGradients.calm),
      child: Icon(
        Icons.apartment_rounded,
        size: 54,
        color: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }
}
