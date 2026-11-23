import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/features/crm/presentation/kilde_handoff_panel.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
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
      subtitle:
          '${serviceTypeLabel(project.serviceType)} · ${projectStatusLabel(project.status)}',
      action: OpsButton(
        'Editar',
        () => context.go('/strom/${project.id}/editar'),
      ),
      children: [
        OpsNote(opsNextAction(project.status)),
        OpsNote(
          [
            if (project.clientName.isNotEmpty) 'Cliente ${project.clientName}',
            if (project.originProject.isNotEmpty)
              'Nace del proyecto ${project.originProject}',
            if (project.code.isNotEmpty) 'Código ${project.code}',
            if (project.clientPoNumber.isNotEmpty)
              'OC ${project.clientPoNumber}',
            if (project.committedOn.isNotEmpty)
              'Compromiso ${project.committedOn}',
            'Aclaraciones abiertas: ${project.openClarifications.length}',
          ].join('\n'),
        ),
        OpsLinks([
          OpsLink(
            'Instalaciones',
            '/strom/instalaciones?proyecto=${project.id}',
          ),
          OpsLink('OT', '/strom/ordenes?proyecto=${project.id}'),
          OpsLink('Visitas', '/strom/visitas?proyecto=${project.id}'),
          OpsLink('RTS', '/strom/rts?proyecto=${project.id}'),
          OpsLink('Informes', '/strom/informes?proyecto=${project.id}'),
          OpsLink('Costos', '/strom/costos?proyecto=${project.id}'),
          OpsLink('Aclaraciones', '/strom/aclaraciones?proyecto=${project.id}'),
        ]),
        if (project.kildeHandoff != null)
          KildeHandoffPanel(
            handoff: project.kildeHandoff!,
            title: 'Viene de Kilde',
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
          const OpsNote(
            'Sin hitos todavía. Registra la planificación oficial cuando la tengas.',
          )
        else
          for (final milestone in project.milestones)
            OpsTile(
              title: opsLabel(milestone.kind, milestoneLabels),
              subtitle: milestone.occurredOn,
              status: milestone.source.isEmpty ? 'Hito' : milestone.source,
            ),
        _ScopeBlock(
          projectId: project.id,
          remote:
              ref.watch(opsScopeProvider(project.id)).asData?.value ?? const [],
          local: _scope,
          onConfirm: _confirm,
        ),
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
      action: () => ref
          .read(projectsRepositoryProvider)
          .setStatus(
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
      action: () => ref
          .read(projectsRepositoryProvider)
          .close(project.id, reason: reason),
    );
    if (ok) await _refresh();
  }

  Future<void> _cost() async {
    await runOps(
      context,
      title: 'Costo del proyecto',
      message: 'Se calcula con el costo diario vigente de cada OT.',
      action: () async {
        final cost = await ref
            .read(projectsRepositoryProvider)
            .cost(project.id);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Total ${cost.total}'),
            content: Text(
              cost.workOrders
                  .map(
                    (row) =>
                        'OT ${specialtyLabel(row.specialty)} · ${row.visitsPerformed} visitas · ${row.total}',
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
        OpsField(
          key: 'day',
          label: 'Fecha',
          hint: 'AAAA-MM-DD',
          required: true,
        ),
      ],
    );
    if (values == null || !mounted) return;
    final ok = await runOps(
      context,
      title: 'Registrar hito',
      message: 'Queda la fecha original del hito.',
      action: () => ref
          .read(projectsRepositoryProvider)
          .addMilestone(
            project.id,
            kind: values['kind']!,
            occurredOn: values['day']!,
          ),
    );
    if (ok) await _refresh();
  }

  Future<void> _scopeImport() async {
    final lookups = OpsLookups(ref);
    final point = await askOpsEntity(
      context,
      title: 'Alcance del punto de captación',
      label: 'Punto de captación',
      load: lookups.points,
    );
    if (point == null || !mounted) return;
    final values = await askOpsFields(
      context,
      title: 'Actividad del alcance',
      fields: const [
        OpsField(key: 'activity', label: 'Actividad', required: true),
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
    final device = requireOpsInt(context, point.id, 'punto');
    if (device == null) return;
    final activity = values['activity']!;
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
                'device_name': point.label,
                'items': [
                  {
                    'source_key': opsSourceKey(activity),
                    'activity': activity,
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
    if (ok) {
      ref.invalidate(opsScopeProvider(project.id));
      await _refresh();
    }
  }

  Future<void> _confirm(String itemId) async {
    final ok = await runOps(
      context,
      title: 'Confirmar ítem',
      message: 'El ítem pasa a confirmado en el alcance.',
      action: () async {
        final point = await ref
            .read(projectsRepositoryProvider)
            .confirmItem(project.id, itemId);
        if (!mounted) return;
        setState(() {
          _scope = [
            for (final current in _scope)
              if (current.id == point.id) point else current,
          ];
        });
      },
    );
    if (ok) {
      ref.invalidate(opsScopeProvider(project.id));
      await _refresh();
    }
  }
}

class _ScopeBlock extends ConsumerWidget {
  const _ScopeBlock({
    required this.projectId,
    required this.remote,
    required this.local,
    required this.onConfirm,
  });

  final String projectId;
  final List<OpsScopePoint> remote;
  final List<OpsScopePoint> local;
  final Future<void> Function(String itemId) onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = remote.isNotEmpty ? remote : local;
    if (points.isEmpty) {
      return const OpsNote(
        'Sin alcance importado. Elige el punto de captación y la actividad.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OpsNote('Alcance importado. Confirma cada ítem técnico.'),
        const SizedBox(height: 8),
        for (final point in points)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.pointLabel),
                if (point.quotationText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Cotización: ${point.quotationText}'),
                ],
                for (final item in point.items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.activity),
                    subtitle: Text(
                      [
                        specialtyLabel(item.specialty),
                        opsLabel(item.status, scopeItemLabels),
                        if (item.originLabel.isNotEmpty) item.originLabel,
                        if (item.productName.isNotEmpty) item.productName,
                        if (item.quantity.isNotEmpty) 'Cantidad ${item.quantity}',
                      ].join(' · '),
                    ),
                    trailing: item.status == 'confirmed'
                        ? null
                        : OpsButton('Confirmar', () => onConfirm(item.id)),
                  ),
              ],
            ),
          ),
        _UnassignedItems(projectId: projectId),
      ],
    );
  }
}

class _UnassignedItems extends ConsumerWidget {
  const _UnassignedItems({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(opsUnassignedScopeProvider(projectId)).asData?.value ??
        const <OpsScopeItem>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const OpsNote(
          'Sin pozo asignado. Operaciones elige el punto de captación.',
        ),
        for (final item in items)
          OpsTile(
            title: item.activity,
            subtitle: [
              if (item.originLabel.isNotEmpty) item.originLabel,
              specialtyLabel(item.specialty),
              if (item.productName.isNotEmpty) item.productName,
            ].join(' · '),
            status: 'Sin pozo',
            onTap: () => _assign(context, ref, item),
          ),
      ],
    );
  }

  Future<void> _assign(
    BuildContext context,
    WidgetRef ref,
    OpsScopeItem item,
  ) async {
    final point = await askOpsEntity(
      context,
      title: 'Asignar pozo',
      label: 'Punto de captación',
      load: OpsLookups(ref).points,
    );
    if (point == null || !context.mounted) return;
    final device = requireOpsInt(context, point.id, 'punto');
    if (device == null) return;
    final ok = await runOps(
      context,
      title: 'Asignar pozo',
      message: 'El ítem queda en ese punto, pendiente de confirmación.',
      action: () => ref
          .read(projectsRepositoryProvider)
          .assignItem(projectId, item.id, device),
    );
    if (!ok) return;
    ref.invalidate(opsUnassignedScopeProvider(projectId));
    ref.invalidate(opsScopeProvider(projectId));
  }
}
