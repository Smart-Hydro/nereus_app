import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/auth/domain/session_models.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/customers/domain/chile_places.dart';
import 'package:nereus_app/features/customers/presentation/clients_screen.dart';
import 'package:nereus_app/features/devices/providers/devices_provider.dart';
import 'package:nereus_app/features/tickets/domain/ticket_models.dart';

void main() {
  testWidgets('clients list renders names, not raw maps', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(_AdminSession.new),
          clientsProvider.overrideWith(
            (ref) async => const [
              ClientItem(
                id: '41',
                name: 'Agricola Nahuen',
                email: 'contacto@nahuen.cl',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ClientsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Agricola Nahuen'), findsOneWidget);
    expect(find.textContaining('{id:'), findsNothing);
  });

  test('el cliente lee giro, comuna y etiquetas', () {
    final item = ClientItem.fromJson(const {
      'id': '1',
      'name': 'APR Valle',
      'commercial_business': 'Agua potable',
      'commune': 'Pemuco',
      'receiver_type': 'EMPRESA',
      'default_document_type': 'FACTURA',
      'tags': ['APR', 'telemetría'],
    });
    expect(item.commercialBusiness, 'Agua potable');
    expect(item.commune, 'Pemuco');
    expect(item.receiverType, 'EMPRESA');
    expect(documentTypeLabel(item.defaultDocumentType), 'Factura electrónica');
    expect(item.tags, ['APR', 'telemetría']);
  });

  test('escribir pemuco sugiere la comuna y su provincia', () {
    expect(chilePlaces, hasLength(346));
    expect(chileRegionNames, hasLength(16));
    expect(
      chilePlaces.map((place) => place.commune).toSet(),
      hasLength(chilePlaces.length),
    );
    final pemuco = suggestPlaces('pem').single;
    expect(pemuco.commune, 'Pemuco');
    expect(pemuco.province, 'Diguillín');
    expect(pemuco.region, 'Ñuble');
    expect(
      suggestPlaces('chillan', region: 'Ñuble').map((place) => place.commune),
      containsAll(['Chillán', 'Chillán Viejo']),
    );
    expect(suggestPlaces('santiago', region: 'Ñuble'), isEmpty);
  });

  testWidgets('el alta de cliente muestra giro, comuna y documento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(_AdminSession.new),
          clientsProvider.overrideWith(
            (ref) async => const [
              ClientItem(id: '41', name: 'Agricola Nahuen'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ClientsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cliente'));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo cliente'), findsOneWidget);
    expect(find.text('Giro'), findsOneWidget);
    expect(find.text('Tipo de receptor'), findsOneWidget);
    expect(find.text('Documento por defecto'), findsOneWidget);
    expect(find.text('Comuna'), findsOneWidget);
    final formList = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(ListView),
    );
    await tester.drag(formList, const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Comuna'), 'Pemu');
    await tester.pumpAndSettle();
    expect(find.text('Diguillín · Ñuble'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Pemuco'));
    await tester.pumpAndSettle();
    expect(find.text('Diguillín'), findsWidgets);
    await tester.drag(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(ListView),
      ),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sector'), findsOneWidget);
    expect(find.text('Etiquetas'), findsOneWidget);
    expect(find.text('Cliente activo'), findsOneWidget);
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
