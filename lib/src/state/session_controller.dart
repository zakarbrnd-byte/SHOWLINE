import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_repository.dart';
import '../data/collection_store.dart';
import '../data/collection_store_types.dart';
import '../models/collection.dart';
import '../models/product.dart';
import '../models/session.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => const DemoSessionRepository(),
);

final collectionStoreProvider = Provider<CollectionStore>(
  (ref) => createCollectionStore(),
);

class UploadedCatalogFile {
  const UploadedCatalogFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

final sessionControllerProvider =
    NotifierProvider<ShowlineSessionController, ShowlineSession>(
  ShowlineSessionController.new,
);

final activeProductProvider = Provider(
  (ref) => ref.watch(
    sessionControllerProvider.select((session) => session.activeProduct),
  ),
);

final currentBuyerInterestsProvider = Provider<Set<String>>(
  (ref) => ref.watch(sessionControllerProvider.select(
    (session) => session.interestsFor('demo-buyer'),
  )),
);

class ShowlineSessionController extends Notifier<ShowlineSession> {
  Timer? _syncTimer;
  Timer? _catalogTimer;
  bool _isPulling = false;
  bool _isPullingCatalog = false;

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);
  CollectionStore get _collectionStore => ref.read(collectionStoreProvider);

  @override
  ShowlineSession build() {
    _syncTimer = Timer.periodic(
      const Duration(milliseconds: 350),
      (_) => _pullSharedState(),
    );
    _catalogTimer = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => _pullCatalog(),
    );
    ref.onDispose(() {
      _syncTimer?.cancel();
      _catalogTimer?.cancel();
    });
    Future<void>.microtask(_pullSharedState);
    Future<void>.microtask(_pullCatalog);
    return ShowlineSession.demo();
  }

  Future<void> _pullCatalog() async {
    if (_isPullingCatalog) return;
    _isPullingCatalog = true;
    try {
      final stored = await _collectionStore.load();
      if (stored == null || stored.revision <= state.catalogRevision) return;
      final catalogProducts = [
        ...demoProducts,
        ...stored.products.where(
          (product) => !demoProducts.any((demo) => demo.id == product.id),
        ),
      ];
      final collections = [
        state.collections.firstWhere(
          (collection) => collection.id == 'demo-collection',
        ),
        ...stored.collections,
      ];
      final selectedId = collections.any(
        (collection) => collection.id == stored.selectedCollectionId,
      )
          ? stored.selectedCollectionId!
          : state.selectedCollectionId;
      final products = _productsFor(
        catalogProducts,
        collections,
        selectedId,
        const [],
      );
      if (products.isEmpty) return;
      state = state.copyWith(
        catalogProducts: catalogProducts,
        collections: collections,
        selectedCollectionId: selectedId,
        temporaryProductIds: const [],
        products: products,
        activeProductIndex:
            state.activeProductIndex.clamp(0, products.length - 1).toInt(),
        selectedProductIndex:
            state.selectedProductIndex.clamp(0, products.length - 1).toInt(),
        catalogRevision: stored.revision,
      );
    } finally {
      _isPullingCatalog = false;
    }
  }

  List<Product> _productsFor(
    List<Product> catalog,
    List<ShowlineCollection> collections,
    String collectionId,
    List<String> temporaryIds,
  ) {
    final collection = collections.firstWhere(
      (item) => item.id == collectionId,
      orElse: () => collections.first,
    );
    final ids = {...collection.productIds, ...temporaryIds};
    final products = <Product>[];
    for (final id in ids) {
      final matches = catalog.where((product) => product.id == id);
      if (matches.isNotEmpty) products.add(matches.first);
    }
    return products;
  }

  Future<void> createCollection(
    String name,
    List<UploadedCatalogFile> files,
  ) async {
    if (name.trim().isEmpty) return;
    final id = 'collection-${DateTime.now().millisecondsSinceEpoch}';
    final collection = ShowlineCollection(
      id: id,
      name: name.trim(),
      productIds: const [],
    );
    final revision = DateTime.now().microsecondsSinceEpoch;
    state = state.copyWith(
      collections: [...state.collections, collection],
      catalogRevision: revision,
    );
    await _saveCatalog(revision);
    if (files.isNotEmpty) await addPictures(id, files);
  }

  Future<void> addPictures(
    String collectionId,
    List<UploadedCatalogFile> files,
  ) async {
    if (files.isEmpty) return;
    final uploaded = files.map((file) {
      final normalized = file.name
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'(^-|-$)'), '');
      return Product(
        id: normalized,
        fileName: file.name,
        imageAsset: null,
        imageBytes: file.bytes,
        accent: const Color(0xFF777777),
      );
    }).toList();
    final catalog = [...state.catalogProducts];
    for (final product in uploaded) {
      catalog.removeWhere((item) => item.id == product.id);
      catalog.add(product);
    }
    final collections = state.collections.map((collection) {
      if (collection.id != collectionId) return collection;
      return collection.copyWith(
        productIds: {
          ...collection.productIds,
          ...uploaded.map((product) => product.id),
        }.toList(),
      );
    }).toList();
    final revision = DateTime.now().microsecondsSinceEpoch;
    final isSelected = state.selectedCollectionId == collectionId;
    final products = isSelected
        ? _productsFor(catalog, collections, collectionId, const [])
        : state.products;
    state = state.copyWith(
      catalogProducts: catalog,
      collections: collections,
      products: products,
      activeProductIndex: isSelected ? 0 : state.activeProductIndex,
      selectedProductIndex: isSelected ? 0 : state.selectedProductIndex,
      catalogRevision: revision,
    );
    await _saveCatalog(revision);
  }

  Future<void> selectCollection(String id) async {
    if (state.status == SessionStatus.live &&
        id != state.selectedCollectionId) {
      if (!state.buyerConnected) {
        await _applyCollection(id);
        return;
      }
      final version = DateTime.now().microsecondsSinceEpoch;
      state = state.copyWith(
        suggestedCollectionId: id,
        collectionSuggestionVersion: version,
      );
      await _repository.saveCollectionSuggestion(state.id, id, version);
      return;
    }
    await _applyCollection(id);
  }

  Future<void> _applyCollection(String id) async {
    if (!state.collections.any((collection) => collection.id == id)) return;
    final products = _productsFor(
      state.catalogProducts,
      state.collections,
      id,
      const [],
    );
    if (products.isEmpty) return;
    final revision = DateTime.now().microsecondsSinceEpoch;
    state = state.copyWith(
      selectedCollectionId: id,
      temporaryProductIds: const [],
      products: products,
      activeProductIndex: 0,
      selectedProductIndex: 0,
      catalogRevision: revision,
    );
    await _saveCatalog(revision);
    await _repository.saveTemporaryProductIds(state.id, const []);
    await updateBuyerView(0);
  }

  Future<void> acceptSuggestedCollection() async {
    final id = state.suggestedCollectionId;
    if (id == null) return;
    await _applyCollection(id);
  }

  Future<void> renameCollection(String id, String name) async {
    if (name.trim().isEmpty) return;
    final collections = state.collections
        .map((item) => item.id == id ? item.copyWith(name: name.trim()) : item)
        .toList();
    final revision = DateTime.now().microsecondsSinceEpoch;
    state = state.copyWith(collections: collections, catalogRevision: revision);
    await _saveCatalog(revision);
  }

  Future<void> reorderCollectionProducts(
    String collectionId,
    int oldIndex,
    int newIndex,
  ) async {
    final collections = state.collections.map((collection) {
      if (collection.id != collectionId) return collection;
      final ids = [...collection.productIds];
      final id = ids.removeAt(oldIndex);
      ids.insert(newIndex, id);
      return collection.copyWith(productIds: ids);
    }).toList();
    final revision = DateTime.now().microsecondsSinceEpoch;
    final products = _productsFor(
      state.catalogProducts,
      collections,
      state.selectedCollectionId,
      state.temporaryProductIds,
    );
    state = state.copyWith(
      collections: collections,
      products: products,
      activeProductIndex:
          state.activeProductIndex.clamp(0, products.length - 1).toInt(),
      selectedProductIndex:
          state.selectedProductIndex.clamp(0, products.length - 1).toInt(),
      catalogRevision: revision,
    );
    await _saveCatalog(revision);
  }

  Future<void> removePicture(String collectionId, String productId) async {
    final collections = state.collections.map((collection) {
      if (collection.id != collectionId) return collection;
      return collection.copyWith(
        productIds:
            collection.productIds.where((id) => id != productId).toList(),
      );
    }).toList();
    final revision = DateTime.now().microsecondsSinceEpoch;
    var products = state.products;
    var selectedCollectionId = state.selectedCollectionId;
    if (state.selectedCollectionId == collectionId) {
      products = _productsFor(
        state.catalogProducts,
        collections,
        collectionId,
        state.temporaryProductIds,
      );
      if (products.isEmpty) {
        selectedCollectionId = 'demo-collection';
        products = _productsFor(
          state.catalogProducts,
          collections,
          selectedCollectionId,
          const [],
        );
      }
    }
    state = state.copyWith(
      collections: collections,
      selectedCollectionId: selectedCollectionId,
      temporaryProductIds: selectedCollectionId == collectionId
          ? state.temporaryProductIds
          : const [],
      products: products,
      activeProductIndex:
          state.activeProductIndex.clamp(0, products.length - 1).toInt(),
      selectedProductIndex:
          state.selectedProductIndex.clamp(0, products.length - 1).toInt(),
      catalogRevision: revision,
    );
    await _saveCatalog(revision);
  }

  Future<void> deleteCollection(String id) async {
    if (id == 'demo-collection') return;
    final collections =
        state.collections.where((item) => item.id != id).toList();
    final selected = state.selectedCollectionId == id
        ? 'demo-collection'
        : state.selectedCollectionId;
    final products = _productsFor(
      state.catalogProducts,
      collections,
      selected,
      const [],
    );
    final revision = DateTime.now().microsecondsSinceEpoch;
    state = state.copyWith(
      collections: collections,
      selectedCollectionId: selected,
      products: products,
      temporaryProductIds: const [],
      activeProductIndex: 0,
      selectedProductIndex: 0,
      catalogRevision: revision,
    );
    await _saveCatalog(revision);
  }

  Future<void> _saveCatalog(int revision) {
    return _collectionStore.save(
      StoredCatalog(
        products: state.catalogProducts,
        collections: state.collections,
        selectedCollectionId: state.selectedCollectionId,
        revision: revision,
      ),
    );
  }

  Future<void> addTemporaryProduct(String productId) async {
    if (state.products.any((product) => product.id == productId)) {
      final index =
          state.products.indexWhere((product) => product.id == productId);
      await updateBuyerView(index);
      return;
    }
    final temporary = [...state.temporaryProductIds, productId];
    final products = _productsFor(
      state.catalogProducts,
      state.collections,
      state.selectedCollectionId,
      temporary,
    );
    state = state.copyWith(
      temporaryProductIds: temporary,
      products: products,
      activeProductIndex: products.length - 1,
    );
    await _repository.saveTemporaryProductIds(state.id, temporary);
    await updateBuyerView(products.length - 1);
  }

  Future<void> exitTemporaryProduct() async {
    final currentId = state.activeProduct.id;
    if (!state.temporaryProductIds.contains(currentId)) return;
    final temporary =
        state.temporaryProductIds.where((id) => id != currentId).toList();
    final products = _productsFor(
      state.catalogProducts,
      state.collections,
      state.selectedCollectionId,
      temporary,
    );
    state = state.copyWith(
      temporaryProductIds: temporary,
      products: products,
      activeProductIndex: 0,
    );
    await _repository.saveTemporaryProductIds(state.id, temporary);
    await updateBuyerView(0);
  }

  Future<void> _pullSharedState() async {
    if (_isPulling || state.isSyncing) return;
    _isPulling = true;
    try {
      final shared = await _repository.readSharedState(state.id);
      final sharedProducts = _productsFor(
        state.catalogProducts,
        state.collections,
        state.selectedCollectionId,
        shared.temporaryProductIds,
      );
      final buyerIndex = shared.buyerProductIndex;
      final safeBuyerIndex = buyerIndex != null &&
              buyerIndex >= 0 &&
              buyerIndex < sharedProducts.length
          ? buyerIndex
          : state.activeProductIndex
              .clamp(0, sharedProducts.length - 1)
              .toInt();
      final favoriteIds = shared.favoriteProductIds;
      final interests = shared.hasFavoriteState
          ? favoriteIds
              .where((id) =>
                  state.catalogProducts.any((product) => product.id == id))
              .map(
                (id) => InterestEvent(
                  buyerId: 'demo-buyer',
                  productId: id,
                  createdAt: DateTime.now(),
                ),
              )
              .toList()
          : state.interests;
      if (state.isSyncing) return;
      state = state.copyWith(
        products: sharedProducts,
        temporaryProductIds: shared.temporaryProductIds,
        activeProductIndex: safeBuyerIndex,
        interests: interests,
        suggestedProductIndex: shared.suggestedProductIndex,
        suggestionVersion: shared.suggestionVersion,
        status: shared.status,
        suggestedCollectionId: shared.suggestedCollectionId,
        collectionSuggestionVersion: shared.collectionSuggestionVersion,
        hasJoinedAsBuyer: shared.status == SessionStatus.live
            ? state.hasJoinedAsBuyer
            : false,
        buyerConnected: shared.buyerConnected,
      );
    } finally {
      _isPulling = false;
    }
  }

  void switchRole(AppRole role) {
    state = state.copyWith(role: role);
  }

  Future<void> initializeSellerDashboard() async {
    state = state.copyWith(
      status: SessionStatus.lobby,
      buyerConnected: false,
      suggestionVersion: 0,
      collectionSuggestionVersion: 0,
      temporaryProductIds: const [],
      clearSuggestedProduct: true,
      clearSuggestedCollection: true,
    );
    await _repository.resetPresentationSignals(state.id);
    await _repository.updateStatus(state.id, SessionStatus.lobby);
  }

  bool joinAsBuyer({required String name, required String code}) {
    if (state.status != SessionStatus.live ||
        name.trim().isEmpty ||
        code.trim().toUpperCase() != state.code) {
      return false;
    }
    final buyer = BuyerProfile(
      id: 'demo-buyer',
      name: name.trim(),
      company: 'Guest buyer',
    );
    state = state.copyWith(
      buyers: [
        ...state.buyers.where((item) => item.id != buyer.id),
        buyer,
      ],
      hasJoinedAsBuyer: true,
      currentBuyerName: buyer.name,
      buyerConnected: true,
    );
    unawaited(_repository.saveBuyerConnected(state.id, true));
    return true;
  }

  Future<void> startPresentation() async {
    if (state.status == SessionStatus.live || state.isSyncing) return;
    final previous = state;
    state = state.copyWith(
      status: SessionStatus.live,
      isSyncing: true,
      suggestionVersion: 0,
      collectionSuggestionVersion: 0,
      buyerConnected: false,
      temporaryProductIds: const [],
      clearSuggestedProduct: true,
      clearSuggestedCollection: true,
    );
    try {
      await _repository.resetPresentationSignals(state.id);
      await _repository.updateStatus(state.id, SessionStatus.live);
      state = state.copyWith(isSyncing: false);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> endPresentation() async {
    if (state.status == SessionStatus.ended || state.isSyncing) return;
    final previous = state;
    state = state.copyWith(status: SessionStatus.ended, isSyncing: true);
    try {
      await _repository.updateStatus(state.id, SessionStatus.ended);
      await _repository.saveBuyerConnected(state.id, false);
      state = state.copyWith(isSyncing: false, buyerConnected: false);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  Future<void> spotlight(int index) async {
    if (index < 0 || index >= state.products.length || state.isSyncing) return;
    final previous = state;
    state = state.copyWith(
      activeProductIndex: index,
      status: SessionStatus.live,
      isSyncing: true,
    );
    try {
      await _repository.spotlightProduct(state.id, state.products[index].id);
      state = state.copyWith(isSyncing: false);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }

  void selectSuggestion(int index) {
    if (index < 0 || index >= state.products.length) return;
    state = state.copyWith(selectedProductIndex: index);
  }

  void moveSuggestionSelection(int delta) {
    final next = (state.selectedProductIndex + delta)
        .clamp(0, state.products.length - 1)
        .toInt();
    selectSuggestion(next);
  }

  Future<void> updateBuyerView(int index) async {
    if (index < 0 || index >= state.products.length) return;
    state = state.copyWith(activeProductIndex: index);
    await _repository.saveBuyerProductIndex(state.id, index);
  }

  Future<void> suggestSelectedProduct() async {
    if (!state.buyerConnected || state.status != SessionStatus.live) return;
    final version = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      suggestedProductIndex: state.selectedProductIndex,
      suggestionVersion: version,
    );
    await _repository.saveSuggestion(
      state.id,
      state.selectedProductIndex,
      version,
    );
  }

  Future<void> openSuggestion() async {
    final index = state.suggestedProductIndex;
    if (index == null) return;
    await updateBuyerView(index);
  }

  Future<void> moveSpotlight(int delta) async {
    final next = (state.activeProductIndex + delta)
        .clamp(0, state.products.length - 1)
        .toInt();
    await spotlight(next);
  }

  Future<void> toggleInterest(String productId) async {
    const buyerId = 'demo-buyer';
    final previous = state;
    final existing = state.interests.any(
      (event) => event.buyerId == buyerId && event.productId == productId,
    );
    final updated = [...state.interests];
    if (existing) {
      updated.removeWhere(
        (event) => event.buyerId == buyerId && event.productId == productId,
      );
    } else {
      updated.add(InterestEvent(
        buyerId: buyerId,
        productId: productId,
        createdAt: DateTime.now(),
      ));
    }
    state = state.copyWith(interests: updated, isSyncing: true);
    try {
      await _repository.saveFavoriteProductIds(
        state.id,
        state.interestsFor(buyerId),
      );
      await _repository.setInterest(
        sessionId: state.id,
        buyerId: buyerId,
        productId: productId,
        interested: !existing,
      );
      state = state.copyWith(isSyncing: false);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}
