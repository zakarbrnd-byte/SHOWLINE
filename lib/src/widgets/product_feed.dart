import 'package:flutter/material.dart';

import '../models/product.dart';
import 'catalog_image.dart';

class ProductFeed extends StatefulWidget {
  const ProductFeed({
    required this.products,
    required this.activeIndex,
    super.key,
    this.onPageChanged,
    this.interestedProductIds = const {},
    this.onToggleInterest,
    this.compact = false,
    this.scrollEnabled = true,
  });

  final List<Product> products;
  final int activeIndex;
  final ValueChanged<int>? onPageChanged;
  final Set<String> interestedProductIds;
  final ValueChanged<String>? onToggleInterest;
  final bool compact;
  final bool scrollEnabled;

  @override
  State<ProductFeed> createState() => _ProductFeedState();
}

class _ProductFeedState extends State<ProductFeed> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.activeIndex);
  }

  @override
  void didUpdateWidget(covariant ProductFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex &&
        _controller.hasClients &&
        _controller.page?.round() != widget.activeIndex) {
      _controller.animateToPage(
        widget.activeIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          physics: widget.scrollEnabled
              ? const PageScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          itemCount: widget.products.length,
          onPageChanged: widget.onPageChanged,
          itemBuilder: (context, index) {
            final product = widget.products[index];
            return ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(widget.compact ? 6 : 12),
                child: CatalogImage(
                  product: product,
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .66),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${widget.activeIndex + 1} / ${widget.products.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (widget.onToggleInterest != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: null,
              onPressed: () => widget
                  .onToggleInterest!(widget.products[widget.activeIndex].id),
              backgroundColor: Colors.white,
              foregroundColor: widget.interestedProductIds
                      .contains(widget.products[widget.activeIndex].id)
                  ? const Color(0xFFD86655)
                  : const Color(0xFF17221C),
              child: Icon(widget.interestedProductIds
                      .contains(widget.products[widget.activeIndex].id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded),
            ),
          ),
      ],
    );
  }
}
