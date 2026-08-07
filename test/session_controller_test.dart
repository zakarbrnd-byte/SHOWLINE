import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showline/src/models/session.dart';
import 'package:showline/src/models/product.dart';
import 'package:showline/src/routing/buyer_invite.dart';
import 'package:showline/src/state/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hyphenated filenames group alternate colors by style', () {
    const product = Product(
      id: 'kb3074-lt-grey',
      fileName: 'KB3074-LT-GREY.jpg',
      imageAsset: null,
      accent: Color(0xFF777777),
    );
    expect(product.styleCode, 'KB3074');
    expect(product.colorName, 'LT GREY');
  });

  test('seller can start a live presentation and move spotlight', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(sessionControllerProvider.notifier);
    await controller.startPresentation();
    await controller.spotlight(1);

    final session = container.read(sessionControllerProvider);
    expect(session.status, SessionStatus.live);
    expect(session.activeProductIndex, 1);
    expect(session.activeProduct.id, 'knt136-black-white');
  });

  test('buyer interest toggles optimistically', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(sessionControllerProvider.notifier);
    await controller.toggleInterest('knd5001-black');
    expect(
      container.read(currentBuyerInterestsProvider),
      contains('knd5001-black'),
    );

    await controller.toggleInterest('knd5001-black');
    expect(
      container.read(currentBuyerInterestsProvider),
      isNot(contains('knd5001-black')),
    );
  });

  test('buyer joins only when the room is live and code matches', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);

    expect(controller.joinAsBuyer(name: 'Alex', code: 'WRONG'), isFalse);
    expect(controller.joinAsBuyer(name: 'Alex', code: 'line27'), isFalse);
    await controller.startPresentation();
    expect(controller.joinAsBuyer(name: 'Alex', code: 'line27'), isTrue);
    expect(container.read(sessionControllerProvider).hasJoinedAsBuyer, isTrue);
  });

  test('buyer invite opens the buyer view for the active room', () {
    final invite = buildBuyerInviteUri(
      Uri.parse('https://showline.example/present?old=value'),
      'LINE27',
    );

    expect(invite.queryParameters['view'], 'buyer');
    expect(invite.queryParameters['room'], 'LINE27');
    expect(isBuyerInvite(invite), isTrue);
  });

  test('seller selection does not move buyer until suggestion is opened',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.startPresentation();
    expect(controller.joinAsBuyer(name: 'Alex', code: 'LINE27'), isTrue);

    controller.selectSuggestion(1);
    expect(container.read(sessionControllerProvider).activeProductIndex, 0);
    expect(container.read(sessionControllerProvider).selectedProductIndex, 1);

    await controller.suggestSelectedProduct();
    expect(container.read(sessionControllerProvider).activeProductIndex, 0);

    await controller.openSuggestion();
    expect(container.read(sessionControllerProvider).activeProductIndex, 1);
  });

  test('two tabs synchronize buyer position, favorites, and suggestions',
      () async {
    final buyerTab = ProviderContainer();
    final sellerTab = ProviderContainer();
    addTearDown(buyerTab.dispose);
    addTearDown(sellerTab.dispose);

    final buyer = buyerTab.read(sessionControllerProvider.notifier);
    final seller = sellerTab.read(sessionControllerProvider.notifier);

    await seller.startPresentation();
    await Future<void>.delayed(const Duration(milliseconds: 750));
    expect(buyer.joinAsBuyer(name: 'Alex', code: 'LINE27'), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 750));

    await buyer.updateBuyerView(1);
    await Future<void>.delayed(const Duration(milliseconds: 750));
    expect(sellerTab.read(sessionControllerProvider).activeProductIndex, 1);

    await buyer.toggleInterest('knt136-black-white');
    await Future<void>.delayed(const Duration(milliseconds: 750));
    expect(
      sellerTab.read(sessionControllerProvider).interests,
      hasLength(1),
    );

    seller.selectSuggestion(0);
    await seller.suggestSelectedProduct();
    await Future<void>.delayed(const Duration(milliseconds: 750));
    expect(
      buyerTab.read(sessionControllerProvider).suggestedProductIndex,
      0,
    );
  });
}
