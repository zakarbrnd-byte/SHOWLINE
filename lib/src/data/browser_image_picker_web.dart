// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedBrowserImage {
  const PickedBrowserImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<List<PickedBrowserImage>> pickBrowserImages() {
  final completer = Completer<List<PickedBrowserImage>>();
  final input = html.FileUploadInputElement()
    ..accept = '.jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp'
    ..multiple = true;

  input.onChange.first.then((_) async {
    final picked = <PickedBrowserImage>[];
    for (final file in input.files ?? const <html.File>[]) {
      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoad.first;
      final result = reader.result;
      if (result is ByteBuffer) {
        picked.add(PickedBrowserImage(
          name: file.name,
          bytes: result.asUint8List(),
        ));
      } else if (result is Uint8List) {
        picked.add(PickedBrowserImage(name: file.name, bytes: result));
      }
    }
    if (!completer.isCompleted) completer.complete(picked);
  });

  // This is intentionally synchronous so Chrome treats it as part of the
  // seller's button click and allows the native chooser to open.
  input.click();
  return completer.future;
}
