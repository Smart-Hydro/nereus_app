import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

/// Validación técnica. La ejecuta el líder de la especialidad.
class StromTechnicalScreen extends ConsumerWidget {
  const StromTechnicalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(opsActivitiesProvider);
    return OpsBrowse<OpsActivity>(
      title: 'Check técnico',
      subtitle:
          'El líder de la especialidad valida. No es el check de terreno.',
      value: activities.whenData(
        (items) =>
            items.where((item) => item.validationStatus != 'approved').toList(),
      ),
      onRetry: () => ref.invalidate(opsActivitiesProvider),
      emptyMessage: 'No hay actividades pendientes de validación.',
      itemBuilder: (context, item) => OpsTile(
        title: item.description.isEmpty ? 'Actividad' : item.description,
        subtitle:
            'Ejecución ${opsLabel(item.executionStatus, executionLabels)}',
        status: opsLabel(item.validationStatus, validationLabels),
        onTap: () => context.go('/strom/actividades/${item.id}'),
      ),
    );
  }
}
