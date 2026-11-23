import 'package:dio/dio.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';

class ReportsRepository {
  ReportsRepository(this._http);

  final OpsHttp _http;
  static const _root = '/api/operations/reports/';

  Future<List<OpsReport>> list({String? project, String? status}) {
    return _http.getList(
      _root,
      OpsReport.fromJson,
      query: {
        if (project != null) 'project': project,
        if (status != null) 'status': status,
      },
    );
  }

  Future<OpsReport> get(String id) =>
      _http.getOne('$_root$id/', OpsReport.fromJson);

  Future<OpsReport> update(String id, {String? body, String? specialty}) {
    return _http.send(
      '$_root$id/',
      method: 'PATCH',
      data: {
        if (body != null) 'body': {'text': body},
        if (specialty != null) 'specialty': specialty,
      },
      parse: OpsReport.fromJson,
    );
  }

  Future<OpsReport> generate({required int projectId, String specialty = ''}) {
    return _http.send(
      '${_root}generate/',
      data: {'project_id': projectId, 'specialty': specialty},
      parse: OpsReport.fromJson,
    );
  }

  Future<OpsReport> submitReview(String id) =>
      _http.send('$_root$id/submit-review/', parse: OpsReport.fromJson);

  Future<OpsReport> revise(String id) =>
      _http.send('$_root$id/revise/', parse: OpsReport.fromJson);

  /// Devolver a borrador. Solo desde revisión, en la misma versión.
  Future<OpsReport> returnToDraft(String id) =>
      _http.send('$_root$id/return-draft/', parse: OpsReport.fromJson);

  /// Con especialidad, el líder de esa especialidad. Sin ella, Operaciones o cualquier líder.
  Future<OpsReport> approve(String id, {String signature = ''}) => _http.send(
    '$_root$id/approve/',
    data: {'signature': signature},
    parse: OpsReport.fromJson,
  );

  Future<List<int>> pdf(String id) async {
    final response = await _http.dio.get<List<int>>(
      '$_root$id/pdf/',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }

  Future<OpsReport> send(String id) => _http.send(
    '$_root$id/send/',
    data: {'send_backup': <String, dynamic>{}},
    parse: OpsReport.fromJson,
  );
}
