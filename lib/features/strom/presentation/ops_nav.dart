import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';

/// Lee un query de la ruta. Fuera de GoRouter devuelve null.
String? opsQuery(BuildContext context, String key) {
  try {
    final value = GoRouterState.of(context).uri.queryParameters[key];
    if (value == null || value.isEmpty) return null;
    return value;
  } on Object {
    return null;
  }
}

class OpsLink {
  const OpsLink(this.label, this.path);

  final String label;
  final String path;
}

/// Saltos del flujo. En teléfono bajan a la línea siguiente.
class OpsLinks extends StatelessWidget {
  const OpsLinks(this.links, {super.key});

  final List<OpsLink> links;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final link in links)
          OutlinedButton(
            onPressed: () => context.go(link.path),
            child: Text(link.label),
          ),
      ],
    );
  }
}

/// Clave de origen a partir del nombre de la actividad. No se pide a mano.
String opsSourceKey(String activity) {
  final buffer = StringBuffer();
  for (final unit in activity.toLowerCase().codeUnits) {
    final char = String.fromCharCode(unit);
    final ok = RegExp('[a-z0-9]').hasMatch(char);
    if (ok) {
      buffer.write(char);
    } else if (buffer.isNotEmpty && !buffer.toString().endsWith('-')) {
      buffer.write('-');
    }
  }
  final key = buffer.toString();
  return key.isEmpty ? 'actividad' : key;
}

/// Qué sigue, en una frase, según el estado.
String opsNextAction(String status) {
  return switch (status) {
    'preparation' => 'Siguiente: importa el alcance y sugiere la OT.',
    'suggested' => 'Siguiente: confirma la OT.',
    'confirmed' =>
      'Siguiente: planifica la visita y materializa las actividades.',
    'planned' => 'Siguiente: programa la visita.',
    'proposed' => 'Siguiente: programa la fecha. La visita sigue planificada.',
    'scheduled' => 'Siguiente: suma la cuadrilla e inicia la visita.',
    'in_progress' => 'Siguiente: registra el check de terreno y finaliza.',
    'finished' => 'Siguiente: valida las actividades y arma el informe.',
    'draft' => 'Siguiente: envía a revisión.',
    'review' => 'Siguiente: lo aprueba el líder de la especialidad.',
    'approved' => 'Siguiente: envía el informe.',
    'reserved' => 'Siguiente: da la salida de bodega.',
    'prepared' => 'Siguiente: reserva. $rtsReserveNote',
    _ => 'Revisa el estado y sigue el flujo del proyecto.',
  };
}
