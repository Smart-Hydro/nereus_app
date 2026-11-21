import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/network/fixture_api.dart';
import 'package:nereus_app/core/network/session_controller.dart';

void main() {
  late Dio dio;

  setUp(() {
    final session = SessionController()..token = 'fixture-token';
    dio = Dio(BaseOptions(baseUrl: 'https://gateway.smarthydro.app'))
      ..interceptors.add(FixtureApiInterceptor(session));
  });

  test('editar fusiona el texto y conserva el snapshot', () async {
    final before = _row(
      await dio.get<dynamic>('/api/operations/reports/2/'),
    );
    final snapshot = Map<String, dynamic>.from(before['body'] as Map);
    expect(snapshot['activities'], isNotEmpty);
    expect(snapshot['tests_performed'], isNotEmpty);
    expect(snapshot['evidences'], isNotEmpty);
    expect(snapshot['pending_client_work'], isNotEmpty);

    final edited = _row(
      await dio.patch<dynamic>(
        '/api/operations/reports/2/',
        data: {
          'body': {'text': 'Nota del jefe de obra'},
        },
      ),
    );
    final body = Map<String, dynamic>.from(edited['body'] as Map);
    expect(body['text'], 'Nota del jefe de obra');
    expect(body['activities'], snapshot['activities']);
    expect(body['tests_performed'], snapshot['tests_performed']);
    expect(body['evidences'], snapshot['evidences']);
    expect(body['pending_client_work'], snapshot['pending_client_work']);
  });

  test('un PATCH que trae otra clave del cuerpo se rechaza', () async {
    expect(
      () => dio.patch<dynamic>(
        '/api/operations/reports/2/',
        data: {
          'body': {
            'text': 'Esto no debe borrar el snapshot',
            'activities': <Map<String, dynamic>>[],
          },
        },
      ),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status',
          400,
        ),
      ),
    );
    final row = _row(await dio.get<dynamic>('/api/operations/reports/2/'));
    final body = Map<String, dynamic>.from(row['body'] as Map);
    expect(body['activities'], isNotEmpty);
  });

  test('devolver a borrador solo funciona en revisión', () async {
    expect(
      () => dio.post<dynamic>('/api/operations/reports/2/return-draft/'),
      throwsA(isA<DioException>()),
    );

    final review = _row(
      await dio.post<dynamic>('/api/operations/reports/2/submit-review/'),
    );
    expect(review['status'], 'review');
    expect(
      () => dio.post<dynamic>('/api/operations/reports/2/revise/'),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status',
          400,
        ),
      ),
    );

    final draft = _row(
      await dio.post<dynamic>('/api/operations/reports/2/return-draft/'),
    );
    expect(draft['status'], 'draft');
    expect(draft['version'], 1);
    final body = Map<String, dynamic>.from(draft['body'] as Map);
    expect(body['activities'], isNotEmpty);
    final reasons = _reportTransitions(
      await dio.get<dynamic>(
        '/api/operations/transitions/',
      ),
    ).map((row) => row['reason']);
    expect(reasons, contains('Devuelto a borrador'));
  });

  test('la versión enviada queda bloqueada y revise abre otra', () async {
    await dio.post<dynamic>('/api/operations/reports/2/submit-review/');
    await dio.post<dynamic>('/api/operations/reports/2/approve/');
    final sent = _row(
      await dio.post<dynamic>('/api/operations/reports/2/send/'),
    );
    expect(sent['status'], 'sent');

    expect(
      () => dio.patch<dynamic>(
        '/api/operations/reports/2/',
        data: {
          'body': {'text': 'No se pisa un enviado'},
        },
      ),
      throwsA(
        isA<DioException>().having(
          (error) => error.response?.statusCode,
          'status',
          400,
        ),
      ),
    );

    final created = _row(
      await dio.post<dynamic>('/api/operations/reports/2/revise/'),
    );
    expect(created['id'], isNot(2));
    expect(created['status'], 'draft');
    expect(created['version'], 2);
    final createdBody = Map<String, dynamic>.from(created['body'] as Map);
    expect(
      createdBody['text'],
      'Borrador del informe de puesta en marcha.',
    );
    expect(createdBody['activities'], isEmpty);
    expect(createdBody['pending_client_work'], isNotEmpty);

    final locked = _row(
      await dio.get<dynamic>('/api/operations/reports/2/'),
    );
    expect(locked['status'], 'sent');
    expect(locked['version'], 1);
    final lockedBody = Map<String, dynamic>.from(locked['body'] as Map);
    expect(lockedBody['activities'], isNotEmpty);
    expect(lockedBody['text'], 'Borrador del informe de puesta en marcha.');
  });

  test('generar deja el alta y el texto vacío junto al snapshot', () async {
    final created = _row(
      await dio.post<dynamic>(
        '/api/operations/reports/generate/',
        data: {'project_id': 41, 'specialty': 'hydraulic'},
      ),
    );
    final body = Map<String, dynamic>.from(created['body'] as Map);
    expect(body['text'], '');
    expect(body.containsKey('activities'), isTrue);
    expect(body.containsKey('tests_performed'), isTrue);
    expect(body.containsKey('evidences'), isTrue);
    expect(body.containsKey('pending_client_work'), isTrue);
    final alta = _reportTransitions(
      await dio.get<dynamic>('/api/operations/transitions/'),
    ).where((row) => '${row['entity_id']}' == '${created['id']}');
    expect(alta.single['from_value'], '');
    expect(alta.single['to_value'], 'draft');
    expect(alta.single['reason'], 'Alta de informe');
    final page = Map<String, dynamic>.from(
      (await dio.get<dynamic>('/api/operations/transitions/')).data as Map,
    );
    final projectRow = (page['results'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where(
          (row) =>
              row['entity_type'] == 'project' &&
              row['to_value'] == 'report_v${created['version']}_draft',
        );
    expect(projectRow, isNotEmpty);
  });

  test('revisión, aprobación y envío quedan en la auditoría', () async {
    await dio.post<dynamic>('/api/operations/reports/2/submit-review/');
    await dio.post<dynamic>('/api/operations/reports/2/submit-review/');
    await dio.post<dynamic>('/api/operations/reports/2/approve/');
    await dio.post<dynamic>('/api/operations/reports/2/send/');

    final rows =
        _reportTransitions(
              await dio.get<dynamic>('/api/operations/transitions/'),
            )
            .map(
              (row) =>
                  '${row['from_value']}→${row['to_value']}:${row['reason']}',
            )
            .toList();
    expect(rows, [
      'draft→review:Pasó a revisión',
      'review→approved:Informe aprobado',
      'approved→sent:Informe enviado',
    ]);
  });
}

Map<String, dynamic> _row(Response<dynamic> response) {
  return Map<String, dynamic>.from(response.data as Map);
}

List<Map<String, dynamic>> _reportTransitions(Response<dynamic> response) {
  final page = Map<String, dynamic>.from(response.data as Map);
  return (page['results'] as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .where((row) => row['entity_type'] == 'report')
      .toList();
}
