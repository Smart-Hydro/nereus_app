import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromVisitCreateScreen extends ConsumerStatefulWidget {
  const StromVisitCreateScreen({super.key, this.workOrderId});

  final String? workOrderId;

  @override
  ConsumerState<StromVisitCreateScreen> createState() =>
      _StromVisitCreateScreenState();
}

class _StromVisitCreateScreenState
    extends ConsumerState<StromVisitCreateScreen> {
  final _date = TextEditingController();
  final _notes = TextEditingController();
  OpsChoice? _order;
  var _type = 'planned';
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _date.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lookups = OpsLookups(ref);
    final orders = ref.watch(opsOrdersProvider).asData?.value ?? const [];
    final visits = ref.watch(opsVisitsProvider).asData?.value ?? const [];
    final lockedId = widget.workOrderId;
    OpsChoice? locked;
    if (lockedId != null) {
      final match = orders.where((order) => order.id == lockedId);
      locked = OpsChoice(
        id: lockedId,
        label: match.isEmpty
            ? 'OT de esta orden'
            : 'OT ${specialtyLabel(match.first.specialty)}',
        detail: match.isEmpty ? '' : workOrderStatusLabel(match.first.status),
      );
      _order = locked;
    }
    final first = lockedId == null
        ? visits.isEmpty
        : !visits.any((visit) => visit.workOrder == lockedId);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: 'Nueva visita',
        subtitle: 'La primera visita nace planificada.',
        child: StromForm(
          saving: _saving,
          submitLabel: 'Crear visita',
          onSubmit: _save,
          children: [
            const OpsNote(
              'Sin fecha queda propuesta. Con fecha queda programada y la OT debe estar confirmada.',
            ),
            const SizedBox(height: 12),
            OpsEntityField(
              label: 'Orden de trabajo',
              load: lookups.orders(),
              required: true,
              locked: locked != null,
              initial: locked ?? _order,
              onChanged: (choice) => _order = choice,
            ),
            const SizedBox(height: 12),
            if (first)
              const OpsNote('La primera visita de la OT queda planificada.')
            else
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final entry in visitTypeLabels.entries)
                    DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
            const SizedBox(height: 12),
            OpsDateField(label: 'Fecha', controller: _date),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final order = _order;
    if (order == null) {
      setState(() => _error = 'Elige la orden de trabajo.');
      return;
    }
    final orderId = requireOpsInt(context, order.id, 'OT');
    if (orderId == null) return;
    final visits = ref.read(opsVisitsProvider).asData?.value ?? const [];
    final first = !visits.any((visit) => visit.workOrder == order.id);
    setState(() => _saving = true);
    try {
      final created = await ref
          .read(visitsRepositoryProvider)
          .create(
            workOrderId: orderId,
            scheduledFor: _date.text.trim().isEmpty ? null : _date.text.trim(),
            notes: _notes.text.trim(),
            visitType: first ? 'planned' : _type,
          );
      ref.invalidate(opsVisitsProvider);
      if (mounted) context.go('/strom/visitas/${created.id}');
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
