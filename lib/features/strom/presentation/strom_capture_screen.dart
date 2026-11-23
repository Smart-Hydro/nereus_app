import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';

/// Captura de la cuadrilla. No pide cuenta.
class StromCaptureScreen extends ConsumerStatefulWidget {
  const StromCaptureScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<StromCaptureScreen> createState() => _StromCaptureScreenState();
}

class _StromCaptureScreenState extends ConsumerState<StromCaptureScreen> {
  Map<String, dynamic>? _visit;
  Object? _error;
  var _loading = true;
  var _name = '';
  final _sent = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Dio _dio() {
    return Dio(BaseOptions(baseUrl: ref.read(appConfigProvider).apiBase));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _dio().get<dynamic>(
        '/api/operations/capture/${widget.token}/',
      );
      setState(() {
        _visit = asMap(response.data);
        _loading = false;
      });
    } on Object catch (error) {
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
        children: [
          Text('Captura de terreno', style: text.headlineMedium),
          const SizedBox(height: 8),
          const Text(
            'No necesitas cuenta. Indica tu nombre y el resultado de cada actividad.',
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(labelText: 'Tu nombre'),
            onChanged: (value) => _name = value,
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              'El enlace no está vigente o ya venció.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (_visit != null)
            for (final raw in asMapList(_visit!['activities']))
              _ActivityCard(
                activity: raw,
                sent: _sent.contains(asString(raw['id'])),
                onSend: (result, observation, measurement, files) => _send(
                  asString(raw['id']),
                  result,
                  observation,
                  measurement,
                  files,
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _send(
    String activityId,
    String result,
    String observation,
    String measurement,
    List<PlatformFile> files,
  ) async {
    if (_name.trim().isEmpty) {
      showFriendlyError(context, 'Indica tu nombre.');
      return;
    }
    try {
      final form = FormData.fromMap({
        'activity_id': activityId,
        'result': result,
        'crew_member_name': _name.trim(),
        'observation': observation,
        'measurement': measurement,
      });
      for (final file in files) {
        final bytes = file.bytes;
        if (bytes == null) continue;
        form.files.add(
          MapEntry(
            'photos',
            MultipartFile.fromBytes(bytes, filename: file.name),
          ),
        );
      }
      await _dio().post<dynamic>(
        '/api/operations/capture/${widget.token}/checks/',
        data: form,
      );
      setState(() => _sent.add(activityId));
      if (mounted) showFriendlyOk(context, 'Propuesta enviada al líder.');
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    }
  }
}

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.activity,
    required this.sent,
    required this.onSend,
  });

  final Map<String, dynamic> activity;
  final bool sent;
  final Future<void> Function(
    String result,
    String observation,
    String measurement,
    List<PlatformFile> files,
  )
  onSend;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  var _result = 'completed';
  final _observation = TextEditingController();
  final _measurement = TextEditingController();
  var _files = <PlatformFile>[];
  var _busy = false;

  @override
  void dispose() {
    _observation.dispose();
    _measurement.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = asString(widget.activity['point']);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(asString(widget.activity['activity'], fallback: 'Actividad')),
            if (point.isNotEmpty) Text(point),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _result,
              decoration: const InputDecoration(labelText: 'Resultado'),
              items: const [
                DropdownMenuItem(value: 'completed', child: Text('Completa')),
                DropdownMenuItem(value: 'partial', child: Text('Parcial')),
                DropdownMenuItem(value: 'not_done', child: Text('No realizada')),
              ],
              onChanged: widget.sent
                  ? null
                  : (value) {
                      if (value != null) setState(() => _result = value);
                    },
            ),
            TextField(
              controller: _observation,
              decoration: const InputDecoration(labelText: 'Observación'),
            ),
            TextField(
              controller: _measurement,
              decoration: const InputDecoration(labelText: 'Medición'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.sent
                    ? null
                    : () async {
                        final picked = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          withData: true,
                          allowMultiple: true,
                        );
                        if (picked == null) return;
                        setState(() => _files = picked.files);
                      },
                child: Text(
                  _files.isEmpty ? 'Agregar fotos' : '${_files.length} fotos',
                ),
              ),
            ),
            FilledButton(
              onPressed: widget.sent || _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      await widget.onSend(
                        _result,
                        _observation.text,
                        _measurement.text,
                        _files,
                      );
                      if (mounted) setState(() => _busy = false);
                    },
              child: Text(widget.sent ? 'Enviada' : 'Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
