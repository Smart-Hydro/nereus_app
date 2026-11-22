import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';

class ClientPoFile {
  const ClientPoFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;
}

class ClientPoInput {
  const ClientPoInput({
    required this.number,
    required this.receivedOn,
    required this.netAmount,
    this.file,
  });

  final String number;
  final String receivedOn;
  final String netAmount;
  final ClientPoFile? file;
}

typedef ClientPoFilePicker = Future<ClientPoFile?> Function();

Future<ClientPoFile?> pickClientPoFile() async {
  final picked = await FilePicker.platform.pickFiles(
    withData: true,
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
  );
  if (picked == null) return null;
  final file = picked.files.singleOrNull;
  final bytes = file?.bytes;
  final name = file?.name.trim() ?? '';
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  const allowed = {'pdf', 'jpg', 'jpeg', 'png'};
  if (file == null || bytes == null || !allowed.contains(ext)) {
    throw const FormatException('archivo');
  }
  return ClientPoFile(name: name, bytes: bytes);
}

Future<ClientPoInput?> askClientPo(
  BuildContext context, {
  ClientPoFilePicker? pickFile,
  String? initialDate,
}) {
  return showDialog<ClientPoInput>(
    context: context,
    builder: (context) => _ClientPoDialog(
      pickFile: pickFile ?? pickClientPoFile,
      initialDate: initialDate,
    ),
  );
}

class _ClientPoDialog extends StatefulWidget {
  const _ClientPoDialog({required this.pickFile, this.initialDate});

  final ClientPoFilePicker pickFile;
  final String? initialDate;

  @override
  State<_ClientPoDialog> createState() => _ClientPoDialogState();
}

class _ClientPoDialogState extends State<_ClientPoDialog> {
  late final TextEditingController _number;
  late final TextEditingController _date;
  late final TextEditingController _amount;
  ClientPoFile? _file;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _number = TextEditingController();
    _date = TextEditingController(text: widget.initialDate ?? today);
    _amount = TextEditingController();
  }

  @override
  void dispose() {
    _number.dispose();
    _date.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    try {
      final file = await widget.pickFile();
      if (!mounted || file == null) return;
      setState(() {
        _file = file;
        _error = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'El archivo tiene que ser pdf, jpg o png.';
      });
    }
  }

  void _save() {
    final number = _number.text.trim();
    final date = _date.text.trim();
    final amount = _amount.text.trim();
    if (number.isEmpty || amount.isEmpty || !isIsoDate(date)) {
      setState(() {
        _error = 'Indica número, fecha AAAA-MM-DD y monto neto.';
      });
      return;
    }
    Navigator.pop(
      context,
      ClientPoInput(
        number: number,
        receivedOn: date,
        netAmount: amount,
        file: _file,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Orden de compra'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _number,
            decoration: const InputDecoration(labelText: 'Número'),
          ),
          TextField(
            controller: _date,
            decoration: const InputDecoration(
              labelText: 'Fecha de recepción (AAAA-MM-DD)',
            ),
          ),
          TextField(
            controller: _amount,
            decoration: const InputDecoration(labelText: 'Monto neto'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _attach,
            child: Text(
              _file == null ? 'Adjuntar archivo' : 'Archivo: ${_file!.name}',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
