import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';

class OpsFieldCheck {
  const OpsFieldCheck({
    required this.id,
    this.visit = '',
    this.workOrder = '',
    this.activity = '',
    this.projectPoint = '',
    this.result = '',
    this.executionStatus = '',
    this.observation = '',
    this.measurement = '',
    this.pendingReason = '',
    this.pendingOwner = '',
    this.diagnosis = '',
    this.actionsTaken = '',
    this.partsUsed = const [],
    this.created = '',
  });

  final String id;
  final String visit;
  final String workOrder;
  final String activity;
  final String projectPoint;
  final String result;
  final String executionStatus;
  final String observation;
  final String measurement;
  final String pendingReason;
  final String pendingOwner;
  final String diagnosis;
  final String actionsTaken;
  final List<String> partsUsed;
  final String created;

  factory OpsFieldCheck.fromJson(Map<String, dynamic> json) {
    return OpsFieldCheck(
      id: asString(json['id']),
      visit: asString(json['visit']),
      workOrder: asString(json['work_order']),
      activity: asString(json['activity']),
      projectPoint: asString(json['project_point']),
      result: asString(json['result']),
      executionStatus: asString(json['activity_execution_status']),
      observation: asString(json['observation']),
      measurement: asString(json['measurement']),
      pendingReason: asString(json['pending_reason']),
      pendingOwner: asString(json['pending_owner']),
      diagnosis: asString(json['diagnosis']),
      actionsTaken: asString(json['actions_taken']),
      partsUsed: _parts(json['parts_used']),
      created: asString(json['created']),
    );
  }
}

List<String> _parts(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final row in raw)
      if (row is Map)
        [
          asString(row['item']),
          if (asString(row['serial']).isNotEmpty) 'serie ${asString(row['serial'])}',
          if (asString(row['quantity']).isNotEmpty) 'x${asString(row['quantity'])}',
        ].where((part) => part.isNotEmpty).join(' · '),
  ];
}

class OpsEvidence {
  const OpsEvidence({
    required this.id,
    this.visit = '',
    this.workOrder = '',
    this.activity = '',
    this.projectPoint = '',
    this.fieldCheck = '',
    this.file = '',
    this.url = '',
    this.caption = '',
    this.created = '',
  });

  final String id;
  final String visit;
  final String workOrder;
  final String activity;
  final String projectPoint;
  final String fieldCheck;
  final String file;
  final String url;
  final String caption;
  final String created;

  /// Enlace para abrir: el de Drive queda en `url` después de vincular.
  String get link => url.isNotEmpty ? url : file;

  factory OpsEvidence.fromJson(Map<String, dynamic> json) {
    return OpsEvidence(
      id: asString(json['id']),
      visit: asString(json['visit']),
      workOrder: asString(json['work_order']),
      activity: asString(json['activity']),
      projectPoint: asString(json['project_point']),
      fieldCheck: asString(json['field_check']),
      file: asString(json['file']),
      url: asString(json['url']),
      caption: asString(json['caption']),
      created: asString(json['created']),
    );
  }
}

class OpsRtsItem {
  const OpsRtsItem({
    required this.id,
    this.product = '',
    this.productName = '',
    this.productType = '',
    this.quantity = '',
    this.unit = '',
    this.status = 'pending',
    this.warehouse = '',
    this.warehouseName = '',
    this.stockQuantity = '',
  });

  final String id;
  final String product;
  final String productName;
  final String productType;
  final String quantity;
  final String unit;
  final String status;
  final String warehouse;
  final String warehouseName;
  final String stockQuantity;

  String get stockLine {
    final line = '$quantity $unit · stock $stockQuantity'.trim();
    if (warehouseName.isEmpty) return line;
    return '$line · $warehouseName';
  }

  factory OpsRtsItem.fromJson(Map<String, dynamic> json) {
    return OpsRtsItem(
      id: asString(json['id']),
      product: asString(json['product']),
      productName: asString(json['product_name']),
      productType: asString(json['product_type']),
      quantity: asString(json['quantity']),
      unit: asString(json['unit']),
      status: asString(json['status'], fallback: 'pending'),
      warehouse: opsRefId(json['warehouse']),
      warehouseName: _warehouseName(json),
      stockQuantity: asString(json['stock_quantity']),
    );
  }
}

String _warehouseName(Map<String, dynamic> json) {
  final named = opsReadableName(json['warehouse_name']);
  if (named.isNotEmpty) return named;
  final warehouse = json['warehouse'];
  if (warehouse is Map) return opsReadableName(warehouse);
  if (warehouse is String && int.tryParse(warehouse.trim()) == null) {
    return warehouse.trim();
  }
  return '';
}

class OpsRts {
  const OpsRts({
    required this.id,
    this.workOrder = '',
    this.specialty = '',
    this.status = 'draft',
    this.notes = '',
    this.purchaseOrder = '',
    this.purchaseOrderNumber = '',
    this.supplierName = '',
    this.items = const [],
    this.preparedAt = '',
  });

  final String id;
  final String workOrder;
  final String specialty;
  final String status;
  final String notes;
  final String purchaseOrder;
  final String purchaseOrderNumber;
  final String supplierName;
  final List<OpsRtsItem> items;
  final String preparedAt;

  /// Número y proveedor. Si el JSON solo trae el id, no se muestra.
  String get purchaseCaption {
    if (purchaseOrderNumber.isEmpty) {
      return purchaseOrder.isEmpty ? '' : 'Orden de compra vinculada';
    }
    if (supplierName.isEmpty) return purchaseOrderNumber;
    return '$purchaseOrderNumber · $supplierName';
  }

  factory OpsRts.fromJson(Map<String, dynamic> json) {
    final linked = _linkedPurchaseOrder(json);
    return OpsRts(
      id: asString(json['id']),
      workOrder: asString(json['work_order']),
      specialty: asString(json['work_order_specialty']),
      status: asString(json['status'], fallback: 'draft'),
      notes: asString(json['notes']),
      purchaseOrder: linked.id,
      purchaseOrderNumber: linked.number,
      supplierName: linked.supplier,
      items: asMapList(json['items']).map(OpsRtsItem.fromJson).toList(),
      preparedAt: asString(json['prepared_at']),
    );
  }
}

class _LinkedPurchaseOrder {
  const _LinkedPurchaseOrder({
    required this.id,
    required this.number,
    required this.supplier,
  });

  final String id;
  final String number;
  final String supplier;
}

_LinkedPurchaseOrder _linkedPurchaseOrder(Map<String, dynamic> json) {
  final raw = json['purchase_order'];
  final nested = raw is Map
      ? raw.map((key, value) => MapEntry('$key', value))
      : const <String, dynamic>{};
  final number = opsReadableName(
    json['purchase_order_number'] ??
        json['order_number'] ??
        nested['order_number'] ??
        nested['number'],
  );
  final supplier = opsReadableName(
    json['supplier_name'] ?? nested['supplier_name'] ?? nested['supplier'],
  );
  return _LinkedPurchaseOrder(
    id: opsRefId(raw),
    number: number,
    supplier: supplier,
  );
}

class OpsReportActivity {
  const OpsReportActivity({
    this.title = '',
    this.specialty = '',
    this.executionStatus = '',
    this.validationStatus = '',
    this.validationNotes = '',
    this.leaderValidationResult = '',
    this.operationsValidationResult = '',
  });

  final String title;
  final String specialty;
  final String executionStatus;
  final String validationStatus;
  final String validationNotes;
  final String leaderValidationResult;
  final String operationsValidationResult;

  factory OpsReportActivity.fromJson(Map<String, dynamic> json) {
    final description = asString(json['description']);
    return OpsReportActivity(
      title: description.isNotEmpty
          ? description
          : asString(json['activity_type']),
      specialty: asString(json['specialty']),
      executionStatus: asString(json['execution_status']),
      validationStatus: asString(json['validation_status']),
      validationNotes: asString(json['validation_notes']),
      leaderValidationResult: asString(json['leader_validation_result']),
      operationsValidationResult: asString(json['operations_validation_result']),
    );
  }
}

class OpsReportPerformedTest {
  const OpsReportPerformedTest({
    this.result = '',
    this.measurement = '',
    this.observation = '',
    this.diagnosis = '',
    this.actionsTaken = '',
    this.partsUsed = '',
  });

  final String result;
  final String measurement;
  final String observation;
  final String diagnosis;
  final String actionsTaken;
  final String partsUsed;

  factory OpsReportPerformedTest.fromJson(Map<String, dynamic> json) {
    return OpsReportPerformedTest(
      result: asString(json['result']),
      measurement: asString(json['measurement']),
      observation: asString(json['observation']),
      diagnosis: asString(json['diagnosis']),
      actionsTaken: asString(json['actions_taken']),
      partsUsed: _parts(json['parts_used']).join(', '),
    );
  }
}

class OpsReportEvidenceRow {
  const OpsReportEvidenceRow({this.caption = '', this.url = ''});

  final String caption;
  final String url;

  factory OpsReportEvidenceRow.fromJson(Map<String, dynamic> json) {
    return OpsReportEvidenceRow(
      caption: asString(json['caption']),
      url: asString(json['url']),
    );
  }
}

class OpsReportPendingWork {
  const OpsReportPendingWork({
    this.description = '',
    this.status = '',
    this.responsible = '',
  });

  final String description;
  final String status;
  final String responsible;

  factory OpsReportPendingWork.fromJson(Map<String, dynamic> json) {
    return OpsReportPendingWork(
      description: asString(json['description']),
      status: asString(json['status']),
      responsible: asString(json['responsible']),
    );
  }
}

class OpsReport {
  const OpsReport({
    required this.id,
    this.project = '',
    this.version = '',
    this.status = 'draft',
    this.kind = 'project',
    this.specialty = '',
    this.bodyText = '',
    this.activities = const [],
    this.testsPerformed = const [],
    this.evidences = const [],
    this.pendingClientWork = const [],
    this.approvedAt = '',
    this.sentAt = '',
    this.driveUrl = '',
  });

  final String id;
  final String project;
  final String version;
  final String status;
  final String kind;
  final String specialty;
  final String bodyText;
  final List<OpsReportActivity> activities;
  final List<OpsReportPerformedTest> testsPerformed;
  final List<OpsReportEvidenceRow> evidences;
  final List<OpsReportPendingWork> pendingClientWork;
  final String approvedAt;
  final String sentAt;
  final String driveUrl;

  bool get hasSnapshot =>
      activities.isNotEmpty ||
      testsPerformed.isNotEmpty ||
      evidences.isNotEmpty ||
      pendingClientWork.isNotEmpty;

  factory OpsReport.fromJson(Map<String, dynamic> json) {
    return OpsReport(
      id: asString(json['id']),
      project: asString(json['project']),
      version: asString(json['version']),
      status: asString(json['status'], fallback: 'draft'),
      kind: asString(json['kind'], fallback: 'project'),
      specialty: asString(json['specialty']),
      bodyText: _body(json['body']),
      activities: _reportRows(
        json['body'],
        'activities',
        OpsReportActivity.fromJson,
      ),
      testsPerformed: _reportRows(
        json['body'],
        'tests_performed',
        OpsReportPerformedTest.fromJson,
      ),
      evidences: _reportRows(
        json['body'],
        'evidences',
        OpsReportEvidenceRow.fromJson,
      ),
      pendingClientWork: _reportRows(
        json['body'],
        'pending_client_work',
        OpsReportPendingWork.fromJson,
      ),
      approvedAt: asString(json['approved_at']),
      sentAt: asString(json['sent_at']),
      driveUrl: asString(json['drive_url']),
    );
  }
}

String _body(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map) {
    final text = asString(value['text'] ?? value['body'] ?? value['resumen']);
    if (text.isNotEmpty) return text;
  }
  return '';
}

List<T> _reportRows<T>(
  dynamic body,
  String key,
  T Function(Map<String, dynamic> json) parse,
) {
  final map = asMap(body);
  return [for (final row in asMapList(map[key])) parse(row)];
}
