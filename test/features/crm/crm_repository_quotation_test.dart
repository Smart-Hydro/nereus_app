import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/features/crm/data/crm_repository.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';

void main() {
  late _Capture capture;
  late CrmRepository repo;

  setUp(() {
    capture = _Capture();
    repo = CrmRepository(dio: Dio()..httpClientAdapter = capture);
  });

  test('la fecha de Santiago respeta el horario de Chile', () {
    expect(
      kildeSantiagoDate(DateTime.utc(2026, 11, 22, 3)),
      '2026-11-22',
    );
    expect(
      kildeSantiagoDate(DateTime.utc(2026, 7, 15, 3)),
      '2026-07-14',
    );
    expect(
      kildeSantiagoDate(DateTime.utc(2026, 3, 1, 3)),
      '2026-03-01',
    );
    expect(
      kildeSantiagoDate(DateTime.utc(2026, 4, 5, 3)),
      '2026-04-04',
    );
    expect(
      kildeSantiagoDate(DateTime.utc(2026, 9, 6, 3)),
      '2026-09-05',
    );
    expect(
      kildeSantiagoDate(DateTime.utc(2026, 9, 6, 4)),
      '2026-09-06',
    );
  });

  test('crear cotización manda la fecha de hoy en Santiago', () async {
    capture.body = {
      'id': 'q-1',
      'order_number': 'B1-0001',
      'kilde_quote_status': 'draft',
    };
    await repo.createQuotation(
      const QuoteDraft(
        clientId: '15',
        clientName: 'APR Valle',
        glosa: 'Bomba',
        quantity: 2,
        unitPrice: 1000,
        productId: '9',
        validUntil: '2026-12-01',
      ),
    );
    expect(capture.last?.method, 'POST');
    expect(capture.last?.path, '/api/sales/quotations/');
    final data = Map<String, dynamic>.from(capture.last?.data as Map);
    expect(data['date'], kildeSantiagoDate());
    expect(data['client_id'], 15);
    expect(data['order_type'], 'SALE');
    expect(data['valid_until'], '2026-12-01');
    expect(data['items'], [
      {
        'product': 9,
        'quantity': 2,
        'unit_price': 1000,
        'notes': 'Bomba',
      },
    ]);
  });

  test('crear RFI manda cliente y pregunta', () async {
    capture.body = {'id': 'rfi-1'};
    await repo.createRfi(
      question: '¿Caudal?',
      blocking: true,
      clientId: '8',
      opportunityId: 'opp-1',
      quotationId: 'q-1',
    );
    expect(capture.last?.path, '/api/crm/rfis/');
    expect(capture.last?.data, {
      'question': '¿Caudal?',
      'is_blocking': true,
      'client': 8,
      'opportunity': 'opp-1',
      'quotation': 'q-1',
    });
  });

  test('marcar prospecto perdido manda el motivo', () async {
    capture.body = {'id': 'lead-1', 'first_name': 'Ana', 'status': 'LOST'};
    await repo.setLeadStatus(
      id: 'lead-1',
      status: 'LOST',
      noRequirementReason: 'Sin presupuesto',
    );
    expect(capture.last?.method, 'PATCH');
    expect(capture.last?.path, '/api/crm/leads/lead-1/');
    expect(capture.last?.data, {
      'status': 'LOST',
      'no_requirement_reason': 'Sin presupuesto',
    });
  });
}

class _Capture implements HttpClientAdapter {
  RequestOptions? last;
  dynamic body = const <String, dynamic>{};

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
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
