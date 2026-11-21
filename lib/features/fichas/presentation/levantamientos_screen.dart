import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/fichas/domain/ficha_models.dart';
import 'package:nereus_app/features/fichas/presentation/ficha_ui.dart';
import 'package:nereus_app/features/fichas/presentation/levantamiento_share_card.dart';
import 'package:nereus_app/features/fichas/providers/fichas_provider.dart';

class LevantamientosScreen extends ConsumerWidget {
  const LevantamientosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(levantamientoTemplatesProvider);
    final published = ref.watch(levantamientosProvider);
    final text = Theme.of(context).textTheme;
    final demo = ref.watch(dataModeProvider) == NereusDataMode.fixture;
    final plantillas = templates.value ?? const <LevantamientoTemplate>[];
    final listos = published.value ?? const <Levantamiento>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Terreno',
            title: 'Levantamientos',
            subtitle: 'Formularios de terreno para tenencias y captación',
          ),
          Expanded(
            child: AsyncBody(
              isLoading: templates.isLoading || published.isLoading,
              hasError: templates.hasError || published.hasError,
              isEmpty: false,
              onRetry: () {
                ref.invalidate(levantamientoTemplatesProvider);
                ref.invalidate(levantamientosProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NereusTokens.spaceMd,
                  0,
                  NereusTokens.spaceMd,
                  NereusTokens.spaceLg,
                ),
                children: [
                  FichaGrid(
                    maxColumns: 4,
                    children: [
                      FichaKpi(
                        label: 'Plantillas',
                        value: '${plantillas.length}',
                        icon: Icons.auto_awesome_outlined,
                      ),
                      FichaKpi(
                        label: 'Listos',
                        value: '${listos.length}',
                        icon: Icons.fact_check_outlined,
                        tone: NereusTokens.lagoon,
                      ),
                      FichaKpi(
                        label: 'Activos',
                        value:
                            '${listos.where((item) => item.isActive).length}',
                        icon: Icons.play_circle_outline,
                        tone: NereusTokens.emerald,
                      ),
                      FichaKpi(
                        label: 'Preguntas',
                        value:
                            '${plantillas.fold<int>(0, (sum, item) => sum + item.questions.length)}',
                        icon: Icons.help_outline,
                        tone: NereusTokens.lagoon,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Plantillas', style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Ármalas una vez y úsalas en cada cliente.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (plantillas.isEmpty)
                    const GlassCard(
                      child: Text(
                        'No hay plantillas todavía. Ábrelas desde Fichas.',
                      ),
                    )
                  else
                    FichaGrid(
                      maxColumns: 2,
                      children: [
                        for (final template in plantillas)
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: NereusTokens.readable(
                                          context,
                                          NereusTokens.navy,
                                        ).withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.fact_check_outlined,
                                        size: 17,
                                        color: NereusTokens.readable(
                                          context,
                                          NereusTokens.navy,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        template.name,
                                        style: text.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${template.questions.length} pregunta${template.questions.length == 1 ? '' : 's'}',
                                  style: text.bodyMedium,
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton(
                                      onPressed: () => _usarPlantilla(
                                        context,
                                        ref,
                                        template,
                                      ),
                                      child: const Text('Usar en terreno'),
                                    ),
                                    OutlinedButton(
                                      onPressed: () => context.go(
                                        '/levantamientos/plantilla/${template.id}/editar',
                                      ),
                                      child: const Text('Editar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text('Enlaces para compartir', style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Copia el enlace, abre la vista previa o edita las preguntas.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (listos.isEmpty)
                    const GlassCard(
                      child: Text(
                        'Cuando publiques una plantilla, aparece acá el enlace público.',
                      ),
                    )
                  else
                    FichaGrid(
                      maxColumns: 2,
                      children: [
                        for (final item in listos)
                          LevantamientoShareCard(item: item, demo: demo),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _usarPlantilla(
    BuildContext context,
    WidgetRef ref,
    LevantamientoTemplate template,
  ) async {
    try {
      final published = await ref
          .read(levantamientoRepositoryProvider)
          .publish(
            title: template.name,
            questions: template.questions,
          );
      ref.invalidate(levantamientosProvider);
      if (context.mounted) {
        showFriendlyOk(context, 'Formulario listo para terreno');
        context.go('/levantamientos/fill/${published.id}');
      }
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }
}
