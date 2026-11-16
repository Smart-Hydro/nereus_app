import 'package:dio/dio.dart';

/// Datos de ejemplo de `/api/operations/` para `NEREUS_DATA_MODE=fixture`.
class OperationsFixture {
  var _seq = 80;

  final List<Map<String, dynamic>> projects = [
    {
      'id': 41,
      'name': 'Instalación Norte',
      'code': 'PN-41',
      'service_type': 'project',
      'status': 'preparation',
      'status_reason': '',
      'committed_on': '2026-12-01',
      'owner': 7,
      'client_po_number': 'OC-1042',
      'client_po_received_on': '2026-11-02',
      'quotation': null,
      'ticket': null,
      'is_active': true,
      'milestones': [
        {
          'id': 1,
          'kind': 'committed_date',
          'occurred_on': '2026-12-01',
          'source': 'manual',
          'recorded_by': 7,
          'created': '2026-11-01T12:00:00Z',
        },
      ],
      'open_clarifications': <Map<String, dynamic>>[],
      'created': '2026-11-01T12:00:00Z',
      'modified': '2026-11-01T12:00:00Z',
    },
    {
      'id': 42,
      'name': 'Falla de logger',
      'code': 'PS-42',
      'service_type': 'support',
      'status': 'execution',
      'status_reason': '',
      'committed_on': '2026-11-20',
      'owner': 8,
      'client_po_number': '',
      'is_active': true,
      'milestones': <Map<String, dynamic>>[],
      'open_clarifications': [
        {'id': 3, 'text': '¿El pozo tiene energía?', 'asked_by': 8, 'created': '2026-11-10T12:00:00Z'},
      ],
      'created': '2026-11-10T12:00:00Z',
      'modified': '2026-11-10T12:00:00Z',
    },
  ];

  final List<Map<String, dynamic>> installations = [
    {
      'id': 5,
      'name': 'Pozo Norte',
      'code': 'IN-5',
      'client': 12,
      'location': 'Camino Los Pozos 100, Ñuble',
      'access_requirements': 'Inducción del predio',
      'device_ids': [101, 102],
      'is_active': true,
    },
  ];

  final List<Map<String, dynamic>> equipment = [
    {
      'id': 9,
      'project_point': 3,
      'device_id': 101,
      'product': 4,
      'model_name': 'Sensor caudal',
      'serial': 'SC-19',
      'work_order': 8,
      'is_current': true,
    },
  ];

  final List<Map<String, dynamic>> orders = [
    {
      'id': 8,
      'project': 41,
      'service_type': 'project',
      'specialty': 'hydraulic',
      'status': 'suggested',
      'block_reason': '',
      'cancel_reason': '',
      'scope_version': 1,
      'commercial_reference': '',
      'pending_scope_changes': 1,
      'created': '2026-11-03T12:00:00Z',
    },
  ];

  final List<Map<String, dynamic>> changes = [
    {
      'id': 2,
      'kind': 'added',
      'device': 101,
      'source_key': 'caudal',
      'activity': 'Medir caudal del pozo',
      'specialty': 'hydraulic',
      'mandatory': true,
      'status': 'pending',
    },
  ];

  final List<Map<String, dynamic>> visits = [
    {
      'id': 15,
      'work_order': 8,
      'project': 41,
      'specialty': 'hydraulic',
      'visit_type': 'planned',
      'is_rework': false,
      'status': 'scheduled',
      'scheduled_for': '2026-11-18',
      'notes': 'Pozo 1',
      'crew': [
        {
          'id': 4,
          'name': 'Cuadrilla Sur',
          'company': 'SmartHydro',
          'specialty': 'hydraulic',
          'contact': '',
          'is_active': true,
        },
      ],
      'reschedules': <Map<String, dynamic>>[],
      'site_requirement_warnings': [
        {'message': 'Requisito de sitio pendiente: Permiso de ingreso.'},
      ],
      'rts_warnings': [
        {'message': 'La OT no tiene RTS de insumos.'},
      ],
    },
  ];

  final List<Map<String, dynamic>> crew = [
    {
      'id': 4,
      'name': 'Cuadrilla Sur',
      'company': 'SmartHydro',
      'specialty': 'hydraulic',
      'contact': '+56 9 1111 2222',
      'is_active': true,
    },
  ];

  final List<Map<String, dynamic>> activities = [
    {
      'id': 21,
      'work_order': 8,
      'specialty': 'hydraulic',
      'project_point': 3,
      'device': 101,
      'description': 'Medir caudal del pozo',
      'mandatory': true,
      'execution_status': 'pending',
      'validation_status': 'pending',
      'not_done_reason': '',
      'validation_notes': '',
    },
  ];

  final List<Map<String, dynamic>> checks = [
    {
      'id': 6,
      'visit': 15,
      'work_order': 8,
      'activity': 21,
      'project_point': 3,
      'result': 'partial',
      'activity_execution_status': 'partial',
      'observation': 'Falta energizar',
      'measurement': '12 l/s',
      'pending_reason': 'Sin tablero',
      'pending_owner': 'Cliente',
    },
  ];

  final List<Map<String, dynamic>> evidences = [
    {
      'id': 11,
      'visit': 15,
      'work_order': 8,
      'activity': 21,
      'caption': 'Tablero del pozo',
      'url': 'https://drive.google.com/file/d/demo-tablero',
      'file': '',
    },
  ];

  final List<Map<String, dynamic>> rts = [
    {
      'id': 3,
      'work_order': 8,
      'work_order_specialty': 'hydraulic',
      'status': 'draft',
      'notes': 'Sensores del pozo',
      'items': [
        {
          'id': 1,
          'product': 4,
          'product_name': 'Sensor caudal',
          'quantity': '1.0000',
          'unit': 'un',
          'status': 'pending',
          'stock_quantity': '6.0000',
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> reports = [
    {
      'id': 2,
      'project': 41,
      'version': 1,
      'status': 'draft',
      'kind': 'project',
      'specialty': 'hydraulic',
      'body': {'text': 'Borrador del informe de puesta en marcha.'},
      'drive_url': 'https://drive.google.com/file/d/demo-informe',
    },
  ];

  final List<Map<String, dynamic>> clarifications = [
    {
      'id': 3,
      'project': 42,
      'text': '¿El pozo tiene energía?',
      'status': 'open',
      'answer': '',
    },
  ];

  final List<Map<String, dynamic>> outOfScope = [
    {
      'id': 1,
      'project': 41,
      'description': 'Canaleta adicional no cotizada',
      'decision': 'pending',
      'decision_reason': '',
    },
  ];

  final List<Map<String, dynamic>> costs = [
    {
      'id': 1,
      'specialty': 'hydraulic',
      'amount': '180000.00',
      'valid_from': '2026-11-01',
    },
  ];

  final List<Map<String, dynamic>> targets = [
    {
      'id': 1,
      'kpi_code': 'kpi_9',
      'category': 'Dos puntos',
      'capture_points_min': 1,
      'capture_points_max': 3,
      'target_calendar_days': 20,
      'notes': 'Rango de puntos de captación',
    },
  ];

  final List<Map<String, dynamic>> indicators = [
    {
      'id': 1,
      'name': 'Plan a informe',
      'start_event': 'official_plan',
      'end_event': 'report_sent',
      'day_type': 'business',
      'deduct_pauses': true,
    },
  ];

  final List<Map<String, dynamic>> sites = [
    {
      'id': 1,
      'project': 41,
      'kind': 'entry_permit',
      'status': 'pending',
      'notes': 'Aviso al administrador del predio',
    },
  ];

  final List<Map<String, dynamic>> obligations = [
    {
      'id': 1,
      'work_order': 8,
      'description': 'Dejar energizado el tablero',
      'status': 'pending',
      'responsible': 'Cliente',
      'notes': '',
    },
  ];

  final List<Map<String, dynamic>> transitions = [
    {
      'id': 70,
      'entity_type': 'project',
      'entity_id': 41,
      'from_value': '',
      'to_value': 'preparation',
      'reason': 'Alta del proyecto',
      'scope_version': null,
      'actor': 7,
      'occurred_at': '2026-11-01T15:00:00Z',
    },
  ];

  dynamic answer(RequestOptions options) {
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
        return _projects(method, id, action, segs, body);
      case 'installations':
        return _crud(installations, method, id, body, (data) => {...data, 'id': ++_seq, 'device_ids': data['device_ids'] ?? []});
      case 'installed-equipment':
        return _equipment(method, id, action, body);
      case 'site-requirements':
        return _crud(sites, method, id, body, (data) => {...data, 'id': ++_seq, 'status': data['status'] ?? 'pending'});
      case 'client-obligations':
        return _crud(obligations, method, id, body, (data) => {...data, 'id': ++_seq, 'status': 'pending'});
      case 'work-orders':
        return _orders(method, id, action, segs, body);
      case 'visits':
        return _visits(method, id, action, body);
      case 'crew-members':
        return _crud(crew, method, id, body, (data) => {...data, 'id': ++_seq, 'is_active': true});
      case 'activities':
        return _activities(method, id, action, body);
      case 'field-checks':
        return _crud(checks, method, id, body, (data) => {...data, 'id': ++_seq, 'visit': data['visit_id'], 'activity': data['activity_id']});
      case 'evidences':
        return _evidences(method, id, action, body);
      case 'rts':
        return _rts(method, id, action, body);
      case 'reports':
        return _reports(method, id, action, body);
      case 'clarifications':
        return _clarifications(method, id, action, body);
      case 'out-of-scope-work':
        return _scopeWork(method, id, action, body);
      case 'crew-daily-costs':
        return _crud(costs, method, id, body, (data) => {...data, 'id': ++_seq});
      case 'indicators':
        return _dashboard();
      case 'indicator-targets':
        return _crud(targets, method, id, body, (data) => {...data, 'id': ++_seq, 'kpi_code': data['kpi_code'] ?? 'kpi_9'});
      case 'configurable-indicators':
        return _configurable(method, id, action, body);
      case 'transitions':
        if (id != null) return _find(transitions, id) ?? {};
        return _page(transitions);
      default:
        return method == 'GET' ? _page(const []) : {'id': ++_seq, ...body};
    }
  }

  dynamic _projects(String method, String? id, String? action, List<String> segs, Map<String, dynamic> body) {
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
      final points = body['points'];
      var deviceId = 101;
      if (points is List && points.isNotEmpty && points.first is Map) {
        final raw = (points.first as Map)['device_id'];
        if (raw is int) deviceId = raw;
      }
      return [
        {
          'id': ++_seq,
          'device': deviceId,
          'device_type': 'FLOW',
          'quotation_text': body['quotation_text'] ?? '',
          'items': [
            {
              'id': ++_seq,
              'source_key': 'caudal',
              'activity': 'Medir caudal del pozo',
              'specialty': 'hydraulic',
              'mandatory': true,
              'status': 'pending_technical',
            },
          ],
        },
      ];
    }
    if (action == 'scope-items') {
      return {
        'id': ++_seq,
        'device': 101,
        'items': [
          {
            'id': segs.length >= 6 ? segs[5] : '1',
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

  dynamic _orders(String method, String? id, String? action, List<String> segs, Map<String, dynamic> body) {
    if (id == 'suggest' || (id == null && method == 'POST' && optionsPathSuggest(body))) {
      return orders;
    }
    if (id == 'suggest') return orders;
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
      if (change != null) change['status'] = body['approve'] == true ? 'approved' : 'rejected';
      return change ?? {};
    }
    if (action == 'scope-changes') return changes;
    return row;
  }

  bool optionsPathSuggest(Map<String, dynamic> body) => body.containsKey('project_id');

  dynamic _visits(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'work_order': body['work_order_id'],
          'visit_type': body['visit_type'] ?? 'planned',
          'status': body['scheduled_for'] == null ? 'proposed' : 'scheduled',
          'scheduled_for': body['scheduled_for'],
          'notes': body['notes'] ?? '',
          'specialty': 'hydraulic',
          'crew': <Map<String, dynamic>>[],
          'reschedules': <Map<String, dynamic>>[],
          'site_requirement_warnings': <Map<String, dynamic>>[],
          'rts_warnings': <Map<String, dynamic>>[],
        };
        visits.insert(0, created);
        return created;
      }
      return _page(visits);
    }
    final row = _find(visits, id);
    if (row == null) return {};
    if (action == 'schedule') {
      row['status'] = 'scheduled';
      row['scheduled_for'] = body['scheduled_for'];
    } else if (action == 'reschedule') {
      final history = (row['reschedules'] as List?) ?? <dynamic>[];
      history.add({
        'id': ++_seq,
        'previous_date': row['scheduled_for'],
        'new_date': body['new_date'],
        'reason': body['reason'] ?? '',
      });
      row['reschedules'] = history;
      row['scheduled_for'] = body['new_date'];
    } else if (action == 'start') {
      row['status'] = 'in_progress';
    } else if (action == 'finish') {
      row['status'] = 'finished';
    } else if (action == 'cancel') {
      row['status'] = 'cancelled';
      row['cancel_reason'] = body['reason'] ?? '';
    } else if (action == 'crew' && method == 'POST') {
      final member = _find(crew, '${body['crew_member_id']}');
      final list = (row['crew'] as List?) ?? <dynamic>[];
      if (member != null) list.add(member);
      row['crew'] = list;
    } else if (action == 'crew' && method == 'DELETE') {
      final list = (row['crew'] as List?) ?? <dynamic>[];
      list.removeWhere((item) => item is Map && '${item['id']}' == '${body['crew_member_id']}');
      row['crew'] = list;
      return {'deleted': body['crew_member_id']};
    }
    return row;
  }

  dynamic _activities(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == 'materialize' || (id == null && method == 'POST')) return activities;
    if (id == null) return _page(activities);
    final row = _find(activities, id);
    if (row == null) return {};
    if (action == 'execution') {
      row['execution_status'] = body['execution_status'];
      row['not_done_reason'] = body['not_done_reason'] ?? '';
    } else if (action == 'validation') {
      row['validation_status'] = body['result'];
      row['validation_notes'] = body['notes'] ?? '';
    } else if (action == 'history') {
      return [
        {
          'id': 1,
          'activity': row['id'],
          'from_status': 'pending',
          'to_status': row['execution_status'],
          'reason': '',
          'changed_at': '2026-11-12T12:00:00Z',
        },
      ];
    }
    return row;
  }

  dynamic _equipment(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'project_point': body['project_point_id'],
          'work_order': body['work_order_id'],
          'model_name': body['model_name'] ?? '',
          'serial': body['serial'] ?? '',
          'is_current': true,
        };
        equipment.insert(0, created);
        return created;
      }
      return _page(equipment);
    }
    final row = _find(equipment, id);
    if (row == null) return {};
    if (action == 'remove') {
      row['is_current'] = false;
    } else if (action == 'replace') {
      row['is_current'] = false;
      final created = {
        'id': ++_seq,
        'project_point': row['project_point'],
        'model_name': body['model_name'] ?? '',
        'serial': body['serial'] ?? '',
        'is_current': true,
      };
      equipment.insert(0, created);
      return created;
    }
    return row;
  }

  dynamic _evidences(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'visit': body['visit_id'],
          'caption': body['caption'] ?? '',
          'url': body['url'] ?? '',
        };
        evidences.insert(0, created);
        return created;
      }
      return _page(evidences);
    }
    final row = _find(evidences, id);
    if (row == null) return {};
    if (action == 'link-drive') {
      final fileId = body['file_id'] ?? 'demo';
      row['url'] = 'https://drive.google.com/file/d/$fileId';
    }
    return row;
  }

  dynamic _rts(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'work_order': body['work_order_id'],
          'status': 'draft',
          'notes': body['notes'] ?? '',
          'items': body['items'] ?? <Map<String, dynamic>>[],
        };
        rts.insert(0, created);
        return created;
      }
      return _page(rts);
    }
    final row = _find(rts, id);
    if (row == null) return {};
    if (action == 'prepare') row['status'] = 'prepared';
    if (action == 'reserve') row['status'] = 'reserved';
    if (action == 'issue') row['status'] = 'issued';
    if (action == 'link-purchase-order') row['purchase_order'] = body['purchase_order_id'];
    return row;
  }

  dynamic _reports(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == 'generate') {
      final created = {
        'id': ++_seq,
        'project': body['project_id'],
        'version': 1,
        'status': 'draft',
        'kind': 'project',
        'specialty': body['specialty'] ?? '',
        'body': {'text': ''},
        'drive_url': '',
      };
      reports.insert(0, created);
      return created;
    }
    if (id == null) return _page(reports);
    final row = _find(reports, id);
    if (row == null) return {};
    if (method == 'PATCH') row['body'] = body['body'] ?? row['body'];
    if (action == 'submit-review') row['status'] = 'review';
    if (action == 'revise') row['status'] = 'draft';
    if (action == 'approve') row['status'] = 'approved';
    if (action == 'send') row['status'] = 'sent';
    return row;
  }

  dynamic _clarifications(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'project': body['project'],
          'text': body['text'] ?? '',
          'status': 'open',
          'answer': '',
        };
        clarifications.insert(0, created);
        return created;
      }
      return _page(clarifications);
    }
    final row = _find(clarifications, id);
    if (row == null) return {};
    if (action == 'answer') {
      row['answer'] = body['answer'] ?? '';
      row['status'] = 'answered';
    }
    return row;
  }

  dynamic _scopeWork(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'project': body['project'],
          'description': body['description'] ?? '',
          'decision': 'pending',
          'decision_reason': '',
        };
        outOfScope.insert(0, created);
        return created;
      }
      return _page(outOfScope);
    }
    final row = _find(outOfScope, id);
    if (row == null) return {};
    if (action == 'decide') {
      row['decision'] = body['decision'] ?? row['decision'];
      row['decision_reason'] = body['reason'] ?? '';
    }
    return row;
  }

  dynamic _configurable(String method, String? id, String? action, Map<String, dynamic> body) {
    if (id == null) {
      if (method == 'POST') {
        final created = {'id': ++_seq, 'deduct_pauses': true, ...body};
        indicators.insert(0, created);
        return created;
      }
      return _page(indicators);
    }
    if (method == 'DELETE') {
      indicators.removeWhere((row) => '${row['id']}' == id);
      return {'deleted': id};
    }
    final row = _find(indicators, id);
    if (row == null) return {};
    if (action == 'compute') {
      return {
        'indicator_id': row['id'],
        'name': row['name'],
        'project_id': 41,
        'day_type': row['day_type'],
        'days': 12,
        'calendar_days': 18,
        'business_days': 12,
      };
    }
    if (method == 'PATCH') row.addAll(body);
    return row;
  }

  Map<String, dynamic> _dashboard() {
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
    return {'count': rows.length, 'results': rows};
  }

  Map<String, dynamic>? _find(List<Map<String, dynamic>> rows, String id) {
    for (final row in rows) {
      if ('${row['id']}' == id) return row;
    }
    return null;
  }

  List<String> _segs(String path) {
    return path.split('?').first.split('/').where((part) => part.isNotEmpty).toList();
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
