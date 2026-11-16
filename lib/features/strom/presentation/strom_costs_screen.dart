import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromCostsScreen extends ConsumerWidget {
  const StromCostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsDailyCost>(
      title: 'Costos',
      subtitle: 'Rige el costo diario de cuadrilla más reciente.',
      value: ref.watch(opsDailyCostsProvider),
      onRetry: () => ref.invalidate(opsDailyCostsProvider),
      action: FilledButton(onPressed: () => _create(context, ref), child: const Text('Registrar')),
      header: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => _project(context, ref),
            child: const Text('Costo del proyecto'),
          ),
          OutlinedButton(
            onPressed: () => _order(context, ref),
            child: const Text('Costo de la OT'),
          ),
        ],
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.specialty.isEmpty ? 'Costo general' : specialtyLabel(item.specialty),
        subtitle: 'Vigente desde ${item.validFrom}',
        status: item.amount,
        onTap: () => _edit(context, ref, item),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final values = await _fields(context);
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Registrar costo diario',
      message: 'El cálculo usa el monto con la fecha de vigencia más reciente.',
      action: () => ref.read(costsRepositoryProvider).createDaily(
            amount: values['amount']!,
            validFrom: values['day']!,
            specialty: values['specialty'] ?? '',
          ),
    );
    if (ok) ref.invalidate(opsDailyCostsProvider);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, OpsDailyCost item) async {
    final values = await _fields(
      context,
      amount: item.amount,
      day: item.validFrom,
      specialty: item.specialty,
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Actualizar costo',
      message: 'El vigente sigue siendo el de fecha más reciente.',
      action: () => ref.read(costsRepositoryProvider).updateDaily(
            item.id,
            amount: values['amount'],
            validFrom: values['day'],
            specialty: values['specialty'],
          ),
    );
    if (ok) ref.invalidate(opsDailyCostsProvider);
  }

  Future<Map<String, String>?> _fields(
    BuildContext context, {
    String amount = '',
    String day = '',
    String specialty = 'hydraulic',
  }) {
    return askOpsFields(
      context,
      title: 'Costo diario',
      fields: [
        OpsField(key: 'amount', label: 'Monto', initial: amount, required: true),
        OpsField(key: 'day', label: 'Vigente desde', hint: 'AAAA-MM-DD', initial: day, required: true),
        OpsField(
          key: 'specialty',
          label: 'Especialidad',
          initial: specialty.isEmpty ? 'hydraulic' : specialty,
          options: const {'': 'General', 'hydraulic': 'Hidráulica', 'electric': 'Eléctrica'},
        ),
      ],
    );
  }

  Future<void> _project(BuildContext context, WidgetRef ref) async {
    final raw = await askOpsText(context, title: 'Costo del proyecto', label: 'Id del proyecto');
    if (raw == null || !context.mounted) return;
    final id = requireOpsInt(context, raw, 'proyecto');
    if (id == null) return;
    await runOps(
      context,
      title: 'Costo del proyecto',
      message: 'Suma el costo de sus OT.',
      confirm: false,
      action: () async {
        final cost = await ref.read(costsRepositoryProvider).projectCost('$id');
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Total ${cost.total}'),
            content: Text('${cost.workOrders.length} OT'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _order(BuildContext context, WidgetRef ref) async {
    final raw = await askOpsText(context, title: 'Costo de la OT', label: 'Id de la OT');
    if (raw == null || !context.mounted) return;
    final id = requireOpsInt(context, raw, 'OT');
    if (id == null) return;
    await runOps(
      context,
      title: 'Costo de la OT',
      message: 'Visitas realizadas por el costo diario vigente.',
      confirm: false,
      action: () async {
        final cost = await ref.read(costsRepositoryProvider).workOrderCost('$id');
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Total ${cost.total}'),
            content: Text('${cost.visitsPerformed} visitas · diario ${cost.dailyCost}'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ],
          ),
        );
      },
    );
  }
}
