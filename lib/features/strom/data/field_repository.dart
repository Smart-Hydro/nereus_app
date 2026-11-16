import 'package:dio/dio.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';

class FieldRepository {
  FieldRepository(this._http);

  final OpsHttp _http;

  Future<List<OpsFieldCheck>> checks({String? visit, String? activity}) {
    return _http.getList(
      '/api/operations/field-checks/',
      OpsFieldCheck.fromJson,
      query: {
        if (visit != null) 'visit': visit,
        if (activity != null) 'activity': activity,
      },
    );
  }

  Future<OpsFieldCheck> createCheck(Map<String, dynamic> body) => _http.send(
        '/api/operations/field-checks/',
        data: body,
        parse: OpsFieldCheck.fromJson,
      );

  Future<List<OpsEvidence>> evidences({String? visit}) {
    return _http.getList(
      '/api/operations/evidences/',
      OpsEvidence.fromJson,
      query: {if (visit != null) 'visit': visit},
    );
  }

  Future<OpsEvidence> createEvidence({
    required int visitId,
    int? activityId,
    int? fieldCheckId,
    String url = '',
    String caption = '',
    List<int>? bytes,
    String filename = 'evidencia.jpg',
  }) {
    final Object data;
    if (bytes != null) {
      data = FormData.fromMap({
        'visit_id': visitId,
        if (activityId != null) 'activity_id': activityId,
        if (fieldCheckId != null) 'field_check_id': fieldCheckId,
        'caption': caption,
        'url': url,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
    } else {
      data = {
        'visit_id': visitId,
        if (activityId != null) 'activity_id': activityId,
        if (fieldCheckId != null) 'field_check_id': fieldCheckId,
        'url': url,
        'caption': caption,
      };
    }
    return _http.send(
      '/api/operations/evidences/',
      data: data,
      parse: OpsEvidence.fromJson,
    );
  }

  Future<OpsEvidence> linkDrive(String id, {required String fileId}) => _http.send(
        '/api/operations/evidences/$id/link-drive/',
        data: {'file_id': fileId},
        parse: OpsEvidence.fromJson,
      );
}
