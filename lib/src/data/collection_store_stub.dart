import 'collection_store_types.dart';

CollectionStore createCollectionStore() => _MemoryCollectionStore();

class _MemoryCollectionStore implements CollectionStore {
  static StoredCatalog? _catalog;

  @override
  Future<StoredCatalog?> load() async => _catalog;

  @override
  Future<void> save(StoredCatalog catalog) async {
    _catalog = catalog;
  }
}
