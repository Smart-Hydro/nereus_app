import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';

class AuditRepository {
  AuditRepository(this._http);

  final OpsHttp _http;

  Future<List<OpsTransition>> list({String? entityType, String? entityId}) {
    return _http.getList(
      '/api/operations/transitions/',
      OpsTransition.fromJson,
      query: {
        if (entityType != null && entityType.isNotEmpty) 'entity_type': entityType,
        if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
      },
    );
  }

  Future<OpsTransition> get(String id) =>
      _http.getOne('/api/operations/transitions/$id/', OpsTransition.fromJson);
}
