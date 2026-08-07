import 'dart:typed_data';

import 'package:flutter/material.dart';

@immutable
class Product {
  const Product({
    required this.id,
    required this.fileName,
    required this.imageAsset,
    required this.accent,
    this.imageBytes,
  });

  final String id;
  final String fileName;
  final String? imageAsset;
  final Uint8List? imageBytes;
  final Color accent;

  String get nameWithoutExtension {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  String get styleCode {
    final underscore = nameWithoutExtension.indexOf('_');
    final hyphen = nameWithoutExtension.indexOf('-');
    final separators = [underscore, hyphen].where((index) => index > 0);
    final separator = separators.isEmpty
        ? -1
        : separators.reduce((first, next) => first < next ? first : next);
    return separator > 0
        ? nameWithoutExtension.substring(0, separator).toUpperCase()
        : nameWithoutExtension.toUpperCase();
  }

  String get colorName {
    final underscore = nameWithoutExtension.indexOf('_');
    final hyphen = nameWithoutExtension.indexOf('-');
    final separators = [underscore, hyphen].where((index) => index > 0);
    final separator = separators.isEmpty
        ? -1
        : separators.reduce((first, next) => first < next ? first : next);
    return separator > 0
        ? nameWithoutExtension
            .substring(separator + 1)
            .replaceAll('_', ' ')
            .replaceAll('-', ' ')
            .toUpperCase()
        : 'COLOR';
  }
}

const demoProducts = <Product>[
  Product(
    id: 'knd5001-black',
    fileName: 'KND5001_BLACK.jpg',
    imageAsset: 'assets/catalog/KND5001_BLACK.jpg',
    accent: Color(0xFF343434),
  ),
  Product(
    id: 'knt136-black-white',
    fileName: 'KNT136_BLACK_WHITE.jpg',
    imageAsset: 'assets/catalog/KNT136_BLACK_WHITE.jpg',
    accent: Color(0xFF777777),
  ),
];
