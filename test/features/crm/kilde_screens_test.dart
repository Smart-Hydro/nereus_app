import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/presentation/kilde_screens.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';

void main() {
  test('indicadores leen el snapshot de la API', () {
    final data = KildeIndicators.fromJson({
      'prospects': {
        'contacted': 4,
        'with_requirement': 3,
        'without_requirement': 1,
        'not_contacted': 2,
      },
      'quotations': {
        'with_response': 2,
        'without_response': 1,
        'accepted': 1,
        'objected': 0,
        'rejected': {'count': 1},
      },
      'sales': {'count': 1, 'net_total': '4500000.00'},
      'funnel': {'weighted_value': '1200000'},
      'missing_next_action': 2,
      'overdue_activities': 1,
    });
    expect(data.contacted, 4);
    expect(data.withRequirement, 3);
    expect(data.quotesRejected, 1);
    expect(data.salesNet, 4500000);
    expect(data.weighted, 1200000);
    expect(data.missingNext, 2);
  });

  test('la próxima acción sale en la tarjeta del embudo', () {
    final item = OpportunityItem.fromJson({
      'id': '1',
      'title': 'Pozo Sur',
      'next_action': {'at': '2026-11-22T15:00:00Z', 'type': 'CALL'},
    });
    expect(item.nextActionLabel, contains('Llamada'));
    expect(item.nextActionLabel, contains('2026-11-22'));
  });

  testWidgets('indicadores muestran contactados y venta neta', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kildeIndicatorsProvider.overrideWith(
            (ref) async => const KildeIndicators(
              contacted: 4,
              salesNet: 4500000,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const KildeIndicatorsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Indicadores'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.textContaining('4.500.000'), findsOneWidget);
  });
}
