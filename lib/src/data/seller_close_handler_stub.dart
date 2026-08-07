abstract interface class SellerCloseHandler {
  void dispose();
}

SellerCloseHandler installSellerCloseHandler(String sessionId) =>
    _NoopSellerCloseHandler();

class _NoopSellerCloseHandler implements SellerCloseHandler {
  @override
  void dispose() {}
}
