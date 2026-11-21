import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/fichas/domain/ficha_models.dart';
import 'package:nereus_app/features/fichas/providers/fichas_provider.dart';

final publicLevantamientoProvider = FutureProvider.autoDispose
    .family<Levantamiento, String>((ref, slug) {
      return ref.watch(levantamientoRepositoryProvider).bySlug(slug);
    });

/// Formulario público del levantamiento. No pide sesión.
class EncuestaPublicScreen extends ConsumerStatefulWidget {
  const EncuestaPublicScreen({
    super.key,
    required this.slug,
    this.demo = false,
  });

  final String slug;
  final bool demo;

  @override
  ConsumerState<EncuestaPublicScreen> createState() =>
      _EncuestaPublicScreenState();
}

class _EncuestaPublicScreenState extends ConsumerState<EncuestaPublicScreen> {
  final _answers = <String, Object?>{};
  bool _busy = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    if (widget.demo) {
      ref.read(dataModeProvider.notifier).useFixture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final survey = ref.watch(publicLevantamientoProvider(widget.slug));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: AsyncBody(
        isLoading: survey.isLoading,
        hasError: survey.hasError,
        isEmpty: survey.value == null,
        onRetry: () => ref.invalidate(publicLevantamientoProvider(widget.slug)),
        errorMessage: survey.hasError
            ? userFacingErrorMessage(survey.error ?? 'Error')
            : 'No pudimos abrir el formulario.',
        emptyMessage: 'Este enlace no tiene un formulario activo.',
        child: survey.value == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                children: [
                  Text(survey.value!.title, style: text.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    widget.demo
                        ? 'Vista de la demostración. El enlace se puede compartir.'
                        : 'Formulario público. No necesitas entrar a Nereus.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_sent)
                    const GlassCard(
                      child: Text('Respuesta enviada. Gracias.'),
                    )
                  else ...[
                    for (final question in survey.value!.questions) ...[
                      _PublicQuestion(
                        question: question,
                        onChanged: (value) => _answers[question.id] = value,
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _busy ? null : () => _send(survey.value!),
                      child: const Text('Enviar respuesta'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _send(Levantamiento survey) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(levantamientoRepositoryProvider)
          .respondPublic(
            slug: survey.slug ?? widget.slug,
            answers: _answers,
          );
      if (mounted) setState(() => _sent = true);
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _PublicQuestion extends StatefulWidget {
  const _PublicQuestion({required this.question, required this.onChanged});

  final LevantamientoQuestion question;
  final ValueChanged<Object?> onChanged;

  @override
  State<_PublicQuestion> createState() => _PublicQuestionState();
}

class _PublicQuestionState extends State<_PublicQuestion> {
  bool _flag = false;
  String? _select;

  @override
  Widget build(BuildContext context) {
    final question = widget.question;
    final label = question.required ? '${question.label} *' : question.label;
    final ink = NereusTokens.text(context);
    if (question.type == LevantamientoQuestionType.boolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: TextStyle(color: ink)),
        value: _flag,
        onChanged: (value) {
          setState(() => _flag = value);
          widget.onChanged(value);
        },
      );
    }
    if (question.type == LevantamientoQuestionType.select &&
        question.options.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: ink, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in question.options)
                ChoiceChip(
                  label: Text(option),
                  selected: _select == option,
                  onSelected: (_) {
                    setState(() => _select = option);
                    widget.onChanged(option);
                  },
                ),
            ],
          ),
        ],
      );
    }
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType:
          question.type == LevantamientoQuestionType.number ||
              question.type == LevantamientoQuestionType.decimal ||
              question.type == LevantamientoQuestionType.integer
          ? TextInputType.number
          : TextInputType.text,
      onChanged: widget.onChanged,
    );
  }
}
