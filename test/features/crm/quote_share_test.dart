import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/auth/domain/session_models.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/catalog/providers/journey_providers.dart';
import 'package:nereus_app/features/crm/data/fixture_crm_repository.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/quote_share.dart';
import 'package:nereus_app/features/crm/presentation/cotizacion_public_screen.dart';
import 'package:nereus_app/features/crm/presentation/kilde_quotes_screen.dart';
import 'package:nereus_app/features/customers/domain/client_models.dart';

void main() {
  test('el enlace público de la demo lleva demo=1', () {
    expect(
      quoteSharePath('q-1042', demo: true),
      '/cotizacion/q-1042?demo=1',
    );
    expect(quoteSharePath('q-1042'), '/cotizacion/q-1042');
  });

  test('la cotización lee cliente e ítems', () {
    final quote = KildeQuote.fromJson(const {
      'id': 'q',
      'order_number': 'COT-9',
      'kilde_quote_status': 'sent',
      'client': {'name': 'APR Valle del Itata'},
      'products': [
        {'product_name': 'Datalogger', 'quantity': 2, 'unit_price': '1000'},
      ],
    });
    expect(quote.clientName, 'APR Valle del Itata');
    expect(quote.lines.single.name, 'Datalogger');
    expect(quote.total, 2000);
    expect(quoteDocument(quote), contains('Datalogger'));
  });

  test('la demo crea una cotización y el cliente la aprueba', () async {
    final repo = FixtureCrmRepository();
    final created = await repo.createQuotation(
      const QuoteDraft(
        clientId: '1',
        clientName: 'Agrícola Santa Rosa SpA',
        glosa: 'Caseta de pozo',
        quantity: 1,
        unitPrice: 1500000,
      ),
    );
    expect(created.clientName, 'Agrícola Santa Rosa SpA');
    expect(created.lines.single.name, 'Caseta de pozo');
    expect((await repo.quotations()).first.id, created.id);
    await repo.quoteAction(created.id, 'accept');
    expect((await repo.quotation(created.id)).status, 'accepted');
    expect(
      quoteDocument(await repo.quotation('q-1042')),
      contains('APR Valle'),
    );
  });

  testWidgets('cotizaciones muestra crear y el enlace para compartir', (
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
          sessionProvider.overrideWith(_AdminSession.new),
          customerClientsProvider.overrideWith(
            (ref) async => const [
              ClientItem(id: '1', name: 'Agrícola Santa Rosa SpA'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const KildeQuotesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nueva cotización'), findsOneWidget);
    expect(find.text('Compartir'), findsWidgets);
    expect(find.text('Vista pública'), findsWidgets);
    expect(
      find.textContaining('/cotizacion/q-1042?demo=1'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nueva cotización'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Caseta de pozo');
    await tester.enterText(find.byType(TextField).at(2), '1500000');
    await tester.tap(find.text('Crear cotización'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Caseta de pozo'), findsWidgets);
    expect(find.textContaining('/cotizacion/q-101?demo=1'), findsOneWidget);
  });

  testWidgets('la vista pública descarga y aprueba la cotización', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const CotizacionPublicScreen(id: 'q-1042'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('APR Valle del Itata'), findsOneWidget);
    expect(find.textContaining('Datalogger de pozo'), findsOneWidget);
    expect(find.text('Descargar'), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);

    await tester.tap(find.text('Descargar'));
    await tester.pumpAndSettle();
    expect(find.text('Resumen descargado.'), findsOneWidget);

    final approve = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Aprobar'),
    );
    expect(approve.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Aprobar'));
    await tester.pumpAndSettle();
    expect(find.text('El cliente ya aprobó esta cotización.'), findsOneWidget);
  });
}

class _AdminSession extends Session {
  @override
  FutureOr<AuthSession> build() => const AuthSession(
    token: 't',
    branchId: '1',
    enabledApps: ['customers'],
    branches: [BranchAssignment(branchId: 1, roleCode: 'ADM')],
  );
}
