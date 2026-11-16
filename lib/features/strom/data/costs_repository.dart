import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';

class CostsRepository {
  CostsRepository(this._http);

  final OpsHttp _http;

  Future<List<OpsDailyCost>> daily({String? specialty}) {
    return _http.getList(
      '/api/operations/crew-daily-costs/',
      OpsDailyCost.fromJson,
      query: {if (specialty != null) 'specialty': specialty},
    );
  }

  Future<OpsDailyCost> createDaily({
    required String amount,
    required String validFrom,
    String specialty = '',
  }) {
    return _http.send(
      '/api/operations/crew-daily-costs/',
      data: {
        'specialty': specialty,
        'amount': amount,
        'valid_from': validFrom,
      },
      parse: OpsDailyCost.fromJson,
    );
  }

  Future<OpsDailyCost> updateDaily(
    String id, {
    String? amount,
    String? validFrom,
    String? specialty,
  }) {
    return _http.send(
      '/api/operations/crew-daily-costs/$id/',
      method: 'PATCH',
      data: {
        if (amount != null) 'amount': amount,
        if (validFrom != null) 'valid_from': validFrom,
        if (specialty != null) 'specialty': specialty,
      },
      parse: OpsDailyCost.fromJson,
    );
  }

  Future<OpsProjectCost> projectCost(String projectId) {
    return _http.getOne(
      '/api/operations/projects/$projectId/cost/',
      OpsProjectCost.fromJson,
    );
  }

  Future<OpsCostRow> workOrderCost(String workOrderId) {
    return _http.getOne(
      '/api/operations/work-orders/$workOrderId/cost/',
      OpsCostRow.fromJson,
    );
  }
}
