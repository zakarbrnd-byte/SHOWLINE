import 'package:flutter/material.dart';

import '../models/product.dart';

class CatalogImage extends StatelessWidget {
  const CatalogImage({
    required this.product,
    super.key,
    this.fit = BoxFit.contain,
  });

  final Product product;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = product.imageBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: fit, gaplessPlayback: true);
    }
    final asset = product.imageAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: fit,
        errorBuilder: (_, __, ___) => _MissingImage(fileName: product.fileName),
      );
    }
    return _MissingImage(fileName: product.fileName);
  }
}

class _MissingImage extends StatelessWidget {
  const _MissingImage({required this.fileName});
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, size: 42),
          const SizedBox(height: 8),
          Text(fileName, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
