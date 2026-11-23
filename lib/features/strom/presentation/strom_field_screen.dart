import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromFieldScreen extends StatelessWidget {
  const StromFieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StromChrome(
          title: 'Check de terreno',
          subtitle: 'Registrar el check de terreno no cierra el proyecto.',
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Checks'),
                  Tab(text: 'Evidencias'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Checks(),
                    _Evidences(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checks extends ConsumerWidget {
  const _Checks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitId = opsQuery(context, 'visita');
    return OpsBrowse<OpsFieldCheck>(
      title: 'Checks',
      bare: true,
      value: ref.watch(opsFieldChecksProvider).whenData((items) {
        if (visitId == null) return items;
        return items.where((item) => item.visit == visitId).toList();
      }),
      onRetry: () => ref.invalidate(opsFieldChecksProvider),
      emptyMessage: 'No hay checks. Registra el de la visita en curso.',
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OpsNote('Registrar el check de terreno no cierra el proyecto.'),
          if (visitId != null) _CrewProposals(visitId: visitId),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => _create(context, ref, visitId),
            child: const Text('Registrar'),
          ),
        ],
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.observation.isEmpty ? 'Check de terreno' : item.observation,
        subtitle: [
          item.measurement,
          item.observation,
          if (item.diagnosis.isNotEmpty) 'Diagnóstico: ${item.diagnosis}',
          if (item.actionsTaken.isNotEmpty) 'Acciones: ${item.actionsTaken}',
          if (item.partsUsed.isNotEmpty) 'Repuestos: ${item.partsUsed.join(', ')}',
        ].where((part) => part.trim().isNotEmpty).join(' · '),
        status: opsLabel(item.result, executionLabels),
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    String? visitId,
  ) async {
    final lookups = OpsLookups(ref);
    final values = await askOpsFields(
      context,
      title: 'Check de terreno',
      fields: [
        if (visitId == null)
          OpsField(
            key: 'visit',
            label: 'Visita',
            required: true,
            choices: lookups.visits(),
          )
        else
          OpsField(
            key: 'visit',
            label: 'Visita',
            required: true,
            locked: true,
            initial: visitId,
            lockedLabel: 'Visita de esta ficha',
            choices: lookups.visits(),
          ),
        OpsField(
          key: 'activity',
          label: 'Actividad',
          required: true,
          choices: lookups.activities(),
        ),
        const OpsField(
          key: 'result',
          label: 'Resultado',
          initial: 'completed',
          options: {
            'completed': 'Completa',
            'partial': 'Parcial',
            'not_done': 'No realizada',
          },
        ),
        const OpsField(key: 'measurement', label: 'Medición'),
        const OpsField(key: 'observation', label: 'Observación'),
        const OpsField(key: 'diagnosis', label: 'Diagnóstico'),
        const OpsField(key: 'actions', label: 'Acciones realizadas'),
        const OpsField(
          key: 'parts',
          label: 'Repuestos',
          hint: 'Ítem, serie y cantidad. Ej: Sello A1 x2',
        ),
        const OpsField(key: 'reason', label: 'Motivo pendiente'),
        const OpsField(key: 'owner', label: 'Responsable del pendiente'),
      ],
    );
    if (values == null || !context.mounted) return;
    final visit = requireOpsInt(context, values['visit']!, 'visita');
    final activity = requireOpsInt(context, values['activity']!, 'actividad');
    if (visit == null || activity == null) return;
    final ok = await runOps(
      context,
      title: 'Registrar check',
      message: 'Registrar el check de terreno no cierra el proyecto.',
      action: () => ref.read(fieldRepositoryProvider).createCheck({
        'visit_id': visit,
        'activity_id': activity,
        'result': values['result'],
        'measurement': values['measurement'],
        'observation': values['observation'],
        'diagnosis': values['diagnosis'],
        'actions_taken': values['actions'],
        'parts_used': _parts(values['parts'] ?? ''),
        'pending_reason': values['reason'],
        'pending_owner': values['owner'],
      }),
    );
    if (ok) ref.invalidate(opsFieldChecksProvider);
  }
}

class _CrewProposals extends ConsumerWidget {
  const _CrewProposals({required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(opsVisitProvider(visitId)).asData?.value;
    final rows = visit?.pendingCrewProposals ?? const [];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const OpsNote('Propuestas de la cuadrilla. Confírmalas o descártalas.'),
        for (final row in rows)
          OpsTile(
            title: row.crewMemberName.isEmpty ? 'Cuadrilla' : row.crewMemberName,
            subtitle:
                '${opsLabel(row.result, executionLabels)} · ${row.observation} ${row.measurement}'
                    .trim(),
            status: 'Propuesta',
            onTap: () => _review(context, ref, row.id),
          ),
      ],
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref, String id) async {
    final values = await askOpsFields(
      context,
      title: 'Propuesta de la cuadrilla',
      fields: const [
        OpsField(
          key: 'action',
          label: 'Qué hacer',
          initial: 'confirm',
          options: {'confirm': 'Confirmar en el check', 'discard': 'Descartar'},
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final confirm = values['action'] != 'discard';
    final ok = await runOps(
      context,
      title: confirm ? 'Confirmar propuesta' : 'Descartar propuesta',
      message: confirm
          ? 'Pasa al check de terreno de la visita.'
          : 'La propuesta no entra al check.',
      action: () => confirm
          ? ref.read(visitsRepositoryProvider).confirmProposal(id)
          : ref.read(visitsRepositoryProvider).discardProposal(id),
    );
    if (!ok) return;
    ref.invalidate(opsVisitProvider(visitId));
    ref.invalidate(opsFieldChecksProvider);
  }
}

List<Map<String, Object>> _parts(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return const [];
  return [
    for (final piece in text.split(','))
      if (piece.trim().isNotEmpty) {'item': piece.trim(), 'serial': '', 'quantity': 1},
  ];
}

class _Evidences extends ConsumerWidget {
  const _Evidences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitId = opsQuery(context, 'visita');
    return OpsBrowse<OpsEvidence>(
      title: 'Evidencias',
      bare: true,
      value: ref.watch(opsEvidencesProvider).whenData((items) {
        if (visitId == null) return items;
        return items.where((item) => item.visit == visitId).toList();
      }),
      onRetry: () => ref.invalidate(opsEvidencesProvider),
      header: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => _create(context, ref, visitId),
          child: const Text('Agregar'),
        ),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.caption.isEmpty ? 'Evidencia' : item.caption,
        subtitle: item.link.isEmpty ? 'Sin enlace de Drive' : item.link,
        status: item.link.isEmpty ? 'Sin Drive' : 'Con enlace',
        onTap: () => _open(context, ref, item),
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    String? visitId,
  ) async {
    final lookups = OpsLookups(ref);
    final values = await askOpsFields(
      context,
      title: 'Evidencia',
      fields: [
        if (visitId == null)
          OpsField(
            key: 'visit',
            label: 'Visita',
            required: true,
            choices: lookups.visits(),
          )
        else
          OpsField(
            key: 'visit',
            label: 'Visita',
            required: true,
            locked: true,
            initial: visitId,
            lockedLabel: 'Visita de esta ficha',
            choices: lookups.visits(),
          ),
        OpsField(
          key: 'activity',
          label: 'Actividad',
          choices: lookups.activities(),
        ),
        const OpsField(key: 'url', label: 'Enlace'),
        const OpsField(key: 'caption', label: 'Descripción'),
      ],
    );
    if (values == null || !context.mounted) return;
    final visit = requireOpsInt(context, values['visit']!, 'visita');
    if (visit == null) return;
    final activity = (values['activity'] ?? '').isEmpty
        ? null
        : requireOpsInt(context, values['activity']!, 'actividad');
    if ((values['activity'] ?? '').isNotEmpty && activity == null) return;
    final ok = await runOps(
      context,
      title: 'Guardar evidencia',
      message: 'Puedes vincular Drive después, sin copiar el archivo.',
      action: () => ref
          .read(fieldRepositoryProvider)
          .createEvidence(
            visitId: visit,
            activityId: activity,
            url: values['url'] ?? '',
            caption: values['caption'] ?? '',
          ),
    );
    if (ok) ref.invalidate(opsEvidencesProvider);
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    OpsEvidence item,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.link.isNotEmpty)
            ListTile(
              title: const Text('Abrir enlace'),
              onTap: () => Navigator.pop(context, 'open'),
            ),
          ListTile(
            title: const Text('Vincular Drive'),
            onTap: () => Navigator.pop(context, 'drive'),
          ),
        ],
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'open') {
      await openOpsLink(context, item.link);
      return;
    }
    final link = await askOpsText(
      context,
      title: 'Drive',
      label: 'Enlace de Drive',
    );
    if (link == null || !context.mounted) return;
    final fileId = _driveFile(link);
    final ok = await runOps(
      context,
      title: 'Vincular Drive',
      message: 'Se guarda el enlace. No se copia el archivo.',
      action: () =>
          ref.read(fieldRepositoryProvider).linkDrive(item.id, fileId: fileId),
    );
    if (ok) ref.invalidate(opsEvidencesProvider);
  }
}

String _driveFile(String raw) {
  final match = RegExp('/d/([^/?#]+)').firstMatch(raw);
  return match?.group(1) ?? raw.trim();
}
