import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';

/// Proyecto de operaciones. El id llega como int o string.
class OpsProject {
  const OpsProject({
    required this.id,
    required this.name,
    this.code = '',
    this.serviceType = 'project',
    this.status = 'preparation',
    this.statusReason = '',
    this.committedOn = '',
    this.owner = '',
    this.clientPoNumber = '',
    this.clientPoReceivedOn = '',
    this.quotation = '',
    this.ticket = '',
    this.isActive = true,
    this.milestones = const [],
    this.openClarifications = const [],
    this.created = '',
    this.modified = '',
    this.kildeHandoff,
  });

  final String id;
  final String name;
  final String code;
  final String serviceType;
  final String status;
  final String statusReason;
  final String committedOn;
  final String owner;
  final String clientPoNumber;
  final String clientPoReceivedOn;
  final String quotation;
  final String ticket;
  final bool isActive;
  final List<OpsMilestone> milestones;
  final List<OpsOpenClarification> openClarifications;
  final String created;
  final String modified;
  final KildeHandoff? kildeHandoff;

  bool get looksLikeSupport => serviceType == 'support';

  factory OpsProject.fromJson(Map<String, dynamic> json) {
    return OpsProject(
      id: asString(json['id']),
      name: asString(json['name']),
      code: asString(json['code']),
      serviceType: asString(json['service_type'], fallback: 'project'),
      status: asString(json['status'], fallback: 'preparation'),
      statusReason: asString(json['status_reason']),
      committedOn: opsDay(json['committed_on']),
      owner: asString(json['owner']),
      clientPoNumber: asString(json['client_po_number']),
      clientPoReceivedOn: opsDay(json['client_po_received_on']),
      quotation: asString(json['quotation']),
      ticket: asString(json['ticket']),
      isActive: opsBool(json['is_active'], fallback: true),
      milestones: asMapList(json['milestones'])
          .map(OpsMilestone.fromJson)
          .toList(),
      openClarifications: asMapList(json['open_clarifications'])
          .map(OpsOpenClarification.fromJson)
          .toList(),
      created: asString(json['created']),
      modified: asString(json['modified']),
      kildeHandoff: _kildeHandoff(json),
    );
  }
}

KildeHandoff? _kildeHandoff(Map<String, dynamic> json) {
  final raw = json['kilde_handoff'];
  if (raw is! Map) return null;
  final merged = Map<String, dynamic>.from(raw);
  if (merged['client'] == null && json['client'] != null) {
    merged['client'] = json['client'];
  }
  if (merged['client_name'] == null && json['client_name'] != null) {
    merged['client_name'] = json['client_name'];
  }
  if (merged['quotation'] == null && json['quotation'] is Map) {
    merged['quotation'] = json['quotation'];
  }
  return KildeHandoff.fromJson(merged);
}

class OpsOpenClarification {
  const OpsOpenClarification({
    required this.id,
    this.text = '',
    this.askedBy = '',
    this.created = '',
  });

  final String id;
  final String text;
  final String askedBy;
  final String created;

  factory OpsOpenClarification.fromJson(Map<String, dynamic> json) {
    return OpsOpenClarification(
      id: asString(json['id']),
      text: asString(json['text']),
      askedBy: asString(json['asked_by']),
      created: asString(json['created']),
    );
  }
}

class OpsMilestone {
  const OpsMilestone({
    required this.id,
    this.kind = '',
    this.occurredOn = '',
    this.source = '',
    this.recordedBy = '',
    this.created = '',
  });

  final String id;
  final String kind;
  final String occurredOn;
  final String source;
  final String recordedBy;
  final String created;

  factory OpsMilestone.fromJson(Map<String, dynamic> json) {
    return OpsMilestone(
      id: asString(json['id']),
      kind: asString(json['kind']),
      occurredOn: opsDay(json['occurred_on']),
      source: asString(json['source']),
      recordedBy: asString(json['recorded_by']),
      created: asString(json['created']),
    );
  }
}

class OpsScopeItem {
  const OpsScopeItem({
    required this.id,
    this.sourceKey = '',
    this.activity = '',
    this.specialty = '',
    this.mandatory = true,
    this.status = 'pending_technical',
  });

  final String id;
  final String sourceKey;
  final String activity;
  final String specialty;
  final bool mandatory;
  final String status;

  factory OpsScopeItem.fromJson(Map<String, dynamic> json) {
    return OpsScopeItem(
      id: asString(json['id']),
      sourceKey: asString(json['source_key']),
      activity: asString(json['activity']),
      specialty: asString(json['specialty']),
      mandatory: opsBool(json['mandatory'], fallback: true),
      status: asString(json['status'], fallback: 'pending_technical'),
    );
  }
}

class OpsScopePoint {
  const OpsScopePoint({
    required this.id,
    this.device = '',
    this.deviceName = '',
    this.deviceType = '',
    this.quotationText = '',
    this.items = const [],
  });

  final String id;
  final String device;
  final String deviceName;
  final String deviceType;
  final String quotationText;
  final List<OpsScopeItem> items;

  String get pointLabel =>
      deviceName.isEmpty ? 'Punto de captación' : deviceName;

  factory OpsScopePoint.fromJson(Map<String, dynamic> json) {
    return OpsScopePoint(
      id: asString(json['id']),
      device: opsRefId(json['device']),
      deviceName: _scopeDeviceName(json),
      deviceType: asString(json['device_type']),
      quotationText: asString(json['quotation_text']),
      items: asMapList(json['items']).map(OpsScopeItem.fromJson).toList(),
    );
  }
}

/// Nombre del punto que trae el GET de alcance. Nunca el id del dispositivo.
String _scopeDeviceName(Map<String, dynamic> json) {
  final named = opsReadableName(json['device_name']);
  if (named.isNotEmpty) return named;
  final device = json['device'];
  if (device is Map) {
    final nested = opsReadableName(device['name'] ?? device['device_name']);
    if (nested.isNotEmpty) return nested;
  }
  return '';
}

class OpsInstallation {
  const OpsInstallation({
    required this.id,
    required this.name,
    this.code = '',
    this.client = '',
    this.location = '',
    this.accessRequirements = '',
    this.deviceIds = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final String code;
  final String client;
  final String location;
  final String accessRequirements;
  final List<String> deviceIds;
  final bool isActive;

  factory OpsInstallation.fromJson(Map<String, dynamic> json) {
    final rawIds = json['device_ids'];
    return OpsInstallation(
      id: asString(json['id']),
      name: asString(json['name']),
      code: asString(json['code']),
      client: asString(json['client']),
      location: asString(json['location']),
      accessRequirements: asString(json['access_requirements']),
      deviceIds: rawIds is List
          ? [for (final id in rawIds) asString(id)]
          : const [],
      isActive: opsBool(json['is_active'], fallback: true),
    );
  }
}

class OpsEquipment {
  const OpsEquipment({
    required this.id,
    this.projectPoint = '',
    this.deviceId = '',
    this.product = '',
    this.modelName = '',
    this.serial = '',
    this.workOrder = '',
    this.activity = '',
    this.validFrom = '',
    this.validUntil = '',
    this.removedAt = '',
    this.replacedBy = '',
    this.isCurrent = false,
  });

  final String id;
  final String projectPoint;
  final String deviceId;
  final String product;
  final String modelName;
  final String serial;
  final String workOrder;
  final String activity;
  final String validFrom;
  final String validUntil;
  final String removedAt;
  final String replacedBy;
  final bool isCurrent;

  factory OpsEquipment.fromJson(Map<String, dynamic> json) {
    return OpsEquipment(
      id: asString(json['id']),
      projectPoint: asString(json['project_point']),
      deviceId: asString(json['device_id']),
      product: asString(json['product']),
      modelName: asString(json['model_name']),
      serial: asString(json['serial']),
      workOrder: asString(json['work_order']),
      activity: asString(json['activity']),
      validFrom: asString(json['valid_from']),
      validUntil: asString(json['valid_until']),
      removedAt: asString(json['removed_at']),
      replacedBy: asString(json['replaced_by']),
      isCurrent: opsBool(json['is_current']),
    );
  }
}

class OpsSiteRequirement {
  const OpsSiteRequirement({
    required this.id,
    this.project = '',
    this.visit = '',
    this.kind = '',
    this.status = 'pending',
    this.notes = '',
  });

  final String id;
  final String project;
  final String visit;
  final String kind;
  final String status;
  final String notes;

  factory OpsSiteRequirement.fromJson(Map<String, dynamic> json) {
    return OpsSiteRequirement(
      id: asString(json['id']),
      project: asString(json['project']),
      visit: asString(json['visit']),
      kind: asString(json['kind']),
      status: asString(json['status'], fallback: 'pending'),
      notes: asString(json['notes']),
    );
  }
}

class OpsObligation {
  const OpsObligation({
    required this.id,
    this.workOrder = '',
    this.visit = '',
    this.activity = '',
    this.description = '',
    this.status = 'pending',
    this.responsible = '',
    this.notes = '',
  });

  final String id;
  final String workOrder;
  final String visit;
  final String activity;
  final String description;
  final String status;
  final String responsible;
  final String notes;

  factory OpsObligation.fromJson(Map<String, dynamic> json) {
    return OpsObligation(
      id: asString(json['id']),
      workOrder: asString(json['work_order']),
      visit: asString(json['visit']),
      activity: asString(json['activity']),
      description: asString(json['description']),
      status: asString(json['status'], fallback: 'pending'),
      responsible: asString(json['responsible']),
      notes: asString(json['notes']),
    );
  }
}
