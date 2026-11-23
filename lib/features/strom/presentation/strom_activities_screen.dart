import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromActivitiesScreen extends ConsumerWidget {
  const StromActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = opsQuery(context, 'ot');
    return OpsBrowse<OpsActivity>(
      title: 'Actividades',
      subtitle: 'Por punto de captación. Nacen del alcance de la OT.',
      value: ref.watch(opsActivitiesProvider).whenData((items) {
        if (orderId == null) return items;
        return items.where((item) => item.workOrder == orderId).toList();
      }),
      onRetry: () => ref.invalidate(opsActivitiesProvider),
      emptyMessage:
          'No hay actividades. Materialízalas desde la OT confirmada.',
      action: FilledButton(
        onPressed: () => _materialize(context, ref, orderId),
        child: const Text('Materializar'),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.description.isEmpty ? 'Actividad' : item.description,
        subtitle: 'OT ${specialtyLabel(item.specialty)} · ${item.pointCaption}',
        status: opsLabel(item.executionStatus, executionLabels),
        onTap: () => context.go('/strom/actividades/${item.id}'),
      ),
    );
  }

  Future<void> _materialize(
    BuildContext context,
    WidgetRef ref,
    String? orderId,
  ) async {
    final OpsChoice? picked;
    if (orderId != null) {
      picked = OpsChoice(id: orderId, label: 'OT de esta orden');
    } else {
      picked = await askOpsEntity(
        context,
        title: 'Materializar',
        label: 'Orden de trabajo',
        load: OpsLookups(ref).orders(),
      );
    }
    if (picked == null || !context.mounted) return;
    final order = requireOpsInt(context, picked.id, 'OT');
    if (order == null) return;
    final ok = await runOps(
      context,
      title: 'Materializar actividades',
      message: 'Se crean desde el alcance confirmado de la OT.',
      action: () => ref.read(activitiesRepositoryProvider).materialize(order),
    );
    if (ok) ref.invalidate(opsActivitiesProvider);
  }
}

class StromActivityScreen extends ConsumerWidget {
  const StromActivityScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(opsActivityProvider(activityId));
    return OpsAsync(
      isLoading: activity.isLoading,
      error: activity.hasError ? activity.error : null,
      onRetry: () => ref.invalidate(opsActivityProvider(activityId)),
      child: activity.asData == null
          ? const SizedBox.shrink()
          : _ActivityBody(activity: activity.asData!.value),
    );
  }
}

class _ActivityBody extends ConsumerWidget {
  const _ActivityBody({required this.activity});

  final OpsActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsDetail(
      title: activity.description.isEmpty ? 'Actividad' : activity.description,
      subtitle:
          '${opsLabel(activity.executionStatus, executionLabels)} · ${opsLabel(activity.validationStatus, validationLabels)}',
      children: [
        OpsNote(opsNextAction(activity.executionStatus)),
        OpsNote(
          'OT ${specialtyLabel(activity.specialty)} · ${activity.pointCaption}\n'
          '${activity.validationLine}\n'
          '${activity.notDoneReason}\n${activity.validationNotes}',
        ),
        const OpsNote('La ejecución y la validación son estados distintos.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OpsButton('Ejecución', () => _execution(context, ref)),
            OpsButton('Validar', () => _validate(context, ref)),
            OpsButton('Historial', () => _history(context, ref)),
          ],
        ),
      ],
    );
  }

  Future<void> _reload(WidgetRef ref) async {
    ref.invalidate(opsActivityProvider(activity.id));
    ref.invalidate(opsActivitiesProvider);
  }

  Future<void> _execution(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Ejecución',
      fields: const [
        OpsField(
          key: 'status',
          label: 'Resultado',
          initial: 'completed',
          options: executionLabels,
        ),
        OpsField(
          key: 'reason',
          label: 'Motivo',
          hint: 'Obligatorio si no se realizó',
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Registrar ejecución',
      message: 'No cierra el proyecto.',
      action: () => ref
          .read(activitiesRepositoryProvider)
          .execution(
            activity.id,
            executionStatus: values['status']!,
            notDoneReason: values['reason'] ?? '',
          ),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _validate(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Validación técnica',
      fields: const [
        OpsField(
          key: 'result',
          label: 'Resultado',
          initial: 'approved',
          options: {
            'approved': 'Aprobada',
            'approved_with_observations': 'Aprobada con observaciones',
            'requires_correction': 'Requiere corrección',
          },
        ),
        OpsField(key: 'notes', label: 'Notas'),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Validar actividad',
      message: 'Lo registra el líder de la especialidad.',
      action: () => ref
          .read(activitiesRepositoryProvider)
          .validation(
            activity.id,
            result: values['result']!,
            notes: values['notes'] ?? '',
          ),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _history(BuildContext context, WidgetRef ref) async {
    final rows = await ref
        .read(activitiesRepositoryProvider)
        .history(activity.id);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial'),
        content: Text(
          rows.isEmpty
              ? 'Sin cambios de estado.'
              : rows
                    .map(
                      (row) =>
                          '${opsLabel(row.fromStatus, executionLabels)} → ${opsLabel(row.toStatus, executionLabels)} ${row.reason}',
                    )
                    .join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
