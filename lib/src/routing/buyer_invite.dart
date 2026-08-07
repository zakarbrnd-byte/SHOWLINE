Uri buildBuyerInviteUri(Uri base, String roomCode) {
  final invite = base.replace(
    queryParameters: {
      'view': 'buyer',
      'room': roomCode,
    },
    fragment: '',
  );
  return Uri.parse(invite.toString().split('#').first);
}

bool isBuyerInvite(Uri uri) => uri.queryParameters['view'] == 'buyer';
