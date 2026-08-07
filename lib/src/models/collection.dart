import 'package:flutter/foundation.dart';

@immutable
class ShowlineCollection {
  const ShowlineCollection({
    required this.id,
    required this.name,
    required this.productIds,
  });

  final String id;
  final String name;
  final List<String> productIds;

  ShowlineCollection copyWith({String? name, List<String>? productIds}) {
    return ShowlineCollection(
      id: id,
      name: name ?? this.name,
      productIds: productIds ?? this.productIds,
    );
  }
}
