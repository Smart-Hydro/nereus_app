import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';

class RfiActions extends ConsumerWidget {
  const RfiActions({required this.row, required this.team, super.key});

  final KildeRfi row;
  final List<KildeMember> team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closed = row.status == 'closed' || row.status == 'answered';
    final who = row.assignedToName ?? _name(team, row.assignedToId);
    return Wrap(
      spacing: 4,
      children: [
        if ((who ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: Text(who!),
          ),
        if (!closed) ...[
          TextButton(
            onPressed: team.isEmpty ? null : () => _assign(context, ref),
            child: const Text('Asignar'),
          ),
          TextButton(
            onPressed: () => _close(context, ref),
            child: const Text('Cerrar'),
          ),
        ] else
          TextButton(
            onPressed: () => _reopen(context, ref),
            child: const Text('Reabrir'),
          ),
      ],
    );
  }

  String? _name(List<KildeMember> team, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final member in team) {
      if (member.userId == id) return member.label;
    }
    return null;
  }

  Future<void> _assign(BuildContext context, WidgetRef ref) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Asignar consulta'),
        children: [
          for (final member in team)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, member.userId),
              child: Text(member.label),
            ),
        ],
      ),
    );
    if (selected == null || selected.isEmpty) return;
    try {
      await ref
          .read(crmRepositoryProvider)
          .assignRfi(id: row.id, userId: selected);
      ref.invalidate(kildeRfisProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(crmRepositoryProvider).closeRfi(row.id);
      ref.invalidate(kildeRfisProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _reopen(BuildContext context, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _ReopenDialog(),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await ref
          .read(crmRepositoryProvider)
          .reopenRfi(id: row.id, reason: reason);
      ref.invalidate(kildeRfisProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }
}

class _ReopenDialog extends StatefulWidget {
  const _ReopenDialog();

  @override
  State<_ReopenDialog> createState() => _ReopenDialogState();
}

class _ReopenDialogState extends State<_ReopenDialog> {
  final _motivo = TextEditingController();
  var _error = false;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _motivo.text.trim();
    if (text.isEmpty) {
      setState(() => _error = true);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reabrir consulta'),
      content: TextField(
        controller: _motivo,
        decoration: InputDecoration(
          labelText: 'Motivo',
          helperText: 'El motivo es obligatorio.',
          errorText: _error ? 'El motivo es obligatorio.' : null,
        ),
        onChanged: (_) {
          if (_error) setState(() => _error = false);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Reabrir')),
      ],
    );
  }
}
