import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromVisitsScreen extends ConsumerWidget {
  const StromVisitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsVisit>(
      title: 'Visitas',
      subtitle: 'La primera visita nace planificada.',
      value: ref.watch(opsVisitsProvider),
      onRetry: () => ref.invalidate(opsVisitsProvider),
      action: StromCreateButton(onPressed: () => context.go('/strom/visitas/nueva')),
      emptyMessage: 'No hay visitas. Crea la primera.',
      itemBuilder: (context, visit) => OpsTile(
        title: 'Visita ${visit.id} · ${visitTypeLabel(visit.visitType)}',
        subtitle: [
          'OT ${visit.workOrder}',
          specialtyLabel(visit.specialty),
          if (visit.scheduledFor.isNotEmpty) visit.scheduledFor,
        ].join(' · '),
        status: visitStatusLabel(visit.status),
        onTap: () => context.go('/strom/visitas/${visit.id}'),
      ),
    );
  }
}
