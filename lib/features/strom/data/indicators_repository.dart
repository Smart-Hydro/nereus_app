import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';

class IndicatorsRepository {
  IndicatorsRepository(this._http);

  final OpsHttp _http;

  Future<OpsDashboard> dashboard({String? project, String? workOrder}) {
    return _http.getOne(
      '/api/operations/indicators/',
      OpsDashboard.fromJson,
      query: {
        if (project != null) 'project': project,
        if (workOrder != null) 'work_order': workOrder,
      },
    );
  }

  Future<List<OpsIndicatorTarget>> targets() => _http.getList(
    '/api/operations/indicator-targets/',
    OpsIndicatorTarget.fromJson,
  );

  Future<OpsIndicatorTarget> createTarget(Map<String, dynamic> body) =>
      _http.send(
        '/api/operations/indicator-targets/',
        data: body,
        parse: OpsIndicatorTarget.fromJson,
      );

  Future<OpsIndicatorTarget> updateTarget(
    String id,
    Map<String, dynamic> body,
  ) => _http.send(
    '/api/operations/indicator-targets/$id/',
    method: 'PATCH',
    data: body,
    parse: OpsIndicatorTarget.fromJson,
  );

  Future<void> deleteTarget(String id) => _http.sendEmpty(
    '/api/operations/indicator-targets/$id/',
    method: 'DELETE',
  );

  Future<List<OpsConfigurableIndicator>> configurable() {
    return _http.getList(
      '/api/operations/configurable-indicators/',
      OpsConfigurableIndicator.fromJson,
    );
  }

  Future<OpsConfigurableIndicator> createConfigurable(
    Map<String, dynamic> body,
  ) => _http.send(
    '/api/operations/configurable-indicators/',
    data: body,
    parse: OpsConfigurableIndicator.fromJson,
  );

  Future<OpsConfigurableIndicator> updateConfigurable(
    String id,
    Map<String, dynamic> body,
  ) {
    return _http.send(
      '/api/operations/configurable-indicators/$id/',
      method: 'PATCH',
      data: body,
      parse: OpsConfigurableIndicator.fromJson,
    );
  }

  Future<void> deleteConfigurable(String id) => _http.sendEmpty(
    '/api/operations/configurable-indicators/$id/',
    method: 'DELETE',
  );

  Future<Map<String, dynamic>> compute(
    String id, {
    required String projectId,
    String? workOrderId,
  }) {
    return _http.getOne(
      '/api/operations/configurable-indicators/$id/compute/',
      asMap,
      query: {
        'project': projectId,
        if (workOrderId != null) 'work_order': workOrderId,
      },
    );
  }
}
