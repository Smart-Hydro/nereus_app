import 'package:nereus_app/core/json_util.dart';

/// Booleano tolerante: true/false, 1/0 o texto.
bool opsBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'si':
      case 'sí':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}

/// Avisos del backend: texto plano o mapas con `message`.
List<String> opsMessages(dynamic value) {
  if (value is! List) return const [];
  final out = <String>[];
  for (final item in value) {
    if (item is String && item.trim().isNotEmpty) {
      out.add(item.trim());
    } else if (item is Map) {
      final text = asString(item['message'] ?? item['detail'] ?? item['text']);
      if (text.isNotEmpty) out.add(text);
    }
  }
  return out;
}

/// Entero desde un id int o string. Null si no es un número.
int? opsInt(String raw) => int.tryParse(raw.trim());

/// Nombre para mostrar. Un id numérico o un mapa sin nombre queda vacío.
String opsReadableName(dynamic value) {
  if (value is String) return value.trim();
  if (value is Map) {
    final name = value['name'] ?? value['device_name'] ?? value['label'];
    if (name is String) return name.trim();
  }
  return '';
}

/// Id de una referencia plana o anidada (`{"id": 3}`). Vacío si no hay.
String opsRefId(dynamic value) {
  if (value is Map) {
    final id = value['id'];
    if (id == null) return '';
    return '$id'.trim();
  }
  if (value == null) return '';
  final text = '$value'.trim();
  if (text.isEmpty || text == 'null') return '';
  return text;
}

/// Fecha `AAAA-MM-DD` a partir de un ISO o de un día suelto.
String opsDay(dynamic value) {
  final text = asString(value);
  if (text.length >= 10) return text.substring(0, 10);
  return text;
}
