import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/auth/domain/session_models.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/catalog/domain/journey_models.dart';
import 'package:nereus_app/features/crm/data/fixture_crm_repository.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/presentation/client_po_dialog.dart';
import 'package:nereus_app/features/crm/presentation/cotizacion_public_screen.dart';
import 'package:nereus_app/features/crm/presentation/kilde_client_card.dart';
import 'package:nereus_app/features/crm/presentation/kilde_quotes_screen.dart';
import 'package:nereus_app/features/crm/presentation/quote_versions_dialog.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_project_screen.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

void main() {
  test('la versión tolera campos nulos y la v1 no trae diff', () {
    final versions = [
      QuoteVersion.fromJson(const {
        'id': 1,
        'version': null,
        'items': [
          null,
          {'product_name': 'Sensor'},
        ],
        'diff_vs_previous': null,
      }),
      QuoteVersion.fromJson(const {
        'id': '2',
        'version': 2,
        'kilde_quote_status': 'sent',
        'total': '1200',
        'valid_until': '2026-12-01',
        'diff_vs_previous': {
          'added': [
            {'product_id': 9, 'product_name': 'Radio', 'quantity': 1},
          ],
          'removed': null,
          'changed': [
            {
              'product_id': 'p',
              'product_name': 'Sensor',
              'field': 'quantity',
              'before': 1,
              'after': null,
            },
          ],
          'total_before': 1000,
          'total_after': '1200',
          'valid_until_before': '2026-11-01',
          'valid_until_after': '2026-12-01',
        },
      }),
    ];
    expect(versions.first.version, 1);
    expect(versions.first.diff, isNull);
    expect(versions.first.items.single.productName, 'Sensor');
    expect(versions.first.items.single.quantity, 0);
    expect(versions.last.diff!.added.single.productName, 'Radio');
    expect(versions.last.diff!.removed, isEmpty);
    expect(versions.last.diff!.changed.single.before, '1');
    expect(versions.last.diff!.changed.single.after, '');
    expect(versions.last.diff!.totalAfter, 1200);
  });

  test('la RFI lee el historial con id o nombre', () {
    final row = KildeRfi.fromJson(const {
      'id': '1',
      'question': '¿Hay trifásica?',
      'reopen_reason': 'Falta el plano',
      'answer': 'Sí',
      'answers': [
        {
          'id': 4,
          'answer': 'Primera',
          'answered_by': 9,
          'answered_at': '2026-11-01T10:00:00Z',
        },
        {
          'id': '5',
          'answer': 'Segunda',
          'answered_by': {'id': 3, 'full_name': 'Ana Ruiz'},
          'answered_at': null,
        },
      ],
    });
    expect(row.reopenReason, 'Falta el plano');
    expect(row.answers, hasLength(2));
    expect(row.answers.first.answeredBy, '9');
    expect(row.answers.last.answeredBy, 'Ana Ruiz');
    expect(row.history.last.answer, 'Segunda');
  });

  test('la demo recorre versiones, vencida, OC y hitos', () async {
    final repo = FixtureCrmRepository();
    final versions = await repo.quotationVersions('q-1042');
    expect(versions.map((row) => row.version), [1, 2]);
    expect(versions.first.diff, isNull);
    expect(versions.last.diff!.changed.single.field, 'quantity');
    expect(versions.last.diff!.totalBefore, 18800000);
    expect(versions.last.diff!.validUntilAfter, '2026-12-15');

    await expectLater(
      repo.quoteAction('q-1080', 'accept'),
      throwsA(
        isA<ApiError>().having(
          (error) => error.message,
          'message',
          expiredQuoteAcceptDetail,
        ),
      ),
    );
    expect((await repo.quotation('q-1080')).status, 'sent');

    await expectLater(
      repo.registerClientPo(
        quotationId: 'q-1080',
        number: 'OC-1',
        receivedOn: '2026-11-22',
        netAmount: '1',
      ),
      throwsA(isA<ApiError>()),
    );

    await repo.registerClientPo(
      quotationId: 'q-1101',
      number: 'OC-77',
      receivedOn: '2026-11-22',
      netAmount: '21000000',
      filename: 'oc.pdf',
      fileBytes: [1, 2, 3],
    );
    final quote = await repo.quotation('q-1101');
    expect(quote.poNumber, 'OC-77');
    expect(quote.poFile, '/media/client_po/oc.pdf');
    expect(quote.acceptedWithPo, isTrue);
    final won = (await repo.opportunities()).singleWhere(
      (item) => item.id == 'opp-6',
    );
    expect(won.isWon, isTrue);
    expect(
      deriveEnabled(
        roleCode: kildeSalesLead,
        hasSurvey: (won.surveyId ?? '').isNotEmpty,
        hasAcceptedQuoteWithPo: true,
      ),
      isTrue,
    );
    final preview = await repo.derivationPreview('opp-3');
    expect(preview.clientName, 'APR Valle del Itata');
    expect(preview.contacts, isNotEmpty);
    expect(preview.wells, isNotEmpty);
    expect(preview.equipment, isNotEmpty);
    expect(preview.surveyLabel, contains('Segunda etapa'));
    expect(preview.closedRfis.single.question, contains('gabinete'));
    expect(preview.closedRfis.single.answeredBy, 'Héctor Muñoz');

    final card = await repo.client360('cli-5');
    final milestones = card['milestones'] as List;
    expect(milestones, hasLength(4));
    final channels = [
      for (final row in milestones)
        if (row is Map) '${row['channel']}',
    ];
    expect(channels, [
      'strom_install',
      'strom_commissioning',
      'strom_handover',
      'strom_ikolu_training',
    ]);
    final line = stromMilestoneLine(milestones.first as Map);
    expect(line, contains('Fecha 2026-10-28'));
    expect(line, contains('Responsable Héctor Muñoz'));
  });

  test('el proyecto Strøm lee kilde_handoff incompleto', () {
    final project = OpsProject.fromJson(const {
      'id': 41,
      'name': 'Instalación Norte',
      'kilde_handoff': {
        'contacts': [
          {'first_name': 'Rosa', 'last_name': 'Muñoz'},
        ],
        'wells': ['Pozo norte'],
        'equipment': null,
        'survey': {'id': 'sv-1', 'title': 'Ficha Itata'},
        'closed_rfis': [
          {
            'id': 1,
            'question': '¿Hay energía?',
            'answer': 'Sí',
            'answered_by': 'Héctor Muñoz',
          },
        ],
      },
    });
    expect(project.kildeHandoff!.contacts.single, 'Rosa Muñoz');
    expect(project.kildeHandoff!.wells.single, 'Pozo norte');
    expect(project.kildeHandoff!.equipment, isEmpty);
    expect(project.kildeHandoff!.surveyTitle, 'Ficha Itata');
    expect(project.kildeHandoff!.closedRfis.single.answer, 'Sí');
    expect(OpsProject.fromJson(const {'id': 1, 'name': 'Solo'}).kildeHandoff, isNull);
  });

  testWidgets('versiones muestra el cambio y la v1 tal como quedó', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 5200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
          sessionProvider.overrideWith(_LeadSession.new),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const KildeQuotesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Versiones').first);
    await tester.pumpAndSettle();
    expect(find.byType(QuoteVersionsPanel), findsOneWidget);
    expect(find.textContaining('Cantidad: 1 → 2'), findsOneWidget);
    expect(find.textContaining('Total:'), findsOneWidget);
    expect(find.textContaining('Vigencia:'), findsOneWidget);

    await tester.tap(find.text('Versión 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tal como quedó'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Archivo de OC: /media/client_po/oc-4412.pdf'),
      findsOneWidget,
    );
    final expired = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, expiredQuoteAcceptLabel),
    );
    expect(expired.onPressed, isNull);
    expect(find.textContaining('· Vencida'), findsWidgets);
  });

  testWidgets('la vista pública deja Aprobar apagado si está vencida', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const CotizacionPublicScreen(id: 'q-1080'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Vencida'), findsWidgets);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, expiredQuoteAcceptLabel),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('el diálogo de OC pide fecha y archivo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                final result = await askClientPo(
                  context,
                  initialDate: '2026-11-22',
                  pickFile: () async =>
                      const ClientPoFile(name: 'oc.pdf', bytes: [1]),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result?.file?.name ?? 'nada')),
                );
              },
              child: const Text('Abrir OC'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir OC'));
    await tester.pumpAndSettle();
    expect(find.text('Fecha de recepción (AAAA-MM-DD)'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'OC-77');
    await tester.enterText(find.byType(TextField).at(2), '21000000');
    await tester.tap(find.text('Adjuntar archivo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('oc.pdf'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('oc.pdf'), findsOneWidget);
  });

  testWidgets('la ficha muestra los cuatro hitos con fecha y responsable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          kildeClient360Provider.overrideWith(
            (ref, id) async => {
              'derivation': {'status': 'derived'},
              'milestones': [
                {
                  'channel': 'strom_install',
                  'description': 'Instalación en terreno',
                  'at': '2026-10-28',
                  'assigned_to_name': 'Héctor Muñoz',
                },
                {
                  'channel': 'strom_commissioning',
                  'at': '2026-11-03',
                  'assigned_to_name': 'Héctor Muñoz',
                },
                {
                  'channel': 'strom_handover',
                  'at': '2026-11-10',
                  'assigned_to_name': 'Josefa Lagos',
                },
                {
                  'channel': 'strom_ikolu_training',
                  'at': '2026-11-18',
                  'assigned_to_name': 'Martín Soto',
                },
              ],
            },
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(body: KildeClientCard(clientId: 'cli-5')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Hito Strøm: instalación'), findsOneWidget);
    expect(find.textContaining('Fecha 2026-10-28'), findsOneWidget);
    expect(find.textContaining('Responsable Héctor Muñoz'), findsWidgets);
    expect(find.textContaining('Hito Strøm: capacitación Ikolu'), findsOneWidget);
    expect(find.textContaining('Responsable Martín Soto'), findsOneWidget);
  });

  testWidgets('el proyecto Strøm muestra lo que vino de Kilde', (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const project = OpsProject(
      id: '41',
      name: 'Instalación Norte',
      kildeHandoff: KildeHandoff(
        clientName: 'Agrícola Los Aromos',
        contacts: ['Roberto Henríquez'],
        wells: ['Los Niches 1'],
        quotation: 'COT-1018',
        equipment: ['Datalogger × 3'],
        surveyTitle: 'Levantamiento Pozos Los Niches',
        closedRfis: [
          KildeClosedRfi(
            id: 'rfi-8',
            question: '¿El pozo 2 tiene caudalímetro?',
            answer: 'Sí, instalado en octubre.',
            answeredBy: 'Héctor Muñoz',
            answeredAt: '2026-10-16',
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsProjectProvider.overrideWith((ref, id) async => project),
          opsScopeProvider.overrideWith((ref, id) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const StromProjectScreen(projectId: '41'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Viene de Kilde'), findsOneWidget);
    expect(find.text('Agrícola Los Aromos'), findsOneWidget);
    expect(find.text('Los Niches 1'), findsOneWidget);
    expect(find.text('Levantamiento Pozos Los Niches'), findsOneWidget);
    expect(find.textContaining('caudalímetro'), findsOneWidget);
    expect(find.textContaining('Héctor Muñoz'), findsOneWidget);
  });
}

class _LeadSession extends Session {
  @override
  FutureOr<AuthSession> build() => const AuthSession(
    token: 't',
    branchId: '1',
    branches: [
      BranchAssignment(branchId: 1, roleCode: 'KILDE_SALES_LEAD'),
    ],
  );
}
