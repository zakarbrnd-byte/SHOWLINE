import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/session_controller.dart';
import '../models/product.dart';
import '../models/session.dart';
import '../widgets/catalog_image.dart';
import '../widgets/product_feed.dart';

class BuyerView extends ConsumerStatefulWidget {
  const BuyerView({super.key});

  @override
  ConsumerState<BuyerView> createState() => _BuyerViewState();
}

class _BuyerViewState extends ConsumerState<BuyerView> {
  int _lastSuggestionVersion = 0;
  int _lastCollectionSuggestionVersion = 0;
  bool _showSuggestion = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (session.status == SessionStatus.ended) {
      return const _DisconnectedRoom();
    }
    if (!session.hasJoinedAsBuyer) {
      return _JoinRoom(expectedCode: session.code);
    }
    final interests = ref.watch(currentBuyerInterestsProvider);
    if (session.collectionSuggestionVersion > 0 &&
        session.collectionSuggestionVersion !=
            _lastCollectionSuggestionVersion &&
        session.suggestedCollectionId != null) {
      _lastCollectionSuggestionVersion = session.collectionSuggestionVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCollectionInvitation();
      });
    }
    final active = session.activeProduct;
    final alternatives = session.catalogProducts
        .where((product) =>
            product.id != active.id && product.styleCode == active.styleCode)
        .toList();
    if (session.suggestionVersion > 0 &&
        session.suggestionVersion != _lastSuggestionVersion) {
      _lastSuggestionVersion = session.suggestionVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showSuggestion = true);
      });
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ProductFeed(
                products: session.products,
                activeIndex: session.activeProductIndex,
                interestedProductIds: interests,
                onPageChanged: ref
                    .read(sessionControllerProvider.notifier)
                    .updateBuyerView,
                onToggleInterest: session.isSyncing
                    ? null
                    : ref
                        .read(sessionControllerProvider.notifier)
                        .toggleInterest,
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'Favorites',
                  onPressed: () => _showFavorites(context, interests),
                  backgroundColor: const Color(0xFF17221C),
                  foregroundColor: Colors.white,
                  child: Badge(
                    label: Text('${interests.length}'),
                    isLabelVisible: interests.isNotEmpty,
                    child: const Icon(Icons.favorite_rounded),
                  ),
                ),
              ),
              Positioned(
                left: 72,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: null,
                  tooltip: 'All pictures',
                  onPressed: _showAllPictures,
                  backgroundColor: const Color(0xFF4E725C),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.grid_view_rounded),
                ),
              ),
              if (session.temporaryProductIds.contains(active.id))
                Positioned(
                  top: 16,
                  left: 16,
                  child: FilledButton.tonalIcon(
                    onPressed: ref
                        .read(sessionControllerProvider.notifier)
                        .exitTemporaryProduct,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Exit color view'),
                  ),
                ),
              if (_showSuggestion && session.suggestedProductIndex != null)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _SuggestionCard(
                    product: session.products[session.suggestedProductIndex!],
                    onOpen: () async {
                      await ref
                          .read(sessionControllerProvider.notifier)
                          .openSuggestion();
                      if (mounted) setState(() => _showSuggestion = false);
                    },
                    onDismiss: () => setState(() => _showSuggestion = false),
                  ),
                ),
            ],
          ),
        ),
        if (alternatives.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: _ColorRail(
              products: alternatives,
              onOpen: ref
                  .read(sessionControllerProvider.notifier)
                  .addTemporaryProduct,
            ),
          ),
      ],
    );
  }

  Future<void> _showAllPictures() async {
    final session = ref.read(sessionControllerProvider);
    final index = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All pictures',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: session.products.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () => Navigator.pop(context, index),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: CatalogImage(product: session.products[index]),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (index != null) {
      await ref.read(sessionControllerProvider.notifier).updateBuyerView(index);
    }
  }

  Future<void> _showCollectionInvitation() async {
    final session = ref.read(sessionControllerProvider);
    final id = session.suggestedCollectionId;
    if (id == null || !mounted) return;
    final matches = session.collections.where((item) => item.id == id);
    if (matches.isEmpty) return;
    final collection = matches.first;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.collections_rounded, size: 38),
        title: const Text('A new collection is available'),
        content: Text(
          'The seller would like to show you “${collection.name}”. '
          'Would you like to view it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('View collection'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      await ref
          .read(sessionControllerProvider.notifier)
          .acceptSuggestedCollection();
    }
  }

  Future<void> _showFavorites(
    BuildContext context,
    Set<String> favoriteIds,
  ) async {
    final products = ref
        .read(sessionControllerProvider)
        .products
        .where((product) => favoriteIds.contains(product.id))
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorites',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child: Text('Tap the heart to save a linesheet.'),
                      )
                    : ListView.separated(
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) => Card(
                          clipBehavior: Clip.antiAlias,
                          child: AspectRatio(
                            aspectRatio: 1.25,
                            child: ColoredBox(
                              color: Colors.white,
                              child: CatalogImage(product: products[index]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisconnectedRoom extends StatelessWidget {
  const _DisconnectedRoom();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded, size: 48),
              const SizedBox(height: 16),
              Text(
                'Presentation ended',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'The seller ended the live session. You have been disconnected.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.product,
    required this.onOpen,
    required this.onDismiss,
  });

  final Product product;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: SizedBox(
          width: 250,
          height: 116,
          child: Row(
            children: [
              SizedBox(
                width: 92,
                height: double.infinity,
                child: CatalogImage(product: product, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Seller suggestion',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            onPressed: onDismiss,
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Tap to view',
                        style: TextStyle(color: Color(0xFF4E725C)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorRail extends StatefulWidget {
  const _ColorRail({required this.products, required this.onOpen});

  final List<Product> products;
  final ValueChanged<String> onOpen;

  @override
  State<_ColorRail> createState() => _ColorRailState();
}

class _ColorRailState extends State<_ColorRail> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _move(double amount) {
    if (!_controller.hasClients) return;
    _controller.animateTo(
      (_controller.offset + amount)
          .clamp(0, _controller.position.maxScrollExtent)
          .toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white.withValues(alpha: .96),
      child: SizedBox(
        height: 104,
        child: Row(children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Other\ncolors',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            tooltip: 'Previous colors',
            onPressed: () => _move(-220),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Scrollbar(
              controller: _controller,
              thumbVisibility: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: ListView.separated(
                controller: _controller,
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                scrollDirection: Axis.horizontal,
                itemCount: widget.products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return InkWell(
                    onTap: () => widget.onOpen(product.id),
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 92,
                      child: Column(children: [
                        Expanded(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CatalogImage(product: product))),
                        const SizedBox(height: 3),
                        Text(product.colorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            tooltip: 'More colors',
            onPressed: () => _move(220),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
      ),
    );
  }
}

class _JoinRoom extends ConsumerStatefulWidget {
  const _JoinRoom({required this.expectedCode});

  final String expectedCode;

  @override
  ConsumerState<_JoinRoom> createState() => _JoinRoomState();
}

class _JoinRoomState extends ConsumerState<_JoinRoom> {
  final _nameController = TextEditingController(text: 'Alex Morgan');
  final _codeController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeController.text = widget.expectedCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _join() {
    final session = ref.read(sessionControllerProvider);
    if (session.status != SessionStatus.live) {
      setState(() {
        _error = 'No Live Presentation. Please wait for the seller to go live.';
      });
      return;
    }
    final joined = ref.read(sessionControllerProvider.notifier).joinAsBuyer(
          name: _nameController.text,
          code: _codeController.text,
        );
    if (!joined) {
      setState(() {
        _error = 'Check your name and room code, then try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.waving_hand_rounded,
                    size: 42,
                    color: Color(0xFF4E725C),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Join the line',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontSize: 42),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _join(),
                    decoration: InputDecoration(
                      labelText: 'Room code',
                      border: const OutlineInputBorder(),
                      errorText: _error,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _join,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('Join presentation'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
