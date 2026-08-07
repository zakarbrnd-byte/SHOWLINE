import 'dart:typed_data';

class PickedBrowserImage {
  const PickedBrowserImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<List<PickedBrowserImage>> pickBrowserImages() async => const [];
