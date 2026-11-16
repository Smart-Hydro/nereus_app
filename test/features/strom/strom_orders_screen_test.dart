import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/strom/domain/strom_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_orders_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_reports_screen.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

void main() {
  testWidgets('work orders show the hydraulic specialty', (tester) async {
    const orders = [
      OpsWorkOrder(
        id: '8',
        project: '41',
        specialty: 'hydraulic',
        status: 'suggested',
        scopeVersion: '1',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsOrdersProvider.overrideWith((ref) async => orders),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StromOrdersScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('OT 8 · Hidráulica'), findsOneWidget);
    expect(find.text('Sugerida'), findsOneWidget);
  });

  testWidgets('reports show version and the drive link', (tester) async {
    const reports = [
      OpsReport(
        id: '2',
        project: '41',
        version: '1',
        status: 'draft',
        driveUrl: 'https://drive.google.com/file/d/informe',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsReportsProvider.overrideWith((ref) async => reports),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StromReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Versión 1 · proyecto 41'), findsOneWidget);
    expect(find.text('https://drive.google.com/file/d/informe'), findsOneWidget);
    expect(
      find.text('El líder de la especialidad aprueba el informe.'),
      findsOneWidget,
    );
  });
}
