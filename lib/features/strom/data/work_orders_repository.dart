import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';

class WorkOrdersRepository {
  WorkOrdersRepository(this._http);

  final OpsHttp _http;
  static const _root = '/api/operations/work-orders/';

  Future<List<OpsWorkOrder>> list({
    String? project,
    String? specialty,
    String? status,
  }) {
    return _http.getList(
      _root,
      OpsWorkOrder.fromJson,
      query: {
        if (project != null) 'project': project,
        if (specialty != null) 'specialty': specialty,
        if (status != null) 'status': status,
      },
    );
  }

  Future<OpsWorkOrder> get(String id) =>
      _http.getOne('$_root$id/', OpsWorkOrder.fromJson);

  Future<List<OpsWorkOrder>> suggest(int projectId) {
    return _http.sendList(
      '${_root}suggest/',
      OpsWorkOrder.fromJson,
      data: {'project_id': projectId},
    );
  }

  Future<OpsWorkOrder> confirm(String id, {String commercialReference = ''}) {
    return _http.send(
      '$_root$id/confirm/',
      data: {'commercial_reference': commercialReference},
      parse: OpsWorkOrder.fromJson,
    );
  }

  Future<OpsWorkOrder> setStatus(
    String id, {
    required String status,
    String blockReason = '',
    String cancelReason = '',
  }) {
    return _http.send(
      '$_root$id/status/',
      data: {
        'status': status,
        'block_reason': blockReason,
        'cancel_reason': cancelReason,
      },
      parse: OpsWorkOrder.fromJson,
    );
  }

  Future<OpsCostRow> cost(String id) =>
      _http.getOne('$_root$id/cost/', OpsCostRow.fromJson);

  Future<List<OpsScopeChange>> scopeChanges(String id) {
    return _http.getList('$_root$id/scope-changes/', OpsScopeChange.fromJson);
  }

  Future<OpsScopeChange> decide(
    String id,
    String changeId, {
    required bool approve,
    String reason = '',
  }) {
    return _http.send(
      '$_root$id/scope-changes/$changeId/decide/',
      data: {'approve': approve, 'reason': reason},
      parse: OpsScopeChange.fromJson,
    );
  }
}
