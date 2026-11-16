part of 'operations_fixture.dart';

/// Altas y transiciones que no son el alta del proyecto ni de la OT.
extension OperationsFixtureActions on OperationsFixture {
  dynamic handleVisits(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
    if (id == null) {
      if (method == 'POST') {
        final order = _find(orders, '${body['work_order_id']}');
        final created = {
          'id': ++_seq,
          'work_order': body['work_order_id'],
          'project': order?['project'],
          'visit_type': body['visit_type'] ?? 'planned',
          'status': body['scheduled_for'] == null ? 'proposed' : 'scheduled',
          'scheduled_for': body['scheduled_for'],
          'notes': body['notes'] ?? '',
          'specialty': order?['specialty'] ?? 'hydraulic',
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
      list.removeWhere(
        (item) => item is Map && '${item['id']}' == '${body['crew_member_id']}',
      );
      row['crew'] = list;
      return {'deleted': body['crew_member_id']};
    }
    return row;
  }

  dynamic handleActivities(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
    if (id == 'materialize' || (id == null && method == 'POST')) {
      final created = {
        'id': ++_seq,
        'work_order': body['work_order_id'],
        'specialty': 'hydraulic',
        'project_point': 3,
        'device': 101,
        'description': 'Medir caudal del pozo',
        'mandatory': true,
        'execution_status': 'pending',
        'validation_status': 'pending',
        'not_done_reason': '',
        'validation_notes': '',
      };
      activities.insert(0, created);
      return [created];
    }
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

  dynamic handleEquipment(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
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

  dynamic handleEvidences(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
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

  dynamic handleRts(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
    if (id == null) {
      if (method == 'POST') {
        final created = {
          'id': ++_seq,
          'work_order': body['work_order_id'],
          'work_order_specialty': 'hydraulic',
          'status': 'draft',
          'notes': body['notes'] ?? '',
          'items': [
            for (final item in (body['items'] as List? ?? const <dynamic>[]))
              if (item is Map)
                {
                  'id': ++_seq,
                  'product': item['product_id'],
                  'product_name': 'Sensor caudal',
                  'quantity': '${item['quantity'] ?? '1'}',
                  'unit': item['unit'] ?? 'un',
                  'status': 'pending',
                  'warehouse': item['warehouse_id'] ?? 2,
                  'warehouse_name': '${item['warehouse_id']}' == '3'
                      ? 'Bodega taller'
                      : 'Bodega Ñuble',
                  'stock_quantity': '6',
                },
          ],
        };
        rts.insert(0, created);
        return created;
      }
      return _page(rts);
    }
    final row = _find(rts, id);
    if (row == null) return {};
    if (action == 'prepare') row['status'] = 'prepared';
    if (action == 'reserve') _reserveOnce(row);
    if (action == 'issue') row['status'] = 'issued';
    if (action == 'link-purchase-order') {
      row['purchase_order'] = body['purchase_order_id'];
      row['purchase_order_number'] = 'OC-1042';
      row['supplier_name'] = 'Ferretería El Huape';
      if (body['reception_id'] != null) {
        row['reception'] = body['reception_id'];
      }
    }
    return row;
  }

  void _reserveOnce(Map<String, dynamic> row) {
    if (row['status'] == 'reserved' || row['status'] == 'issued') return;
    row['status'] = 'reserved';
    final items = row['items'];
    if (items is! List) return;
    for (final item in items) {
      if (item is! Map) continue;
      final stock = num.tryParse('${item['stock_quantity']}') ?? 0;
      final qty = num.tryParse('${item['quantity']}') ?? 0;
      item['stock_quantity'] = '${stock - qty}';
      item['status'] = 'reserved';
    }
  }

  dynamic handleReports(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
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

  dynamic handleClarifications(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
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

  dynamic handleScopeWork(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
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

  dynamic handleConfigurable(
    String method,
    String? id,
    String? action,
    Map<String, dynamic> body,
  ) {
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
}
