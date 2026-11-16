import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';

class InstallationsRepository {
  InstallationsRepository(this._http);

  final OpsHttp _http;

  Future<List<OpsInstallation>> list() =>
      _http.getList('/api/operations/installations/', OpsInstallation.fromJson);

  Future<OpsInstallation> get(String id) =>
      _http.getOne('/api/operations/installations/$id/', OpsInstallation.fromJson);

  Future<OpsInstallation> create(Map<String, dynamic> body) => _http.send(
        '/api/operations/installations/',
        data: body,
        parse: OpsInstallation.fromJson,
      );

  Future<OpsInstallation> update(String id, Map<String, dynamic> body) => _http.send(
        '/api/operations/installations/$id/',
        method: 'PATCH',
        data: body,
        parse: OpsInstallation.fromJson,
      );

  Future<List<OpsEquipment>> equipment({String? projectPoint, String? workOrder}) {
    return _http.getList(
      '/api/operations/installed-equipment/',
      OpsEquipment.fromJson,
      query: {
        if (projectPoint != null) 'project_point': projectPoint,
        if (workOrder != null) 'work_order': workOrder,
      },
    );
  }

  Future<OpsEquipment> install(Map<String, dynamic> body) => _http.send(
        '/api/operations/installed-equipment/',
        data: body,
        parse: OpsEquipment.fromJson,
      );

  Future<OpsEquipment> removeEquipment(String id) => _http.send(
        '/api/operations/installed-equipment/$id/remove/',
        parse: OpsEquipment.fromJson,
      );

  Future<OpsEquipment> replaceEquipment(String id, Map<String, dynamic> body) =>
      _http.send(
        '/api/operations/installed-equipment/$id/replace/',
        data: body,
        parse: OpsEquipment.fromJson,
      );

  Future<List<OpsSiteRequirement>> siteRequirements({String? project}) {
    return _http.getList(
      '/api/operations/site-requirements/',
      OpsSiteRequirement.fromJson,
      query: {if (project != null) 'project': project},
    );
  }

  Future<OpsSiteRequirement> createSite(Map<String, dynamic> body) => _http.send(
        '/api/operations/site-requirements/',
        data: body,
        parse: OpsSiteRequirement.fromJson,
      );

  Future<OpsSiteRequirement> updateSite(String id, Map<String, dynamic> body) =>
      _http.send(
        '/api/operations/site-requirements/$id/',
        method: 'PATCH',
        data: body,
        parse: OpsSiteRequirement.fromJson,
      );

  Future<List<OpsObligation>> obligations({String? workOrder}) {
    return _http.getList(
      '/api/operations/client-obligations/',
      OpsObligation.fromJson,
      query: {if (workOrder != null) 'work_order': workOrder},
    );
  }

  Future<OpsObligation> createObligation(Map<String, dynamic> body) => _http.send(
        '/api/operations/client-obligations/',
        data: body,
        parse: OpsObligation.fromJson,
      );

  Future<OpsObligation> updateObligation(String id, Map<String, dynamic> body) =>
      _http.send(
        '/api/operations/client-obligations/$id/',
        method: 'PATCH',
        data: body,
        parse: OpsObligation.fromJson,
      );
}
