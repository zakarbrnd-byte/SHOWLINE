import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:idb_shim/idb_browser.dart';

import '../models/collection.dart';
import '../models/product.dart';
import 'collection_store_types.dart';

CollectionStore createCollectionStore() => _WebCollectionStore();

class _WebCollectionStore implements CollectionStore {
  static const _storeName = 'catalog';
  Database? _database;

  Future<Database> _open() async {
    final existing = _database;
    if (existing != null) return existing;
    final database = await idbFactoryBrowser.open(
      'showline_catalog',
      version: 1,
      onUpgradeNeeded: (event) {
        final database = event.database;
        if (!database.objectStoreNames.contains(_storeName)) {
          database.createObjectStore(_storeName);
        }
      },
    );
    _database = database;
    return database;
  }

  @override
  Future<StoredCatalog?> load() async {
    final database = await _open();
    final transaction = database.transaction(_storeName, idbModeReadOnly);
    final raw = await transaction.objectStore(_storeName).getObject('state');
    await transaction.completed;
    if (raw is! Map) return null;
    final map = Map<String, Object?>.from(raw);
    final productMaps = (map['products'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item));
    final collectionMaps = (map['collections'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item));
    return StoredCatalog(
      products: productMaps
          .map(
            (item) => Product(
              id: item['id']! as String,
              fileName: item['fileName']! as String,
              imageAsset: null,
              imageBytes: item['imageBytes']! as Uint8List,
              accent: Color((item['accent']! as num).toInt()),
            ),
          )
          .toList(),
      collections: collectionMaps
          .map(
            (item) => ShowlineCollection(
              id: item['id']! as String,
              name: item['name']! as String,
              productIds: List<String>.from(item['productIds']! as List),
            ),
          )
          .toList(),
      selectedCollectionId: map['selectedCollectionId'] as String?,
      revision: (map['revision'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> save(StoredCatalog catalog) async {
    final database = await _open();
    final transaction = database.transaction(_storeName, idbModeReadWrite);
    await transaction.objectStore(_storeName).put({
      'products': catalog.products
          .where((product) => product.imageBytes != null)
          .map(
            (product) => {
              'id': product.id,
              'fileName': product.fileName,
              'imageBytes': product.imageBytes,
              'accent': product.accent.toARGB32(),
            },
          )
          .toList(),
      'collections': catalog.collections
          .where((collection) => collection.id != 'demo-collection')
          .map(
            (collection) => {
              'id': collection.id,
              'name': collection.name,
              'productIds': collection.productIds,
            },
          )
          .toList(),
      'selectedCollectionId': catalog.selectedCollectionId,
      'revision': catalog.revision,
    }, 'state');
    await transaction.completed;
  }
}
