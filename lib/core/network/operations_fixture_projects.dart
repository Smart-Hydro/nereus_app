part of 'operations_fixture.dart';

/// Alta del proyecto, alcance importado e indicadores del tablero.
extension OperationsFixtureProjects on OperationsFixture {
  dynamic handleProjects(
    String method,
    String? id,
    String? action,
    List<String> segs,
    Map<String, dynamic> body,
  ) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'status': 'preparation',
          'is_active': true,
          'milestones': <Map<String, dynamic>>[],
          'open_clarifications': <Map<String, dynamic>>[],
          ...body,
        };
        projects.insert(0, created);
        return created;
      }
      return _page(projects);
    }
    final row = _find(projects, id);
    if (row == null) return {};
    if (action == null) {
      if (method == 'PATCH') row.addAll(body);
      return row;
    }
    if (action == 'status') {
      row['status'] = body['status'] ?? row['status'];
      row['status_reason'] = body['status_reason'] ?? '';
      return row;
    }
    if (action == 'close') {
      row['status'] = 'closed';
      return row;
    }
    if (action == 'cost') {
      return {
        'project_id': row['id'],
        'total': '180000.00',
        'work_orders': [
          {
            'work_order_id': 8,
            'project_id': row['id'],
            'specialty': 'hydraulic',
            'visits_performed': 1,
            'daily_cost': '180000.00',
            'total': '180000.00',
          },
        ],
      };
    }
    if (action == 'scope') {
      if (method == 'GET') return scopes[id] ?? <Map<String, dynamic>>[];
      final created = importedScope(body);
      scopes[id] = created;
      return created;
    }
    if (action == 'scope-items') {
      final itemId = segs.length >= 6 ? segs[5] : '';
      final stored = scopes[id];
      if (stored != null) {
        for (final point in stored) {
          final items = point['items'];
          if (items is! List) continue;
          for (final item in items) {
            if (item is Map && '${item['id']}' == itemId) {
              item['status'] = 'confirmed';
              return point;
            }
          }
        }
      }
      return {
        'id': ++_seq,
        'device': 101,
        'device_name': 'Punto de captación',
        'items': [
          {
            'id': itemId,
            'activity': 'Medir caudal del pozo',
            'specialty': 'hydraulic',
            'status': 'confirmed',
            'mandatory': true,
          },
        ],
      };
    }
    if (action == 'milestones') {
      final milestone = {
        'id': ++_seq,
        'kind': body['kind'],
        'occurred_on': body['occurred_on'],
        'source': 'manual',
      };
      final list = (row['milestones'] as List?) ?? <dynamic>[];
      list.add(milestone);
      row['milestones'] = list;
      return milestone;
    }
    return row;
  }

  List<Map<String, dynamic>> importedScope(Map<String, dynamic> body) {
    final points = body['points'];
    if (points is! List || points.isEmpty) return [];
    return [
      for (final raw in points)
        if (raw is Map)
          {
            'id': ++_seq,
            'device': raw['device_id'],
            'device_name': raw['device_name'] ?? 'Punto de captación',
            'device_type': 'FLOW',
            'quotation_text': body['quotation_text'] ?? '',
            'items': [
              for (final item in (raw['items'] as List? ?? const []))
                if (item is Map)
                  {
                    'id': ++_seq,
                    'source_key': item['source_key'] ?? 'actividad',
                    'activity': item['activity'] ?? '',
                    'specialty': item['specialty'] ?? 'hydraulic',
                    'mandatory': item['mandatory'] ?? true,
                    'status': 'pending_technical',
                  },
            ],
          },
    ];
  }

  Map<String, dynamic> handleDashboard() {
    return {
      'timezone': 'America/Santiago',
      'kpi_1': [
        {'project_id': 41, 'calendar_days': 4},
      ],
      'kpi_9': [
        {
          'project_id': 41,
          'capture_points': 2,
          'target_calendar_days': 20,
          'actual_calendar_days': 12,
        },
      ],
      'delays': {
        'projects': [
          {
            'project_id': 42,
            'status': 'execution',
            'committed_on': '2026-11-20',
            'overdue': false,
          },
        ],
        'work_orders': [
          {
            'work_order_id': 8,
            'project_id': 41,
            'specialty': 'hydraulic',
            'status': 'suggested',
          },
        ],
      },
    };
  }
}
