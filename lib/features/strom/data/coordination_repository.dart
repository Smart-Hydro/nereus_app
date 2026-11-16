import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';

class CoordinationRepository {
  CoordinationRepository(this._http);

  final OpsHttp _http;

  Future<List<OpsClarification>> clarifications({String? project, String? status}) {
    return _http.getList(
      '/api/operations/clarifications/',
      OpsClarification.fromJson,
      query: {
        if (project != null) 'project': project,
        if (status != null) 'status': status,
      },
    );
  }

  Future<OpsClarification> ask({required int projectId, required String text}) {
    return _http.send(
      '/api/operations/clarifications/',
      data: {'project': projectId, 'text': text},
      parse: OpsClarification.fromJson,
    );
  }

  Future<OpsClarification> answer(String id, {required String answer}) {
    return _http.send(
      '/api/operations/clarifications/$id/answer/',
      data: {'answer': answer},
      parse: OpsClarification.fromJson,
    );
  }

  Future<List<OpsOutOfScope>> outOfScope({String? project}) {
    return _http.getList(
      '/api/operations/out-of-scope-work/',
      OpsOutOfScope.fromJson,
      query: {if (project != null) 'project': project},
    );
  }

  Future<OpsOutOfScope> registerOutOfScope({
    required int projectId,
    required String description,
  }) {
    return _http.send(
      '/api/operations/out-of-scope-work/',
      data: {'project': projectId, 'description': description},
      parse: OpsOutOfScope.fromJson,
    );
  }

  Future<OpsOutOfScope> decide(
    String id, {
    required String decision,
    String reason = '',
  }) {
    return _http.send(
      '/api/operations/out-of-scope-work/$id/decide/',
      data: {'decision': decision, 'reason': reason},
      parse: OpsOutOfScope.fromJson,
    );
  }
}
