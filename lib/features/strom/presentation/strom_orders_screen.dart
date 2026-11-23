import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromOrdersScreen extends ConsumerWidget {
  const StromOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = opsQuery(context, 'proyecto');
    final projects = ref.watch(opsProjectsProvider).asData?.value ?? const [];
    return OpsBrowse<OpsWorkOrder>(
      title: 'Órdenes de trabajo',
      subtitle: 'OT técnica por especialidad. No es la visita.',
      value: ref.watch(opsOrdersProvider).whenData((items) {
        if (projectId == null) return items;
        return items.where((order) => order.project == projectId).toList();
      }),
      onRetry: () => ref.invalidate(opsOrdersProvider),
      emptyMessage: 'No hay OT. Sugiere una desde el alcance del proyecto.',
      action: FilledButton(
        onPressed: () => _suggest(context, ref, projectId, projects),
        child: const Text('Sugerir'),
      ),
      itemBuilder: (context, order) => OpsTile(
        title: 'OT ${specialtyLabel(order.specialty)}',
        subtitle: _projectName(projects, order.project),
        status: workOrderStatusLabel(order.status),
        onTap: () => context.go('/strom/ordenes/${order.id}'),
      ),
    );
  }

  String _projectName(List<OpsProject> projects, String id) {
    for (final project in projects) {
      if (project.id == id) return project.name;
    }
    return 'Proyecto de la sucursal';
  }

  Future<void> _suggest(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
    List<OpsProject> projects,
  ) async {
    final OpsChoice? picked;
    if (projectId != null) {
      picked = OpsChoice(
        id: projectId,
        label: _projectName(projects, projectId),
      );
    } else {
      picked = await askOpsEntity(
        context,
        title: 'Sugerir OT',
        label: 'Proyecto',
        load: OpsLookups(ref).projects,
      );
    }
    if (picked == null || !context.mounted) return;
    final project = requireOpsInt(context, picked.id, 'proyecto');
    if (project == null) return;
    final ok = await runOps(
      context,
      title: 'Sugerir OT',
      message:
          'Se crean las OT por especialidad del alcance. No quedan vacías.',
      action: () => ref.read(workOrdersRepositoryProvider).suggest(project),
    );
    if (ok) ref.invalidate(opsOrdersProvider);
  }
}

class StromOrderScreen extends ConsumerWidget {
  const StromOrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(opsOrderProvider(orderId));
    final changes = ref.watch(opsScopeChangesProvider(orderId));
    return OpsAsync(
      isLoading: order.isLoading,
      error: order.hasError ? order.error : null,
      onRetry: () {
        ref.invalidate(opsOrderProvider(orderId));
        ref.invalidate(opsScopeChangesProvider(orderId));
      },
      child: order.asData == null
          ? const SizedBox.shrink()
          : _OrderBody(
              order: order.asData!.value,
              changes: changes.asData?.value ?? const [],
            ),
    );
  }
}

class _OrderBody extends ConsumerWidget {
  const _OrderBody({required this.order, required this.changes});

  final OpsWorkOrder order;
  final List<OpsScopeChange> changes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(opsProjectsProvider).asData?.value ?? const [];
    final projectName = projects
        .where((project) => project.id == order.project)
        .map((project) => project.name)
        .firstOrNull;
    return OpsDetail(
      title: 'OT ${specialtyLabel(order.specialty)}',
      subtitle:
          '${projectName ?? 'Proyecto'} · ${workOrderStatusLabel(order.status)}',
      children: [
        if (order.kind == 'adicional')
          const OpsNote('OT adicional. La principal confirmada no se modifica.'),
        if (order.confirmedByName.isNotEmpty)
          OpsNote(
            'Confirmada por ${order.confirmedByName} el ${order.confirmedAtDisplay} · versión ${order.scopeVersion} · ${order.commercialReference.isEmpty ? 'sin cotización ni OC' : order.commercialReference}',
          ),
        OpsNote(opsNextAction(order.status)),
        OpsNote(
          '${projectName ?? 'Proyecto de la sucursal'}\n'
          'Referencia ${order.commercialReference.isEmpty ? 'sin referencia' : order.commercialReference}\n'
          'Cambios de alcance pendientes: ${order.pendingScopeChanges}',
        ),
        OpsLinks([
          OpsLink('Visitas', '/strom/visitas?ot=${order.id}'),
          OpsLink('Nueva visita', '/strom/visitas/nueva?ot=${order.id}'),
          OpsLink('Actividades', '/strom/actividades?ot=${order.id}'),
          OpsLink('RTS', '/strom/rts?ot=${order.id}'),
        ]),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (order.status == 'suggested')
              OpsButton('Confirmar', () => _confirm(context, ref)),
            OpsButton('Estado', () => _status(context, ref)),
            OpsButton('Costo', () => _cost(context, ref)),
          ],
        ),
        if (order.blockReason.isNotEmpty)
          OpsNote('Bloqueo: ${order.blockReason}'),
        if (order.cancelReason.isNotEmpty)
          OpsNote('Cancelación: ${order.cancelReason}'),
        for (final change in changes)
          OpsTile(
            title: change.activity.isEmpty
                ? scopeChangeKindLabel(change.kind)
                : change.activity,
            subtitle: change.deviceName.isEmpty
                ? specialtyLabel(change.specialty)
                : '${specialtyLabel(change.specialty)} · ${change.deviceName}',
            status: scopeChangeStatusLabel(change.status),
            onTap: () => _decide(context, ref, change),
          ),
      ],
    );
  }

  Future<void> _reload(WidgetRef ref) async {
    ref.invalidate(opsOrderProvider(order.id));
    ref.invalidate(opsOrdersProvider);
    ref.invalidate(opsScopeChangesProvider(order.id));
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final reference = await askOpsText(
      context,
      title: 'Confirmar OT',
      label: 'Referencia comercial',
      required: false,
    );
    if (reference == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Confirmar OT',
      message: 'Después de confirmar, el alcance no cambia sin aprobación de Operaciones.',
      action: () => ref
          .read(workOrdersRepositoryProvider)
          .confirm(
            order.id,
            commercialReference: reference,
          ),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _status(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Estado de la OT',
      fields: const [
        OpsField(
          key: 'status',
          label: 'Estado',
          initial: 'planned',
          options: {
            'confirmed': 'Confirmada',
            'planned': 'Planificada',
            'in_progress': 'En ejecución',
            'executed': 'Ejecutada',
            'blocked': 'Bloqueada',
            'cancelled': 'Cancelada',
          },
        ),
        OpsField(key: 'reason', label: 'Motivo de bloqueo o cancelación'),
      ],
    );
    if (values == null || !context.mounted) return;
    final status = values['status']!;
    final reason = values['reason'] ?? '';
    final ok = await runOps(
      context,
      title: 'Cambiar estado',
      message: 'El líder de la especialidad registra el cambio.',
      action: () => ref
          .read(workOrdersRepositoryProvider)
          .setStatus(
            order.id,
            status: status,
            blockReason: status == 'blocked' ? reason : '',
            cancelReason: status == 'cancelled' ? reason : '',
          ),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _cost(BuildContext context, WidgetRef ref) async {
    await runOps(
      context,
      title: 'Costo de la OT',
      message: 'Visitas realizadas por el costo diario vigente.',
      action: () async {
        final cost = await ref
            .read(workOrdersRepositoryProvider)
            .cost(order.id);
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Total ${cost.total}'),
            content: Text(
              '${cost.visitsPerformed} visitas · diario ${cost.dailyCost}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    OpsScopeChange change,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Diferencia de alcance',
      fields: const [
        OpsField(
          key: 'approve',
          label: 'Decisión',
          initial: 'yes',
          options: {'yes': 'Aprobar', 'no': 'Rechazar'},
        ),
        OpsField(key: 'reason', label: 'Motivo'),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Decidir alcance',
      message: 'Operaciones aprueba o rechaza la diferencia.',
      action: () => ref
          .read(workOrdersRepositoryProvider)
          .decide(
            order.id,
            change.id,
            approve: values['approve'] == 'yes',
            reason: values['reason'] ?? '',
          ),
    );
    if (ok) await _reload(ref);
  }
}
