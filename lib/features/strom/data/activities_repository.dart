import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';

class ActivitiesRepository {
  ActivitiesRepository(this._http);

  final OpsHttp _http;
  static const _root = '/api/operations/activities/';

  Future<List<OpsActivity>> list({
    String? workOrder,
    String? executionStatus,
    String? validationStatus,
  }) {
    return _http.getList(
      _root,
      OpsActivity.fromJson,
      query: {
        if (workOrder != null) 'work_order': workOrder,
        if (executionStatus != null) 'execution_status': executionStatus,
        if (validationStatus != null) 'validation_status': validationStatus,
      },
    );
  }

  Future<OpsActivity> get(String id) =>
      _http.getOne('$_root$id/', OpsActivity.fromJson);

  Future<List<OpsActivity>> materialize(int workOrderId) {
    return _http.sendList(
      '${_root}materialize/',
      OpsActivity.fromJson,
      data: {'work_order_id': workOrderId},
    );
  }

  Future<OpsActivity> execution(
    String id, {
    required String executionStatus,
    String notDoneReason = '',
  }) {
    return _http.send(
      '$_root$id/execution/',
      data: {
        'execution_status': executionStatus,
        'not_done_reason': notDoneReason,
      },
      parse: OpsActivity.fromJson,
    );
  }

  Future<OpsActivity> validation(
    String id, {
    required String result,
    String notes = '',
  }) {
    return _http.send(
      '$_root$id/validation/',
      data: {'result': result, 'notes': notes},
      parse: OpsActivity.fromJson,
    );
  }

  Future<List<OpsStatusChange>> history(String id) {
    return _http.getList('$_root$id/history/', OpsStatusChange.fromJson);
  }
}
