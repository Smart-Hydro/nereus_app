import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/strom/data/reports_repository.dart';
import 'package:nereus_app/features/strom/domain/strom_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_audit_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_reports_screen.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

void main() {
  testWidgets('un informe sin texto muestra el snapshot validado', (
    tester,
  ) async {
    final repo = _FakeReports(_report(bodyText: ''));
    await _pumpReport(tester, repo, '9');

    expect(find.text('Sin cuerpo.'), findsNothing);
    expect(find.textContaining('Medir caudal del pozo'), findsOneWidget);
    expect(find.textContaining('12 l/s'), findsOneWidget);
    expect(find.textContaining('Tablero del pozo'), findsOneWidget);
    expect(find.textContaining('Dejar energizado el tablero'), findsOneWidget);
    expect(find.text('Actividades validadas'), findsOneWidget);
    expect(find.text('Pruebas realizadas'), findsOneWidget);
    expect(find.text('Evidencias'), findsOneWidget);
    expect(find.text('Pendientes del cliente'), findsOneWidget);
  });

  testWidgets('editar el texto deja el snapshot visible', (tester) async {
    final repo = _FakeReports(_report(bodyText: 'Cierre de puesta en marcha'));
    await _pumpReport(tester, repo, '9');

    expect(find.textContaining('Medir caudal del pozo'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Editar'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Cierre de puesta en marcha');

    await tester.enterText(
      find.byType(TextField),
      'Texto corregido en terreno',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['update']);
    expect(repo.lastBody, 'Texto corregido en terreno');
    expect(find.text('Texto corregido en terreno'), findsOneWidget);
    expect(find.textContaining('Medir caudal del pozo'), findsOneWidget);
    expect(find.textContaining('Dejar energizado el tablero'), findsOneWidget);
    expect(find.text('Sin cuerpo.'), findsNothing);
  });

  testWidgets('en revisión, devolver vuelve a borrador en la misma versión', (
    tester,
  ) async {
    final repo = _FakeReports(_report(status: 'review'));
    await _pumpReport(tester, repo, '9');

    expect(find.text('Nueva versión'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Devolver'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Devolver'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['return-draft']);
    expect(find.textContaining('Borrador'), findsWidgets);
    expect(find.textContaining('Informe v1'), findsOneWidget);
    expect(find.textContaining('Medir caudal del pozo'), findsOneWidget);
  });

  testWidgets('en enviado, nueva versión abre un borrador y no se edita', (
    tester,
  ) async {
    final repo = _FakeReports(_report(status: 'sent', bodyText: 'Ya enviado'));
    await _pumpReport(tester, repo, '9');

    expect(find.text('Editar'), findsNothing);
    expect(find.text('Devolver'), findsNothing);
    expect(find.text('Ya enviado'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Nueva versión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['revise']);
    expect(find.textContaining('Informe v2'), findsOneWidget);
    expect(find.textContaining('Borrador'), findsWidgets);
    expect(find.text('Ya enviado'), findsOneWidget);
    expect(find.textContaining('Medir caudal del pozo'), findsOneWidget);
    expect(find.text('Enviado'), findsNothing);
  });

  testWidgets('la auditoría nombra el informe y sus estados', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsTransitionsProvider.overrideWith(
            (ref) async => const [
              OpsTransition(
                id: '80',
                entityType: 'report',
                entityId: '9',
                fromValue: 'draft',
                toValue: 'review',
                reason: 'Pasó a revisión',
                occurredAt: '2026-11-17T12:00:00Z',
              ),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StromAuditScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Informe'), findsWidgets);
    expect(
      find.textContaining('Borrador → Revisión. Pasó a revisión'),
      findsOneWidget,
    );
  });
}

OpsReport _report({String status = 'draft', String bodyText = ''}) {
  return OpsReport(
    id: '9',
    project: '41',
    version: '1',
    status: status,
    specialty: 'hydraulic',
    bodyText: bodyText,
    activities: const [
      OpsReportActivity(
        title: 'Medir caudal del pozo',
        specialty: 'hydraulic',
        executionStatus: 'completed',
        validationStatus: 'approved',
      ),
    ],
    testsPerformed: const [
      OpsReportPerformedTest(
        result: 'completed',
        measurement: '12 l/s',
        observation: 'Caudal estable',
      ),
    ],
    evidences: const [
      OpsReportEvidenceRow(
        caption: 'Tablero del pozo',
        url: 'https://drive.google.com/file/d/demo-tablero',
      ),
    ],
    pendingClientWork: const [
      OpsReportPendingWork(
        description: 'Dejar energizado el tablero',
        status: 'pending',
        responsible: 'Cliente',
      ),
    ],
  );
}

Future<void> _pumpReport(
  WidgetTester tester,
  _FakeReports repo,
  String id,
) async {
  final router = GoRouter(
    initialLocation: '/strom/informes/$id',
    routes: [
      GoRoute(
        path: '/strom/informes/:id',
        builder: (context, state) => StromReportScreen(
          reportId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportsRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeReports extends Fake implements ReportsRepository {
  _FakeReports(OpsReport report) : reports = {report.id: report};

  final Map<String, OpsReport> reports;
  final calls = <String>[];
  String? lastBody;

  @override
  Future<OpsReport> get(String id) async => reports[id]!;

  @override
  Future<OpsReport> update(String id, {String? body, String? specialty}) async {
    calls.add('update');
    lastBody = body;
    final current = reports[id]!;
    final next = OpsReport(
      id: current.id,
      project: current.project,
      version: current.version,
      status: current.status,
      kind: current.kind,
      specialty: specialty ?? current.specialty,
      bodyText: body ?? current.bodyText,
      activities: current.activities,
      testsPerformed: current.testsPerformed,
      evidences: current.evidences,
      pendingClientWork: current.pendingClientWork,
      driveUrl: current.driveUrl,
    );
    reports[id] = next;
    return next;
  }

  @override
  Future<OpsReport> returnToDraft(String id) async {
    calls.add('return-draft');
    final current = reports[id]!;
    final next = OpsReport(
      id: current.id,
      project: current.project,
      version: current.version,
      status: 'draft',
      kind: current.kind,
      specialty: current.specialty,
      bodyText: current.bodyText,
      activities: current.activities,
      testsPerformed: current.testsPerformed,
      evidences: current.evidences,
      pendingClientWork: current.pendingClientWork,
      driveUrl: current.driveUrl,
    );
    reports[id] = next;
    return next;
  }

  @override
  Future<List<int>> pdf(String id) async => const [];

  @override
  Future<OpsReport> approve(String id, {String signature = ''}) async {
    calls.add('approve');
    return reports[id]!;
  }

  @override
  Future<OpsReport> revise(String id) async {
    calls.add('revise');
    final current = reports[id]!;
    final created = OpsReport(
      id: '99',
      project: current.project,
      version: '2',
      status: 'draft',
      kind: current.kind,
      specialty: current.specialty,
      bodyText: current.bodyText,
      activities: current.activities,
      testsPerformed: current.testsPerformed,
      evidences: current.evidences,
      pendingClientWork: current.pendingClientWork,
    );
    reports['99'] = created;
    return created;
  }
}
