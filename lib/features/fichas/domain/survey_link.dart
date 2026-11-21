import 'package:flutter/foundation.dart';

/// Ruta pública del formulario. En la demo lleva `demo=1` para abrir
/// el ejemplo sin sesión.
String levantamientoSharePath(String slug, {bool demo = false}) {
  final path = '/encuesta/${Uri.encodeComponent(slug)}';
  return demo ? '$path?demo=1' : path;
}

/// URL absoluta en web. En escritorio devuelve la ruta.
String levantamientoShareUrl(String slug, {bool demo = false}) {
  final relative = levantamientoSharePath(slug, demo: demo);
  if (!kIsWeb) return relative;
  final path = Uri.base.path;
  const marker = '/nereus_app';
  final at = path.indexOf(marker);
  final prefix = at >= 0 ? marker : '';
  return '${Uri.base.origin}$prefix$relative';
}
