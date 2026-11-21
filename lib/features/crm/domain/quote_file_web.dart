import 'dart:convert';

import 'package:web/web.dart';

void saveQuoteBytes({
  required String filename,
  required List<int> bytes,
  required String mime,
}) {
  final anchor = HTMLAnchorElement()
    ..href = 'data:$mime;base64,${base64Encode(bytes)}'
    ..download = filename;
  document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
