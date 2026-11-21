import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/presentation/kilde_flow.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';

final kildeClient360Provider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, clientId) => ref.watch(crmRepositoryProvider).client360(clientId),
);

class KildeClientCard extends ConsumerWidget {
  const KildeClientCard({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(kildeClient360Provider(clientId));
    final data = snap.value;
    if (snap.isLoading && data == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 16),
        child: LinearProgressIndicator(),
      );
    }
    if (snap.hasError || data == null) return const SizedBox.shrink();
    final nps = data['nps'];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comercial', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Derivación: ${derivationLabels[asString(data['derivation'] is Map ? (data['derivation'] as Map)['status'] : '')] ?? 'Por derivar'}',
            ),
            if (nps is Map)
              Text('NPS ${nps['latest_score']} (${nps['count']} respuestas)'),
            _block(context, 'Oportunidades', data['opportunities'], 'title'),
            _block(context, 'Cotizaciones', data['quotations'], 'status'),
            _block(context, 'Órdenes de compra', data['purchase_orders'], 'client_po_number'),
            _block(context, 'Levantamientos', data['surveys'], 'title'),
            _block(context, 'Consultas', data['rfis'], 'question'),
            _block(context, 'Hitos de Strøm', data['milestones'], 'description'),
            _block(context, 'Seguimiento', data['follow_up'], 'description'),
            _block(context, 'Contratos', data['contracts'], 'title'),
            TextButton(
              onPressed: () => context.go('/pipeline?client=$clientId'),
              child: const Text('Ver en el embudo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _block(BuildContext context, String title, Object? raw, String field) {
    if (raw is! List || raw.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          for (final row in raw.take(6))
            if (row is Map)
              Text(
                [
                  activityTypeLabel(asString(row['channel'])),
                  asString(row[field]),
                  asString(row['at']),
                  asString(row['assigned_to_id']),
                ].where((part) => part.isNotEmpty && part != field).join(' · '),
              ),
        ],
      ),
    );
  }
}
