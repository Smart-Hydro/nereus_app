import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';

class ProjectsRepository {
  ProjectsRepository(this._http);

  final OpsHttp _http;
  static const _root = '/api/operations/projects/';

  Future<List<OpsProject>> list({String? search, String? status}) {
    return _http.getList(
      _root,
      OpsProject.fromJson,
      query: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
  }

  Future<OpsProject> get(String id) => _http.getOne('$_root$id/', OpsProject.fromJson);

  Future<OpsProject> create(Map<String, dynamic> body) =>
      _http.send(_root, data: body, parse: OpsProject.fromJson);

  Future<OpsProject> update(String id, Map<String, dynamic> body) =>
      _http.send('$_root$id/', method: 'PATCH', data: body, parse: OpsProject.fromJson);

  Future<OpsProject> setStatus(String id, String status, {String reason = ''}) {
    return _http.send(
      '$_root$id/status/',
      data: {'status': status, 'status_reason': reason},
      parse: OpsProject.fromJson,
    );
  }

  Future<OpsProject> close(String id, {String reason = ''}) {
    return _http.send(
      '$_root$id/close/',
      data: {'reason': reason},
      parse: OpsProject.fromJson,
    );
  }

  Future<OpsProjectCost> cost(String id) =>
      _http.getOne('$_root$id/cost/', OpsProjectCost.fromJson);

  Future<List<OpsScopePoint>> importScope(String id, Map<String, dynamic> body) {
    return _http.sendList('$_root$id/scope/', OpsScopePoint.fromJson, data: body);
  }

  Future<OpsScopePoint> confirmItem(String projectId, String itemId) {
    return _http.send(
      '$_root$projectId/scope-items/$itemId/confirm/',
      parse: OpsScopePoint.fromJson,
    );
  }

  Future<OpsMilestone> addMilestone(
    String id, {
    required String kind,
    required String occurredOn,
  }) {
    return _http.send(
      '$_root$id/milestones/',
      data: {'kind': kind, 'occurred_on': occurredOn},
      parse: OpsMilestone.fromJson,
    );
  }
}
