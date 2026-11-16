import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromRequirementsPanel extends ConsumerWidget {
  const StromRequirementsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = opsQuery(context, 'proyecto');
    final sites = ref.watch(opsSiteRequirementsProvider);
    final duties = ref.watch(opsObligationsProvider);
    final projects = ref.watch(opsProjectsProvider).asData?.value ?? const [];
    return ListView(
      children: [
        OpsButton(
          'Nuevo requisito de sitio',
          () => _site(context, ref, projectId),
        ),
        const SizedBox(height: 8),
        sites.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => OpsNote(userFacingErrorMessage(error)),
          data: (items) => Column(
            children: [
              for (final item in items)
                if (projectId == null || item.project == projectId)
                  OpsTile(
                    title: opsLabel(item.kind, siteKindLabels),
                    subtitle: _projectName(projects, item.project),
                    status: opsLabel(item.status, siteStatusLabels),
                    onTap: () => _siteStatus(context, ref, item),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OpsButton('Nueva obligación del cliente', () => _duty(context, ref)),
        const SizedBox(height: 8),
        duties.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => OpsNote(userFacingErrorMessage(error)),
          data: (items) => Column(
            children: [
              for (final item in items)
                OpsTile(
                  title: item.description,
                  subtitle: 'Responsable ${item.responsible}',
                  status: opsLabel(item.status, obligationLabels),
                  onTap: () => _dutyStatus(context, ref, item),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _projectName(List<OpsProject> projects, String id) {
    for (final project in projects) {
      if (project.id == id) return project.name;
    }
    return 'Proyecto';
  }

  Future<void> _site(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Requisito de sitio',
      fields: [
        if (projectId == null)
          OpsField(
            key: 'project',
            label: 'Proyecto',
            required: true,
            choices: OpsLookups(ref).projects,
          )
        else
          OpsField(
            key: 'project',
            label: 'Proyecto',
            required: true,
            locked: true,
            initial: projectId,
            lockedLabel: 'Proyecto de esta ficha',
            choices: OpsLookups(ref).projects,
          ),
        const OpsField(
          key: 'kind',
          label: 'Tipo',
          initial: 'entry_permit',
          options: siteKindLabels,
        ),
        const OpsField(key: 'notes', label: 'Notas'),
      ],
    );
    if (values == null || !context.mounted) return;
    final project = requireOpsInt(context, values['project']!, 'proyecto');
    if (project == null) return;
    final ok = await runOps(
      context,
      title: 'Crear requisito',
      message: 'Queda pendiente hasta que se cumpla.',
      action: () => ref.read(installationsRepositoryProvider).createSite({
        'project': project,
        'kind': values['kind'],
        'status': 'pending',
        'notes': values['notes'],
      }),
    );
    if (ok) ref.invalidate(opsSiteRequirementsProvider);
  }

  Future<void> _siteStatus(
    BuildContext context,
    WidgetRef ref,
    OpsSiteRequirement item,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Estado del requisito',
      fields: [
        OpsField(
          key: 'status',
          label: 'Estado',
          initial: item.status,
          options: siteStatusLabels,
        ),
        OpsField(key: 'notes', label: 'Notas', initial: item.notes),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Actualizar requisito',
      message: 'El aviso de la visita usa este estado.',
      action: () =>
          ref.read(installationsRepositoryProvider).updateSite(item.id, {
            'status': values['status'],
            'notes': values['notes'],
          }),
    );
    if (ok) ref.invalidate(opsSiteRequirementsProvider);
  }

  Future<void> _duty(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Obligación del cliente',
      fields: [
        OpsField(
          key: 'ot',
          label: 'Orden de trabajo',
          required: true,
          choices: OpsLookups(ref).orders(),
        ),
        const OpsField(
          key: 'description',
          label: 'Descripción',
          required: true,
        ),
        const OpsField(
          key: 'responsible',
          label: 'Responsable',
          required: true,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final order = requireOpsInt(context, values['ot']!, 'OT');
    if (order == null) return;
    final ok = await runOps(
      context,
      title: 'Crear obligación',
      message: 'No marca pruebas ni cierra la actividad.',
      action: () => ref.read(installationsRepositoryProvider).createObligation({
        'work_order_id': order,
        'description': values['description'],
        'responsible': values['responsible'],
        'status': 'pending',
      }),
    );
    if (ok) ref.invalidate(opsObligationsProvider);
  }

  Future<void> _dutyStatus(
    BuildContext context,
    WidgetRef ref,
    OpsObligation item,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Estado de la obligación',
      fields: [
        OpsField(
          key: 'status',
          label: 'Estado',
          initial: item.status,
          options: obligationLabels,
        ),
        OpsField(key: 'notes', label: 'Notas', initial: item.notes),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Actualizar obligación',
      message: 'Queda el responsable y el estado.',
      action: () =>
          ref.read(installationsRepositoryProvider).updateObligation(item.id, {
            'status': values['status'],
            'notes': values['notes'],
          }),
    );
    if (ok) ref.invalidate(opsObligationsProvider);
  }
}
