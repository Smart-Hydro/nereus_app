import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/strom/domain/strom_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_visit_screen.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

void main() {
  testWidgets('a scheduled planned visit shows its crew and start', (tester) async {
    const visit = OpsVisit(
      id: '15',
      workOrder: '8',
      specialty: 'hydraulic',
      visitType: 'planned',
      status: 'scheduled',
      scheduledFor: '2026-11-12',
      crew: [
        OpsCrewMember(id: '3', name: 'Cuadrilla Sur', specialty: 'hydraulic'),
      ],
      siteWarnings: ['Falta el permiso de ingreso'],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsVisitProvider.overrideWith((ref, id) async => visit),
          opsCrewProvider.overrideWith((ref) async => visit.crew),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StromVisitScreen(visitId: '15'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Visita 15'), findsOneWidget);
    expect(find.textContaining('Planificada'), findsWidgets);
    expect(find.textContaining('Cuadrilla Sur'), findsWidgets);
    expect(find.textContaining('Hidráulica'), findsWidgets);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Falta el permiso de ingreso'), findsOneWidget);
  });
}
