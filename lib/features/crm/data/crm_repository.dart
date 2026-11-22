import 'package:dio/dio.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';

/// Fecha civil de hoy en America/Santiago (YYYY-MM-DD).
///
/// Chile continental, regla IANA vigente desde 2019: horario de verano
/// UTC-3 desde el domingo en o después del 2 de septiembre a las 04:00 UTC
/// hasta el domingo en o después del 2 de abril a las 03:00 UTC; el resto
/// del año es UTC-4.
String kildeSantiagoDate([DateTime? now]) {
  final utc = (now ?? DateTime.now()).toUtc();
  final offset = _santiagoIsDaylight(utc)
      ? const Duration(hours: -3)
      : const Duration(hours: -4);
  final local = utc.add(offset);
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime _sundayOnOrAfter(int year, int month, int day) {
  final start = DateTime.utc(year, month, day);
  final delta = (DateTime.sunday - start.weekday) % 7;
  return DateTime.utc(year, month, day + delta);
}

bool _santiagoIsDaylight(DateTime utc) {
  final year = utc.year;
  final start = _sundayOnOrAfter(year, 9, 2).add(const Duration(hours: 4));
  final end = _sundayOnOrAfter(year, 4, 2).add(const Duration(hours: 3));
  return !utc.isBefore(start) || utc.isBefore(end);
}

class CrmRepository {
  CrmRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Never _rethrow(Object error, StackTrace stack) =>
      throw ApiError.fromAny(error, stack);

  Future<CrmDashboardSummary> summary({String? start, String? end}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/crm/dashboard/summary/',
        queryParameters: {
          if (start != null && start.isNotEmpty) 'start': start,
          if (end != null && end.isNotEmpty) 'end': end,
        },
      );
      return CrmDashboardSummary.fromJson(response.data ?? const {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<LeadSourceItem>> leadSources() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/lead-sources/',
        queryParameters: {'page_size': 100, 'ordering': 'name'},
      );
      return asResults(response.data).map(LeadSourceItem.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<LeadSourceItem> createLeadSource({
    required String name,
    String? description,
    String? color,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/lead-sources/',
        data: {
          'name': name,
          if (description != null) 'description': description,
          if (color != null) 'color': color,
        },
      );
      return LeadSourceItem.fromJson(response.data ?? const {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<LeadItem>> leads({
    String? status,
    String? search,
    String? sourceId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/leads/',
        queryParameters: {
          'page_size': 100,
          'ordering': '-created',
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.isNotEmpty) 'search': search,
          if (sourceId != null && sourceId.isNotEmpty) 'source': sourceId,
        },
      );
      return asResults(response.data).map(LeadItem.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<LeadItem> createLead({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? sourceId,
    int score = 0,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/leads/',
        data: {
          'first_name': firstName,
          'last_name': lastName ?? '',
          'email': email ?? '',
          'phone': phone ?? '',
          'company': company ?? '',
          'notes': notes ?? '',
          'status': 'NEW',
          'score': score,
          if (sourceId != null && sourceId.isNotEmpty) 'source': sourceId,
        },
      );
      return LeadItem.fromJson(response.data ?? {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<LeadItem> updateLead({
    required String id,
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? company,
    String? notes,
    String? sourceId,
    String? status,
    int? score,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/crm/leads/$id/',
        data: {
          'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (company != null) 'company': company,
          if (notes != null) 'notes': notes,
          if (sourceId != null) 'source': sourceId.isEmpty ? null : sourceId,
          if (status != null) 'status': status,
          if (score != null) 'score': score,
        },
      );
      return LeadItem.fromJson(response.data ?? {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> deleteLead(String id) async {
    try {
      await _dio.delete<dynamic>('/api/crm/leads/$id/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> setLeadStatus({
    required String id,
    required String status,
    String? noRequirementReason,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/crm/leads/$id/',
        data: {
          'status': status,
          if (noRequirementReason != null && noRequirementReason.isNotEmpty)
            'no_requirement_reason': noRequirementReason,
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<LeadItem> convertLead(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/leads/$id/convert/',
      );
      return LeadItem.fromJson(response.data ?? {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<OpportunityStageItem>> stages() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/opportunity-stages/',
        queryParameters: {'page_size': 100, 'ordering': 'order'},
      );
      return asResults(response.data)
          .map(OpportunityStageItem.fromJson)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> createStage({
    required String name,
    required int order,
    required int probability,
    required String color,
    required bool isClosed,
    required bool isWon,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/opportunity-stages/',
        data: {
          'name': name,
          'order': order,
          'probability': probability,
          'color': color,
          'is_closed': isClosed,
          'is_won': isWon,
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> deleteStage(String id) async {
    try {
      await _dio.delete<dynamic>('/api/crm/opportunity-stages/$id/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> seedWaterStages() async {
    final existing = await stages();
    final names = {for (final s in existing) s.name.toLowerCase().trim()};
    for (var i = 0; i < defaultWaterStages.length; i++) {
      final stage = defaultWaterStages[i];
      if (names.contains(stage.name.toLowerCase())) continue;
      await createStage(
        name: stage.name,
        order: i + 1,
        probability: stage.probability,
        color: stage.color,
        isClosed: stage.closed,
        isWon: stage.won,
      );
    }
  }

  Future<List<OpportunityItem>> opportunities({
    String? clientId,
    String? stageId,
    String? search,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/opportunities/',
        queryParameters: {
          'page_size': 100,
          'ordering': '-created',
          if (clientId != null && clientId.isNotEmpty) 'client': clientId,
          if (stageId != null && stageId.isNotEmpty) 'stage': stageId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return asResults(response.data).map(OpportunityItem.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<OpportunityItem> retrieve(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/crm/opportunities/$id/',
      );
      return OpportunityItem.fromJson(response.data ?? {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<OpportunityItem> createOpportunity({
    required String title,
    required String stageId,
    String? description,
    String? notes,
    String? clientId,
    String? leadId,
    double estimatedValue = 0,
    double actualValue = 0,
    String? expectedCloseDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/opportunities/',
        data: {
          'title': title,
          'stage_id': stageId,
          'description': description ?? notes ?? '',
          'estimated_value': estimatedValue,
          if (actualValue > 0) 'actual_value': actualValue,
          if (clientId != null && clientId.isNotEmpty) 'client': clientId,
          if (leadId != null && leadId.isNotEmpty) 'lead': leadId,
          if (expectedCloseDate != null && expectedCloseDate.isNotEmpty)
            'expected_close_date': expectedCloseDate,
        },
      );
      return OpportunityItem.fromJson(response.data ?? {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<OpportunityItem> updateOpportunity({
    required String id,
    required String title,
    String? stageId,
    String? description,
    String? notes,
    String? clientId,
    double? estimatedValue,
    double? actualValue,
    String? expectedCloseDate,
  }) async {
    try {
      final desc = description ?? notes;
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/crm/opportunities/$id/',
        data: {
          'title': title,
          if (stageId != null && stageId.isNotEmpty) 'stage_id': stageId,
          if (desc != null) 'description': desc,
          if (clientId != null) 'client': clientId.isEmpty ? null : clientId,
          if (estimatedValue != null) 'estimated_value': estimatedValue,
          if (actualValue != null) 'actual_value': actualValue,
          if (expectedCloseDate != null)
            'expected_close_date': expectedCloseDate.isEmpty
                ? null
                : expectedCloseDate,
        },
      );
      return OpportunityItem.fromJson(response.data ?? {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> deleteOpportunity(String id) async {
    try {
      await _dio.delete<dynamic>('/api/crm/opportunities/$id/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> move({
    required String id,
    required String stageId,
    String? lostReasonId,
    String? lostReasonText,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/opportunities/$id/move/',
        data: {
          'stage_id': stageId,
          if (lostReasonId != null && lostReasonId.isNotEmpty)
            'lost_reason_id': lostReasonId,
          if (lostReasonText != null && lostReasonText.isNotEmpty)
            'lost_reason_text': lostReasonText,
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<FollowUpCategoryItem>> followUpCategories() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/follow-up-categories/',
        queryParameters: {'page_size': 100, 'ordering': 'order'},
      );
      return asResults(response.data)
          .map(FollowUpCategoryItem.fromJson)
          .toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<FollowUpItem>> todayActivities() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/opportunity-activities/',
        queryParameters: {'page_size': 100, 'ordering': 'scheduled_at'},
      );
      final today = DateTime.now();
      return [
        for (final item in asResults(response.data).map(FollowUpItem.fromJson))
          if (_isSameDay(item.scheduledAt, today) && !item.isCompleted) item,
      ];
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  bool _isSameDay(DateTime? when, DateTime today) {
    if (when == null) return false;
    final local = when.toLocal();
    return local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
  }

  Future<List<FollowUpItem>> activities(String opportunityId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/opportunity-activities/',
        queryParameters: {
          'opportunity': opportunityId,
          'page_size': 100,
          'ordering': '-created',
        },
      );
      return asResults(response.data).map(FollowUpItem.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> createActivity({
    required String opportunityId,
    required String activityType,
    required String description,
    String? categoryId,
    DateTime? scheduledAt,
    String? intakeOn,
    bool? siteVisitNeeded,
    String? installRequirements,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/opportunity-activities/',
        data: {
          'opportunity': opportunityId,
          'activity_type': activityType,
          'description': description,
          if (categoryId != null && categoryId.isNotEmpty)
            'category': categoryId,
          if (scheduledAt != null)
            'scheduled_at': scheduledAt.toUtc().toIso8601String(),
          if (intakeOn != null && intakeOn.isNotEmpty) 'intake_on': intakeOn,
          if (siteVisitNeeded != null) 'site_visit_needed': siteVisitNeeded,
          if (installRequirements != null && installRequirements.isNotEmpty)
            'install_requirements': installRequirements,
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _dio.delete<dynamic>('/api/crm/opportunity-activities/$id/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> completeActivity(String id) async {
    try {
      await _dio.post<dynamic>('/api/crm/opportunity-activities/$id/complete/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<ProposalItem>> proposals(String opportunityId) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/opportunity-products/',
        queryParameters: {'opportunity': opportunityId, 'page_size': 100},
      );
      return asResults(response.data).map(ProposalItem.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> createProposal({
    required String opportunityId,
    String? productId,
    String? serviceId,
    double quantity = 1,
    double unitPrice = 0,
    double discount = 0,
    String? notes,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/opportunity-products/',
        data: {
          'opportunity': opportunityId,
          if (productId != null && productId.isNotEmpty) 'product': productId,
          if (serviceId != null && serviceId.isNotEmpty) 'service': serviceId,
          'quantity': quantity,
          'unit_price': unitPrice,
          if (discount > 0) 'discount': discount,
          'notes': notes ?? '',
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> deleteProposal(String id) async {
    try {
      await _dio.delete<dynamic>('/api/crm/opportunity-products/$id/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<LeadItem> registerContact({
    required String leadId,
    required String channel,
    required String outcome,
    String? requirementText,
    String? reason,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/leads/$leadId/register_contact/',
        data: {
          'channel': channel,
          'outcome': outcome,
          if (requirementText != null) 'requirement_text': requirementText,
          if (reason != null) 'reason': reason,
        },
      );
      return LeadItem.fromJson(response.data ?? const {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<String> deriveToStrom(String opportunityId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/opportunities/$opportunityId/derive_to_strom/',
      );
      return asString(response.data?['project_id']);
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  /// Resumen de lo que se copia a Strøm, armado con lo que ya está en Kilde.
  Future<KildeHandoff> derivationPreview(String opportunityId) async {
    try {
      final deal = await retrieve(opportunityId);
      final quotes = await quotations();
      final allRfis = await rfis();
      final related = [
        for (final quote in quotes)
          if (quote.opportunityId == opportunityId) quote,
      ];
      final accepted = related.where((quote) => quote.status == 'accepted');
      final quote = accepted.isNotEmpty
          ? accepted.first
          : (related.isEmpty ? null : related.first);
      var card = const <String, dynamic>{};
      if ((deal.clientId ?? '').isNotEmpty) {
        try {
          card = await client360(deal.clientId!);
        } on Object {
          card = const {};
        }
      }
      final wells = <String>[];
      if ((deal.clientId ?? '').isNotEmpty) {
        try {
          final response = await _dio.get<dynamic>(
            '/api/inventory/measurement-points/',
            queryParameters: {'client': deal.clientId, 'page_size': 100},
          );
          for (final row in asResults(response.data)) {
            final label = asString(
              row['label'] ?? row['name'] ?? row['code'],
              fallback: 'Pozo',
            );
            if (label.isNotEmpty) wells.add(label);
          }
        } on Object {
          // El resumen sigue sin pozos si el inventario no responde.
        }
      }
      String? surveyTitle;
      for (final row in asMapList(card['surveys'])) {
        if (asString(row['id']) == (deal.surveyId ?? '')) {
          surveyTitle = asStringOrNull(row['title']);
        }
      }
      return KildeHandoff(
        clientName: deal.clientName ?? _handoffName(card['client']),
        contacts: [
          for (final row in asMapList(card['contacts']))
            if (_contactLabel(row) != null) _contactLabel(row)!,
        ],
        wells: wells,
        quotation: quote == null
            ? null
            : '${quote.number} · ${clp(quote.total)}',
        equipment: [
          for (final line in quote?.lines ?? const <QuoteLine>[])
            '${_qtyLabel(line.quantity)} × ${line.name}',
        ],
        surveyId: deal.surveyId,
        surveyTitle: surveyTitle ??
            ((deal.surveyId ?? '').isEmpty
                ? null
                : 'Ficha ${deal.surveyId}'),
        closedRfis: [
          for (final rfi in allRfis)
            if (rfi.opportunityId == opportunityId && rfi.status == 'closed')
              KildeClosedRfi(
                id: rfi.id,
                question: rfi.question,
                answer: rfi.answer ?? rfi.history.lastOrNull?.answer ?? '',
                answeredBy: rfi.history.lastOrNull?.answeredBy,
                answeredAt: rfi.history.lastOrNull?.answeredAt,
              ),
        ],
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  String? _handoffName(Object? raw) {
    if (raw is Map) return asStringOrNull(raw['name']);
    return asStringOrNull(raw);
  }

  String? _contactLabel(Map<String, dynamic> row) {
    final person = [
      asStringOrNull(row['first_name']),
      asStringOrNull(row['last_name']),
    ].whereType<String>().join(' ');
    final name = person.isEmpty ? asStringOrNull(row['name']) : person;
    final email = asStringOrNull(row['email']);
    if (name == null) return email;
    if (email == null) return name;
    return '$name · $email';
  }

  String _qtyLabel(double quantity) {
    if (quantity == quantity.roundToDouble()) return '${quantity.round()}';
    return '$quantity';
  }

  Future<KildeIndicators> kildeIndicators() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/crm/kilde/indicators/',
      );
      return KildeIndicators.fromJson(response.data ?? const {});
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<KildeMember>> kildeTeam() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/crm/kilde/team/',
      );
      final members = response.data?['members'];
      if (members is! List) return const [];
      return [
        for (final row in members)
          if (row is Map) KildeMember.fromJson(Map<String, dynamic>.from(row)),
      ];
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<KildeRenewal>> kildeRenewals() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/crm/kilde/renewals/',
      );
      final rows = response.data?['contracts'];
      if (rows is! List) return const [];
      return [
        for (final row in rows)
          if (row is Map) KildeRenewal.fromJson(Map<String, dynamic>.from(row)),
      ];
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<String> openRenewal(String contractId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/crm/kilde/renewals/$contractId/open_opportunity/',
      );
      return asString(response.data?['id']);
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<Map<String, dynamic>> client360(String clientId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/crm/kilde/clients/$clientId/360/',
      );
      return response.data ?? const {};
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<String> openLevantamiento({
    required String opportunityId,
    required String title,
    String? quoteResponseOn,
    String? openQuestions,
    String? resolutionMeetingOn,
    bool? resolutionMeetingDone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/surveys/surveys/',
        data: {
          'title': title,
          'survey_type': 'CUSTOM',
          'status': 'ACTIVE',
          'opportunity_id': opportunityId,
          if (quoteResponseOn != null) 'quote_response_on': quoteResponseOn,
          if (openQuestions != null) 'open_questions': openQuestions,
          if (resolutionMeetingOn != null)
            'resolution_meeting_on': resolutionMeetingOn,
          if (resolutionMeetingDone != null)
            'resolution_meeting_done': resolutionMeetingDone,
        },
      );
      return asString(response.data?['id']);
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> uploadClientPoFile({
    required String quotationId,
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      await _dio.patch<dynamic>(
        '/api/sales/quotations/$quotationId/',
        data: FormData.fromMap({
          'client_po_file': MultipartFile.fromBytes(bytes, filename: filename),
        }),
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<KildeRfi>> rfis() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/rfis/',
        queryParameters: {'page_size': 100, 'ordering': '-created'},
      );
      return asResults(response.data).map(KildeRfi.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> createRfi({
    required String question,
    required bool blocking,
    String? clientId,
    String? opportunityId,
    String? quotationId,
  }) async {
    try {
      final client = int.tryParse(clientId ?? '');
      await _dio.post<dynamic>(
        '/api/crm/rfis/',
        data: {
          'question': question,
          'is_blocking': blocking,
          if (client != null) 'client': client,
          if (opportunityId != null && opportunityId.isNotEmpty)
            'opportunity': opportunityId,
          if (quotationId != null && quotationId.isNotEmpty)
            'quotation': quotationId,
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> answerRfi({required String id, required String answer}) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/rfis/$id/answer/',
        data: {'answer': answer},
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> assignRfi({required String id, required String userId}) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/rfis/$id/assign/',
        data: {'assigned_to': int.tryParse(userId) ?? userId},
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> closeRfi(String id) async {
    try {
      await _dio.post<dynamic>('/api/crm/rfis/$id/close/');
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> reopenRfi({required String id, required String reason}) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/rfis/$id/reopen/',
        data: {'reason': reason},
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<KildeQuote>> quotations() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/sales/quotations/',
        queryParameters: {'page_size': 50, 'ordering': '-created'},
      );
      return asResults(response.data).map(KildeQuote.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> saveQuotationVersion({
    required String id,
    required String validUntil,
    required double total,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      final canSendItems =
          items != null &&
          items.isNotEmpty &&
          items.every((row) => row['product'] != null);
      await _dio.patch<dynamic>(
        '/api/sales/quotations/$id/',
        data: {
          if (validUntil.isNotEmpty) 'valid_until': validUntil,
          'total_amount': total,
          if (canSendItems) 'items': items,
        },
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<int>> clientPoFile(String quotationId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/sales/quotations/$quotationId/client-po-file/',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ApiError(message: 'El archivo de la OC vino vacío.');
      }
      return bytes;
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> quoteAction(
    String id,
    String action, [
    Map<String, dynamic>? body,
  ]) async {
    try {
      await _dio.post<dynamic>(
        '/api/sales/quotations/$id/$action/',
        data: body ?? const <String, dynamic>{},
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<KildeQuote> quotation(String id) async {
    try {
      final response = await _dio.get<dynamic>('/api/sales/quotations/$id/');
      return KildeQuote.fromJson(_quoteMap(response.data));
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<QuoteVersion>> quotationVersions(String id) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/sales/quotations/$id/versions/',
      );
      final versions = asResults(response.data).map(QuoteVersion.fromJson).toList()
        ..sort((a, b) => a.version.compareTo(b.version));
      return versions;
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> registerClientPo({
    required String quotationId,
    required String number,
    required String receivedOn,
    required String netAmount,
    List<int>? fileBytes,
    String? filename,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/api/sales/quotations/$quotationId/register_client_po/',
        data: FormData.fromMap({
          'client_po_number': number,
          'client_po_received_on': receivedOn,
          'client_po_net_amount': netAmount,
          if (fileBytes != null && (filename ?? '').isNotEmpty)
            'client_po_file': MultipartFile.fromBytes(
              fileBytes,
              filename: filename,
            ),
        }),
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<KildeQuote> createQuotation(QuoteDraft draft) async {
    try {
      final clientId = int.tryParse(draft.clientId);
      final productId = int.tryParse(draft.productId ?? '');
      final response = await _dio.post<dynamic>(
        '/api/sales/quotations/',
        data: {
          'date': kildeSantiagoDate(),
          if (clientId != null) 'client_id': clientId,
          'observation': draft.glosa,
          if ((draft.validUntil ?? '').isNotEmpty)
            'valid_until': draft.validUntil,
          'order_type': 'SALE',
          'status': 'DRAFT',
          if (productId != null)
            'items': [
              {
                'product': productId,
                'quantity': draft.quantity.round().clamp(1, 1000000),
                'unit_price': draft.unitPrice,
                'notes': draft.glosa,
              },
            ],
        },
      );
      return KildeQuote.fromJson(_quoteMap(response.data));
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<List<int>> quotationPdf(String id) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/sales/quotations/$id/generate-pdf/',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const ApiError(message: 'El PDF de la cotización vino vacío.');
      }
      return bytes;
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Map<String, dynamic> _quoteMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiError(
      message: 'La cotización no volvió en el formato esperado.',
    );
  }

  Future<List<LostReasonItem>> lostReasons() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/crm/lost-reasons/',
        queryParameters: {'page_size': 100, 'ordering': 'name'},
      );
      return asResults(response.data).map(LostReasonItem.fromJson).toList();
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }

  Future<void> createLostReason(String name) async {
    try {
      await _dio.post<dynamic>(
        '/api/crm/lost-reasons/',
        data: {'name': name},
      );
    } on Object catch (error, stack) {
      _rethrow(error, stack);
    }
  }
}
