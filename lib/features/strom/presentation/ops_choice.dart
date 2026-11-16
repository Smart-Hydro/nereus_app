import 'package:flutter/material.dart';

/// Opción de un selector. El id viaja al API; la persona ve [label].
class OpsChoice {
  const OpsChoice({required this.id, required this.label, this.detail = ''});

  final String id;
  final String label;
  final String detail;

  String get caption => detail.isEmpty ? label : '$label · $detail';
}

typedef OpsChoiceLoader = Future<List<OpsChoice>> Function(String query);

/// Campo de búsqueda que elige un registro por su nombre.
class OpsEntityField extends StatefulWidget {
  const OpsEntityField({
    super.key,
    required this.label,
    required this.load,
    required this.onChanged,
    this.initial,
    this.locked = false,
    this.required = false,
  });

  final String label;
  final OpsChoiceLoader load;
  final ValueChanged<OpsChoice?> onChanged;
  final OpsChoice? initial;
  final bool locked;
  final bool required;

  @override
  State<OpsEntityField> createState() => _OpsEntityFieldState();
}

class _OpsEntityFieldState extends State<OpsEntityField> {
  late final TextEditingController _search;
  List<OpsChoice> _options = const [];
  OpsChoice? _selected;
  var _loading = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _search = TextEditingController();
    if (widget.locked) return;
    _reload('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload(String query) async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final rows = await widget.load(query);
      if (!mounted) return;
      setState(() {
        _options = rows;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _options = const [];
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.required ? '${widget.label} *' : widget.label;
    if (widget.locked) {
      return InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(widget.initial?.caption ?? 'Definido por el contexto'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Busca por nombre',
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: _reload,
        ),
        const SizedBox(height: 8),
        if (_loading)
          const LinearProgressIndicator()
        else if (_failed)
          const Text(
            'El listado no está disponible. No hace falta escribir un id.',
          )
        else if (_options.isEmpty)
          const Text('No hay registros para elegir. Crea uno antes.')
        else
          for (final option in _options.take(8))
            ListTile(
              dense: true,
              selected: _selected?.id == option.id,
              title: Text(option.label),
              subtitle: option.detail.isEmpty ? null : Text(option.detail),
              onTap: () {
                setState(() => _selected = option);
                widget.onChanged(option);
              },
            ),
      ],
    );
  }
}

/// Elige varios registros. Sirve para los puntos de una instalación.
Future<List<OpsChoice>?> askOpsMany(
  BuildContext context, {
  required String title,
  required OpsChoiceLoader load,
  List<OpsChoice> initial = const [],
}) {
  return showDialog<List<OpsChoice>>(
    context: context,
    builder: (context) =>
        _ManyDialog(title: title, load: load, initial: initial),
  );
}

class _ManyDialog extends StatefulWidget {
  const _ManyDialog({
    required this.title,
    required this.load,
    required this.initial,
  });

  final String title;
  final OpsChoiceLoader load;
  final List<OpsChoice> initial;

  @override
  State<_ManyDialog> createState() => _ManyDialogState();
}

class _ManyDialogState extends State<_ManyDialog> {
  late final List<OpsChoice> _picked = [...widget.initial];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final choice in _picked)
                    InputChip(
                      label: Text(choice.label),
                      onDeleted: () => setState(() => _picked.remove(choice)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              OpsEntityField(
                label: 'Agregar',
                load: widget.load,
                onChanged: (choice) {
                  if (choice == null) return;
                  if (_picked.any((item) => item.id == choice.id)) return;
                  setState(() => _picked.add(choice));
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _picked),
          child: const Text('Listo'),
        ),
      ],
    );
  }
}

String opsDayText(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

/// Fecha AAAA-MM-DD elegida en el calendario.
class OpsDateField extends StatelessWidget {
  const OpsDateField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
  });

  final String label;
  final TextEditingController controller;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: 'Elige el día',
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(now.year - 2),
          lastDate: DateTime(now.year + 5),
          initialDate: DateTime.tryParse(controller.text) ?? now,
        );
        if (picked != null) controller.text = opsDayText(picked);
      },
    );
  }
}
