import 'package:flutter/material.dart';
import 'package:nereus_app/features/crm/domain/quote_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

final _firmas = <String, String>{};

class _FirmaField extends StatefulWidget {
  const _FirmaField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_FirmaField> createState() => _FirmaFieldState();
}

class _FirmaFieldState extends State<_FirmaField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Firma de quien aprueba',
        hintText: 'Nombre. Queda en el PDF.',
      ),
      onChanged: widget.onChanged,
    );
  }
}

class StromReportsScreen extends ConsumerWidget {
  const StromReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = opsQuery(context, 'proyecto');
    final projects = ref.watch(opsProjectsProvider).asData?.value ?? const [];
    return OpsBrowse<OpsReport>(
      title: 'Informes',
      subtitle: 'Con especialidad, Operaciones o su líder. Sin especialidad, Operaciones o cualquier líder.',
      value: ref.watch(opsReportsProvider).whenData((items) {
        if (projectId == null) return items;
        return items.where((item) => item.project == projectId).toList();
      }),
      onRetry: () => ref.invalidate(opsReportsProvider),
      emptyMessage: 'No hay informes. Genera el borrador del proyecto.',
      action: FilledButton(
        onPressed: () => _generate(context, ref, projectId),
        child: const Text('Generar'),
      ),
      itemBuilder: (context, item) {
        final name = projects
            .where((project) => project.id == item.project)
            .map((project) => project.name)
            .firstOrNull;
        return OpsTile(
          title: 'Informe versión ${item.version}',
          subtitle:
              name ??
              (item.driveUrl.isEmpty ? 'Sin enlace de Drive' : item.driveUrl),
          status: opsLabel(item.status, reportStatusLabels),
          onTap: () => context.go('/strom/informes/${item.id}'),
        );
      },
    );
  }

  Future<void> _generate(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Generar informe',
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
          key: 'specialty',
          label: 'Especialidad',
          initial: 'hydraulic',
          options: {
            'hydraulic': 'Hidráulica',
            'electric': 'Eléctrica',
            '': 'Sin especialidad',
          },
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final project = requireOpsInt(context, values['project']!, 'proyecto');
    if (project == null) return;
    final ok = await runOps(
      context,
      title: 'Generar informe',
      message: 'Nace en borrador, con versión nueva.',
      action: () => ref
          .read(reportsRepositoryProvider)
          .generate(
            projectId: project,
            specialty: values['specialty'] ?? '',
          ),
    );
    if (ok) ref.invalidate(opsReportsProvider);
  }
}

class StromReportScreen extends ConsumerWidget {
  const StromReportScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(opsReportProvider(reportId));
    return OpsAsync(
      isLoading: report.isLoading,
      error: report.hasError ? report.error : null,
      onRetry: () => ref.invalidate(opsReportProvider(reportId)),
      child: report.asData == null
          ? const SizedBox.shrink()
          : _Body(report: report.asData!.value),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.report});

  final OpsReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsDetail(
      title: 'Informe v${report.version}',
      subtitle:
          '${opsLabel(report.kind, reportKindLabels)} · ${opsLabel(report.status, reportStatusLabels)}',
      children: [
        OpsNote(
          report.status == 'review'
              ? 'Siguiente: ${reportApproverNote(report.specialty)}'
              : opsNextAction(report.status),
        ),
        OpsNote(reportApproverNote(report.specialty)),
        ..._reportNotes(report),
        if (report.driveUrl.isNotEmpty)
          OpsButton('Abrir Drive', () => openOpsLink(context, report.driveUrl)),
        OpsButton('Descargar PDF', () => _pdf(context, ref)),
        if (report.status == 'review')
          _FirmaField(
            onChanged: (value) => _firmas[report.id] = value,
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (report.status == 'draft' || report.status == 'review')
              OpsButton('Editar', () => _edit(context, ref)),
            if (report.status == 'draft')
              OpsButton(
                'Enviar a revisión',
                () => _act(context, ref, 'review'),
              ),
            if (report.status == 'review') ...[
              OpsButton('Devolver', () => _act(context, ref, 'return-draft')),
              OpsButton('Aprobar', () => _act(context, ref, 'approve')),
            ],
            if (report.status == 'approved')
              OpsButton('Enviar', () => _act(context, ref, 'send')),
            if (report.status == 'sent')
              OpsButton('Nueva versión', () => _revise(context, ref)),
          ],
        ),
      ],
    );
  }

  Future<void> _pdf(BuildContext context, WidgetRef ref) async {
    try {
      final bytes = await ref.read(reportsRepositoryProvider).pdf(report.id);
      saveQuoteBytes(
        filename: 'informe-${report.project}-v${report.version}.pdf',
        bytes: bytes,
        mime: 'application/pdf',
      );
      if (context.mounted) showFriendlyOk(context, 'PDF listo.');
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _reload(WidgetRef ref) async {
    ref.invalidate(opsReportProvider(report.id));
    ref.invalidate(opsReportsProvider);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final text = await askOpsText(
      context,
      title: 'Cuerpo del informe',
      label: 'Texto',
      initial: report.bodyText,
      required: false,
    );
    if (text == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Guardar informe',
      message: 'Solo se edita en borrador o revisión.',
      action: () =>
          ref.read(reportsRepositoryProvider).update(report.id, body: text),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(reportsRepositoryProvider);
    final ok = await runOps(
      context,
      title: switch (action) {
        'review' => 'Enviar a revisión',
        'return-draft' => 'Devolver a borrador',
        'approve' => 'Aprobar informe',
        _ => 'Enviar informe',
      },
      message: switch (action) {
        'approve' => reportApproverNote(report.specialty),
        'return-draft' => 'Vuelve a borrador, en la misma versión.',
        'review' => 'Pasa a revisión. Queda en la misma versión.',
        'send' => 'Queda enviado y bloqueado. Un cambio abre otra versión.',
        _ => 'Se actualiza el informe.',
      },
      action: () => switch (action) {
        'review' => repo.submitReview(report.id),
        'return-draft' => repo.returnToDraft(report.id),
        'approve' => repo.approve(
          report.id,
          signature: _firmas[report.id] ?? '',
        ),
        _ => repo.send(report.id),
      },
    );
    if (ok) await _reload(ref);
  }

  Future<void> _revise(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(reportsRepositoryProvider);
    OpsReport? created;
    final ok = await runOps(
      context,
      title: 'Nueva versión',
      message: 'La versión enviada queda bloqueada. Se abre un borrador nuevo.',
      action: () async {
        created = await repo.revise(report.id);
      },
    );
    if (!ok || !context.mounted || created == null) return;
    ref.invalidate(opsReportsProvider);
    context.go('/strom/informes/${created!.id}');
  }
}

List<Widget> _reportNotes(OpsReport report) {
  final notes = <Widget>[
    if (report.bodyText.isNotEmpty)
      OpsNote(report.bodyText)
    else if (!report.hasSnapshot)
      const OpsNote('Sin cuerpo.'),
  ];
  void section(String title, List<String> rows) {
    if (rows.isEmpty) return;
    notes
      ..add(OpsNote(title))
      ..add(OpsNote(rows.join('\n')));
  }

  section('Actividades validadas', [
    for (final row in report.activities) _activityLine(row),
  ]);
  section('Pruebas realizadas', [
    for (final row in report.testsPerformed) _testLine(row),
  ]);
  section('Evidencias', [
    for (final row in report.evidences)
      if (row.caption.isNotEmpty) row.caption else row.url,
  ]);
  section('Pendientes del cliente', [
    for (final row in report.pendingClientWork) _pendingLine(row),
  ]);
  return notes;
}

String _activityLine(OpsReportActivity row) {
  final name = row.title.isEmpty ? 'Actividad' : row.title;
  final leader = row.leaderValidationResult.isEmpty
      ? 'pendiente'
      : opsLabel(row.leaderValidationResult, validationLabels);
  final ops = row.operationsValidationResult.isEmpty
      ? 'pendiente'
      : opsLabel(row.operationsValidationResult, validationLabels);
  return '$name · ${specialtyLabel(row.specialty)} · Líder: $leader · Operaciones: $ops';
}

String _testLine(OpsReportPerformedTest row) {
  return [
    if (row.result.isNotEmpty) opsLabel(row.result, executionLabels),
    if (row.measurement.isNotEmpty) row.measurement,
    if (row.observation.isNotEmpty) row.observation,
    if (row.diagnosis.isNotEmpty) 'Diagnóstico ${row.diagnosis}',
    if (row.actionsTaken.isNotEmpty) 'Acciones ${row.actionsTaken}',
    if (row.partsUsed.isNotEmpty) 'Repuestos ${row.partsUsed}',
  ].join(' · ');
}

String _pendingLine(OpsReportPendingWork row) {
  return [
    row.description,
    if (row.status.isNotEmpty) opsLabel(row.status, obligationLabels),
    if (row.responsible.isNotEmpty) row.responsible,
  ].where((part) => part.isNotEmpty).join(' · ');
}
