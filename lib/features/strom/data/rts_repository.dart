import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';

class RtsRepository {
  RtsRepository(this._http);

  final OpsHttp _http;
  static const _root = '/api/operations/rts/';

  Future<List<OpsRts>> list({String? workOrder, String? status}) {
    return _http.getList(
      _root,
      OpsRts.fromJson,
      query: {
        if (workOrder != null) 'work_order': workOrder,
        if (status != null) 'status': status,
      },
    );
  }

  Future<OpsRts> get(String id) => _http.getOne('$_root$id/', OpsRts.fromJson);

  Future<OpsRts> create({
    required int workOrderId,
    String notes = '',
    required List<Map<String, dynamic>> items,
  }) {
    return _http.send(
      _root,
      data: {
        'work_order_id': workOrderId,
        'notes': notes,
        'items': items,
      },
      parse: OpsRts.fromJson,
    );
  }

  Future<OpsRts> prepare(String id, {List<int>? itemIds}) =>
      _act(id, 'prepare', itemIds);

  /// La reserva descuenta el stock de la sucursal una sola vez.
  Future<OpsRts> reserve(String id, {List<int>? itemIds}) =>
      _act(id, 'reserve', itemIds);

  Future<OpsRts> issue(String id, {List<int>? itemIds}) => _act(id, 'issue', itemIds);

  Future<OpsRts> linkPurchaseOrder(
    String id, {
    required String purchaseOrderId,
    int? receptionId,
  }) {
    return _http.send(
      '$_root$id/link-purchase-order/',
      data: {
        'purchase_order_id': purchaseOrderId,
        'reception_id': receptionId,
      },
      parse: OpsRts.fromJson,
    );
  }

  Future<OpsRts> _act(String id, String action, List<int>? itemIds) {
    return _http.send(
      '$_root$id/$action/',
      data: {if (itemIds != null) 'item_ids': itemIds},
      parse: OpsRts.fromJson,
    );
  }
}
