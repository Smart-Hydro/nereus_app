import 'package:flutter/material.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/theme/tokens.dart';

/// Etapas del flujo comercial Kilde. El API las siembra por sucursal;
/// la app las crea por la misma API solo si el tablero está vacío.
const defaultWaterStages =
    <
      ({
        String name,
        int probability,
        String color,
        bool closed,
        bool won,
      })
    >[
      (
        name: 'Prospección',
        probability: 10,
        color: '#0F766E',
        closed: false,
        won: false,
      ),
      (
        name: 'Captación',
        probability: 20,
        color: '#0284C7',
        closed: false,
        won: false,
      ),
      (
        name: 'Levantamiento',
        probability: 35,
        color: '#0369A1',
        closed: false,
        won: false,
      ),
      (
        name: 'Cotización',
        probability: 50,
        color: '#D97706',
        closed: false,
        won: false,
      ),
      (
        name: 'Negociación/Cierre',
        probability: 70,
        color: '#C2410C',
        closed: false,
        won: false,
      ),
      (
        name: 'Reunión técnico-comercial',
        probability: 85,
        color: '#7C3AED',
        closed: false,
        won: false,
      ),
      (
        name: 'Reunión de programación',
        probability: 95,
        color: '#4F46E5',
        closed: false,
        won: false,
      ),
      (
        name: 'Ganada',
        probability: 100,
        color: '#15803D',
        closed: true,
        won: true,
      ),
      (
        name: 'Perdida',
        probability: 0,
        color: '#E11D48',
        closed: true,
        won: false,
      ),
    ];

const leadStatusLabels = <String, String>{
  'NEW': 'Nuevo',
  'CONTACTED': 'Contactado',
  'QUALIFIED': 'Calificado',
  'CONVERTED': 'Cliente',
  'LOST': 'Perdido',
  'ARCHIVED': 'Archivado',
};

String leadStatusLabel(String code) => leadStatusLabels[code] ?? code;

const activityTypeLabels = <String, String>{
  'CALL': 'Llamada',
  'EMAIL': 'Correo',
  'MEETING': 'Reunión',
  'NOTE': 'Nota',
  'TASK': 'Tarea',
  'QUOTE': 'Cotización',
  'STAGE_CHANGE': 'Cambio de etapa',
  'OTHER': 'Otro',
  'survey_resolution': 'Reunión de levantamiento',
  'tech_commercial_handoff': 'Reunión técnico-comercial',
  'install_planning': 'Programación de instalación',
  'strom_install': 'Hito Strøm: instalación',
  'strom_commissioning': 'Hito Strøm: puesta en marcha',
  'strom_handover': 'Hito Strøm: entrega',
  'strom_ikolu_training': 'Hito Strøm: capacitación Ikolu',
};

String activityTypeLabel(String code) => activityTypeLabels[code] ?? code;

String clp(num value) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${rounded < 0 ? '-' : ''}\$$buffer';
}

Color colorFromHex(String? hex, {Color fallback = NereusTokens.teal}) {
  final raw = (hex ?? '').replaceAll('#', '').trim();
  if (raw.length != 6) return fallback;
  final value = int.tryParse(raw, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
}

@immutable
class LeadSourceItem {
  const LeadSourceItem({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? description;
  final String? color;
  final bool isActive;

  factory LeadSourceItem.fromJson(Map<String, dynamic> json) => LeadSourceItem(
    id: asString(json['id']),
    name: asString(json['name'], fallback: 'Fuente'),
    description: asStringOrNull(json['description']),
    color: asStringOrNull(json['color']),
    isActive: json['is_active'] != false,
  );
}

@immutable
class FollowUpCategoryItem {
  const FollowUpCategoryItem({
    required this.id,
    required this.name,
    this.color,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? color;
  final int order;
  final bool isActive;

  factory FollowUpCategoryItem.fromJson(Map<String, dynamic> json) =>
      FollowUpCategoryItem(
        id: asString(json['id']),
        name: asString(json['name'], fallback: 'Categoría'),
        color: asStringOrNull(json['color']),
        order: asInt(json['order']),
        isActive: json['is_active'] != false,
      );
}

@immutable
class OpportunityStageItem {
  const OpportunityStageItem({
    required this.id,
    required this.name,
    this.description,
    this.order = 0,
    this.probability = 0,
    this.color,
    this.isClosed = false,
    this.isWon = false,
  });

  final String id;
  final String name;
  final String? description;
  final int order;
  final double probability;
  final String? color;
  final bool isClosed;
  final bool isWon;

  bool get isLost => isClosed && !isWon;

  factory OpportunityStageItem.fromJson(Map<String, dynamic> json) =>
      OpportunityStageItem(
        id: asString(json['id']),
        name: asString(json['name'], fallback: 'Etapa'),
        description: asStringOrNull(json['description']),
        order: asInt(json['order']),
        probability: asDoubleOrNull(json['probability']) ?? 0,
        color: asStringOrNull(json['color']),
        isClosed: json['is_closed'] == true,
        isWon: json['is_won'] == true,
      );
}

@immutable
class OpportunityItem {
  const OpportunityItem({
    required this.id,
    required this.title,
    this.description,
    this.stageId,
    this.stageName,
    this.clientId,
    this.clientName,
    this.leadId,
    this.leadName,
    this.estimatedValue = 0,
    this.actualValue = 0,
    this.weightedValue = 0,
    this.expectedCloseDate,
    this.closedAt,
    this.assignedToName,
    this.nextActionAt,
    this.nextActionType,
    this.surveyId,
    this.lostReasonId,
    this.lostReasonName,
    this.lostReasonText,
    this.probability = 0,
  });

  final String id;
  final String title;
  final String? description;
  final String? stageId;
  final String? stageName;
  final String? clientId;
  final String? clientName;
  final String? leadId;
  final String? leadName;
  final double estimatedValue;
  final double actualValue;
  final double weightedValue;
  final String? expectedCloseDate;
  final DateTime? closedAt;
  final String? assignedToName;
  final String? nextActionAt;
  final String? nextActionType;
  final String? surveyId;
  final String? lostReasonId;
  final String? lostReasonName;
  final String? lostReasonText;
  final double probability;

  String? get nextActionLabel {
    final type = nextActionType;
    if (type == null || type.isEmpty) return null;
    final when = nextActionAt;
    final name = activityTypeLabel(type);
    if (when == null || when.length < 10) return name;
    return '$name · ${when.substring(0, 10)}';
  }

  String? get notes => description;
  bool get isWon => (stageName ?? '').toLowerCase().contains('ganad');
  bool get isLost => (stageName ?? '').toLowerCase().contains('perdid');

  factory OpportunityItem.fromJson(Map<String, dynamic> json) {
    final stage = json['stage'];
    final client = json['client'];
    final lead = json['lead'];
    final assigned = json['assigned_to'];
    final lost = json['lost_reason'];
    return OpportunityItem(
      id: asString(json['id']),
      title: asString(json['title'], fallback: 'Oportunidad'),
      description: asStringOrNull(json['description'] ?? json['notes']),
      stageId: stage is Map
          ? asStringOrNull(stage['id'])
          : asStringOrNull(stage),
      stageName:
          asStringOrNull(json['stage_name']) ??
          (stage is Map ? asStringOrNull(stage['name']) : null),
      clientId: client is Map
          ? asStringOrNull(client['id'])
          : asStringOrNull(client),
      clientName:
          asStringOrNull(json['client_name']) ??
          (client is Map ? asStringOrNull(client['name']) : null),
      leadId: lead is Map ? asStringOrNull(lead['id']) : asStringOrNull(lead),
      leadName:
          asStringOrNull(json['lead_name']) ??
          (lead is Map ? asStringOrNull(lead['full_name']) : null),
      estimatedValue: asDoubleOrNull(json['estimated_value']) ?? 0,
      actualValue: asDoubleOrNull(json['actual_value']) ?? 0,
      weightedValue: asDoubleOrNull(json['weighted_value']) ?? 0,
      expectedCloseDate: asStringOrNull(json['expected_close_date']),
      closedAt: asDateTime(json['closed_at']),
      assignedToName:
          asStringOrNull(json['assigned_to_name']) ??
          (assigned is Map
              ? (asStringOrNull(assigned['full_name']) ??
                    asStringOrNull(assigned['username']))
              : null),
      nextActionAt: json['next_action'] is Map
          ? asStringOrNull((json['next_action'] as Map)['at'])
          : null,
      nextActionType: json['next_action'] is Map
          ? asStringOrNull((json['next_action'] as Map)['type'])
          : null,
      surveyId: asStringOrNull(json['survey_id']),
      lostReasonId: lost is Map
          ? asStringOrNull(lost['id'])
          : asStringOrNull(lost),
      lostReasonName: lost is Map ? asStringOrNull(lost['name']) : null,
      lostReasonText: asStringOrNull(json['lost_reason_text']),
      probability: stage is Map
          ? (asDoubleOrNull(stage['probability']) ?? 0)
          : (asDoubleOrNull(json['probability']) ?? 0),
    );
  }
}

@immutable
class LeadItem {
  const LeadItem({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.company,
    this.status = 'NEW',
    this.score = 0,
    this.sourceId,
    this.sourceName,
    this.sourceDetail,
    this.assignedToName,
    this.notes,
    this.convertedClientId,
    this.requirementOutcome,
    this.requirementText,
    this.noRequirementReason,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String status;
  final int score;
  final String? sourceId;
  final String? sourceName;
  final String? sourceDetail;
  final String? assignedToName;
  final String? notes;
  final String? convertedClientId;
  final String? requirementOutcome;
  final String? requirementText;
  final String? noRequirementReason;

  String get name {
    final full = '$firstName ${lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : (company ?? 'Prospecto');
  }

  bool get canConvert =>
      (status == 'CONTACTED' || status == 'QUALIFIED') &&
      requirementOutcome == 'with_requirement';

  bool get notContacted =>
      requirementOutcome == null ||
      requirementOutcome!.isEmpty ||
      requirementOutcome == 'not_contacted';

  factory LeadItem.fromJson(Map<String, dynamic> json) {
    final converted = json['converted_to_client'];
    final source = json['source'];
    final assigned = json['assigned_to'];
    return LeadItem(
      id: asString(json['id']),
      firstName: asString(json['first_name'], fallback: 'Prospecto'),
      lastName: asStringOrNull(json['last_name']),
      email: asStringOrNull(json['email']),
      phone: asStringOrNull(json['phone']),
      company: asStringOrNull(json['company']),
      status: asString(json['status'], fallback: 'NEW'),
      score: asInt(json['score']),
      sourceId: source is Map
          ? asStringOrNull(source['id'])
          : asStringOrNull(source),
      sourceName:
          asStringOrNull(json['source_name']) ??
          (source is Map ? asStringOrNull(source['name']) : null),
      sourceDetail: asStringOrNull(json['source_detail']),
      assignedToName:
          asStringOrNull(json['assigned_to_name']) ??
          (assigned is Map
              ? (asStringOrNull(assigned['full_name']) ??
                    asStringOrNull(assigned['username']))
              : null),
      notes: asStringOrNull(json['notes']),
      convertedClientId: converted is Map
          ? asStringOrNull(converted['id'])
          : asStringOrNull(converted),
      requirementOutcome: asStringOrNull(json['requirement_outcome']),
      requirementText: asStringOrNull(json['requirement_text']),
      noRequirementReason: asStringOrNull(json['no_requirement_reason']),
    );
  }
}

@immutable
class FollowUpItem {
  const FollowUpItem({
    required this.id,
    required this.description,
    this.activityType = 'NOTE',
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.scheduledAt,
    this.completedAt,
    this.isCompleted = false,
    this.createdByName,
    this.assignedToName,
    this.opportunityId,
  });

  final String id;
  final String description;
  final String activityType;
  final String? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final String? createdByName;
  final String? assignedToName;
  final String? opportunityId;

  factory FollowUpItem.fromJson(Map<String, dynamic> json) {
    final cat = json['category'];
    final opportunity = json['opportunity'];
    return FollowUpItem(
      id: asString(json['id']),
      description: asString(json['description']),
      activityType: asString(json['activity_type'], fallback: 'NOTE'),
      categoryId: cat is Map ? asStringOrNull(cat['id']) : asStringOrNull(cat),
      categoryName: asStringOrNull(json['category_name']),
      categoryColor: asStringOrNull(json['category_color']),
      scheduledAt: asDateTime(json['scheduled_at']),
      completedAt: asDateTime(json['completed_at']),
      isCompleted: json['is_completed'] == true,
      createdByName: asStringOrNull(json['created_by_name']),
      assignedToName: asStringOrNull(json['assigned_to_name']),
      opportunityId: opportunity is Map
          ? asStringOrNull(opportunity['id'])
          : asStringOrNull(opportunity),
    );
  }
}

@immutable
class ProposalItem {
  const ProposalItem({
    required this.id,
    this.productId,
    this.productName,
    this.serviceId,
    this.serviceName,
    this.quantity = 1,
    this.unitPrice = 0,
    this.discount = 0,
    this.totalPrice = 0,
    this.notes,
  });

  final String id;
  final String? productId;
  final String? productName;
  final String? serviceId;
  final String? serviceName;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double totalPrice;
  final String? notes;

  String get label {
    final name = productName ?? serviceName;
    if (name != null && name.isNotEmpty) return name;
    if (notes != null && notes!.isNotEmpty) return notes!;
    return 'Ítem de propuesta';
  }

  factory ProposalItem.fromJson(Map<String, dynamic> json) {
    final prod = json['product'];
    final srv = json['service'];
    return ProposalItem(
      id: asString(json['id']),
      productId: prod is Map
          ? asStringOrNull(prod['id'])
          : asStringOrNull(prod),
      productName: asStringOrNull(json['product_name']),
      serviceId: srv is Map ? asStringOrNull(srv['id']) : asStringOrNull(srv),
      serviceName: asStringOrNull(json['service_name']),
      quantity: asDoubleOrNull(json['quantity']) ?? 1,
      unitPrice: asDoubleOrNull(json['unit_price']) ?? 0,
      discount: asDoubleOrNull(json['discount']) ?? 0,
      totalPrice: asDoubleOrNull(json['total_price']) ?? 0,
      notes: asStringOrNull(json['notes']),
    );
  }
}

@immutable
class CrmDashboardSummary {
  const CrmDashboardSummary({
    this.newLeads = 0,
    this.convertedLeads = 0,
    this.openOpportunities = 0,
    this.openValue = 0,
    this.openWeightedValue = 0,
    this.wonCount = 0,
    this.wonValue = 0,
    this.completedActivities = 0,
    this.overdueActivities = 0,
    this.todayActivities = 0,
    this.totalCustomers = 0,
  });

  final int newLeads;
  final int convertedLeads;
  final int openOpportunities;
  final double openValue;
  final double openWeightedValue;
  final int wonCount;
  final double wonValue;
  final int completedActivities;
  final int overdueActivities;
  final int todayActivities;
  final int totalCustomers;

  int get activitiesDueToday => todayActivities;

  factory CrmDashboardSummary.fromJson(Map<String, dynamic> json) {
    final leads = asMap(json['leads']);
    final opps = asMap(json['opportunities']);
    final acts = asMap(json['activities']);
    final cust = asMap(json['customers']);
    return CrmDashboardSummary(
      newLeads: asInt(leads['new']),
      convertedLeads: asInt(leads['converted']),
      openOpportunities: asInt(opps['open_count']),
      openValue: asDoubleOrNull(opps['open_value']) ?? 0,
      openWeightedValue: asDoubleOrNull(opps['open_weighted']) ?? 0,
      wonCount: asInt(opps['won_count']),
      wonValue: asDoubleOrNull(opps['won_value']) ?? 0,
      completedActivities: asInt(acts['completed']),
      overdueActivities: asInt(acts['overdue']),
      todayActivities: asInt(acts['today']),
      totalCustomers: asInt(cust['total']),
    );
  }
}

@immutable
class KildeIndicators {
  const KildeIndicators({
    this.contacted = 0,
    this.withRequirement = 0,
    this.withoutRequirement = 0,
    this.notContacted = 0,
    this.quotesWithResponse = 0,
    this.quotesWithoutResponse = 0,
    this.quotesAccepted = 0,
    this.quotesObjected = 0,
    this.quotesRejected = 0,
    this.salesCount = 0,
    this.salesNet = 0,
    this.weighted = 0,
    this.missingNext = 0,
    this.overdue = 0,
    this.openRfis = 0,
    this.periodLabel,
  });

  final int contacted;
  final int withRequirement;
  final int withoutRequirement;
  final int notContacted;
  final int quotesWithResponse;
  final int quotesWithoutResponse;
  final int quotesAccepted;
  final int quotesObjected;
  final int quotesRejected;
  final int salesCount;
  final double salesNet;
  final double weighted;
  final int missingNext;
  final int overdue;
  final int openRfis;
  final String? periodLabel;

  factory KildeIndicators.fromJson(Map<String, dynamic> json) {
    final period = json['period'];
    final prospects = json['prospects'] is Map
        ? Map<String, dynamic>.from(json['prospects'] as Map)
        : const <String, dynamic>{};
    final quotes = json['quotations'] is Map
        ? Map<String, dynamic>.from(json['quotations'] as Map)
        : const <String, dynamic>{};
    final rejected = quotes['rejected'] is Map
        ? Map<String, dynamic>.from(quotes['rejected'] as Map)
        : const <String, dynamic>{};
    final sales = json['sales'] is Map
        ? Map<String, dynamic>.from(json['sales'] as Map)
        : const <String, dynamic>{};
    final funnel = json['funnel'] is Map
        ? Map<String, dynamic>.from(json['funnel'] as Map)
        : const <String, dynamic>{};
    return KildeIndicators(
      contacted: asInt(prospects['contacted']),
      withRequirement: asInt(prospects['with_requirement']),
      withoutRequirement: asInt(prospects['without_requirement']),
      notContacted: asInt(prospects['not_contacted']),
      quotesWithResponse: asInt(quotes['with_response']),
      quotesWithoutResponse: asInt(quotes['without_response']),
      quotesAccepted: asInt(quotes['accepted']),
      quotesObjected: asInt(quotes['objected']),
      quotesRejected: asInt(rejected['count']),
      salesCount: asInt(sales['count']),
      salesNet: asDoubleOrNull(sales['net_total']) ?? 0,
      weighted: asDoubleOrNull(funnel['weighted_value']) ?? 0,
      missingNext: asInt(json['missing_next_action']),
      overdue: asInt(json['overdue_activities']),
      openRfis: _openRfiCount(json['open_rfis']),
      periodLabel: period is Map
          ? '${asString(period['start'])} – ${asString(period['end'])}'
          : null,
    );
  }

  static int _openRfiCount(Object? raw) {
    if (raw is List) {
      var total = 0;
      for (final row in raw) {
        if (row is Map && row['count'] != null) {
          total += asInt(row['count']);
        } else {
          total += 1;
        }
      }
      return total;
    }
    return asInt(raw);
  }
}

@immutable
class KildeMember {
  const KildeMember({
    required this.userId,
    this.name,
    this.openOpportunities = 0,
    this.weightedValue = 0,
    this.missingNext = 0,
    this.overdue = 0,
    this.wonPeriod = 0,
    this.weekActivities = 0,
    this.todayAgenda = const [],
  });

  final String userId;
  final String? name;
  final int openOpportunities;
  final double weightedValue;
  final int missingNext;
  final int overdue;
  final int wonPeriod;
  final int weekActivities;
  final List<String> todayAgenda;

  String get label =>
      (name != null && name!.isNotEmpty) ? name! : 'Ejecutivo $userId';

  factory KildeMember.fromJson(Map<String, dynamic> json) {
    final agenda = json['today_agenda'];
    return KildeMember(
      userId: asString(json['user_id'], fallback: '—'),
      name:
          asStringOrNull(json['name']) ??
          asStringOrNull(json['username']) ??
          asStringOrNull(json['full_name']),
      openOpportunities: asInt(json['open_opportunities']),
      weightedValue: asDoubleOrNull(json['weighted_value']) ?? 0,
      missingNext: asInt(json['missing_next_action']),
      overdue: asInt(json['overdue_activities']),
      wonPeriod: asInt(json['won_period']),
      weekActivities: asInt(json['week_activities']),
      todayAgenda: [
        if (agenda is List)
          for (final row in agenda)
            if (row is Map)
              [
                activityTypeLabel(asString(row['activity_type'])),
                asString(row['description']),
              ].where((part) => part.isNotEmpty).join(' · '),
      ],
    );
  }
}

@immutable
class KildeRenewal {
  const KildeRenewal({
    required this.id,
    required this.title,
    this.clientName,
    this.clientId,
    this.endDate,
    this.contractNumber,
    this.contractType,
    this.autoRenewal = false,
  });

  final String id;
  final String title;
  final String? clientName;
  final String? clientId;
  final String? endDate;
  final String? contractNumber;
  final String? contractType;
  final bool autoRenewal;

  factory KildeRenewal.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    return KildeRenewal(
      id: asString(json['id']),
      title: asString(json['title'], fallback: 'Contrato'),
      clientName:
          asStringOrNull(json['client_name']) ??
          (client is Map ? asStringOrNull(client['name']) : null),
      clientId:
          asStringOrNull(json['client_id']) ??
          (client is Map ? asStringOrNull(client['id']) : null),
      endDate: asStringOrNull(json['end_date']),
      contractNumber: asStringOrNull(json['contract_number']),
      contractType: asStringOrNull(json['contract_type']),
      autoRenewal: json['auto_renewal'] == true,
    );
  }
}

@immutable
class KildeRfi {
  const KildeRfi({
    required this.id,
    required this.question,
    this.number,
    this.status = 'open',
    this.blocking = false,
    this.answer,
    this.reopenReason,
    this.assignedToId,
    this.assignedToName,
    this.quotationId,
    this.opportunityId,
  });

  final String id;
  final String question;
  final String? number;
  final String status;
  final bool blocking;
  final String? answer;
  final String? reopenReason;
  final String? assignedToId;
  final String? assignedToName;
  final String? quotationId;
  final String? opportunityId;

  bool get isOpen => status != 'closed' && status != 'answered';

  factory KildeRfi.fromJson(Map<String, dynamic> json) {
    final assigned = json['assigned_to'];
    final assignedMap = assigned is Map
        ? Map<String, dynamic>.from(assigned)
        : null;
    return KildeRfi(
      id: asString(json['id']),
      question: asString(json['question'], fallback: 'Consulta'),
      number: asStringOrNull(json['number']),
      status: asString(json['status'], fallback: 'open'),
      blocking: json['is_blocking'] == true,
      answer: asStringOrNull(json['answer']),
      reopenReason: asStringOrNull(json['reopen_reason']),
      assignedToId: assignedMap != null
          ? asStringOrNull(assignedMap['id'])
          : asStringOrNull(assigned),
      assignedToName: assignedMap != null
          ? asStringOrNull(assignedMap['full_name']) ??
                asStringOrNull(assignedMap['username'])
          : asStringOrNull(json['assigned_to_name']),
      quotationId: asStringOrNull(json['quotation']),
      opportunityId: asStringOrNull(json['opportunity']),
    );
  }
}

@immutable
class QuoteLine {
  const QuoteLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

@immutable
class QuoteDraft {
  const QuoteDraft({
    required this.clientId,
    required this.clientName,
    required this.glosa,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.validUntil,
  });

  final String clientId;
  final String clientName;
  final String glosa;
  final double quantity;
  final double unitPrice;
  final String? productId;
  final String? validUntil;

  double get total => quantity * unitPrice;
}

@immutable
class KildeQuote {
  const KildeQuote({
    required this.id,
    required this.number,
    this.status = '',
    this.discountStatus = '',
    this.poNumber,
    this.total = 0,
    this.version = 1,
    this.validUntil,
    this.objection,
    this.rejectionReason,
    this.receptionConfirmed = false,
    this.responseOn,
    this.opportunityId,
    this.parentId,
    this.immutable = false,
    this.poReceivedOn,
    this.poNet,
    this.poFile,
    this.clientName,
    this.observation,
    this.lines = const [],
  });

  final String id;
  final String number;
  final String status;
  final String discountStatus;
  final String? poNumber;
  final double total;
  final int version;
  final String? validUntil;
  final String? objection;
  final String? rejectionReason;
  final bool receptionConfirmed;
  final String? responseOn;
  final String? opportunityId;
  final String? parentId;
  final bool immutable;
  final String? poReceivedOn;
  final double? poNet;
  final String? poFile;
  final String? clientName;
  final String? observation;
  final List<QuoteLine> lines;

  bool get acceptedWithPo =>
      status == 'accepted' &&
      poNumber != null &&
      poNumber!.isNotEmpty &&
      poNet != null;

  factory KildeQuote.fromJson(Map<String, dynamic> json) {
    final opportunity = json['opportunity'];
    final parent = json['parent_quotation'];
    final client = json['client'];
    final lines = _quoteLines(json['products']);
    final parsedTotal = asDoubleOrNull(json['total_amount']) ?? 0;
    final lineTotal = lines.fold<double>(0, (sum, line) => sum + line.total);
    return KildeQuote(
      id: asString(json['id']),
      number: asString(json['order_number'], fallback: 'Cotización'),
      status: asString(json['kilde_quote_status']),
      discountStatus: asString(json['discount_approval_status']),
      poNumber: asStringOrNull(json['client_po_number']),
      total: parsedTotal == 0 && lineTotal > 0 ? lineTotal : parsedTotal,
      version: asInt(json['version']) == 0 ? 1 : asInt(json['version']),
      validUntil: asStringOrNull(json['valid_until']),
      objection: asStringOrNull(json['objection']),
      rejectionReason: asStringOrNull(json['rejection_reason']),
      receptionConfirmed: json['reception_confirmed'] == true,
      responseOn: asStringOrNull(json['response_on']),
      opportunityId: opportunity is Map
          ? asStringOrNull(opportunity['id'])
          : asStringOrNull(opportunity),
      parentId: parent is Map
          ? asStringOrNull(parent['id'])
          : asStringOrNull(parent),
      immutable: json['is_immutable'] == true,
      poReceivedOn: asStringOrNull(json['client_po_received_on']),
      poNet: asDoubleOrNull(json['client_po_net_amount']),
      poFile: asStringOrNull(json['client_po_file']),
      clientName: client is Map
          ? asStringOrNull(client['name'])
          : asStringOrNull(json['client_name']),
      observation: asStringOrNull(json['observation']),
      lines: lines,
    );
  }
}

List<QuoteLine> _quoteLines(Object? raw) {
  if (raw is! List) return const [];
  final lines = <QuoteLine>[];
  for (final item in raw) {
    if (item is! Map) continue;
    lines.add(
      QuoteLine(
        name: asString(
          item['product_name'] ?? item['name'] ?? item['notes'],
          fallback: 'Ítem',
        ),
        quantity: asDoubleOrNull(item['quantity']) ?? 1,
        unitPrice: asDoubleOrNull(item['unit_price']) ?? 0,
      ),
    );
  }
  return lines;
}

@immutable
class LostReasonItem {
  const LostReasonItem({required this.id, required this.name});

  final String id;
  final String name;

  factory LostReasonItem.fromJson(Map<String, dynamic> json) {
    return LostReasonItem(
      id: asString(json['id']),
      name: asString(json['name'], fallback: 'Motivo'),
    );
  }
}
