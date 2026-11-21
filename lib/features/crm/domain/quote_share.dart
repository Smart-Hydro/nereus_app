import 'package:flutter/foundation.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';

/// Ruta pública. En la demo lleva `demo=1` para abrir el ejemplo sin sesión.
String quoteSharePath(String id, {bool demo = false}) {
  final path = '/cotizacion/${Uri.encodeComponent(id)}';
  return demo ? '$path?demo=1' : path;
}

/// URL absoluta en web. En escritorio devuelve la ruta.
String quoteShareUrl(String id, {bool demo = false}) {
  final relative = quoteSharePath(id, demo: demo);
  if (!kIsWeb) return relative;
  final path = Uri.base.path;
  const marker = '/nereus_app';
  final at = path.indexOf(marker);
  final prefix = at >= 0 ? marker : '';
  return '${Uri.base.origin}$prefix$relative';
}

/// Resumen de la vista pública. No es el PDF A4 del API.
String quoteDocument(KildeQuote quote) {
  final buffer = StringBuffer()
    ..writeln('Cotización ${quote.number}')
    ..writeln('Cliente: ${quote.clientName ?? 'Sin cliente'}')
    ..writeln('Estado: ${_statusLabel(quote.status)}');
  if ((quote.validUntil ?? '').isNotEmpty) {
    buffer.writeln('Vigente hasta: ${quote.validUntil}');
  }
  if ((quote.observation ?? '').isNotEmpty) {
    buffer.writeln(quote.observation);
  }
  buffer.writeln('');
  if (quote.lines.isEmpty) {
    buffer.writeln('Total: ${clp(quote.total)}');
  } else {
    for (final line in quote.lines) {
      final qty = line.quantity == line.quantity.roundToDouble()
          ? line.quantity.round().toString()
          : line.quantity.toString();
      buffer.writeln(
        '$qty × ${line.name} · ${clp(line.unitPrice)} · ${clp(line.total)}',
      );
    }
    buffer
      ..writeln('')
      ..writeln('Total: ${clp(quote.total)}');
  }
  buffer.writeln('');
  buffer.writeln('Vista pública de Nereus.');
  return buffer.toString();
}

String _statusLabel(String code) {
  const labels = {
    'draft': 'Borrador',
    'sent': 'Enviada',
    'accepted': 'Aceptada',
    'objected': 'Objetada',
    'rejected': 'Rechazada',
    'expired': 'Vencida',
  };
  if (code.isEmpty) return 'Borrador';
  return labels[code] ?? code;
}
