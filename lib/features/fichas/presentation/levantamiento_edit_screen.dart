import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/fichas/domain/ficha_models.dart';
import 'package:nereus_app/features/fichas/domain/survey_link.dart';
import 'package:nereus_app/features/fichas/providers/fichas_provider.dart';

const _typeLabels = <LevantamientoQuestionType, String>{
  LevantamientoQuestionType.text: 'Texto',
  LevantamientoQuestionType.number: 'Número',
  LevantamientoQuestionType.decimal: 'Decimal',
  LevantamientoQuestionType.select: 'Lista',
  LevantamientoQuestionType.boolean: 'Sí / No',
  LevantamientoQuestionType.date: 'Fecha',
};

class LevantamientoEditScreen extends ConsumerStatefulWidget {
  const LevantamientoEditScreen.survey({super.key, required this.surveyId})
    : templateId = null;

  const LevantamientoEditScreen.template({super.key, required this.templateId})
    : surveyId = null;

  final String? surveyId;
  final String? templateId;

  @override
  ConsumerState<LevantamientoEditScreen> createState() =>
      _LevantamientoEditScreenState();
}

class _Draft {
  _Draft.from(LevantamientoQuestion question)
    : id = question.id,
      label = TextEditingController(text: question.label),
      options = TextEditingController(text: question.options.join(', ')),
      type = _typeLabels.containsKey(question.type)
          ? question.type
          : LevantamientoQuestionType.text,
      required = question.required;

  _Draft.empty()
    : id = 'q-${DateTime.now().microsecondsSinceEpoch}',
      label = TextEditingController(),
      options = TextEditingController(),
      type = LevantamientoQuestionType.text,
      required = false;

  final String id;
  final TextEditingController label;
  final TextEditingController options;
  LevantamientoQuestionType type;
  bool required;

  void dispose() {
    label.dispose();
    options.dispose();
  }
}

class _LevantamientoEditScreenState
    extends ConsumerState<LevantamientoEditScreen> {
  final _title = TextEditingController();
  final _drafts = <_Draft>[];
  bool _ready = false;
  bool _busy = false;
  String? _slug;

  @override
  void dispose() {
    _title.dispose();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _load(
    String title,
    List<LevantamientoQuestion> questions,
    String? slug,
  ) {
    if (_ready) return;
    _title.text = title;
    _slug = slug;
    _drafts.addAll(questions.map(_Draft.from));
    if (_drafts.isEmpty) _drafts.add(_Draft.empty());
    _ready = true;
  }

  @override
  Widget build(BuildContext context) {
    final surveyId = widget.surveyId;
    final templateId = widget.templateId;
    final survey = surveyId == null
        ? null
        : ref.watch(levantamientoDetailProvider(surveyId));
    final templates = templateId == null
        ? null
        : ref.watch(levantamientoTemplatesProvider);
    final loading =
        (survey?.isLoading ?? false) || (templates?.isLoading ?? false);
    final failed =
        (survey?.hasError ?? false) || (templates?.hasError ?? false);
    if (!_ready && !loading && !failed) {
      if (survey?.value != null) {
        _load(
          survey!.value!.title,
          survey.value!.questions,
          survey.value!.slug,
        );
      } else if (templates?.value != null) {
        final match = templates!.value!.where((item) => item.id == templateId);
        if (match.isNotEmpty) {
          _load(match.first.name, match.first.questions, null);
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            kicker: 'Terreno',
            title: 'Editar formulario',
            subtitle: surveyId == null
                ? 'Cambia las preguntas de la plantilla'
                : 'Cambia las preguntas del enlace público',
            actions: [
              FilledButton(
                onPressed: _busy || !_ready ? null : _save,
                child: const Text('Guardar'),
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              isLoading: loading && !_ready,
              hasError: failed && !_ready,
              isEmpty: !_ready,
              onRetry: () {
                if (surveyId != null) {
                  ref.invalidate(levantamientoDetailProvider(surveyId));
                }
                ref.invalidate(levantamientoTemplatesProvider);
              },
              errorMessage: userFacingErrorMessage(
                survey?.error ?? templates?.error ?? 'Error',
              ),
              emptyMessage: 'No encontramos este formulario.',
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  if (_slug != null && _slug!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      levantamientoShareUrl(
                        _slug!,
                        demo:
                            ref.watch(dataModeProvider) ==
                            NereusDataMode.fixture,
                      ),
                      style: TextStyle(color: NereusTokens.text(context)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  for (var i = 0; i < _drafts.length; i++)
                    _QuestionEditor(
                      draft: _drafts[i],
                      onChanged: () => setState(() {}),
                      onDelete: _drafts.length == 1
                          ? null
                          : () => setState(() {
                              _drafts.removeAt(i).dispose();
                            }),
                    ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _drafts.add(_Draft.empty())),
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar pregunta'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      showFriendlyError(context, 'El formulario necesita un nombre.');
      return;
    }
    final questions = <LevantamientoQuestion>[];
    for (final draft in _drafts) {
      final label = draft.label.text.trim();
      if (label.isEmpty) {
        showFriendlyError(context, 'Cada pregunta necesita un nombre.');
        return;
      }
      final options = [
        for (final part in draft.options.text.split(','))
          if (part.trim().isNotEmpty) part.trim(),
      ];
      questions.add(
        LevantamientoQuestion(
          id: draft.id,
          label: label,
          type: draft.type,
          required: draft.required,
          options: draft.type == LevantamientoQuestionType.select
              ? options
              : const [],
        ),
      );
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(levantamientoRepositoryProvider);
      final surveyId = widget.surveyId;
      if (surveyId != null) {
        await repo.save(id: surveyId, title: title, questions: questions);
        ref.invalidate(levantamientoDetailProvider(surveyId));
        ref.invalidate(levantamientosProvider);
      } else {
        await repo.saveTemplate(
          id: widget.templateId!,
          name: title,
          questions: questions,
        );
        ref.invalidate(levantamientoTemplatesProvider);
      }
      if (mounted) {
        showFriendlyOk(context, 'Formulario guardado');
        context.pop();
      }
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    required this.draft,
    required this.onChanged,
    required this.onDelete,
  });

  final _Draft draft;
  final VoidCallback onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          children: [
            TextField(
              controller: draft.label,
              decoration: const InputDecoration(labelText: 'Pregunta'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<LevantamientoQuestionType>(
              initialValue: draft.type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final entry in _typeLabels.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) {
                if (value == null) return;
                draft.type = value;
                onChanged();
              },
            ),
            if (draft.type == LevantamientoQuestionType.select) ...[
              const SizedBox(height: 8),
              TextField(
                controller: draft.options,
                decoration: const InputDecoration(
                  labelText: 'Opciones',
                  hintText: 'Separadas por coma',
                ),
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Obligatoria'),
              value: draft.required,
              onChanged: (value) {
                draft.required = value;
                onChanged();
              },
            ),
            if (onDelete != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onDelete,
                  child: const Text('Quitar pregunta'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
