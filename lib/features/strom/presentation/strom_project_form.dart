import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromProjectCreateScreen extends ConsumerStatefulWidget {
  const StromProjectCreateScreen({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<StromProjectCreateScreen> createState() =>
      _StromProjectCreateScreenState();
}

class _StromProjectCreateScreenState
    extends ConsumerState<StromProjectCreateScreen> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _po = TextEditingController();
  final _poDate = TextEditingController();
  final _committed = TextEditingController();
  OpsChoice? _owner;
  OpsChoice? _client;
  OpsChoice? _ticket;
  OpsChoice? _quotation;
  var _service = 'project';
  var _saving = false;
  var _loaded = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _po.dispose();
    _poDate.dispose();
    _committed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.projectId;
    final lookups = OpsLookups(ref);
    if (id != null) {
      ref.watch(opsProjectProvider(id)).whenData((project) {
        if (_loaded) return;
        _loaded = true;
        _name.text = project.name;
        _code.text = project.code;
        _po.text = project.clientPoNumber;
        _poDate.text = project.clientPoReceivedOn;
        _committed.text = project.committedOn;
        if (project.owner.isNotEmpty) {
          _owner = OpsChoice(id: project.owner, label: 'Responsable actual');
        }
        if (project.client.isNotEmpty) {
          _client = OpsChoice(
            id: project.client,
            label: project.clientName.isEmpty ? 'Cliente actual' : project.clientName,
          );
        }
        if (serviceTypeLabels.containsKey(project.serviceType)) {
          _service = project.serviceType;
        }
      });
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: id == null ? 'Crear proyecto' : 'Editar proyecto',
        subtitle: 'Elige personas y documentos por su nombre.',
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
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
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
            OpsDateField(label: 'Recepción de la OC', controller: _poDate),
            const SizedBox(height: 12),
            OpsDateField(label: 'Fecha comprometida', controller: _committed),
            const SizedBox(height: 12),
            OpsEntityField(
              label: 'Responsable',
              load: lookups.users,
              initial: _owner,
              onChanged: (choice) => _owner = choice,
            ),
            const SizedBox(height: 12),
            OpsEntityField(
              label: 'Cliente',
              load: lookups.clients,
              initial: _client,
              onChanged: (choice) => _client = choice,
            ),
            if (id == null) ...[
              const SizedBox(height: 12),
              OpsEntityField(
                label: 'Ticket de origen',
                load: lookups.tickets,
                onChanged: (choice) => _ticket = choice,
              ),
              const SizedBox(height: 12),
              OpsEntityField(
                label: 'Cotización de origen',
                load: lookups.quotations,
                onChanged: (choice) => _quotation = choice,
              ),
            ],
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
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Indica el nombre del proyecto.');
      return;
    }
    final owner = _owner == null
        ? null
        : requireOpsInt(context, _owner!.id, 'responsable');
    if (_owner != null && owner == null) return;
    final client = _client == null
        ? null
        : requireOpsInt(context, _client!.id, 'cliente');
    if (_client != null && client == null) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(projectsRepositoryProvider);
      final id = widget.projectId;
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'code': _code.text.trim(),
        'service_type': _service,
        'client_po_number': _po.text.trim(),
        if (_poDate.text.trim().isNotEmpty)
          'client_po_received_on': _poDate.text.trim(),
        if (_committed.text.trim().isNotEmpty)
          'committed_on': _committed.text.trim(),
        if (owner != null) 'owner': owner,
        if (client != null) 'client': client,
      };
      if (id == null) {
        if (_ticket != null) body['ticket_id'] = _ticket!.id;
        if (_quotation != null) body['quotation_id'] = _quotation!.id;
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
