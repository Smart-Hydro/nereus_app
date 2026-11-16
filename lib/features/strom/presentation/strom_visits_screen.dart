import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromVisitsScreen extends ConsumerWidget {
  const StromVisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = opsQuery(context, 'ot');
    final projectId = opsQuery(context, 'proyecto');
    final nueva = orderId == null
        ? '/strom/visitas/nueva'
        : '/strom/visitas/nueva?ot=$orderId';
    return OpsBrowse<OpsVisit>(
      title: 'Visitas',
      subtitle: 'La primera visita nace planificada.',
      value: ref.watch(opsVisitsProvider).whenData((items) {
        return items.where((visit) {
          if (orderId != null && visit.workOrder != orderId) return false;
          if (projectId != null && visit.project != projectId) return false;
          return true;
        }).toList();
      }),
      onRetry: () => ref.invalidate(opsVisitsProvider),
      action: StromCreateButton(onPressed: () => context.go(nueva)),
      emptyMessage: 'No hay visitas. Crea la primera, planificada.',
      emptyAction: FilledButton(
        onPressed: () => context.go(nueva),
        child: const Text('Crear visita'),
      ),
      itemBuilder: (context, visit) => OpsTile(
        title: 'Visita ${visitTypeLabel(visit.visitType).toLowerCase()}',
        subtitle: [
          'OT ${specialtyLabel(visit.specialty)}',
          if (visit.scheduledFor.isNotEmpty) visit.scheduledFor,
          if (visit.notes.isNotEmpty) visit.notes,
        ].join(' · '),
        status: visitStatusLabel(visit.status),
        onTap: () => context.go('/strom/visitas/${visit.id}'),
      ),
    );
  }
}
