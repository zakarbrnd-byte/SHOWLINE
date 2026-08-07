import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../data/browser_image_picker.dart';
import '../data/seller_close_handler.dart';
import '../models/session.dart';
import '../routing/buyer_invite.dart';
import '../state/session_controller.dart';
import '../widgets/product_feed.dart';
import '../widgets/catalog_image.dart';

class SellerView extends ConsumerStatefulWidget {
  const SellerView({super.key});

  @override
  ConsumerState<SellerView> createState() => _SellerViewState();
}

class _SellerViewState extends ConsumerState<SellerView> {
  int _tab = 0;
  SellerCloseHandler? _closeHandler;

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(sessionControllerProvider.notifier).initializeSellerDashboard(),
    );
    _closeHandler = installSellerCloseHandler(
      ref.read(sessionControllerProvider).id,
    );
  }

  @override
  void dispose() {
    _closeHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: _tab == 0
                ? const _SellerControl()
                : const _CollectionManager()),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) => setState(() => _tab = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.live_tv_rounded), label: 'Control'),
            NavigationDestination(
                icon: Icon(Icons.collections_rounded),
                label: 'Manage collections'),
          ],
        ),
      ],
    );
  }
}

class _SellerControl extends ConsumerWidget {
  const _SellerControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final interests = ref.watch(currentBuyerInterestsProvider);
    final size = MediaQuery.sizeOf(context);

    if (size.width < 820) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
        child: Column(
          children: [
            _ControlRoomHeader(session: session, interests: interests),
            const SizedBox(height: 14),
            SizedBox(
              height: 520,
              child: _BuyerPreview(session: session, interests: interests),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 680,
              child: _AdminControls(session: session),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Column(
        children: [
          _ControlRoomHeader(session: session, interests: interests),
          const SizedBox(height: 14),
          Expanded(
            flex: 6,
            child: _BuyerPreview(session: session, interests: interests),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 5,
            child: _AdminControls(session: session),
          ),
        ],
      ),
    );
  }
}

class _CollectionManager extends ConsumerWidget {
  const _CollectionManager();

  Future<String?> _nameDialog(BuildContext context, [String initial = '']) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(initial.isEmpty ? 'New collection' : 'Rename collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Collection name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _nameDialog(context);
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .createCollection(name, const []);
  }

  Future<void> _pickAndAdd(
    BuildContext context,
    WidgetRef ref,
    String collectionId,
  ) async {
    final selected = await pickBrowserImages();
    final files = selected
        .map((file) => UploadedCatalogFile(name: file.name, bytes: file.bytes))
        .toList();
    await ref
        .read(sessionControllerProvider.notifier)
        .addPictures(collectionId, files);
    if (context.mounted && files.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${files.length} pictures added')),
      );
    }
  }

  Future<void> _showCollection(
    BuildContext context,
    WidgetRef ref,
    String collectionId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CollectionEditorSheet(collectionId: collectionId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final controller = ref.read(sessionControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text('Collections',
                    style: Theme.of(context).textTheme.headlineLarge)),
            FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: const Text('Create collection')),
          ]),
          const SizedBox(height: 8),
          const Text('Select the collection currently shown to the buyer.'),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: session.collections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final collection = session.collections[index];
                final selected = collection.id == session.selectedCollectionId;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text('${collection.productIds.length}')),
                    title: Text(collection.name),
                    subtitle:
                        Text('${collection.productIds.length} linesheets'),
                    selected: selected,
                    onTap: () => _showCollection(context, ref, collection.id),
                    trailing: SizedBox(
                      width: 208,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: collection.productIds.isEmpty
                                  ? 'Add pictures before displaying'
                                  : 'Display to buyer',
                              icon: Icon(selected
                                  ? Icons.check_circle_rounded
                                  : Icons.play_circle_outline_rounded),
                              onPressed: collection.productIds.isEmpty
                                  ? null
                                  : () => controller
                                      .selectCollection(collection.id),
                            ),
                            IconButton(
                              tooltip: 'View collection',
                              icon: const Icon(Icons.visibility_rounded),
                              onPressed: () =>
                                  _showCollection(context, ref, collection.id),
                            ),
                            IconButton(
                              tooltip: 'Add pictures',
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              onPressed: () =>
                                  _pickAndAdd(context, ref, collection.id),
                            ),
                            IconButton(
                              tooltip: 'Edit collection',
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () =>
                                  _showCollection(context, ref, collection.id),
                            ),
                            IconButton(
                              tooltip: 'Delete collection',
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: collection.id == 'demo-collection'
                                  ? null
                                  : () => controller
                                      .deleteCollection(collection.id),
                            ),
                          ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionEditorSheet extends ConsumerStatefulWidget {
  const _CollectionEditorSheet({required this.collectionId});

  final String collectionId;

  @override
  ConsumerState<_CollectionEditorSheet> createState() =>
      _CollectionEditorSheetState();
}

class _CollectionEditorSheetState
    extends ConsumerState<_CollectionEditorSheet> {
  bool _editing = false;

  bool _isImage(String name) =>
      RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(name);

  Future<void> _addPickedPictures() async {
    final selected = await pickBrowserImages();
    final files = selected
        .where((file) => _isImage(file.name))
        .map((file) => UploadedCatalogFile(name: file.name, bytes: file.bytes))
        .toList();
    await _saveFiles(files);
  }

  Future<void> _saveFiles(List<UploadedCatalogFile> files) async {
    if (files.isEmpty) return;
    await ref
        .read(sessionControllerProvider.notifier)
        .addPictures(widget.collectionId, files);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${files.length} pictures added')),
      );
    }
  }

  Future<void> _rename(String currentName) async {
    final text = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename collection'),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await ref
          .read(sessionControllerProvider.notifier)
          .renameCollection(widget.collectionId, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final collection = session.collections
        .firstWhere((item) => item.id == widget.collectionId);
    final products = collection.productIds
        .map((id) =>
            session.catalogProducts.firstWhere((product) => product.id == id))
        .toList();
    final controller = ref.read(sessionControllerProvider.notifier);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .84,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(collection.name,
                        style: Theme.of(context).textTheme.headlineLarge),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _rename(collection.name),
                    icon: const Icon(Icons.drive_file_rename_outline_rounded),
                    label: const Text('Rename'),
                  ),
                  FilledButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(
                        _editing ? Icons.done_rounded : Icons.edit_rounded),
                    label: Text(_editing ? 'Done editing' : 'Edit'),
                  ),
                  FilledButton.icon(
                    onPressed: _addPickedPictures,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Add pictures'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: products.isEmpty
                    ? const Center(
                        child: Text('Click Add pictures to begin.'),
                      )
                    : _editing
                        ? ReorderableListView.builder(
                            itemCount: products.length,
                            onReorderItem: (oldIndex, newIndex) =>
                                controller.reorderCollectionProducts(
                              collection.id,
                              oldIndex,
                              newIndex,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Card(
                                key: ValueKey(product.id),
                                clipBehavior: Clip.antiAlias,
                                child: SizedBox(
                                  height: 170,
                                  child: Row(children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const SizedBox(
                                        width: 52,
                                        child:
                                            Icon(Icons.drag_indicator_rounded),
                                      ),
                                    ),
                                    Expanded(
                                        child: CatalogImage(product: product)),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: IconButton.filled(
                                        tooltip: 'Remove picture',
                                        onPressed: () =>
                                            controller.removePicture(
                                          collection.id,
                                          product.id,
                                        ),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ]),
                                ),
                              );
                            },
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 290,
                              childAspectRatio: 1.3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: products.length,
                            itemBuilder: (_, index) => Card(
                              clipBehavior: Clip.antiAlias,
                              child: CatalogImage(product: products[index]),
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

class _ControlRoomHeader extends StatelessWidget {
  const _ControlRoomHeader({
    required this.session,
    required this.interests,
  });

  final ShowlineSession session;
  final Set<String> interests;

  void _showFavorites(BuildContext context) {
    final products = session.catalogProducts
        .where((product) => interests.contains(product.id))
        .toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buyer favorites',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.favorite_rounded, size: 18),
                      label: Text('${products.length} saved'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: products.isEmpty
                      ? const Center(
                          child: Text(
                              'The buyer has not saved any favorites yet.'),
                        )
                      : ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 1.45,
                                    child: CatalogImage(product: product),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      product.fileName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seller control room',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontSize: 30),
              ),
              Text(
                '${session.collection} · Room ${session.code}',
                style: const TextStyle(color: Color(0xFF68716C)),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => _showFavorites(context),
          icon: Badge(
            isLabelVisible: interests.isNotEmpty,
            label: Text('${interests.length}'),
            child: const Icon(Icons.favorite_rounded),
          ),
          label: Text(compact ? 'Favorites' : 'Buyer favorites'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF17221C),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        if (!compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE5ECE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'BUYER VIEW PREVIEW',
              style: TextStyle(
                color: Color(0xFF4E725C),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    );
  }
}

class _BuyerPreview extends StatelessWidget {
  const _BuyerPreview({required this.session, required this.interests});

  final ShowlineSession session;
  final Set<String> interests;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ProductFeed(
        products: session.products,
        activeIndex: session.activeProductIndex,
        interestedProductIds: interests,
        compact: true,
        scrollEnabled: false,
      ),
    );
  }
}

class _AdminControls extends StatelessWidget {
  const _AdminControls({required this.session});

  final ShowlineSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1D2922),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 1000;
          final recommendation = _RecommendationSelector(session: session);
          final sidebar = Column(
            children: [
              _PresentationActions(session: session),
              const SizedBox(height: 12),
              Expanded(child: _InviteAndAudience(session: session)),
            ],
          );
          if (!wide) {
            if (constraints.maxHeight >= 600) {
              return Column(
                children: [
                  SizedBox(height: 280, child: recommendation),
                  const SizedBox(height: 16),
                  Expanded(child: sidebar),
                ],
              );
            }
            return ListView(
              primary: false,
              children: [
                SizedBox(height: 280, child: recommendation),
                const SizedBox(height: 16),
                SizedBox(height: 310, child: sidebar),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 7, child: recommendation),
              const SizedBox(width: 18),
              Expanded(flex: 3, child: sidebar),
            ],
          );
        }),
      ),
    );
  }
}

class _PresentationActions extends ConsumerWidget {
  const _PresentationActions({required this.session});

  final ShowlineSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(sessionControllerProvider.notifier);
    final live = session.status == SessionStatus.live;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: session.isSyncing
                    ? null
                    : live
                        ? controller.endPresentation
                        : controller.startPresentation,
                icon: Icon(live
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow_rounded),
                label: Text(live ? 'End live session' : 'Go live'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      live ? const Color(0xFFD86655) : const Color(0xFF5B8068),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: session.selectedProductIndex == 0
                  ? null
                  : () => controller.moveSuggestionSelection(-1),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              onPressed:
                  session.selectedProductIndex == session.products.length - 1
                      ? null
                      : () => controller.moveSuggestionSelection(1),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed:
                session.status == SessionStatus.live && session.buyerConnected
                    ? controller.suggestSelectedProduct
                    : null,
            icon: const Icon(Icons.send_rounded),
            label: Text(session.buyerConnected
                ? 'Suggest to buyer'
                : 'Waiting for buyer'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD4B877),
              foregroundColor: const Color(0xFF17221C),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationSelector extends ConsumerStatefulWidget {
  const _RecommendationSelector({required this.session});

  final ShowlineSession session;

  @override
  ConsumerState<_RecommendationSelector> createState() =>
      _RecommendationSelectorState();
}

class _RecommendationSelectorState
    extends ConsumerState<_RecommendationSelector> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _moveGallery(double amount) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      (_scrollController.offset + amount)
          .clamp(0, _scrollController.position.maxScrollExtent)
          .toDouble(),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _search() async {
    final input = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search styles'),
        content: TextField(
          controller: input,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter style number or filename',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    if (query == null || query.trim().isEmpty || !mounted) return;
    final normalized = query.trim().toLowerCase();
    final index = widget.session.products.indexWhere(
      (product) => product.fileName.toLowerCase().contains(normalized),
    );
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No style found for “${query.trim()}”')),
      );
      return;
    }
    ref.read(sessionControllerProvider.notifier).selectSuggestion(index);
    await _scrollController.animateTo(
      (index * 184)
          .toDouble()
          .clamp(
            0,
            _scrollController.position.maxScrollExtent,
          )
          .toDouble(),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFD4B877)),
            const SizedBox(width: 9),
            const Text(
              'Recommend a style',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: 'Search by style number',
              onPressed: _search,
              color: const Color(0xFFD4B877),
              icon: const Icon(Icons.search_rounded),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Previous styles',
              onPressed: () => _moveGallery(-368),
              color: Colors.white,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'More styles',
              onPressed: () => _moveGallery(368),
              color: Colors.white,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            Text(
              '${session.selectedProductIndex + 1} / ${session.products.length}',
              style: const TextStyle(color: Colors.white60),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 12),
              scrollDirection: Axis.horizontal,
              itemCount: session.products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final product = session.products[index];
                return _RecommendationCard(
                  product: product,
                  selected: index == session.selectedProductIndex,
                  onTap: () => ref
                      .read(sessionControllerProvider.notifier)
                      .selectSuggestion(index),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final Product product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 174,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F0E5) : Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFD4B877) : Colors.white12,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CatalogImage(
                product: product,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .68),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  product.styleCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFFD4B877),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Color(0xFF17221C),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InviteAndAudience extends StatelessWidget {
  const _InviteAndAudience({required this.session});

  final ShowlineSession session;

  @override
  Widget build(BuildContext context) {
    final invite = buildBuyerInviteUri(Uri.base, session.code).toString();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Buyer invite link',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${session.buyerConnected ? 1 : 0} joined',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            invite,
            maxLines: 2,
            style: const TextStyle(color: Color(0xFFBDD0C2), fontSize: 11),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invite));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Buyer link copied')),
                  );
                }
              },
              icon: const Icon(Icons.link_rounded),
              label: const Text('Copy buyer link'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${session.interests.length} interest signals received',
            style: const TextStyle(color: Color(0xFFD4B877), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
