import 'package:nereus_app/core/json_util.dart';

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
      created: asString(json['created']),
    );
  }
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
  final String stockQuantity;

  factory OpsRtsItem.fromJson(Map<String, dynamic> json) {
    return OpsRtsItem(
      id: asString(json['id']),
      product: asString(json['product']),
      productName: asString(json['product_name']),
      productType: asString(json['product_type']),
      quantity: asString(json['quantity']),
      unit: asString(json['unit']),
      status: asString(json['status'], fallback: 'pending'),
      warehouse: asString(json['warehouse']),
      stockQuantity: asString(json['stock_quantity']),
    );
  }
}

class OpsRts {
  const OpsRts({
    required this.id,
    this.workOrder = '',
    this.specialty = '',
    this.status = 'draft',
    this.notes = '',
    this.purchaseOrder = '',
    this.items = const [],
    this.preparedAt = '',
  });

  final String id;
  final String workOrder;
  final String specialty;
  final String status;
  final String notes;
  final String purchaseOrder;
  final List<OpsRtsItem> items;
  final String preparedAt;

  factory OpsRts.fromJson(Map<String, dynamic> json) {
    return OpsRts(
      id: asString(json['id']),
      workOrder: asString(json['work_order']),
      specialty: asString(json['work_order_specialty']),
      status: asString(json['status'], fallback: 'draft'),
      notes: asString(json['notes']),
      purchaseOrder: asString(json['purchase_order']),
      items: asMapList(json['items']).map(OpsRtsItem.fromJson).toList(),
      preparedAt: asString(json['prepared_at']),
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
  final String approvedAt;
  final String sentAt;
  final String driveUrl;

  factory OpsReport.fromJson(Map<String, dynamic> json) {
    return OpsReport(
      id: asString(json['id']),
      project: asString(json['project']),
      version: asString(json['version']),
      status: asString(json['status'], fallback: 'draft'),
      kind: asString(json['kind'], fallback: 'project'),
      specialty: asString(json['specialty']),
      bodyText: _body(json['body']),
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
  return asString(value);
}
