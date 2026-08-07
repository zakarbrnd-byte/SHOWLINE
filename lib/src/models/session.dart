import 'package:flutter/foundation.dart';

import 'product.dart';
import 'collection.dart';

enum SessionStatus { lobby, live, ended }

enum AppRole { seller, buyer }

@immutable
class BuyerProfile {
  const BuyerProfile({
    required this.id,
    required this.name,
    required this.company,
    this.isOnline = true,
  });

  final String id;
  final String name;
  final String company;
  final bool isOnline;
}

@immutable
class InterestEvent {
  const InterestEvent({
    required this.buyerId,
    required this.productId,
    required this.createdAt,
  });

  final String buyerId;
  final String productId;
  final DateTime createdAt;
}

@immutable
class ShowlineSession {
  const ShowlineSession({
    required this.id,
    required this.code,
    required this.title,
    required this.collection,
    required this.products,
    required this.buyers,
    required this.interests,
    required this.activeProductIndex,
    required this.status,
    required this.role,
    required this.isSyncing,
    required this.hasJoinedAsBuyer,
    required this.currentBuyerName,
    required this.selectedProductIndex,
    required this.suggestedProductIndex,
    required this.suggestionVersion,
    required this.catalogProducts,
    required this.collections,
    required this.selectedCollectionId,
    required this.temporaryProductIds,
    required this.catalogRevision,
    required this.suggestedCollectionId,
    required this.collectionSuggestionVersion,
    required this.buyerConnected,
  });

  factory ShowlineSession.demo() => const ShowlineSession(
        id: 'summer-27-preview',
        code: 'LINE27',
        title: 'Spring / Summer 2027',
        collection: 'The Coastal Edit',
        products: demoProducts,
        buyers: [
          BuyerProfile(id: 'b01', name: 'Mia Chen', company: 'Field & Form'),
          BuyerProfile(
              id: 'b02', name: 'Nora Blake', company: 'The Edit House'),
          BuyerProfile(id: 'b03', name: 'Theo James', company: 'Common Ground'),
        ],
        interests: [],
        activeProductIndex: 0,
        status: SessionStatus.lobby,
        role: AppRole.seller,
        isSyncing: false,
        hasJoinedAsBuyer: false,
        currentBuyerName: '',
        selectedProductIndex: 0,
        suggestedProductIndex: null,
        suggestionVersion: 0,
        catalogProducts: demoProducts,
        collections: [
          ShowlineCollection(
            id: 'demo-collection',
            name: '2026 Catalog',
            productIds: ['knd5001-black', 'knt136-black-white'],
          ),
        ],
        selectedCollectionId: 'demo-collection',
        temporaryProductIds: [],
        catalogRevision: 0,
        suggestedCollectionId: null,
        collectionSuggestionVersion: 0,
        buyerConnected: false,
      );

  final String id;
  final String code;
  final String title;
  final String collection;
  final List<Product> products;
  final List<BuyerProfile> buyers;
  final List<InterestEvent> interests;
  final int activeProductIndex;
  final SessionStatus status;
  final AppRole role;
  final bool isSyncing;
  final bool hasJoinedAsBuyer;
  final String currentBuyerName;
  final int selectedProductIndex;
  final int? suggestedProductIndex;
  final int suggestionVersion;
  final List<Product> catalogProducts;
  final List<ShowlineCollection> collections;
  final String selectedCollectionId;
  final List<String> temporaryProductIds;
  final int catalogRevision;
  final String? suggestedCollectionId;
  final int collectionSuggestionVersion;
  final bool buyerConnected;

  String get activeProductId => products[activeProductIndex].id;
  Product get activeProduct => products[activeProductIndex];
  Product get selectedProduct => products[selectedProductIndex];
  ShowlineCollection get selectedCollection => collections.firstWhere(
        (collection) => collection.id == selectedCollectionId,
        orElse: () => collections.first,
      );

  Set<String> interestsFor(String buyerId) => interests
      .where((event) => event.buyerId == buyerId)
      .map((event) => event.productId)
      .toSet();

  int interestCountFor(String productId) =>
      interests.where((event) => event.productId == productId).length;

  ShowlineSession copyWith({
    List<BuyerProfile>? buyers,
    List<InterestEvent>? interests,
    int? activeProductIndex,
    SessionStatus? status,
    AppRole? role,
    bool? isSyncing,
    bool? hasJoinedAsBuyer,
    String? currentBuyerName,
    int? selectedProductIndex,
    int? suggestedProductIndex,
    int? suggestionVersion,
    List<Product>? products,
    List<Product>? catalogProducts,
    List<ShowlineCollection>? collections,
    String? selectedCollectionId,
    List<String>? temporaryProductIds,
    int? catalogRevision,
    String? suggestedCollectionId,
    int? collectionSuggestionVersion,
    bool? buyerConnected,
    bool clearSuggestedProduct = false,
    bool clearSuggestedCollection = false,
  }) {
    return ShowlineSession(
      id: id,
      code: code,
      title: title,
      collection: collection,
      products: products ?? this.products,
      buyers: buyers ?? this.buyers,
      interests: interests ?? this.interests,
      activeProductIndex: activeProductIndex ?? this.activeProductIndex,
      status: status ?? this.status,
      role: role ?? this.role,
      isSyncing: isSyncing ?? this.isSyncing,
      hasJoinedAsBuyer: hasJoinedAsBuyer ?? this.hasJoinedAsBuyer,
      currentBuyerName: currentBuyerName ?? this.currentBuyerName,
      selectedProductIndex: selectedProductIndex ?? this.selectedProductIndex,
      suggestedProductIndex: clearSuggestedProduct
          ? null
          : suggestedProductIndex ?? this.suggestedProductIndex,
      suggestionVersion: suggestionVersion ?? this.suggestionVersion,
      catalogProducts: catalogProducts ?? this.catalogProducts,
      collections: collections ?? this.collections,
      selectedCollectionId: selectedCollectionId ?? this.selectedCollectionId,
      temporaryProductIds: temporaryProductIds ?? this.temporaryProductIds,
      catalogRevision: catalogRevision ?? this.catalogRevision,
      suggestedCollectionId: clearSuggestedCollection
          ? null
          : suggestedCollectionId ?? this.suggestedCollectionId,
      collectionSuggestionVersion:
          collectionSuggestionVersion ?? this.collectionSuggestionVersion,
      buyerConnected: buyerConnected ?? this.buyerConnected,
    );
  }
}
