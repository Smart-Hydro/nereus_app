import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
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

  OpsChoiceLoader get purchaseOrders =>
      (query) => _catalog(
        '/api/inventory/purchase-orders/',
        query,
        labelKey: 'number',
        detailKey: 'supplier_name',
        emptyLabel: 'Orden de compra',
        altLabelKey: 'name',
      );

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
