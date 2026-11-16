import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromProjectScreen extends ConsumerWidget {
  const StromProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(opsProjectProvider(projectId));
    return OpsAsync(
      isLoading: project.isLoading,
      error: project.hasError ? project.error : null,
      onRetry: () => ref.invalidate(opsProjectProvider(projectId)),
      child: project.asData == null
          ? const SizedBox.shrink()
          : _Body(project: project.asData!.value),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.project});

  final OpsProject project;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  List<OpsScopePoint> _scope = const [];

  OpsProject get project => widget.project;

  Future<void> _refresh() async {
    ref.invalidate(opsProjectProvider(project.id));
    ref.invalidate(opsProjectsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return OpsDetail(
      title: project.name,
      subtitle: '${serviceTypeLabel(project.serviceType)} · ${projectStatusLabel(project.status)}',
      action: OpsButton('Editar', () => context.go('/strom/${project.id}/editar')),
      children: [
        OpsNote(
          [
            if (project.code.isNotEmpty) 'Código ${project.code}',
            if (project.clientPoNumber.isNotEmpty) 'OC ${project.clientPoNumber}',
            if (project.committedOn.isNotEmpty) 'Compromiso ${project.committedOn}',
            'Aclaraciones abiertas: ${project.openClarifications.length}',
          ].join('\n'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OpsButton('Cambiar estado', _status),
            OpsButton('Cerrar', _close, destructive: true),
            OpsButton('Costo', _cost),
            OpsButton('Registrar hito', _milestone),
            OpsButton('Importar alcance', _scopeImport),
          ],
        ),
        if (project.milestones.isEmpty)
          const OpsNote('Sin hitos todavía.')
        else
          for (final milestone in project.milestones)
            OpsTile(
              title: opsLabel(milestone.kind, milestoneLabels),
              subtitle: milestone.occurredOn,
              status: milestone.source.isEmpty ? 'Hito' : milestone.source,
            ),
        if (_scope.isNotEmpty) ...[
          const OpsNote('Alcance importado. Confirma cada ítem técnico.'),
          for (final point in _scope)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Punto ${point.device} · ${point.deviceType}'),
                  for (final item in point.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.activity),
                      subtitle: Text(
                        '${specialtyLabel(item.specialty)} · ${opsLabel(item.status, scopeItemLabels)}',
                      ),
                      trailing: item.status == 'confirmed'
                          ? null
                          : OpsButton('Confirmar', () => _confirm(item.id)),
                    ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _status() async {
    final values = await askOpsFields(
      context,
      title: 'Estado del proyecto',
      fields: [
        const OpsField(
          key: 'status',
          label: 'Estado',
          initial: 'execution',
          options: projectStatusLabels,
        ),
        const OpsField(
          key: 'reason',
          label: 'Motivo',
          hint: 'Obligatorio al suspender o cancelar',
        ),
      ],
    );
    if (values == null || !mounted) return;
    final ok = await runOps(
      context,
      title: 'Cambiar estado',
      message: 'El estado queda registrado como hito.',
      action: () => ref.read(projectsRepositoryProvider).setStatus(
            project.id,
            values['status']!,
            reason: values['reason'] ?? '',
          ),
    );
    if (ok) await _refresh();
  }

  Future<void> _close() async {
    final reason = await askOpsText(
      context,
      title: 'Cerrar proyecto',
      label: 'Motivo',
      required: false,
    );
    if (reason == null || !mounted) return;
    final ok = await runOps(
      context,
      title: 'Cerrar proyecto',
      message: 'Exige las OT ejecutadas o canceladas y el informe enviado.',
      confirmLabel: 'Cerrar',
      destructive: true,
      action: () => ref.read(projectsRepositoryProvider).close(project.id, reason: reason),
    );
    if (ok) await _refresh();
  }

  Future<void> _cost() async {
    await runOps(
      context,
      title: 'Costo del proyecto',
      message: 'Se calcula con el costo diario vigente de cada OT.',
      action: () async {
        final cost = await ref.read(projectsRepositoryProvider).cost(project.id);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Total ${cost.total}'),
            content: Text(
              cost.workOrders
                  .map(
                    (row) =>
                        'OT ${row.workOrderId} · ${specialtyLabel(row.specialty)} · ${row.visitsPerformed} visitas · ${row.total}',
                  )
                  .join('\n'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _milestone() async {
    final values = await askOpsFields(
      context,
      title: 'Hito',
      fields: const [
        OpsField(
          key: 'kind',
          label: 'Hito',
          initial: 'official_plan',
          options: {
            'client_po': 'OC del cliente',
            'client_po_received': 'Recepción de la OC',
            'committed_date': 'Fecha comprometida',
            'official_plan': 'Planificación oficial',
          },
        ),
        OpsField(key: 'day', label: 'Fecha', hint: 'AAAA-MM-DD', required: true),
      ],
    );
    if (values == null || !mounted) return;
    final ok = await runOps(
      context,
      title: 'Registrar hito',
      message: 'Queda la fecha original del hito.',
      action: () => ref.read(projectsRepositoryProvider).addMilestone(
            project.id,
            kind: values['kind']!,
            occurredOn: values['day']!,
          ),
    );
    if (ok) await _refresh();
  }

  Future<void> _scopeImport() async {
    final values = await askOpsFields(
      context,
      title: 'Alcance del punto de captación',
      fields: const [
        OpsField(key: 'device', label: 'Id del punto', required: true),
        OpsField(key: 'activity', label: 'Actividad', required: true),
        OpsField(key: 'key', label: 'Clave de origen', required: true),
        OpsField(
          key: 'specialty',
          label: 'Especialidad',
          initial: 'hydraulic',
          options: specialtyLabels,
        ),
        OpsField(key: 'quote', label: 'Texto de la cotización'),
      ],
    );
    if (values == null || !mounted) return;
    final device = requireOpsInt(context, values['device']!, 'punto');
    if (device == null) return;
    final ok = await runOps(
      context,
      title: 'Importar alcance',
      message: 'Los ítems quedan pendientes de confirmación técnica.',
      action: () async {
        final points = await ref.read(projectsRepositoryProvider).importScope(
          project.id,
          {
            'quotation_text': values['quote'] ?? '',
            'points': [
              {
                'device_id': device,
                'items': [
                  {
                    'source_key': values['key'],
                    'activity': values['activity'],
                    'specialty': values['specialty'],
                    'mandatory': true,
                  },
                ],
              },
            ],
          },
        );
        if (mounted) setState(() => _scope = points);
      },
    );
    if (ok) await _refresh();
  }

  Future<void> _confirm(String itemId) async {
    final ok = await runOps(
      context,
      title: 'Confirmar ítem',
      message: 'El ítem pasa a confirmado en el alcance.',
      action: () async {
        final point = await ref.read(projectsRepositoryProvider).confirmItem(project.id, itemId);
        if (!mounted) return;
        setState(() {
          _scope = [
            for (final current in _scope)
              if (current.id == point.id) point else current,
          ];
        });
      },
    );
    if (ok) await _refresh();
  }
}
