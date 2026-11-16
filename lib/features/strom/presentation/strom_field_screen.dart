import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
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
    return OpsBrowse<OpsFieldCheck>(
      title: 'Checks',
      bare: true,
      value: ref.watch(opsFieldChecksProvider),
      onRetry: () => ref.invalidate(opsFieldChecksProvider),
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OpsNote('Registrar el check de terreno no cierra el proyecto.'),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => _create(context, ref), child: const Text('Registrar')),
        ],
      ),
      itemBuilder: (context, item) => OpsTile(
        title: 'Visita ${item.visit} · actividad ${item.activity}',
        subtitle: '${item.measurement} ${item.observation}'.trim(),
        status: opsLabel(item.result, executionLabels),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Check de terreno',
      fields: const [
        OpsField(key: 'visit', label: 'Id de la visita', required: true),
        OpsField(key: 'activity', label: 'Id de la actividad', required: true),
        OpsField(
          key: 'result',
          label: 'Resultado',
          initial: 'completed',
          options: {
            'completed': 'Completa',
            'partial': 'Parcial',
            'not_done': 'No realizada',
          },
        ),
        OpsField(key: 'measurement', label: 'Medición'),
        OpsField(key: 'observation', label: 'Observación'),
        OpsField(key: 'reason', label: 'Motivo pendiente'),
        OpsField(key: 'owner', label: 'Responsable del pendiente'),
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
        'pending_reason': values['reason'],
        'pending_owner': values['owner'],
      }),
    );
    if (ok) ref.invalidate(opsFieldChecksProvider);
  }
}

class _Evidences extends ConsumerWidget {
  const _Evidences();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsEvidence>(
      title: 'Evidencias',
      bare: true,
      value: ref.watch(opsEvidencesProvider),
      onRetry: () => ref.invalidate(opsEvidencesProvider),
      header: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => _create(context, ref),
          child: const Text('Agregar'),
        ),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.caption.isEmpty ? 'Evidencia ${item.id}' : item.caption,
        subtitle: item.link.isEmpty ? 'Sin enlace de Drive' : item.link,
        status: item.link.isEmpty ? 'Sin Drive' : 'Con enlace',
        onTap: () => _open(context, ref, item),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Evidencia',
      fields: const [
        OpsField(key: 'visit', label: 'Id de la visita', required: true),
        OpsField(key: 'activity', label: 'Id de la actividad'),
        OpsField(key: 'url', label: 'URL'),
        OpsField(key: 'caption', label: 'Descripción'),
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
      action: () => ref.read(fieldRepositoryProvider).createEvidence(
            visitId: visit,
            activityId: activity,
            url: values['url'] ?? '',
            caption: values['caption'] ?? '',
          ),
    );
    if (ok) ref.invalidate(opsEvidencesProvider);
  }

  Future<void> _open(BuildContext context, WidgetRef ref, OpsEvidence item) async {
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
    final fileId = await askOpsText(context, title: 'Drive', label: 'Id del archivo');
    if (fileId == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Vincular Drive',
      message: 'Se guarda el enlace. No se copia el archivo.',
      action: () => ref.read(fieldRepositoryProvider).linkDrive(item.id, fileId: fileId),
    );
    if (ok) ref.invalidate(opsEvidencesProvider);
  }
}
