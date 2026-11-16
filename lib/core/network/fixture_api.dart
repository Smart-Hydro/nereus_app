import 'package:dio/dio.dart';
import 'package:nereus_app/core/network/operations_fixture.dart';
import 'package:nereus_app/core/network/session_controller.dart';

/// Answers the app locally while the session is the demo fixture token.
class FixtureApiInterceptor extends Interceptor {
  FixtureApiInterceptor(this.session);

  final SessionController session;
  final OperationsFixture _operations = OperationsFixture();
  final List<Map<String, dynamic>> _comments = [];
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 't-norte',
      'subject': 'Instalación Norte',
      'ticket_number': 'T-1042',
      'status': 'OPEN',
      'priority': 'MEDIUM',
      'description': 'TIPO=PROYECTO\nCLIENTE=Agrícola Santa Rosa SpA\nOC=OC-1042\nCOMPROMISO=2026-12-01\nRESPONSABLE=Carlos\nPuesta en marcha de dos pozos.',
      'client_name': 'Agrícola Santa Rosa SpA',
      'ticket_type_name': 'Proyecto',
      'category_name': 'Hidráulica',
    },
    {
      'id': 't-soporte',
      'subject': 'Falla de logger',
      'ticket_number': 'T-1108',
      'status': 'OPEN',
      'priority': 'HIGH',
      'description': 'TIPO=SOPORTE\nCLIENTE=Comunidad de Aguas El Huape\nRESPONSABLE=Soporte\nEl equipo dejó de reportar.',
      'client_name': 'Comunidad de Aguas El Huape',
      'ticket_type_name': 'Soporte',
      'category_name': 'Soporte',
    },
  ];
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'v-norte-1',
      'work_order_number': 'OT-18',
      'ticket': 't-norte',
      'scheduled_date': '2026-11-12T15:00:00Z',
      'status': 'SCHEDULED',
      'location_address': 'Camino Los Pozos 100, Ñuble',
      'notes': 'ESPECIALIDAD=HIDRAULICA\nCUADRILLA=Cuadrilla Sur\nPozo 1',
      'ticket_subject': 'Instalación Norte',
      'client_name': 'Agrícola Santa Rosa SpA',
      'estimated_duration_minutes': 90,
      'checklist_items': [
        {
          'id': 'a-1',
          'work_order': 'v-norte-1',
          'description': 'Medir caudal del pozo 1',
          'is_completed': false,
          'notes': '',
        },
        {
          'id': 'a-2',
          'work_order': 'v-norte-1',
          'description': 'Revisar el tablero del pozo 1',
          'is_completed': false,
          'notes': '',
        },
      ],
      'feedback': null,
      'attachments': <Map<String, dynamic>>[],
    },
  ];
  var _seq = 20;

  bool get _active => session.token == 'fixture-token';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_active) {
      handler.next(options);
      return;
    }
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: _answer(options),
      ),
    );
  }

  dynamic _answer(RequestOptions options) {
    final path = options.path;
    final method = options.method.toUpperCase();
    if (path.contains('/operations/')) {
      final answered = _operations.answer(options);
      if (answered != null) return answered;
    }
    if (path.contains('/devices/overview')) {
      return {
        'devices': {'total': 4, 'online': 3, 'offline': 1},
        'alerts': {'open_unacknowledged': 1},
        'readings_today': {'count': 128, 'errors': 0},
        'projects': [
          {'id': 'p1', 'name': 'Instalación Norte', 'device_count': 4},
        ],
      };
    }
    if (path.contains('/support/tickets/submit') && method == 'POST') {
      final body = _asMap(options.data);
      final created = {
        'id': 't-${++_seq}',
        'status': 'OPEN',
        'priority': 'MEDIUM',
        'ticket_number': 'T-${1000 + _seq}',
        'ticket_type_name': '',
        'category_name': '',
        ...body,
      };
      _tickets.insert(0, created);
      return created;
    }
    if (path.contains('/support/comments')) {
      if (method == 'POST') {
        final saved = {
          'id': 'c-${++_seq}',
          'created': DateTime.now().toUtc().toIso8601String(),
          ..._asMap(options.data),
        };
        _comments.insert(0, saved);
        return saved;
      }
      final ticket = options.queryParameters['ticket']?.toString();
      final rows = ticket == null || ticket.isEmpty
          ? _comments
          : _comments.where((row) => row['ticket'] == ticket).toList();
      return _page(rows);
    }
    if (path.contains('/support/tickets')) {
      final id = _tailId(path, '/tickets/');
      if (id != null) {
        final ticket = _find(_tickets, id);
        if (ticket == null) return _page(const []);
        if (method == 'PATCH' || method == 'PUT') {
          ticket.addAll(_asMap(options.data));
        }
        return ticket;
      }
      return _page(_tickets);
    }
    if (path.contains('/support/work-orders')) {
      return _workOrders(path, method, options);
    }
    if (path.contains('/checklist-items')) {
      return _checklist(path, method, options);
    }
    if (path.contains('/work-order-feedback')) {
      return _feedback(path, method, options);
    }
    if (path.contains('/work-order-attachments')) {
      return _attachment(options);
    }
    final catalog = _catalog(path, options);
    if (catalog != null) return catalog;
    if (method == 'GET') return _page(const []);
    return _echo(options.data);
  }

  dynamic _workOrders(String path, String method, RequestOptions options) {
    final id = _tailId(path, '/work-orders/');
    if (method == 'POST') {
      final body = _asMap(options.data);
      final created = {
        'id': 'v-${++_seq}',
        'work_order_number': 'OT-$_seq',
        'status': 'SCHEDULED',
        'checklist_items': <Map<String, dynamic>>[],
        'feedback': null,
        'attachments': <Map<String, dynamic>>[],
        ...body,
      };
      _orders.insert(0, created);
      return created;
    }
    if (id != null) {
      final order = _find(_orders, id);
      if (order == null) return _page(const []);
      if (method == 'PATCH' || method == 'PUT') {
        order.addAll(_asMap(options.data));
      }
      return order;
    }
    final ticket = options.queryParameters['ticket']?.toString();
    final rows = ticket == null || ticket.isEmpty
        ? _orders
        : _orders.where((order) => order['ticket'] == ticket).toList();
    return _page(rows);
  }

  dynamic _checklist(String path, String method, RequestOptions options) {
    final body = _asMap(options.data);
    if (method == 'POST') {
      final order = _find(_orders, body['work_order']?.toString() ?? '');
      final item = {
        'id': 'a-${++_seq}',
        'is_completed': false,
        'notes': '',
        ...body,
      };
      final items = (order?['checklist_items'] as List?) ?? <dynamic>[];
      items.add(item);
      order?['checklist_items'] = items;
      return item;
    }
    final id = _tailId(path, '/checklist-items/');
    if (method == 'DELETE' && id != null) {
      for (final order in _orders) {
        final items = order['checklist_items'];
        if (items is! List) continue;
        items.removeWhere((raw) => raw is Map && raw['id'] == id);
      }
      return {'deleted': id};
    }
    for (final order in _orders) {
      final items = order['checklist_items'];
      if (items is! List) continue;
      for (final raw in items) {
        if (raw is Map && raw['id'] == id) {
          raw.addAll(body);
          return raw;
        }
      }
    }
    return body;
  }

  dynamic _feedback(String path, String method, RequestOptions options) {
    final body = _asMap(options.data);
    final orderId = body['work_order']?.toString();
    final order = orderId == null ? null : _find(_orders, orderId);
    final current = order?['feedback'];
    final saved = {
      'id': current is Map ? current['id'] : 'fb-${++_seq}',
      ...body,
    };
    if (order != null) order['feedback'] = saved;
    return saved;
  }

  dynamic _attachment(RequestOptions options) {
    final fields = _asMap(options.data);
    final order = _find(_orders, fields['work_order']?.toString() ?? '');
    final item = {
      'id': 'file-${++_seq}',
      'description': fields['description'] ?? 'Foto',
      'file': 'demo.jpg',
    };
    final files = (order?['attachments'] as List?) ?? <dynamic>[];
    files.add(item);
    order?['attachments'] = files;
    return item;
  }

  Map<String, dynamic>? _catalog(String path, RequestOptions options) {
    final rows = switch (path) {
      _ when path.contains('/inventory/products') => [
        {
          'id': 4,
          'name': 'Sensor caudal',
          'code': 'SC',
          'measurement_unit': 'un',
        },
      ],
      _
          when path.contains('/iot-telemetry/devices') &&
              !path.contains('overview') =>
        [
          {
            'id': 101,
            'name': 'Pozo 1',
            'device_type': 'FLOW',
            'address': 'Ñuble',
          },
          {
            'id': 102,
            'name': 'Pozo 2',
            'device_type': 'FLOW',
            'address': 'Ñuble',
          },
        ],
      _ when path.contains('/customers/clients') => [
        {'id': 12, 'name': 'Agrícola Santa Rosa SpA'},
      ],
      _ when path.contains('/operations/assignable-users') => [
        {
          'user_id': 7,
          'name': 'Ana Lagos',
          'email': 'ana@smarthydro.cl',
          'role_code': 'STROM_LIDER_HIDRAULICA',
        },
      ],
      _ when path.contains('/sales/quotations') => [
        {
          'id': 'q-norte',
          'order_number': 'COT-1042',
          'observation': 'Cotización Norte',
          'status': 'PENDING',
        },
      ],
      _ when path.contains('/branches/users') => [
        {
          'id': 1,
          'user': 7,
          'user_name': 'Ana Lagos',
          'role_name': 'Líder hidráulica',
        },
      ],
      _ when path.contains('/crm/opportunities') => [
        {
          'id': 'q-norte',
          'title': 'Cotización Norte',
          'client_name': 'Agrícola Santa Rosa SpA',
        },
      ],
      _ when path.contains('/inventory/warehouses') => [
        {
          'id': 2,
          'name': 'Bodega Ñuble',
          'warehouse_type': 'GENERAL',
          'is_default': true,
          'is_active': true,
          'location': 'Sucursal',
        },
        {
          'id': 3,
          'name': 'Bodega taller',
          'warehouse_type': 'GENERAL',
          'is_default': false,
          'is_active': true,
          'location': 'Taller',
        },
      ],
      _ when path.contains('/receptions') => [
        {
          'id': 15,
          'quantity': '3.00',
          'notes': 'Recepción completa',
          'received_by_name': 'Ana Lagos',
        },
      ],
      _ when path.contains('/purchase-orders') => [
        {
          'id': '8c1e2b7a-4f3d-4a1e-9b2c-0c1042abcdef',
          'order_number': 'OC-1042',
          'number': 'OC-1042',
          'supplier_name': 'Ferretería El Huape',
          'supplier': {'id': 9, 'name': 'Ferretería El Huape'},
          'status': 'CONFIRMED',
        },
      ],
      _ => null,
    };
    if (rows == null) return null;
    final query = '${options.queryParameters['search'] ?? ''}'.toLowerCase();
    final visible = query.isEmpty
        ? rows
        : rows
              .where(
                (row) => row.values.join(' ').toLowerCase().contains(query),
              )
              .toList();
    return _page(visible);
  }

  Map<String, dynamic> _echo(Object? data) {
    return {'id': 'fx-${++_seq}', ..._asMap(data)};
  }

  Map<String, dynamic> _page(List<Map<String, dynamic>> rows) {
    return {'count': rows.length, 'results': rows};
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> rows, String id) {
    for (final row in rows) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  String? _tailId(String path, String marker) {
    final index = path.indexOf(marker);
    if (index < 0) return null;
    final rest = path.substring(index + marker.length);
    if (rest.isEmpty || rest == '/') return null;
    final id = rest.split('/').first;
    return id.isEmpty ? null : id;
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is FormData) {
      return {
        for (final field in data.fields) field.key: field.value,
      };
    }
    return {};
  }
}
