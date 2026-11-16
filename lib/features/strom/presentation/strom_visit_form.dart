import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromVisitCreateScreen extends ConsumerStatefulWidget {
  const StromVisitCreateScreen({super.key, this.workOrderId});

  final String? workOrderId;

  @override
  ConsumerState<StromVisitCreateScreen> createState() => _StromVisitCreateScreenState();
}

class _StromVisitCreateScreenState extends ConsumerState<StromVisitCreateScreen> {
  late final TextEditingController _order;
  final _date = TextEditingController();
  final _notes = TextEditingController();
  var _type = 'planned';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _order = TextEditingController(text: widget.workOrderId ?? '');
  }

  @override
  void dispose() {
    _order.dispose();
    _date.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            TextField(
              controller: _order,
              decoration: const InputDecoration(labelText: 'Id de la OT *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_type),
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final entry in visitTypeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _date,
              decoration: const InputDecoration(
                labelText: 'Fecha',
                hintText: 'AAAA-MM-DD',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final order = requireOpsInt(context, _order.text, 'OT');
    if (order == null) return;
    setState(() => _saving = true);
    try {
      final created = await ref.read(visitsRepositoryProvider).create(
            workOrderId: order,
            scheduledFor: _date.text.trim().isEmpty ? null : _date.text.trim(),
            notes: _notes.text.trim(),
            visitType: _type,
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
