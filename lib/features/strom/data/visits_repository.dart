import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';

class VisitsRepository {
  VisitsRepository(this._http);

  final OpsHttp _http;
  static const _root = '/api/operations/visits/';

  Future<List<OpsVisit>> list({String? workOrder, String? status, String? visitType}) {
    return _http.getList(
      _root,
      OpsVisit.fromJson,
      query: {
        if (workOrder != null) 'work_order': workOrder,
        if (status != null) 'status': status,
        if (visitType != null) 'visit_type': visitType,
      },
    );
  }

  Future<OpsVisit> get(String id) => _http.getOne('$_root$id/', OpsVisit.fromJson);

  /// La primera visita de la OT nace con tipo planificada si no se envía otro.
  Future<OpsVisit> create({
    required int workOrderId,
    String? scheduledFor,
    String notes = '',
    String visitType = 'planned',
  }) {
    return _http.send(
      _root,
      data: {
        'work_order_id': workOrderId,
        'scheduled_for': scheduledFor,
        'notes': notes,
        'visit_type': visitType,
      },
      parse: OpsVisit.fromJson,
    );
  }

  Future<OpsVisit> schedule(String id, String scheduledFor) => _http.send(
        '$_root$id/schedule/',
        data: {'scheduled_for': scheduledFor},
        parse: OpsVisit.fromJson,
      );

  Future<OpsVisit> reschedule(String id, {required String newDate, String reason = ''}) {
    return _http.send(
      '$_root$id/reschedule/',
      data: {'new_date': newDate, 'reason': reason},
      parse: OpsVisit.fromJson,
    );
  }

  Future<OpsVisit> start(String id) =>
      _http.send('$_root$id/start/', parse: OpsVisit.fromJson);

  Future<OpsVisit> finish(String id) =>
      _http.send('$_root$id/finish/', parse: OpsVisit.fromJson);

  Future<OpsVisit> cancel(String id, {String reason = ''}) => _http.send(
        '$_root$id/cancel/',
        data: {'reason': reason},
        parse: OpsVisit.fromJson,
      );

  Future<OpsVisit> addCrew(String visitId, int crewMemberId) => _http.send(
        '$_root$visitId/crew/',
        data: {'crew_member_id': crewMemberId},
        parse: OpsVisit.fromJson,
      );

  Future<void> removeCrew(String visitId, int crewMemberId) {
    return _http.sendEmpty(
      '$_root$visitId/crew/',
      method: 'DELETE',
      data: {'crew_member_id': crewMemberId},
    );
  }

  Future<List<OpsCrewMember>> crew({String? search}) {
    return _http.getList(
      '/api/operations/crew-members/',
      OpsCrewMember.fromJson,
      query: {if (search != null && search.isNotEmpty) 'search': search},
    );
  }

  Future<OpsCrewMember> createCrew(Map<String, dynamic> body) => _http.send(
        '/api/operations/crew-members/',
        data: body,
        parse: OpsCrewMember.fromJson,
      );

  Future<OpsCrewMember> updateCrew(String id, Map<String, dynamic> body) => _http.send(
        '/api/operations/crew-members/$id/',
        method: 'PATCH',
        data: body,
        parse: OpsCrewMember.fromJson,
      );
}
