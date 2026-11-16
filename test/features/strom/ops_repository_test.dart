import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/data/projects_repository.dart';
import 'package:nereus_app/features/strom/data/visits_repository.dart';
import 'package:nereus_app/features/strom/data/work_orders_repository.dart';

void main() {
  late _Capture capture;
  late OpsHttp http;

  setUp(() {
    capture = _Capture();
    http = OpsHttp(Dio()..httpClientAdapter = capture);
  });

  test('project list sends filters and reads int ids', () async {
    capture.body = {
      'count': 1,
      'results': [
        {'id': 41, 'name': 'Instalación Norte', 'service_type': 'project'},
      ],
    };
    final rows = await ProjectsRepository(http).list(
      search: 'Norte',
      status: 'preparation',
    );
    expect(rows.single.id, '41');
    expect(rows.single.name, 'Instalación Norte');
    expect(capture.last?.path, '/api/operations/projects/');
    expect(capture.last?.queryParameters['search'], 'Norte');
    expect(capture.last?.queryParameters['status'], 'preparation');
    expect(capture.last?.queryParameters['page_size'], 100);
  });

  test('suggest posts the project id', () async {
    capture.body = [
      {
        'id': 8,
        'project': 41,
        'specialty': 'hydraulic',
        'status': 'suggested',
      },
    ];
    final rows = await WorkOrdersRepository(http).suggest(41);
    expect(rows.single.specialty, 'hydraulic');
    expect(capture.last?.method, 'POST');
    expect(capture.last?.path, '/api/operations/work-orders/suggest/');
    expect(capture.last?.data, {'project_id': 41});
  });

  test('removing crew sends the member in the delete body', () async {
    capture.body = {'deleted': 3};
    await VisitsRepository(http).removeCrew('15', 3);
    expect(capture.last?.method, 'DELETE');
    expect(capture.last?.path, '/api/operations/visits/15/crew/');
    expect(capture.last?.data, {'crew_member_id': 3});
  });

  test('a 409 detail becomes the api error message', () async {
    capture.status = 409;
    capture.body = {'detail': 'La OT todavía no está confirmada.'};
    expect(
      VisitsRepository(http).start('15'),
      throwsA(
        isA<ApiError>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.message,
              'message',
              'La OT todavía no está confirmada.',
            ),
      ),
    );
  });
}

class _Capture implements HttpClientAdapter {
  RequestOptions? last;
  dynamic body = const <String, dynamic>{};
  int status = 200;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
