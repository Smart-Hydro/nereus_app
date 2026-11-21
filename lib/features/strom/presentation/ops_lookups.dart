import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/features/strom/data/ops_contract.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

/// Listados con `?search=` y filtro por padre. Un 404 deja la lista vacía.
class OpsLookups {
  OpsLookups(this.ref);

  final WidgetRef ref;

  OpsHttp get _http => OpsHttp(ref.read(dioProvider));

  OpsChoiceLoader get projects => _projects;

  Future<List<OpsChoice>> _projects(String query) async {
    try {
      final rows = await ref
          .read(projectsRepositoryProvider)
          .list(
            search: query.isEmpty ? null : query,
          );
      return [
        for (final row in rows)
          if (_hit(query, row.name, row.code))
            OpsChoice(id: row.id, label: row.name, detail: row.code),
      ];
    } on ApiError catch (error) {
      if (query.isNotEmpty && _retryable(error)) {
        return _projects('');
      }
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  OpsChoiceLoader orders({String? project}) => (query) async {
    final rows = await _guard(
      () => ref.read(workOrdersRepositoryProvider).list(project: project),
    );
    return [
      for (final row in rows)
        if (_hit(
          query,
          specialtyLabel(row.specialty),
          workOrderStatusLabel(row.status),
        ))
          OpsChoice(
            id: row.id,
            label: 'OT ${specialtyLabel(row.specialty)}',
            detail: workOrderStatusLabel(row.status),
          ),
    ];
  };

  OpsChoiceLoader visits({String? workOrder}) => (query) async {
    final rows = await _guard(
      () => ref.read(visitsRepositoryProvider).list(workOrder: workOrder),
    );
    return [
      for (final row in rows)
        if (_hit(
          query,
          visitTypeLabel(row.visitType),
          row.scheduledFor,
          row.notes,
        ))
          OpsChoice(
            id: row.id,
            label: 'Visita ${visitTypeLabel(row.visitType).toLowerCase()}',
            detail: row.scheduledFor.isEmpty
                ? visitStatusLabel(row.status)
                : row.scheduledFor,
          ),
    ];
  };

  OpsChoiceLoader activities({String? workOrder}) => (query) async {
    final rows = await _guard(
      () => ref.read(activitiesRepositoryProvider).list(workOrder: workOrder),
    );
    return [
      for (final row in rows)
        if (_hit(query, row.description, specialtyLabel(row.specialty)))
          OpsChoice(
            id: row.id,
            label: row.description.isEmpty ? 'Actividad' : row.description,
            detail: specialtyLabel(row.specialty),
          ),
    ];
  };

  OpsChoiceLoader get installations => (query) async {
    final rows = await _guard(
      () => ref.read(installationsRepositoryProvider).list(),
    );
    return [
      for (final row in rows)
        if (_hit(query, row.name, row.code, row.location))
          OpsChoice(id: row.id, label: row.name, detail: row.location),
    ];
  };

  OpsChoiceLoader get equipment => (query) async {
    final rows = await _guard(
      () => ref.read(installationsRepositoryProvider).equipment(),
    );
    return [
      for (final row in rows)
        if (_hit(query, row.modelName, row.serial))
          OpsChoice(
            id: row.id,
            label: row.modelName.isEmpty ? 'Equipo instalado' : row.modelName,
            detail: row.serial,
          ),
    ];
  };

  OpsChoiceLoader get crew => _crew;

  Future<List<OpsChoice>> _crew(String query) async {
    try {
      final rows = await ref
          .read(visitsRepositoryProvider)
          .crew(
            search: query.isEmpty ? null : query,
          );
      return [
        for (final row in rows)
          OpsChoice(
            id: row.id,
            label: row.name,
            detail: specialtyLabel(row.specialty),
          ),
      ];
    } on ApiError catch (error) {
      if (query.isNotEmpty && _retryable(error)) return _crew('');
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  OpsChoiceLoader get reports => (query) async {
    final rows = await _guard(() => ref.read(reportsRepositoryProvider).list());
    return [
      for (final row in rows)
        if (_hit(query, row.version, specialtyLabel(row.specialty)))
          OpsChoice(
            id: row.id,
            label: 'Informe versión ${row.version}',
            detail: opsLabel(row.status, reportStatusLabels),
          ),
    ];
  };

  OpsChoiceLoader rts({String? workOrder}) => (query) async {
    final rows = await _guard(
      () => ref.read(rtsRepositoryProvider).list(workOrder: workOrder),
    );
    return [
      for (final row in rows)
        if (_hit(query, row.notes, specialtyLabel(row.specialty)))
          OpsChoice(
            id: row.id,
            label: 'RTS ${specialtyLabel(row.specialty)}',
            detail: opsLabel(row.status, rtsStatusLabels),
          ),
    ];
  };

  OpsChoiceLoader get points =>
      (query) => _catalog(
        '/api/iot-telemetry/devices/',
        query,
        labelKey: 'name',
        detailKey: 'address',
        emptyLabel: 'Punto de captación',
      );

  OpsChoiceLoader get products =>
      (query) => _catalog(
        '/api/inventory/products/',
        query,
        labelKey: 'name',
        detailKey: 'code',
        emptyLabel: 'Producto',
      );

  OpsChoiceLoader get clients =>
      (query) => _catalog(
        '/api/customers/clients/',
        query,
        labelKey: 'name',
        emptyLabel: 'Cliente',
      );

  OpsChoiceLoader get users => _users;

  Future<List<OpsChoice>> _users(String query) async {
    try {
      final rows = await _http.getList(
        '/api/operations/assignable-users/',
        (json) => json,
        query: {if (query.isNotEmpty) 'search': query},
      );
      return [
        for (final row in rows)
          if (_hit(query, asString(row['name']), asString(row['email'])))
            OpsChoice(
              id: _idOf(row, 'user_id'),
              label: _label(row, 'name', null, 'Persona'),
              detail: _roleLabel(asString(row['role_code'])),
            ),
      ];
    } on ApiError catch (error) {
      if (query.isNotEmpty && _retryable(error)) return _users('');
      if (error.statusCode != 404 && error.statusCode != 405) rethrow;
    }
    return _catalog(
      '/api/branches/users/',
      query,
      idKey: 'user',
      labelKey: 'user_name',
      detailKey: 'role_name',
      emptyLabel: 'Persona',
    );
  }

  String _roleLabel(String code) {
    return switch (code) {
      'STROM_LIDER_HIDRAULICA' => 'Líder hidráulica',
      'STROM_LIDER_ELECTRICA' => 'Líder eléctrica',
      _ => '',
    };
  }

  OpsChoiceLoader get tickets =>
      (query) => _catalog(
        '/api/support/tickets/',
        query,
        labelKey: 'subject',
        detailKey: 'ticket_number',
        emptyLabel: 'Ticket',
      );

  OpsChoiceLoader get quotations =>
      (query) => _catalog(
        '/api/sales/quotations/',
        query,
        labelKey: 'order_number',
        detailKey: 'observation',
        altLabelKey: 'title',
        emptyLabel: 'Cotización',
      );

  /// OC de proveedor: número y proveedor. Filtro de proyecto y sucursal.
  /// Un 404 (listado aún no publicado) deja el aviso, sin campo de id.
  OpsChoiceLoader purchaseOrders({String? project}) =>
      (query) => _purchaseOrders(query, project: project);

  Future<List<OpsChoice>> _purchaseOrders(
    String query, {
    String? project,
  }) async {
    final branch = _branchId();
    try {
      final rows = await _purchaseOrderRows(
        search: query,
        project: project,
        branch: branch,
      );
      return [
        for (final row in rows)
          if (_purchaseVisible(
            row,
            query: query,
            project: project,
            branch: branch,
          ))
            _purchaseChoice(row),
      ];
    } on ApiError catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) rethrow;
      if (error.statusCode != 400) rethrow;
      final rows = await _purchaseOrderRows();
      return [
        for (final row in rows)
          if (_purchaseVisible(
            row,
            query: query,
            project: project,
            branch: branch,
          ))
            _purchaseChoice(row),
      ];
    }
  }

  Future<List<Map<String, dynamic>>> _purchaseOrderRows({
    String search = '',
    String? project,
    String? branch,
  }) {
    return _http.getList(
      stromPurchaseOrdersPath,
      (json) => json,
      query: {
        if (search.isNotEmpty) 'search': search,
        if (project != null && project.isNotEmpty) 'project': project,
        if (branch != null && branch.isNotEmpty) 'branch': branch,
      },
    );
  }

  OpsChoice _purchaseChoice(Map<String, dynamic> row) {
    final number = _firstName(row, const ['order_number', 'number', 'code']);
    final supplier = _supplierName(row);
    return OpsChoice(
      id: _idOf(row, 'id'),
      label: number.isEmpty ? 'Orden de compra' : number,
      detail: supplier,
    );
  }

  bool _purchaseVisible(
    Map<String, dynamic> row, {
    required String query,
    String? project,
    String? branch,
  }) {
    if (!_sameRef(row['project'], project)) return false;
    if (!_sameRef(row['branch'], branch)) return false;
    final choice = _purchaseChoice(row);
    return _hit(query, choice.label, choice.detail);
  }

  /// Recepciones de la OC. Null si el listado aún no existe (404 o 405).
  Future<List<OpsChoice>?> receptions(String purchaseOrderId) async {
    try {
      final rows = await _http.getList(
        stromPurchaseOrderReceptionsPath(purchaseOrderId),
        (json) => json,
      );
      return [
        for (final row in rows)
          OpsChoice(
            id: _idOf(row, 'id'),
            label: _receptionLabel(row),
            detail: asString(row['quantity']),
          ),
      ];
    } on ApiError catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) return null;
      rethrow;
    }
  }

  String _receptionLabel(Map<String, dynamic> row) {
    final notes = opsReadableName(row['notes']);
    if (notes.isNotEmpty) return notes;
    final who = opsReadableName(row['received_by_name']);
    if (who.isNotEmpty) return 'Recepción de $who';
    return 'Recepción';
  }

  OpsChoiceLoader get warehouses => _warehouses;

  Future<List<OpsChoice>> _warehouses(String query) async {
    try {
      final rows = await _http.getList(
        stromWarehousesPath,
        (json) => json,
        query: {if (query.isNotEmpty) 'search': query},
      );
      return [
        for (final row in rows)
          if (row['is_active'] != false &&
              _hit(
                query,
                opsReadableName(row['name']),
                asString(row['location']),
              ))
            OpsChoice(
              id: _idOf(row, 'id'),
              label: _label(row, 'name', null, 'Bodega'),
              detail: row['is_default'] == true
                  ? 'Por defecto'
                  : asString(row['location']),
            ),
      ];
    } on ApiError catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) rethrow;
      if (query.isNotEmpty && error.statusCode == 400) return _warehouses('');
      rethrow;
    }
  }

  String? _branchId() {
    final id = ref.read(sessionControllerProvider).branchId;
    if (id == null || id.isEmpty) return null;
    return id;
  }

  String _firstName(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final name = opsReadableName(row[key]);
      if (name.isNotEmpty) return name;
    }
    return '';
  }

  String _supplierName(Map<String, dynamic> row) {
    final direct = opsReadableName(row['supplier_name']);
    if (direct.isNotEmpty) return direct;
    final supplier = row['supplier'];
    if (supplier is Map) return opsReadableName(supplier);
    return '';
  }

  /// Si la fila no trae la referencia, no se descarta: el servidor ya filtró.
  bool _sameRef(dynamic raw, String? expected) {
    if (expected == null || expected.isEmpty) return true;
    final id = opsRefId(raw);
    if (id.isEmpty) return true;
    return id == expected;
  }

  Future<List<T>> _guard<T>(Future<List<T>> Function() load) async {
    try {
      return await load();
    } on ApiError catch (error) {
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<List<OpsChoice>> _catalog(
    String path,
    String query, {
    String idKey = 'id',
    required String labelKey,
    String? detailKey,
    String? altLabelKey,
    required String emptyLabel,
  }) async {
    Future<List<OpsChoice>> read({bool search = true}) async {
      final rows = await _http.getList(
        path,
        (json) => json,
        query: {if (search && query.isNotEmpty) 'search': query},
      );
      return [
        for (final row in rows)
          if (_hit(
            query,
            asString(row[labelKey]),
            asString(row[altLabelKey]),
            asString(row[detailKey]),
          ))
            OpsChoice(
              id: _idOf(row, idKey),
              label: _label(row, labelKey, altLabelKey, emptyLabel),
              detail: detailKey == null ? '' : asString(row[detailKey]),
            ),
      ];
    }

    try {
      return await read();
    } on ApiError catch (error) {
      if (query.isNotEmpty && _retryable(error)) {
        try {
          return await read(search: false);
        } on ApiError catch (again) {
          if (again.statusCode == 404) return const [];
          rethrow;
        }
      }
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  String _idOf(Map<String, dynamic> row, String idKey) {
    final raw = row[idKey];
    if (raw == null || '$raw'.isEmpty) return asString(row['id']);
    return asString(raw);
  }

  String _label(
    Map<String, dynamic> row,
    String labelKey,
    String? altLabelKey,
    String emptyLabel,
  ) {
    final main = asString(row[labelKey]);
    if (main.isNotEmpty) return main;
    if (altLabelKey != null) {
      final alt = asString(row[altLabelKey]);
      if (alt.isNotEmpty) return alt;
    }
    final name = asString(row['name']);
    return name.isEmpty ? emptyLabel : name;
  }

  bool _hit(String query, String a, [String b = '', String c = '']) {
    if (query.trim().isEmpty) return true;
    final blob = '$a $b $c'.toLowerCase();
    return blob.contains(query.trim().toLowerCase());
  }

  bool _retryable(ApiError error) =>
      error.statusCode == 400 || error.statusCode == 404;
}
