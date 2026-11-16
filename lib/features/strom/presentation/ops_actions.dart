import 'package:flutter/material.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:url_launcher/url_launcher.dart';

class OpsField {
  const OpsField({
    required this.key,
    required this.label,
    this.initial = '',
    this.required = false,
    this.options = const {},
    this.hint,
    this.choices,
    this.locked = false,
    this.lockedLabel = '',
    this.date = false,
    this.searchHint,
  });

  final String key;
  final String label;
  final String initial;
  final bool required;
  final Map<String, String> options;
  final String? hint;
  final OpsChoiceLoader? choices;
  final bool locked;
  final String lockedLabel;
  final bool date;
  final String? searchHint;
}

/// Pide confirmación y muestra el mensaje del backend en 400, 403 y 409.
Future<bool> runOps(
  BuildContext context, {
  required String title,
  required String message,
  required Future<void> Function() action,
  String confirmLabel = 'Confirmar',
  bool destructive = false,
  bool confirm = true,
}) async {
  if (confirm) {
    final ok = await confirmAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!ok || !context.mounted) return false;
  }
  try {
    await action();
    if (context.mounted) showFriendlyOk(context, 'Listo.');
    return true;
  } on Object catch (error) {
    if (context.mounted) showFriendlyError(context, error);
    return false;
  }
}

Future<String?> askOpsText(
  BuildContext context, {
  required String title,
  required String label,
  String hint = '',
  bool required = true,
}) async {
  final values = await askOpsFields(
    context,
    title: title,
    fields: [
      OpsField(key: 'value', label: label, hint: hint, required: required),
    ],
  );
  return values?['value'];
}

Future<OpsChoice?> askOpsEntity(
  BuildContext context, {
  required String title,
  required String label,
  required OpsChoiceLoader load,
  OpsChoice? locked,
}) async {
  if (locked != null) return locked;
  final values = await askOpsFields(
    context,
    title: title,
    fields: [
      OpsField(key: 'id', label: label, required: true, choices: load),
    ],
  );
  if (values == null) return null;
  final chosen = values['id__label'] ?? '';
  return OpsChoice(
    id: values['id']!,
    label: chosen.isEmpty ? label : chosen,
    detail: values['id__detail'] ?? '',
  );
}

Future<Map<String, String>?> askOpsFields(
  BuildContext context, {
  required String title,
  required List<OpsField> fields,
  String submitLabel = 'Guardar',
}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => _OpsFormDialog(
      title: title,
      fields: fields,
      submitLabel: submitLabel,
    ),
  );
}

int? requireOpsInt(BuildContext context, String raw, String label) {
  final value = opsInt(raw);
  if (value == null) {
    showFriendlyError(
      context,
      ApiError(message: 'Indica un $label numérico.'),
    );
  }
  return value;
}

Future<void> openOpsLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    showFriendlyError(
      context,
      const ApiError(message: 'El enlace no es válido.'),
    );
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    showFriendlyError(
      context,
      const ApiError(message: 'No se pudo abrir el enlace.'),
    );
  }
}

class _OpsFormDialog extends StatefulWidget {
  const _OpsFormDialog({
    required this.title,
    required this.fields,
    required this.submitLabel,
  });

  final String title;
  final List<OpsField> fields;
  final String submitLabel;

  @override
  State<_OpsFormDialog> createState() => _OpsFormDialogState();
}

class _OpsFormDialogState extends State<_OpsFormDialog> {
  late final Map<String, TextEditingController> _texts;
  late final Map<String, String> _choices;
  final Map<String, OpsChoice?> _picked = {};
  String? _error;

  bool _isDate(OpsField field) => field.date || field.hint == 'AAAA-MM-DD';

  @override
  void initState() {
    super.initState();
    _texts = {
      for (final field in widget.fields)
        if (field.options.isEmpty && field.choices == null)
          field.key: TextEditingController(text: field.initial),
    };
    _choices = {
      for (final field in widget.fields)
        if (field.options.isNotEmpty)
          field.key: field.options.containsKey(field.initial)
              ? field.initial
              : field.options.keys.first,
    };
  }

  @override
  void dispose() {
    for (final controller in _texts.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(OpsField field) {
    if (field.choices != null) {
      if (field.locked) return field.initial;
      return _picked[field.key]?.id ?? '';
    }
    if (field.options.isNotEmpty) return _choices[field.key] ?? '';
    return _texts[field.key]?.text.trim() ?? '';
  }

  void _submit() {
    for (final field in widget.fields) {
      if (!field.required) continue;
      if (_value(field).isEmpty) {
        setState(() => _error = 'Completa ${field.label}.');
        return;
      }
    }
    final result = <String, String>{
      for (final field in widget.fields) field.key: _value(field),
    };
    for (final field in widget.fields) {
      final picked = _picked[field.key];
      if (picked == null) continue;
      result['${field.key}__label'] = picked.label;
      if (picked.detail.isNotEmpty) {
        result['${field.key}__detail'] = picked.detail;
      }
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
            ],
            for (final field in widget.fields) ...[
              if (field.choices != null)
                OpsEntityField(
                  label: field.label,
                  load: field.choices!,
                  required: field.required,
                  hint: field.searchHint ?? 'Busca por nombre',
                  locked: field.locked,
                  initial: field.initial.isEmpty
                      ? null
                      : OpsChoice(
                          id: field.initial,
                          label: field.lockedLabel.isEmpty
                              ? field.label
                              : field.lockedLabel,
                        ),
                  onChanged: (choice) => _picked[field.key] = choice,
                )
              else if (field.options.isEmpty && _isDate(field))
                OpsDateField(
                  label: field.label,
                  controller: _texts[field.key]!,
                  required: field.required,
                )
              else if (field.options.isEmpty)
                TextField(
                  controller: _texts[field.key],
                  decoration: InputDecoration(
                    labelText: field.required
                        ? '${field.label} *'
                        : field.label,
                    hintText: field.hint,
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _choices[field.key],
                  decoration: InputDecoration(labelText: field.label),
                  items: [
                    for (final entry in field.options.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _choices[field.key] = value);
                    }
                  },
                ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.submitLabel)),
      ],
    );
  }
}
