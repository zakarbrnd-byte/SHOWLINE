import '../models/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedSessionSnapshot {
  const SharedSessionSnapshot({
    required this.buyerProductIndex,
    required this.favoriteProductIds,
    required this.suggestedProductIndex,
    required this.suggestionVersion,
    required this.hasFavoriteState,
    required this.temporaryProductIds,
    required this.status,
    required this.suggestedCollectionId,
    required this.collectionSuggestionVersion,
    required this.buyerConnected,
  });

  final int? buyerProductIndex;
  final Set<String> favoriteProductIds;
  final int? suggestedProductIndex;
  final int suggestionVersion;
  final bool hasFavoriteState;
  final List<String> temporaryProductIds;
  final SessionStatus status;
  final String? suggestedCollectionId;
  final int collectionSuggestionVersion;
  final bool buyerConnected;
}

abstract interface class SessionRepository {
  Future<void> updateStatus(String sessionId, SessionStatus status);
  Future<void> spotlightProduct(String sessionId, String productId);
  Future<void> setInterest({
    required String sessionId,
    required String buyerId,
    required String productId,
    required bool interested,
  });
  Future<SharedSessionSnapshot> readSharedState(String sessionId);
  Future<void> saveBuyerProductIndex(String sessionId, int index);
  Future<void> saveFavoriteProductIds(String sessionId, Set<String> ids);
  Future<void> saveTemporaryProductIds(String sessionId, List<String> ids);
  Future<void> saveCollectionSuggestion(
    String sessionId,
    String collectionId,
    int version,
  );
  Future<void> saveBuyerConnected(String sessionId, bool connected);
  Future<void> resetPresentationSignals(String sessionId);
  Future<void> saveSuggestion(
    String sessionId,
    int productIndex,
    int version,
  );
}

class DemoSessionRepository implements SessionRepository {
  const DemoSessionRepository();

  Future<void> _simulateNetwork() =>
      Future<void>.delayed(const Duration(milliseconds: 260));

  @override
  Future<void> updateStatus(String sessionId, SessionStatus status) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(sessionId, 'status'), status.name);
    await _simulateNetwork();
  }

  @override
  Future<void> spotlightProduct(String sessionId, String productId) =>
      _simulateNetwork();

  @override
  Future<void> setInterest({
    required String sessionId,
    required String buyerId,
    required String productId,
    required bool interested,
  }) =>
      _simulateNetwork();

  String _key(String sessionId, String field) => 'showline.$sessionId.$field';

  @override
  Future<SharedSessionSnapshot> readSharedState(String sessionId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return SharedSessionSnapshot(
      buyerProductIndex:
          preferences.getInt(_key(sessionId, 'buyerProductIndex')),
      favoriteProductIds: preferences
              .getStringList(_key(sessionId, 'favoriteProductIds'))
              ?.toSet() ??
          {},
      suggestedProductIndex:
          preferences.getInt(_key(sessionId, 'suggestedProductIndex')),
      suggestionVersion:
          preferences.getInt(_key(sessionId, 'suggestionVersion')) ?? 0,
      hasFavoriteState:
          preferences.containsKey(_key(sessionId, 'favoriteProductIds')),
      temporaryProductIds:
          preferences.getStringList(_key(sessionId, 'temporaryProductIds')) ??
              const [],
      status: SessionStatus.values.firstWhere(
        (status) =>
            status.name == preferences.getString(_key(sessionId, 'status')),
        orElse: () => SessionStatus.lobby,
      ),
      suggestedCollectionId:
          preferences.getString(_key(sessionId, 'suggestedCollectionId')),
      collectionSuggestionVersion:
          preferences.getInt(_key(sessionId, 'collectionSuggestionVersion')) ??
              0,
      buyerConnected:
          preferences.getBool(_key(sessionId, 'buyerConnected')) ?? false,
    );
  }

  @override
  Future<void> saveBuyerConnected(String sessionId, bool connected) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key(sessionId, 'buyerConnected'), connected);
  }

  @override
  Future<void> resetPresentationSignals(String sessionId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(sessionId, 'suggestedProductIndex'));
    await preferences.remove(_key(sessionId, 'suggestionVersion'));
    await preferences.remove(_key(sessionId, 'suggestedCollectionId'));
    await preferences.remove(_key(sessionId, 'collectionSuggestionVersion'));
    await preferences.remove(_key(sessionId, 'temporaryProductIds'));
    await preferences.setBool(_key(sessionId, 'buyerConnected'), false);
  }

  @override
  Future<void> saveCollectionSuggestion(
    String sessionId,
    String collectionId,
    int version,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(sessionId, 'suggestedCollectionId'),
      collectionId,
    );
    await preferences.setInt(
      _key(sessionId, 'collectionSuggestionVersion'),
      version,
    );
  }

  @override
  Future<void> saveTemporaryProductIds(
    String sessionId,
    List<String> ids,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
        _key(sessionId, 'temporaryProductIds'), ids);
  }

  @override
  Future<void> saveBuyerProductIndex(String sessionId, int index) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_key(sessionId, 'buyerProductIndex'), index);
  }

  @override
  Future<void> saveFavoriteProductIds(
    String sessionId,
    Set<String> ids,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key(sessionId, 'favoriteProductIds'),
      ids.toList()..sort(),
    );
  }

  @override
  Future<void> saveSuggestion(
    String sessionId,
    int productIndex,
    int version,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _key(sessionId, 'suggestedProductIndex'),
      productIndex,
    );
    await preferences.setInt(_key(sessionId, 'suggestionVersion'), version);
  }
}
