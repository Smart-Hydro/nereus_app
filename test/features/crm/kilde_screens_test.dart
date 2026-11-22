import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/crm/data/fixture_crm_repository.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/presentation/kilde_screens.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';

void main() {
  test('indicadores leen el snapshot de la API', () {
    final data = KildeIndicators.fromJson(const {
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
    final item = OpportunityItem.fromJson(const {
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

  test('la consulta lee el asignado y el motivo de reapertura', () {
    final row = KildeRfi.fromJson(const {
      'id': '1',
      'question': '¿Hay trifásica?',
      'assigned_to': 7,
      'assigned_to_name': 'Josefa Lagos',
      'reopen_reason': 'Falta el plano',
      'status': 'reopened',
    });
    expect(row.assignedToId, '7');
    expect(row.assignedToName, 'Josefa Lagos');
    expect(row.reopenReason, 'Falta el plano');
    expect(row.isOpen, isTrue);
  });

  test('asignar, cerrar y reabrir conserva la respuesta técnica', () async {
    final repo = FixtureCrmRepository();
    await repo.assignRfi(id: 'rfi-2', userId: 'Josefa Lagos');
    final assigned = (await repo.rfis()).firstWhere((row) => row.id == 'rfi-2');
    expect(assigned.status, 'assigned');
    expect(assigned.assignedToName, 'Josefa Lagos');
    expect(assigned.answer, 'Sí, tapa de 60 cm al lado norte.');

    await repo.closeRfi('rfi-2');
    expect(
      (await repo.rfis()).firstWhere((row) => row.id == 'rfi-2').status,
      'closed',
    );

    await repo.reopenRfi(id: 'rfi-2', reason: 'Falta el plano');
    final reopened = (await repo.rfis()).firstWhere((row) => row.id == 'rfi-2');
    expect(reopened.status, 'reopened');
    expect(reopened.reopenReason, 'Falta el plano');
    expect(reopened.answer, 'Sí, tapa de 60 cm al lado norte.');
  });

  test('mi día trae la llamada de hoy con su oportunidad', () async {
    final today = await FixtureCrmRepository().todayActivities();
    final call = today.singleWhere((item) => item.id == 'act-hoy');
    expect(call.description, 'Llamar al APR Valle del Itata');
    expect(call.opportunityId, 'opp-1');
    expect(call.isCompleted, isFalse);
  });

  testWidgets('mi día abre la oportunidad de la llamada', (tester) async {
    final router = GoRouter(
      initialLocation: '/equipo',
      routes: [
        GoRoute(
          path: '/equipo',
          builder: (_, _) => const KildeTeamScreen(),
        ),
        GoRoute(
          path: '/pipeline/:id',
          builder: (_, state) => Scaffold(
            body: Text('oportunidad ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mi día'), findsOneWidget);
    expect(find.text('Llamar al APR Valle del Itata'), findsOneWidget);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('oportunidad opp-1'), findsOneWidget);
  });

  testWidgets('consultas asigna, cierra y reabre con el nombre', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const KildeRfiScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asignar'), findsOneWidget);
    expect(find.text('Cerrar'), findsOneWidget);
    await tester.tap(find.text('Asignar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Josefa Lagos').last);
    await tester.pumpAndSettle();
    expect(find.text('Josefa Lagos'), findsWidgets);

    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Reabrir'), findsNWidgets(3));

    await tester.tap(find.widgetWithText(TextButton, 'Reabrir').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Falta el plano');
    await tester.tap(find.widgetWithText(FilledButton, 'Reabrir'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Motivo de reapertura: Falta el plano'),
      findsOneWidget,
    );
    expect(find.text('Asignar'), findsWidgets);
  });
}
