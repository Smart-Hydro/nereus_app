import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/network/fixture_api.dart';
import 'package:nereus_app/core/network/session_controller.dart';

void main() {
  test('demo session reads local projects and does not call the network', () async {
    final session = SessionController()..token = 'fixture-token';
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.smarthydro.app'))
      ..interceptors.add(FixtureApiInterceptor(session));

    final overview = await dio.get<Map<String, dynamic>>(
      '/api/iot-telemetry/devices/overview/',
    );
    final tickets = await dio.get<Map<String, dynamic>>('/api/support/tickets/');
    final visits = await dio.get<Map<String, dynamic>>(
      '/api/support/work-orders/',
      queryParameters: {'ticket': 't-norte'},
    );

    final operations = await dio.get<Map<String, dynamic>>(
      '/api/operations/projects/',
    );

    final devices = Map<String, dynamic>.from(overview.data?['devices'] as Map);
    final ticketRows = tickets.data?['results'] as List;
    final visitRows = visits.data?['results'] as List;
    final visit = Map<String, dynamic>.from(visitRows.single as Map);
    final projectRows = operations.data?['results'] as List;
    final project = Map<String, dynamic>.from(projectRows.first as Map);
    expect(devices['online'], 3);
    expect(ticketRows.length, 2);
    expect(visit['work_order_number'], 'OT-18');
    expect(project['name'], 'Instalación Norte');
  });

  test('a real token is not answered by the demo', () async {
    final session = SessionController()..token = 'real-token';
    var called = false;
    final dio = Dio()
      ..interceptors.add(FixtureApiInterceptor(session))
      ..httpClientAdapter = _Adapter((options) async {
        called = true;
        return ResponseBody.fromString('{"ok":true}', 200);
      });
    await dio.get<void>('/api/support/tickets/');
    expect(called, isTrue);
  });
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this._handler);
  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}
