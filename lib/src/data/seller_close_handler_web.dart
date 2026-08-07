// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

abstract interface class SellerCloseHandler {
  void dispose();
}

SellerCloseHandler installSellerCloseHandler(String sessionId) =>
    _WebSellerCloseHandler(sessionId);

class _WebSellerCloseHandler implements SellerCloseHandler {
  _WebSellerCloseHandler(this.sessionId) {
    _subscription = html.window.onBeforeUnload.listen((_) {
      html.window.localStorage['flutter.showline.$sessionId.status'] =
          jsonEncode('ended');
      html.window.localStorage['flutter.showline.$sessionId.buyerConnected'] =
          jsonEncode(false);
    });
  }

  final String sessionId;
  late final StreamSubscription<html.Event> _subscription;

  @override
  void dispose() => _subscription.cancel();
}
