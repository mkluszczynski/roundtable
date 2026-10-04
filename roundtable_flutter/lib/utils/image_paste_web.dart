import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'image_paste.dart';

void Function() listenForPastedImages(void Function(PastedImage) onImage) {
  final listener = ((web.Event event) {
    final items = (event as web.ClipboardEvent).clipboardData?.items;
    if (items == null) return;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.kind != 'file' || !item.type.startsWith('image/')) continue;
      final file = item.getAsFile();
      if (file == null) continue;
      file.arrayBuffer().toDart.then((buffer) {
        final extension = item.type.split('/').last;
        onImage((
          name: file.name.isEmpty ? 'pasted.$extension' : file.name,
          bytes: buffer.toDart.asUint8List(),
        ));
      });
    }
  }).toJS;
  web.document.addEventListener('paste', listener);
  return () => web.document.removeEventListener('paste', listener);
}
