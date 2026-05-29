// lib/core/widgets/cached_image.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useCache;
  
  const CachedImage({
    Key? key,
    this.imageUrl,
    this.filePath,
    this.width = double.infinity,
    this.height = 120,
    this.fit = BoxFit.cover,
    this.borderRadius = 12,
    this.placeholder,
    this.errorWidget,
    this.useCache = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // صورة محلية من الملف
    if (filePath != null && filePath!.isNotEmpty) {
      return _buildLocalImage();
    }
    
    // صورة من URL
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return useCache ? _buildNetworkImage() : _buildSimpleNetworkImage();
    }
    
    // Placeholder
    return _buildPlaceholder();
  }
  
  Widget _buildLocalImage() {
    return Image.file(
      File(filePath!),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }
  
  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => placeholder ?? _buildLoader(),
      errorWidget: (_, __, ___) => errorWidget ?? _buildPlaceholder(),
      cacheKey: imageUrl,
      memCacheWidth: width.toInt(),
      memCacheHeight: height.toInt(),
    );
  }
  
  Widget _buildSimpleNetworkImage() {
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildLoader();
      },
      errorBuilder: (_, __, ___) => errorWidget ?? _buildPlaceholder(),
    );
  }

  Widget _buildLoader() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.teal.shade50,
      child: const Center(
        child: Icon(Icons.medication, size: 40, color: Colors.teal),
      ),
    );
  }
}

/// صورة دائرية مع كاش
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? filePath;
  final double radius;
  final Widget? fallback;
  
  const CachedAvatar({
    Key? key,
    this.imageUrl,
    this.filePath,
    this.radius = 30,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.teal.shade100,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: CachedImage(
            imageUrl: imageUrl,
            filePath: filePath,
            width: radius * 2,
            height: radius * 2,
            borderRadius: radius * 2,
            placeholder: fallback,
            errorWidget: fallback,
          ),
        ),
      ),
    );
  }
}