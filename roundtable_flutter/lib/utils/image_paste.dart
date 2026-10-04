import 'dart:typed_data';

import 'image_paste_stub.dart'
    if (dart.library.js_interop) 'image_paste_web.dart'
    as impl;

/// An image taken from the clipboard.
typedef PastedImage = ({String name, Uint8List bytes});

/// Calls [onImage] for every image pasted (Ctrl/Cmd+V) anywhere in the page
/// until the returned function is called. Flutter's `Clipboard` only reads
/// text, so on the web this listens to the browser's `paste` event; on other
/// platforms it's a no-op for now (use the attach button instead).
void Function() listenForPastedImages(void Function(PastedImage) onImage) =>
    impl.listenForPastedImages(onImage);
