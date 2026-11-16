import 'package:dio/dio.dart';

import 'package:nereus_app/core/network/operations_fixture_seed.dart';

part 'operations_fixture_actions.dart';
part 'operations_fixture_projects.dart';

/// Datos de ejemplo de `/api/operations/` para `NEREUS_DATA_MODE=fixture`.
class OperationsFixture {
  var _seq = 80;
  RequestOptions? _request;
  final Map<String, List<Map<String, dynamic>>> scopes = {};

  final List<Map<String, dynamic>> projects = stromSeedProjects();
  final List<Map<String, dynamic>> installations = stromSeedInstallations();
  final List<Map<String, dynamic>> equipment = stromSeedEquipment();
  final List<Map<String, dynamic>> orders = stromSeedOrders();
  final List<Map<String, dynamic>> changes = stromSeedChanges();
  final List<Map<String, dynamic>> visits = stromSeedVisits();
  final List<Map<String, dynamic>> crew = stromSeedCrew();
  final List<Map<String, dynamic>> activities = stromSeedActivities();
  final List<Map<String, dynamic>> checks = stromSeedChecks();
  final List<Map<String, dynamic>> evidences = stromSeedEvidences();
  final List<Map<String, dynamic>> rts = stromSeedRts();
  final List<Map<String, dynamic>> reports = stromSeedReports();
  final List<Map<String, dynamic>> clarifications = stromSeedClarifications();
  final List<Map<String, dynamic>> outOfScope = stromSeedOutOfScope();
  final List<Map<String, dynamic>> costs = stromSeedCosts();
  final List<Map<String, dynamic>> targets = stromSeedTargets();
  final List<Map<String, dynamic>> indicators = stromSeedIndicators();
  final List<Map<String, dynamic>> sites = stromSeedSites();
  final List<Map<String, dynamic>> obligations = stromSeedObligations();
  final List<Map<String, dynamic>> transitions = stromSeedTransitions();

  dynamic answer(RequestOptions options) {
    _request = options;
    final segs = _segs(options.path);
    if (segs.length < 3 || segs[0] != 'api' || segs[1] != 'operations') {
      return null;
    }
    final method = options.method.toUpperCase();
    final resource = segs[2];
    final id = segs.length >= 4 ? segs[3] : null;
    final action = segs.length >= 5 ? segs[4] : null;
    final body = _body(options);
    switch (resource) {
      case 'projects':
        return handleProjects(method, id, action, segs, body);
      case 'installations':
        return _crud(
          installations,
          method,
          id,
          body,
          (data) => {
            ...data,
            'id': ++_seq,
            'device_ids': data['device_ids'] ?? [],
          },
        );
      case 'installed-equipment':
        return handleEquipment(method, id, action, body);
      case 'site-requirements':
        return _crud(
          sites,
          method,
          id,
          body,
          (data) => {
            ...data,
            'id': ++_seq,
            'status': data['status'] ?? 'pending',
          },
        );
      case 'client-obligations':
        return _crud(
          obligations,
          method,
          id,
          body,
          (data) => {...data, 'id': ++_seq, 'status': 'pending'},
        );
      case 'work-orders':
        return _orders(method, id, action, segs, body);
      case 'visits':
        return handleVisits(method, id, action, body);
      case 'crew-members':
        return _crud(
          crew,
          method,
          id,
          body,
          (data) => {...data, 'id': ++_seq, 'is_active': true},
        );
      case 'activities':
        return handleActivities(method, id, action, body);
      case 'field-checks':
        return _crud(
          checks,
          method,
          id,
          body,
          (data) => {
            ...data,
            'id': ++_seq,
            'visit': data['visit_id'],
            'activity': data['activity_id'],
          },
        );
      case 'evidences':
        return handleEvidences(method, id, action, body);
      case 'rts':
        return handleRts(method, id, action, body);
      case 'reports':
        return handleReports(method, id, action, body);
      case 'clarifications':
        return handleClarifications(method, id, action, body);
      case 'out-of-scope-work':
        return handleScopeWork(method, id, action, body);
      case 'crew-daily-costs':
        return _crud(
          costs,
          method,
          id,
          body,
          (data) => {...data, 'id': ++_seq},
        );
      case 'indicators':
        return handleDashboard();
      case 'indicator-targets':
        return _crud(
          targets,
          method,
          id,
          body,
          (data) => {
            ...data,
            'id': ++_seq,
            'kpi_code': data['kpi_code'] ?? 'kpi_9',
          },
        );
      case 'configurable-indicators':
        return handleConfigurable(method, id, action, body);
      case 'transitions':
        if (id != null) return _find(transitions, id) ?? {};
        return _page(transitions);
      default:
        if (method == 'GET') return null;
        return {'id': ++_seq, ...body};
    }
  }

  dynamic _orders(
    String method,
    String? id,
    String? action,
    List<String> segs,
    Map<String, dynamic> body,
  ) {
    if (id == 'suggest' ||
        (id == null && method == 'POST' && optionsPathSuggest(body))) {
      final created = {
        'id': ++_seq,
        'project': body['project_id'],
        'service_type': 'project',
        'specialty': 'hydraulic',
        'status': 'suggested',
        'block_reason': '',
        'cancel_reason': '',
        'scope_version': 1,
        'commercial_reference': '',
        'pending_scope_changes': 0,
        'created': '2026-11-16T12:00:00Z',
      };
      orders.insert(0, created);
      return [created];
    }
    if (id == null) return _page(orders);
    final row = _find(orders, id);
    if (row == null) return {};
    if (action == 'confirm') {
      row['status'] = 'confirmed';
      row['commercial_reference'] = body['commercial_reference'] ?? '';
      return row;
    }
    if (action == 'status') {
      row['status'] = body['status'] ?? row['status'];
      row['block_reason'] = body['block_reason'] ?? '';
      row['cancel_reason'] = body['cancel_reason'] ?? '';
      return row;
    }
    if (action == 'cost') {
      return {
        'work_order_id': row['id'],
        'project_id': row['project'],
        'specialty': row['specialty'],
        'visits_performed': 1,
        'daily_cost': '180000.00',
        'total': '180000.00',
      };
    }
    if (action == 'scope-changes' && segs.length >= 7) {
      final change = _find(changes, segs[5]);
      if (change != null) {
        change['status'] = body['approve'] == true ? 'approved' : 'rejected';
      }
      return change ?? {};
    }
    if (action == 'scope-changes') return changes;
    return row;
  }

  bool optionsPathSuggest(Map<String, dynamic> body) =>
      body.containsKey('project_id');

  dynamic _crud(
    List<Map<String, dynamic>> rows,
    String method,
    String? id,
    Map<String, dynamic> body,
    Map<String, dynamic> Function(Map<String, dynamic> data) create,
  ) {
    if (id == null) {
      if (method == 'POST') {
        final created = create(body);
        rows.insert(0, created);
        return created;
      }
      return _page(rows);
    }
    if (method == 'DELETE') {
      rows.removeWhere((row) => '${row['id']}' == id);
      return {'deleted': id};
    }
    final row = _find(rows, id);
    if (row == null) return {};
    if (method == 'PATCH' || method == 'PUT') row.addAll(body);
    return row;
  }

  Map<String, dynamic> _page(List<Map<String, dynamic>> rows) {
    final visible = _filter(rows);
    return {'count': visible.length, 'results': visible};
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> rows) {
    final query = _request?.queryParameters ?? const <String, dynamic>{};
    return rows.where((row) {
      for (final entry in query.entries) {
        final key = entry.key;
        if (key == 'page' || key == 'page_size') continue;
        final expected = '${entry.value}'.trim().toLowerCase();
        if (expected.isEmpty) continue;
        if (key == 'search') {
          final blob = row.values
              .map((value) => '$value')
              .join(' ')
              .toLowerCase();
          if (!blob.contains(expected)) return false;
          continue;
        }
        if (!row.containsKey(key)) continue;
        if ('${row[key]}'.toLowerCase() != expected) return false;
      }
      return true;
    }).toList();
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> rows, String id) {
    for (final row in rows) {
      if ('${row['id']}' == id) return row;
    }
    return null;
  }

  List<String> _segs(String path) {
    return path
        .split('?')
        .first
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _body(RequestOptions options) {
    final data = options.data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is FormData) {
      return {for (final field in data.fields) field.key: field.value};
    }
    return {};
  }
}
