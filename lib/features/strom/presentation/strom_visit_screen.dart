import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromVisitScreen extends ConsumerWidget {
  const StromVisitScreen({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(opsVisitProvider(visitId));
    final crew = ref.watch(opsCrewProvider);
    return OpsAsync(
      isLoading: visit.isLoading,
      error: visit.hasError ? visit.error : null,
      onRetry: () => ref.invalidate(opsVisitProvider(visitId)),
      child: visit.asData == null
          ? const SizedBox.shrink()
          : _VisitBody(
              visit: visit.asData!.value,
              directory: crew.asData?.value ?? const [],
            ),
    );
  }
}

class _VisitBody extends ConsumerWidget {
  const _VisitBody({required this.visit, required this.directory});

  final OpsVisit visit;
  final List<OpsCrewMember> directory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = visit.crew.map((member) => member.name).join(', ');
    final when = visit.scheduledFor.isEmpty ? 'sin fecha' : visit.scheduledFor;
    return OpsDetail(
      title: 'Visita del $when',
      subtitle:
          '${visitTypeLabel(visit.visitType)} · ${visitStatusLabel(visit.status)}',
      children: [
        OpsNote(opsNextAction(visit.status)),
        OpsNote(
          'OT ${specialtyLabel(visit.specialty)}\n'
          'Fecha ${visit.scheduledFor.isEmpty ? 'sin programar' : visit.scheduledFor}\n'
          'Cuadrilla: ${names.isEmpty ? 'sin integrantes' : names}\n'
          '${visit.notes}',
        ),
        OpsLinks([
          OpsLink('Actividades', '/strom/actividades?ot=${visit.workOrder}'),
          OpsLink('Check de terreno', '/strom/terreno?visita=${visit.id}'),
          const OpsLink('Cuadrilla', '/strom/configuracion'),
        ]),
        for (final warning in [...visit.siteWarnings, ...visit.rtsWarnings])
          OpsNote(warning),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (visit.status == 'proposed')
              OpsButton('Programar', () => _schedule(context, ref)),
            if (visit.status == 'scheduled')
              OpsButton('Iniciar', () => _simple(context, ref, 'start')),
            if (visit.status == 'in_progress')
              OpsButton('Finalizar', () => _simple(context, ref, 'finish')),
            if (visit.status == 'scheduled' || visit.status == 'in_progress')
              OpsButton('Reprogramar', () => _reschedule(context, ref)),
            if (visit.status != 'finished' && visit.status != 'cancelled')
              OpsButton(
                'Cancelar',
                () => _cancel(context, ref),
                destructive: true,
              ),
            OpsButton('Sumar cuadrilla', () => _addCrew(context, ref)),
          ],
        ),
        for (final member in visit.crew)
          OpsTile(
            title: member.name,
            subtitle: '${member.company} · ${specialtyLabel(member.specialty)}',
            status: 'En la visita',
            onTap: () => _removeCrew(context, ref, member),
          ),
        for (final row in visit.reschedules)
          OpsNote('${row.previousDate} → ${row.newDate}. ${row.reason}'),
      ],
    );
  }

  Future<void> _reload(WidgetRef ref) async {
    ref.invalidate(opsVisitProvider(visit.id));
    ref.invalidate(opsVisitsProvider);
  }

  Future<void> _schedule(BuildContext context, WidgetRef ref) async {
    final day = await askOpsText(
      context,
      title: 'Programar',
      label: 'Fecha',
      hint: 'AAAA-MM-DD',
    );
    if (day == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Programar visita',
      message: 'Pasa de propuesta a programada.',
      action: () => ref.read(visitsRepositoryProvider).schedule(visit.id, day),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _reschedule(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Reprogramar',
      fields: const [
        OpsField(
          key: 'day',
          label: 'Nueva fecha',
          hint: 'AAAA-MM-DD',
          required: true,
        ),
        OpsField(key: 'reason', label: 'Motivo'),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Reprogramar visita',
      message: 'Se guarda el historial y el motivo. La visita mantiene su id.',
      action: () => ref
          .read(visitsRepositoryProvider)
          .reschedule(
            visit.id,
            newDate: values['day']!,
            reason: values['reason'] ?? '',
          ),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _simple(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final start = action == 'start';
    final ok = await runOps(
      context,
      title: start ? 'Iniciar visita' : 'Finalizar visita',
      message: start
          ? 'Exige que esté programada y que haya al menos un integrante.'
          : 'La visita queda finalizada.',
      action: () => start
          ? ref.read(visitsRepositoryProvider).start(visit.id)
          : ref.read(visitsRepositoryProvider).finish(visit.id),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await askOpsText(
      context,
      title: 'Cancelar visita',
      label: 'Motivo',
    );
    if (reason == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Cancelar visita',
      message: 'La cancelación exige motivo.',
      destructive: true,
      confirmLabel: 'Cancelar visita',
      action: () =>
          ref.read(visitsRepositoryProvider).cancel(visit.id, reason: reason),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _addCrew(BuildContext context, WidgetRef ref) async {
    if (directory.isEmpty) {
      final values = await askOpsFields(
        context,
        title: 'Integrante sin cuenta',
        fields: const [
          OpsField(key: 'name', label: 'Nombre', required: true),
          OpsField(key: 'company', label: 'Empresa'),
          OpsField(
            key: 'specialty',
            label: 'Especialidad',
            initial: 'hydraulic',
            options: specialtyLabels,
          ),
          OpsField(key: 'contact', label: 'Contacto'),
        ],
      );
      if (values == null || !context.mounted) return;
      final ok = await runOps(
        context,
        title: 'Crear integrante',
        message: 'La cuadrilla no tiene cuenta en el sistema.',
        action: () async {
          final created = await ref.read(visitsRepositoryProvider).createCrew({
            'name': values['name'],
            'company': values['company'],
            'specialty': values['specialty'],
            'contact': values['contact'],
            'is_active': true,
          });
          if (!context.mounted) return;
          final member = requireOpsInt(context, created.id, 'integrante');
          if (member == null) return;
          await ref.read(visitsRepositoryProvider).addCrew(visit.id, member);
        },
      );
      if (ok) {
        ref.invalidate(opsCrewProvider);
        await _reload(ref);
      }
      return;
    }
    final picked = await askOpsEntity(
      context,
      title: 'Sumar a la visita',
      label: 'Integrante',
      load: OpsLookups(ref).crew,
    );
    if (picked == null || !context.mounted) return;
    final member = requireOpsInt(context, picked.id, 'integrante');
    if (member == null) return;
    final ok = await runOps(
      context,
      title: 'Sumar cuadrilla',
      message: 'El integrante queda en esta visita.',
      action: () =>
          ref.read(visitsRepositoryProvider).addCrew(visit.id, member),
    );
    if (ok) await _reload(ref);
  }

  Future<void> _removeCrew(
    BuildContext context,
    WidgetRef ref,
    OpsCrewMember member,
  ) async {
    final id = requireOpsInt(context, member.id, 'integrante');
    if (id == null) return;
    final ok = await runOps(
      context,
      title: 'Quitar de la visita',
      message: '${member.name} sale de la cuadrilla de esta visita.',
      destructive: true,
      confirmLabel: 'Quitar',
      action: () => ref.read(visitsRepositoryProvider).removeCrew(visit.id, id),
    );
    if (ok) await _reload(ref);
  }
}
