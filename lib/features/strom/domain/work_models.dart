import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';

class OpsWorkOrder {
  const OpsWorkOrder({
    required this.id,
    this.project = '',
    this.serviceType = '',
    this.specialty = '',
    this.status = 'suggested',
    this.blockReason = '',
    this.cancelReason = '',
    this.confirmedAt = '',
    this.scopeVersion = '',
    this.commercialReference = '',
    this.pendingScopeChanges = 0,
    this.created = '',
  });

  final String id;
  final String project;
  final String serviceType;
  final String specialty;
  final String status;
  final String blockReason;
  final String cancelReason;
  final String confirmedAt;
  final String scopeVersion;
  final String commercialReference;
  final int pendingScopeChanges;
  final String created;

  factory OpsWorkOrder.fromJson(Map<String, dynamic> json) {
    return OpsWorkOrder(
      id: asString(json['id']),
      project: asString(json['project']),
      serviceType: asString(json['service_type']),
      specialty: asString(json['specialty']),
      status: asString(json['status'], fallback: 'suggested'),
      blockReason: asString(json['block_reason']),
      cancelReason: asString(json['cancel_reason']),
      confirmedAt: asString(json['confirmed_at']),
      scopeVersion: asString(json['scope_version']),
      commercialReference: asString(json['commercial_reference']),
      pendingScopeChanges: asInt(json['pending_scope_changes']),
      created: asString(json['created']),
    );
  }
}

class OpsScopeChange {
  const OpsScopeChange({
    required this.id,
    this.kind = '',
    this.device = '',
    this.sourceKey = '',
    this.activity = '',
    this.specialty = '',
    this.mandatory = true,
    this.status = 'pending',
    this.decidedAt = '',
  });

  final String id;
  final String kind;
  final String device;
  final String sourceKey;
  final String activity;
  final String specialty;
  final bool mandatory;
  final String status;
  final String decidedAt;

  factory OpsScopeChange.fromJson(Map<String, dynamic> json) {
    return OpsScopeChange(
      id: asString(json['id']),
      kind: asString(json['kind']),
      device: asString(json['device']),
      sourceKey: asString(json['source_key']),
      activity: asString(json['activity']),
      specialty: asString(json['specialty']),
      mandatory: opsBool(json['mandatory'], fallback: true),
      status: asString(json['status'], fallback: 'pending'),
      decidedAt: asString(json['decided_at']),
    );
  }
}

class OpsCrewMember {
  const OpsCrewMember({
    required this.id,
    required this.name,
    this.company = '',
    this.specialty = '',
    this.contact = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String company;
  final String specialty;
  final String contact;
  final bool isActive;

  factory OpsCrewMember.fromJson(Map<String, dynamic> json) {
    return OpsCrewMember(
      id: asString(json['id']),
      name: asString(json['name']),
      company: asString(json['company']),
      specialty: asString(json['specialty']),
      contact: asString(json['contact']),
      isActive: opsBool(json['is_active'], fallback: true),
    );
  }
}

class OpsReschedule {
  const OpsReschedule({
    required this.id,
    this.previousDate = '',
    this.newDate = '',
    this.reason = '',
    this.created = '',
  });

  final String id;
  final String previousDate;
  final String newDate;
  final String reason;
  final String created;

  factory OpsReschedule.fromJson(Map<String, dynamic> json) {
    return OpsReschedule(
      id: asString(json['id']),
      previousDate: opsDay(json['previous_date']),
      newDate: opsDay(json['new_date']),
      reason: asString(json['reason']),
      created: asString(json['created']),
    );
  }
}

class OpsVisit {
  const OpsVisit({
    required this.id,
    this.workOrder = '',
    this.project = '',
    this.specialty = '',
    this.visitType = 'planned',
    this.isRework = false,
    this.status = 'proposed',
    this.scheduledFor = '',
    this.startedAt = '',
    this.finishedAt = '',
    this.notes = '',
    this.cancelReason = '',
    this.crew = const [],
    this.reschedules = const [],
    this.siteWarnings = const [],
    this.rtsWarnings = const [],
  });

  final String id;
  final String workOrder;
  final String project;
  final String specialty;
  final String visitType;
  final bool isRework;
  final String status;
  final String scheduledFor;
  final String startedAt;
  final String finishedAt;
  final String notes;
  final String cancelReason;
  final List<OpsCrewMember> crew;
  final List<OpsReschedule> reschedules;
  final List<String> siteWarnings;
  final List<String> rtsWarnings;

  factory OpsVisit.fromJson(Map<String, dynamic> json) {
    return OpsVisit(
      id: asString(json['id']),
      workOrder: asString(json['work_order']),
      project: asString(json['project']),
      specialty: asString(json['specialty']),
      visitType: asString(json['visit_type'], fallback: 'planned'),
      isRework: opsBool(json['is_rework']),
      status: asString(json['status'], fallback: 'proposed'),
      scheduledFor: opsDay(json['scheduled_for']),
      startedAt: asString(json['started_at']),
      finishedAt: asString(json['finished_at']),
      notes: asString(json['notes']),
      cancelReason: asString(json['cancel_reason']),
      crew: asMapList(json['crew']).map(OpsCrewMember.fromJson).toList(),
      reschedules: asMapList(json['reschedules']).map(OpsReschedule.fromJson).toList(),
      siteWarnings: opsMessages(json['site_requirement_warnings']),
      rtsWarnings: opsMessages(json['rts_warnings']),
    );
  }
}

class OpsActivity {
  const OpsActivity({
    required this.id,
    this.workOrder = '',
    this.specialty = '',
    this.projectPoint = '',
    this.device = '',
    this.scopeItem = '',
    this.description = '',
    this.origin = '',
    this.mandatory = false,
    this.executionStatus = 'pending',
    this.notDoneReason = '',
    this.validationStatus = 'pending',
    this.validationNotes = '',
  });

  final String id;
  final String workOrder;
  final String specialty;
  final String projectPoint;
  final String device;
  final String scopeItem;
  final String description;
  final String origin;
  final bool mandatory;
  final String executionStatus;
  final String notDoneReason;
  final String validationStatus;
  final String validationNotes;

  factory OpsActivity.fromJson(Map<String, dynamic> json) {
    return OpsActivity(
      id: asString(json['id']),
      workOrder: asString(json['work_order']),
      specialty: asString(json['specialty']),
      projectPoint: asString(json['project_point']),
      device: asString(json['device']),
      scopeItem: asString(json['scope_item']),
      description: asString(json['description']),
      origin: asString(json['origin']),
      mandatory: opsBool(json['mandatory']),
      executionStatus: asString(json['execution_status'], fallback: 'pending'),
      notDoneReason: asString(json['not_done_reason']),
      validationStatus: asString(json['validation_status'], fallback: 'pending'),
      validationNotes: asString(json['validation_notes']),
    );
  }
}

class OpsStatusChange {
  const OpsStatusChange({
    required this.id,
    this.activity = '',
    this.visit = '',
    this.fromStatus = '',
    this.toStatus = '',
    this.reason = '',
    this.changedAt = '',
  });

  final String id;
  final String activity;
  final String visit;
  final String fromStatus;
  final String toStatus;
  final String reason;
  final String changedAt;

  factory OpsStatusChange.fromJson(Map<String, dynamic> json) {
    return OpsStatusChange(
      id: asString(json['id']),
      activity: asString(json['activity']),
      visit: asString(json['visit']),
      fromStatus: asString(json['from_status']),
      toStatus: asString(json['to_status']),
      reason: asString(json['reason']),
      changedAt: asString(json['changed_at']),
    );
  }
}
