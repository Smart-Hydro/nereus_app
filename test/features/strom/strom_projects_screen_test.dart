import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/strom/domain/strom_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_projects_screen.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

void main() {
  testWidgets('strom lists a project and filters support', (tester) async {
    const projects = [
      OpsProject(
        id: '41',
        name: 'Instalación Norte',
        code: 'PN-41',
        serviceType: 'project',
        status: 'preparation',
      ),
      OpsProject(
        id: '42',
        name: 'Falla de logger',
        code: 'PS-42',
        serviceType: 'support',
        status: 'execution',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsProjectsProvider.overrideWith((ref) async => projects),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StromProjectsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Instalación Norte'), findsOneWidget);
    expect(find.text('Falla de logger'), findsOneWidget);

    await tester.tap(find.text('Soporte'));
    await tester.pumpAndSettle();
    expect(find.text('Falla de logger'), findsOneWidget);
    expect(find.text('Instalación Norte'), findsNothing);
  });
}
