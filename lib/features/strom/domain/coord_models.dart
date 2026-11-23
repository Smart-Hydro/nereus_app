import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/features/strom/domain/ops_parse.dart';

class OpsClarification {
  const OpsClarification({
    required this.id,
    this.project = '',
    this.text = '',
    this.status = 'open',
    this.answer = '',
    this.answeredAt = '',
    this.created = '',
  });

  final String id;
  final String project;
  final String text;
  final String status;
  final String answer;
  final String answeredAt;
  final String created;

  factory OpsClarification.fromJson(Map<String, dynamic> json) {
    return OpsClarification(
      id: asString(json['id']),
      project: asString(json['project']),
      text: asString(json['text']),
      status: asString(json['status'], fallback: 'open'),
      answer: asString(json['answer']),
      answeredAt: asString(json['answered_at']),
      created: asString(json['created']),
    );
  }
}

class OpsOutOfScope {
  const OpsOutOfScope({
    required this.id,
    this.project = '',
    this.description = '',
    this.decision = 'pending',
    this.decisionReason = '',
    this.decidedAt = '',
    this.resultingWorkOrder = '',
    this.resultingProject = '',
    this.specialty = '',
  });

  final String id;
  final String project;
  final String description;
  final String decision;
  final String decisionReason;
  final String decidedAt;
  final String resultingWorkOrder;
  final String resultingProject;
  final String specialty;

  factory OpsOutOfScope.fromJson(Map<String, dynamic> json) {
    return OpsOutOfScope(
      id: asString(json['id']),
      project: asString(json['project']),
      description: asString(json['description']),
      decision: asString(json['decision'], fallback: 'pending'),
      decisionReason: asString(json['decision_reason']),
      decidedAt: asString(json['decided_at']),
      resultingWorkOrder: asString(json['resulting_work_order']),
      resultingProject: asString(json['resulting_project']),
      specialty: asString(json['specialty']),
    );
  }
}

class OpsDailyCost {
  const OpsDailyCost({
    required this.id,
    this.specialty = '',
    this.amount = '',
    this.validFrom = '',
  });

  final String id;
  final String specialty;
  final String amount;
  final String validFrom;

  /// El vigente es el de `valid_from` más reciente, ya aplicado por el backend.
  factory OpsDailyCost.fromJson(Map<String, dynamic> json) {
    return OpsDailyCost(
      id: asString(json['id']),
      specialty: asString(json['specialty']),
      amount: asString(json['amount']),
      validFrom: opsDay(json['valid_from']),
    );
  }
}

class OpsCostRow {
  const OpsCostRow({
    this.workOrderId = '',
    this.projectId = '',
    this.specialty = '',
    this.visitsPerformed = 0,
    this.dailyCost = '',
    this.total = '',
  });

  final String workOrderId;
  final String projectId;
  final String specialty;
  final int visitsPerformed;
  final String dailyCost;
  final String total;

  factory OpsCostRow.fromJson(Map<String, dynamic> json) {
    return OpsCostRow(
      workOrderId: asString(json['work_order_id']),
      projectId: asString(json['project_id']),
      specialty: asString(json['specialty']),
      visitsPerformed: asInt(json['visits_performed']),
      dailyCost: asString(json['daily_cost']),
      total: asString(json['total']),
    );
  }
}

class OpsProjectCost {
  const OpsProjectCost({
    this.projectId = '',
    this.total = '',
    this.workOrders = const [],
  });

  final String projectId;
  final String total;
  final List<OpsCostRow> workOrders;

  factory OpsProjectCost.fromJson(Map<String, dynamic> json) {
    return OpsProjectCost(
      projectId: asString(json['project_id']),
      total: asString(json['total']),
      workOrders: asMapList(json['work_orders'])
          .map(OpsCostRow.fromJson)
          .toList(),
    );
  }
}

class OpsIndicatorTarget {
  const OpsIndicatorTarget({
    required this.id,
    this.kpiCode = 'kpi_9',
    this.category = '',
    this.capturePointsMin = 1,
    this.capturePointsMax = '',
    this.targetCalendarDays = '',
    this.notes = '',
  });

  final String id;
  final String kpiCode;
  final String category;
  final int capturePointsMin;
  final String capturePointsMax;
  final String targetCalendarDays;
  final String notes;

  factory OpsIndicatorTarget.fromJson(Map<String, dynamic> json) {
    return OpsIndicatorTarget(
      id: asString(json['id']),
      kpiCode: asString(json['kpi_code'], fallback: 'kpi_9'),
      category: asString(json['category']),
      capturePointsMin: asInt(json['capture_points_min'], fallback: 1),
      capturePointsMax: asString(json['capture_points_max']),
      targetCalendarDays: asString(json['target_calendar_days']),
      notes: asString(json['notes']),
    );
  }
}

class OpsConfigurableIndicator {
  const OpsConfigurableIndicator({
    required this.id,
    this.name = '',
    this.startEvent = '',
    this.endEvent = '',
    this.dayType = 'calendar',
    this.deductPauses = true,
  });

  final String id;
  final String name;
  final String startEvent;
  final String endEvent;
  final String dayType;
  final bool deductPauses;

  factory OpsConfigurableIndicator.fromJson(Map<String, dynamic> json) {
    return OpsConfigurableIndicator(
      id: asString(json['id']),
      name: asString(json['name']),
      startEvent: asString(json['start_event']),
      endEvent: asString(json['end_event']),
      dayType: asString(json['day_type'], fallback: 'calendar'),
      deductPauses: opsBool(json['deduct_pauses'], fallback: true),
    );
  }
}

class OpsAlert {
  const OpsAlert({
    required this.id,
    this.indicatorName = '',
    this.projectName = '',
    this.value = '',
    this.target = '',
    this.severity = '',
    this.status = 'open',
    this.message = '',
  });

  final String id;
  final String indicatorName;
  final String projectName;
  final String value;
  final String target;
  final String severity;
  final String status;
  final String message;

  factory OpsAlert.fromJson(Map<String, dynamic> json) {
    return OpsAlert(
      id: asString(json['id']),
      indicatorName: asString(json['indicator_name']),
      projectName: asString(json['project_name']),
      value: asString(json['value']),
      target: asString(json['target']),
      severity: asString(json['severity']),
      status: asString(json['status'], fallback: 'open'),
      message: asString(json['message']),
    );
  }
}

class OpsTransition {
  const OpsTransition({
    required this.id,
    this.entityType = '',
    this.entityId = '',
    this.fromValue = '',
    this.toValue = '',
    this.reason = '',
    this.scopeVersion = '',
    this.actor = '',
    this.occurredAt = '',
  });

  final String id;
  final String entityType;
  final String entityId;
  final String fromValue;
  final String toValue;
  final String reason;
  final String scopeVersion;
  final String actor;
  final String occurredAt;

  factory OpsTransition.fromJson(Map<String, dynamic> json) {
    return OpsTransition(
      id: asString(json['id']),
      entityType: asString(json['entity_type']),
      entityId: asString(json['entity_id']),
      fromValue: asString(json['from_value']),
      toValue: asString(json['to_value']),
      reason: asString(json['reason']),
      scopeVersion: asString(json['scope_version']),
      actor: asString(json['actor']),
      occurredAt: asString(json['occurred_at']),
    );
  }
}

class OpsDashboard {
  const OpsDashboard({
    this.timezone = '',
    this.kpis = const {},
    this.delayProjects = const [],
    this.delayOrders = const [],
  });

  final String timezone;
  final Map<String, dynamic> kpis;
  final List<Map<String, dynamic>> delayProjects;
  final List<Map<String, dynamic>> delayOrders;

  factory OpsDashboard.fromJson(Map<String, dynamic> json) {
    final delays = asMap(json['delays']);
    final kpis = <String, dynamic>{};
    for (final entry in json.entries) {
      if (entry.key.startsWith('kpi_')) kpis[entry.key] = entry.value;
    }
    return OpsDashboard(
      timezone: asString(json['timezone']),
      kpis: kpis,
      delayProjects: asMapList(delays['projects']),
      delayOrders: asMapList(delays['work_orders']),
    );
  }
}
