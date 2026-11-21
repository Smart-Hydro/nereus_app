import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/fichas/domain/ficha_models.dart';
import 'package:nereus_app/features/fichas/domain/survey_link.dart';
import 'package:nereus_app/features/fichas/presentation/ficha_ui.dart';

class LevantamientoShareCard extends StatelessWidget {
  const LevantamientoShareCard({
    super.key,
    required this.item,
    required this.demo,
  });

  final Levantamiento item;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final slug = item.slug;
    final url = slug == null || slug.isEmpty
        ? null
        : levantamientoShareUrl(slug, demo: demo);
    final ink = NereusTokens.text(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusChip(
                label: levantamientoEstado(item.status),
                tone: item.isActive
                    ? NereusTokens.emerald
                    : NereusTokens.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            url ?? 'Sin enlace público',
            style: TextStyle(color: ink, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (url != null)
                OutlinedButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) {
                      showFriendlyOk(context, 'Enlace copiado');
                    }
                  },
                  child: const Text('Copiar enlace'),
                ),
              if (slug != null && slug.isNotEmpty)
                OutlinedButton(
                  onPressed: () => context.go(
                    levantamientoSharePath(slug, demo: demo),
                  ),
                  child: const Text('Vista previa'),
                ),
              OutlinedButton(
                onPressed: () =>
                    context.go('/levantamientos/editar/${item.id}'),
                child: const Text('Editar formulario'),
              ),
              FilledButton(
                onPressed: () => context.go('/levantamientos/fill/${item.id}'),
                child: const Text('Completar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
