import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_project_screen.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

void main() {
  testWidgets('los códigos visibles de Strøm se muestran en español', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final label in [
                milestoneSourceLabel('project_open'),
                milestoneSourceLabel('status_change'),
                milestoneSourceLabel('manual'),
                opsLabel('ikolu_training', milestoneLabels),
                visitStatusLabel('in_progress'),
                visitTypeLabel('client_restriction'),
                workOrderStatusLabel('executed'),
                workOrderKindLabel('adicional'),
                opsLabel('completed', executionLabels),
                opsLabel('not_done', executionLabels),
                opsLabel('partial', executionLabels),
                opsLabel('approved', validationLabels),
                opsLabel('approved_with_observations', validationLabels),
                opsLabel('requires_correction', validationLabels),
                specialtyLabel('hydraulic'),
                specialtyLabel('electric'),
                alertSeverityLabel('warning'),
                alertSeverityLabel('info'),
                alertSeverityLabel('critical'),
                alertStatusLabel('open'),
                alertStatusLabel('seen'),
                alertStatusLabel('resolved'),
                scopeChangeKindLabel('added'),
                scopeChangeStatusLabel('rejected'),
                opsLabel('not_fulfilled', obligationLabels),
                opsLabel('entry_permit', siteKindLabels),
                opsLabel('to_buy', rtsItemLabels),
                opsLabel('project', reportKindLabels),
                opsLabel('sent', reportStatusLabels),
                orderStatusLabel('COMPLETED'),
                quotationStatusLabel('COMPLETED'),
                opsLabel('confirmed', captureStatusLabels),
                opsLabel('scope', activityOriginLabels),
              ])
                Text(label),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const spanish = [
      'Alta del proyecto',
      'Cambio de estado',
      'Registro manual',
      'Capacitación Ikolu',
      'En curso',
      'Restricción del cliente',
      'Ejecutada',
      'Adicional',
      'Completada',
      'No realizada',
      'Parcial',
      'Aprobada',
      'Aprobada con observaciones',
      'Requiere corrección',
      'Hidráulica',
      'Eléctrica',
      'Advertencia',
      'Información',
      'Crítica',
      'Abierta',
      'Vista',
      'Resuelta',
      'Ítem nuevo',
      'Rechazada',
      'No cumplida',
      'Permiso de ingreso',
      'Por comprar',
      'Informe de proyecto',
      'Enviado',
      'Completada',
      'Confirmada',
      'Alcance de la cotización',
    ];
    for (final label in spanish) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    for (final code in [
      'project_open',
      'status_change',
      'ikolu_training',
      'in_progress',
      'client_restriction',
      'executed',
      'completed',
      'not_done',
      'approved_with_observations',
      'requires_correction',
      'hydraulic',
      'electric',
      'warning',
      'critical',
      'not_fulfilled',
      'entry_permit',
      'to_buy',
    ]) {
      expect(find.text(code), findsNothing, reason: code);
    }
  });

  testWidgets(
    'Viene de Kilde usa el nombre del cliente y la cotización del proyecto',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final project = OpsProject.fromJson(const {
        'id': 'p-9',
        'name': 'Pozo Norte',
        'client': 61,
        'client_name': 'Agrícola Nahuen',
        'quotation': '8d0c2c2a-6b1e-4a7a-9c1d-111111111111',
        'quotation_number': 'B1-261122-0003',
        'quotation_status': 'COMPLETED',
        'kilde_handoff': {
          'client': 61,
          'contacts': ['Rosa Muñoz'],
          'wells': ['Pozo 2'],
          'equipment': [],
          'closed_rfis': [],
        },
        'milestones': [
          {
            'id': 1,
            'kind': 'official_plan',
            'occurred_on': '2026-11-22',
            'source': 'project_open',
          },
          {
            'id': 2,
            'kind': 'ikolu_training',
            'occurred_on': '2026-11-23',
            'source': 'status_change',
          },
        ],
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            opsProjectProvider.overrideWith((ref, id) async => project),
            opsScopeProvider.overrideWith((ref, id) async => const []),
          ],
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: const StromProjectScreen(projectId: 'p-9'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Viene de Kilde'), findsOneWidget);
      expect(find.text('Agrícola Nahuen'), findsWidgets);
      expect(find.textContaining('B1-261122-0003'), findsOneWidget);
      expect(find.textContaining('Completada'), findsOneWidget);
      expect(find.text('Sin cotización'), findsNothing);
      expect(find.text('61'), findsNothing);
      expect(find.text('Cliente: 61'), findsNothing);
      expect(find.text('Alta del proyecto'), findsOneWidget);
      expect(find.text('Cambio de estado'), findsOneWidget);
      expect(find.text('Capacitación Ikolu'), findsOneWidget);
      expect(find.text('project_open'), findsNothing);
      expect(find.text('status_change'), findsNothing);
      expect(find.text('ikolu_training'), findsNothing);
    },
  );
}
