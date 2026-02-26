import 'dart:typed_data';

import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as impl;

/// עוזר להורדת קבצים - תומך ב-Web (דפדפן) ובפלטפורמות אחרות
void downloadBytes(Uint8List bytes, String fileName) {
  impl.downloadBytes(bytes, fileName);
}
