import 'package:flutter/material.dart';

class RfiDraft {
  const RfiDraft({required this.question, required this.blocking});

  final String question;
  final bool blocking;
}

Future<RfiDraft?> askRfi(BuildContext context) {
  return showDialog<RfiDraft>(
    context: context,
    builder: (context) => const _RfiDialog(),
  );
}

class _RfiDialog extends StatefulWidget {
  const _RfiDialog();

  @override
  State<_RfiDialog> createState() => _RfiDialogState();
}

class _RfiDialogState extends State<_RfiDialog> {
  final _question = TextEditingController();
  var _blocking = true;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva consulta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _question,
            decoration: const InputDecoration(labelText: 'Pregunta'),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          FilterChip(
            label: const Text('Bloquea envío'),
            selected: _blocking,
            onSelected: (value) => setState(() => _blocking = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final text = _question.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(
              context,
              RfiDraft(question: text, blocking: _blocking),
            );
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}
