import '../models/collection.dart';
import '../models/product.dart';

class StoredCatalog {
  const StoredCatalog({
    required this.products,
    required this.collections,
    required this.selectedCollectionId,
    required this.revision,
  });

  final List<Product> products;
  final List<ShowlineCollection> collections;
  final String? selectedCollectionId;
  final int revision;
}

abstract interface class CollectionStore {
  Future<StoredCatalog?> load();
  Future<void> save(StoredCatalog catalog);
}
