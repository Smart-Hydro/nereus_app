import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromProjectCreateScreen extends ConsumerStatefulWidget {
  const StromProjectCreateScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<StromProjectCreateScreen> createState() =>
      _StromProjectCreateScreenState();
}

class _StromProjectCreateScreenState extends ConsumerState<StromProjectCreateScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _po = TextEditingController();
  final _poDate = TextEditingController();
  final _committed = TextEditingController();
  final _owner = TextEditingController();
  final _ticket = TextEditingController();
  final _quotation = TextEditingController();
  var _service = 'project';
  var _saving = false;
  var _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _po.dispose();
    _poDate.dispose();
    _committed.dispose();
    _owner.dispose();
    _ticket.dispose();
    _quotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.projectId;
    if (id != null) {
      ref.watch(opsProjectProvider(id)).whenData((project) {
        if (_loaded) return;
        _loaded = true;
        _name.text = project.name;
        _code.text = project.code;
        _po.text = project.clientPoNumber;
        _poDate.text = project.clientPoReceivedOn;
        _committed.text = project.committedOn;
        _owner.text = project.owner;
        _ticket.text = project.ticket;
        _quotation.text = project.quotation;
        if (serviceTypeLabels.containsKey(project.serviceType)) {
          _service = project.serviceType;
        }
      });
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: id == null ? 'Crear proyecto' : 'Editar proyecto',
        child: StromForm(
          saving: _saving,
          onSubmit: _save,
          children: [
            DropdownButtonFormField<String>(
              key: ValueKey(_service),
              initialValue: _service,
              decoration: const InputDecoration(labelText: 'Tipo *'),
              items: [
                for (final entry in serviceTypeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _service = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Código'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _po,
              decoration: const InputDecoration(labelText: 'OC del cliente'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _poDate,
              decoration: const InputDecoration(
                labelText: 'Recepción de la OC',
                hintText: 'AAAA-MM-DD',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _committed,
              decoration: const InputDecoration(
                labelText: 'Fecha comprometida',
                hintText: 'AAAA-MM-DD',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _owner,
              decoration: const InputDecoration(labelText: 'Responsable (id)'),
            ),
            if (id == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _ticket,
                decoration: const InputDecoration(labelText: 'Ticket (uuid)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quotation,
                decoration: const InputDecoration(labelText: 'Cotización (uuid)'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    final owner = _owner.text.trim().isEmpty ? null : requireOpsInt(context, _owner.text, 'responsable');
    if (_owner.text.trim().isNotEmpty && owner == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final id = widget.projectId;
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'code': _code.text.trim(),
        'service_type': _service,
        'client_po_number': _po.text.trim(),
        if (_poDate.text.trim().isNotEmpty) 'client_po_received_on': _poDate.text.trim(),
        if (_committed.text.trim().isNotEmpty) 'committed_on': _committed.text.trim(),
        if (owner != null) 'owner': owner,
      };
      if (id == null) {
        if (_ticket.text.trim().isNotEmpty) body['ticket_id'] = _ticket.text.trim();
        if (_quotation.text.trim().isNotEmpty) {
          body['quotation_id'] = _quotation.text.trim();
        }
        final created = await repo.create(body);
        ref.invalidate(opsProjectsProvider);
        if (mounted) context.go('/strom/${created.id}');
      } else {
        await repo.update(id, body);
        ref.invalidate(opsProjectsProvider);
        ref.invalidate(opsProjectProvider(id));
        if (mounted) context.go('/strom/$id');
      }
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
