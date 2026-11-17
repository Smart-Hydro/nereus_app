import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/features/strom/domain/strom_models.dart';

void main() {
  test('project json keeps int ids and unknown status', () {
    final project = OpsProject.fromJson({
      'id': 41,
      'name': 'Instalación Norte',
      'code': 'PN-41',
      'service_type': 'support',
      'status': 'estado_nuevo',
      'committed_on': '2026-12-01T00:00:00Z',
      'owner': 7,
      'client_po_number': 'OC-1042',
      'open_clarifications': [
        {
          'id': 3,
          'text': '¿El pozo tiene energía?',
          'asked_by': 8,
          'created': '2026-11-10T12:00:00Z',
        },
      ],
      'milestones': [
        {
          'id': 1,
          'kind': 'committed_date',
          'occurred_on': '2026-12-01',
          'source': 'manual',
        },
      ],
    });

    expect(project.id, '41');
    expect(project.owner, '7');
    expect(project.looksLikeSupport, isTrue);
    expect(project.committedOn, '2026-12-01');
    expect(project.status, 'estado_nuevo');
    expect(projectStatusLabel(project.status), 'estado_nuevo');
    expect(project.openClarifications.single.text, '¿El pozo tiene energía?');
    expect(project.milestones.single.kind, 'committed_date');
  });

  test('visit warnings, specialty and evidence drive link', () {
    final visit = OpsVisit.fromJson({
      'id': '15',
      'work_order': 8,
      'specialty': 'hydraulic',
      'visit_type': 'planned',
      'status': 'scheduled',
      'scheduled_for': '2026-11-12',
      'crew': [
        {'id': 3, 'name': 'Cuadrilla Sur', 'specialty': 'hydraulic'},
      ],
      'site_requirement_warnings': [
        {'message': 'Falta el permiso de ingreso'},
      ],
      'rts_warnings': ['La RTS no está emitida'],
    });
    expect(visit.workOrder, '8');
    expect(specialtyLabel(visit.specialty), 'Hidráulica');
    expect(visitTypeLabel(visit.visitType), 'Planificada');
    expect(visit.crew.single.name, 'Cuadrilla Sur');
    expect(visit.siteWarnings, ['Falta el permiso de ingreso']);
    expect(visit.rtsWarnings, ['La RTS no está emitida']);

    final evidence = OpsEvidence.fromJson({
      'id': 4,
      'url': 'https://drive.google.com/file/d/abc',
      'file': 'foto.jpg',
    });
    expect(evidence.link, 'https://drive.google.com/file/d/abc');
    expect(
      OpsEvidence.fromJson({'id': 5, 'file': 'foto.jpg'}).link,
      'foto.jpg',
    );
  });

  test('kpi target range and dashboard delays stay optional', () {
    final target = OpsIndicatorTarget.fromJson({
      'id': 9,
      'kpi_code': 'kpi_9',
      'capture_points_min': 1,
      'capture_points_max': null,
      'target_calendar_days': 12,
    });
    expect(target.capturePointsMin, 1);
    expect(target.capturePointsMax, isEmpty);

    final board = OpsDashboard.fromJson({
      'timezone': 'America/Santiago',
      'kpi_1': {'value': 3},
      'kpi_9': {'min': 1, 'max': 3},
      'delays': {
        'projects': [
          {'id': 41, 'name': 'Instalación Norte'},
        ],
        'work_orders': [
          {'id': 8},
        ],
      },
    });
    expect(board.timezone, 'America/Santiago');
    expect(board.kpis['kpi_9'], {'min': 1, 'max': 3});
    expect(board.delayProjects.single['name'], 'Instalación Norte');
    expect(board.delayOrders.single['id'], 8);
  });

  test('report body map and work order specialty', () {
    final report = OpsReport.fromJson({
      'id': 2,
      'version': 1,
      'status': 'draft',
      'body': {'text': 'Informe de caudal'},
      'drive_url': 'https://drive.google.com/file/d/informe',
      'specialty': 'electric',
    });
    expect(report.version, '1');
    expect(report.bodyText, 'Informe de caudal');
    expect(specialtyLabel(report.specialty), 'Eléctrica');
    expect(report.driveUrl, contains('drive.google.com'));

    final snapshot = OpsReport.fromJson({
      'id': 3,
      'status': 'draft',
      'body': {
        'activities': [
          {
            'activity_type': 'Medir caudal del pozo',
            'specialty': 'hydraulic',
            'execution_status': 'completed',
            'validation_status': 'approved',
            'validation_notes': '',
          },
        ],
        'tests_performed': [
          {
            'result': 'completed',
            'measurement': '12 l/s',
            'observation': 'Caudal estable',
          },
        ],
        'evidences': [
          {
            'caption': 'Tablero del pozo',
            'url': 'https://drive.google.com/file/d/demo-tablero',
          },
        ],
        'pending_client_work': [
          {
            'description': 'Dejar energizado el tablero',
            'status': 'pending',
            'responsible': 'Cliente',
          },
        ],
      },
    });
    expect(snapshot.bodyText, isEmpty);
    expect(snapshot.hasSnapshot, isTrue);
    expect(snapshot.activities.single.title, 'Medir caudal del pozo');
    expect(snapshot.activities.single.specialty, 'hydraulic');
    expect(snapshot.activities.single.validationStatus, 'approved');
    expect(snapshot.testsPerformed.single.measurement, '12 l/s');
    expect(snapshot.evidences.single.caption, 'Tablero del pozo');
    expect(
      snapshot.pendingClientWork.single.description,
      'Dejar energizado el tablero',
    );

    final order = OpsWorkOrder.fromJson({
      'id': 8,
      'specialty': 'hydraulic',
      'status': 'suggested',
      'pending_scope_changes': '1',
    });
    expect(order.pendingScopeChanges, 1);
    expect(workOrderStatusLabel(order.status), 'Sugerida');
  });
}
