import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/features/crm/data/crm_repository.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/quote_share.dart';

class FixtureCrmRepository extends CrmRepository {
  FixtureCrmRepository() : super(dio: Dio());

  final List<LeadSourceItem> _sources = [
    const LeadSourceItem(
      id: 'src-1',
      name: 'Referido APR',
      description: 'Comités y cooperativas de agua potable rural',
      color: '#0F766E',
    ),
    const LeadSourceItem(
      id: 'src-2',
      name: 'Licitación / Municipio',
      description: 'Mercado Público y direcciones de obras municipales',
      color: '#193665',
    ),
    const LeadSourceItem(
      id: 'src-3',
      name: 'Terreno / Feria Hídrica',
      description: 'Contacto directo en terreno o junta de vigilancia',
      color: '#D97706',
    ),
    const LeadSourceItem(
      id: 'src-4',
      name: 'Sitio Web Smart Hydro',
      description: 'Formulario comercial smarthydro.cl',
      color: '#0284C7',
    ),
  ];

  final List<FollowUpCategoryItem> _categories = [
    const FollowUpCategoryItem(
      id: 'cat-1',
      name: 'Visita técnica',
      color: '#0F766E',
      order: 1,
    ),
    const FollowUpCategoryItem(
      id: 'cat-2',
      name: 'Revisión de propuesta',
      color: '#0284C7',
      order: 2,
    ),
    const FollowUpCategoryItem(
      id: 'cat-3',
      name: 'Documentación DGA',
      color: '#D97706',
      order: 3,
    ),
  ];

  final List<OpportunityStageItem> _stages = [
    for (var i = 0; i < defaultWaterStages.length; i++)
      OpportunityStageItem(
        id: 'st-${i + 1}',
        name: defaultWaterStages[i].name,
        order: i,
        probability: defaultWaterStages[i].probability.toDouble(),
        color: defaultWaterStages[i].color,
        isClosed: defaultWaterStages[i].closed,
        isWon: defaultWaterStages[i].won,
      ),
  ];

  final List<LeadItem> _leads = [
    const LeadItem(
      id: 'lead-1',
      firstName: 'Roberto',
      lastName: 'Henríquez',
      company: 'Agrícola Los Aromos',
      email: 'rhenriquez@losaromos.cl',
      phone: '+56 9 8412 3301',
      status: 'QUALIFIED',
      score: 85,
      sourceId: 'src-4',
      sourceName: 'Sitio Web Smart Hydro',
      assignedToName: 'Martín Soto',
      notes: 'Tres pozos profundos en Los Niches. Quiere partir en diciembre.',
      requirementOutcome: 'with_requirement',
      requirementText:
          'Telemetría de nivel y caudal en 3 pozos, con alerta de freático.',
    ),
    const LeadItem(
      id: 'lead-2',
      firstName: 'Carmen',
      lastName: 'Sepúlveda',
      company: 'APR San Nicolás Sur',
      email: 'comite@aprsannicolas.cl',
      phone: '+56 9 7654 1190',
      status: 'CONTACTED',
      score: 40,
      sourceId: 'src-1',
      sourceName: 'Referido APR',
      assignedToName: 'Josefa Lagos',
      notes: 'Llamada del 12 de noviembre. El directorio no tiene presupuesto.',
      requirementOutcome: 'without_requirement',
      noRequirementReason:
          'Solo pidió precios. El proyecto queda para el próximo año.',
    ),
    const LeadItem(
      id: 'lead-3',
      firstName: 'Andrés',
      lastName: 'Valenzuela',
      company: 'Frutícola Río Cato',
      email: 'avalenzuela@riocato.cl',
      phone: '+56 9 9120 4450',
      status: 'NEW',
      score: 60,
      sourceId: 'src-3',
      sourceName: 'Terreno / Feria Hídrica',
      assignedToName: 'Martín Soto',
      notes: 'Dejó tarjeta en la feria de Chillán. Nadie lo ha llamado.',
      requirementOutcome: 'not_contacted',
    ),
  ];

  final List<OpportunityItem> _opportunities = [
    const OpportunityItem(
      id: 'opp-4',
      title: 'Estación meteorológica y aforo',
      description: 'Sensores de nivel y transmisión en la cuenca del Ñuble.',
      stageId: 'st-1',
      stageName: 'Prospección',
      clientId: 'cli-3',
      clientName: 'Consorcio Riego Ñuble',
      estimatedValue: 11800000,
      weightedValue: 1180000,
      probability: 10,
      expectedCloseDate: '2026-12-20',
      assignedToName: 'Josefa Lagos',
    ),
    const OpportunityItem(
      id: 'opp-5',
      title: 'Cloración y estanque elevado',
      description: 'Automatizar la dosificación y avisar nivel bajo.',
      stageId: 'st-2',
      stageName: 'Captación',
      clientId: 'cli-4',
      clientName: 'APR San Nicolás Sur',
      estimatedValue: 6400000,
      weightedValue: 1280000,
      probability: 20,
      expectedCloseDate: '2026-12-05',
      nextActionAt: '2026-11-24T15:00:00',
      nextActionType: 'CALL',
      assignedToName: 'Josefa Lagos',
    ),
    const OpportunityItem(
      id: 'opp-1',
      title: 'Ampliación 18 puntos de captación',
      description: 'Red de telemetría APR y monitoreo continuo de caudal.',
      stageId: 'st-3',
      stageName: 'Levantamiento',
      clientId: 'cli-1',
      clientName: 'APR Valle del Itata',
      estimatedValue: 28600000,
      weightedValue: 10010000,
      probability: 35,
      expectedCloseDate: '2026-12-15',
      nextActionAt: '2026-11-26T11:00:00',
      nextActionType: 'MEETING',
      assignedToName: 'Josefa Lagos',
    ),
    const OpportunityItem(
      id: 'opp-2',
      title: 'SLA Oro de riego y telemetría',
      description: 'Mantención preventiva, calibración y soporte en 8 horas.',
      stageId: 'st-4',
      stageName: 'Cotización',
      clientId: 'cli-2',
      clientName: 'Viña Lonquén',
      estimatedValue: 9600000,
      weightedValue: 4800000,
      probability: 50,
      expectedCloseDate: '2026-11-30',
      nextActionAt: '2026-11-22T10:00:00',
      nextActionType: 'QUOTE',
      assignedToName: 'Martín Soto',
    ),
    const OpportunityItem(
      id: 'opp-6',
      title: 'Pivote norte y caudal compartido',
      description:
          'El comité comparó con un proveedor local. Falta cerrar alcance.',
      stageId: 'st-5',
      stageName: 'Negociación/Cierre',
      clientId: 'cli-5',
      clientName: 'Agrícola Los Aromos',
      estimatedValue: 22100000,
      weightedValue: 15470000,
      probability: 70,
      expectedCloseDate: '2026-11-28',
      nextActionAt: '2026-11-25T16:30:00',
      nextActionType: 'MEETING',
      assignedToName: 'Martín Soto',
    ),
    const OpportunityItem(
      id: 'opp-3',
      title: 'Segunda etapa pivotes y datalogger',
      description: 'Doce equipos en la caseta de bombeo. OC recibida.',
      stageId: 'st-7',
      stageName: 'Reunión de programación',
      clientId: 'cli-1',
      clientName: 'APR Valle del Itata',
      estimatedValue: 15400000,
      weightedValue: 14630000,
      probability: 95,
      expectedCloseDate: '2026-11-21',
      surveyId: 'sv-opp-3',
      nextActionAt: '2026-11-23T09:00:00',
      nextActionType: 'install_planning',
      assignedToName: 'Josefa Lagos',
    ),
    const OpportunityItem(
      id: 'opp-7',
      title: 'Pozos Los Niches, etapa 1',
      description: 'Vendido en octubre. La instalación ya está en Strøm.',
      stageId: 'st-8',
      stageName: 'Ganada',
      clientId: 'cli-5',
      clientName: 'Agrícola Los Aromos',
      estimatedValue: 8900000,
      actualValue: 8900000,
      weightedValue: 8900000,
      probability: 100,
      expectedCloseDate: '2026-10-18',
      surveyId: 'sv-opp-7',
      assignedToName: 'Martín Soto',
    ),
    const OpportunityItem(
      id: 'opp-8',
      title: 'Aforo satelital Río Cato',
      description: 'El directorio eligió otra oferta por precio.',
      stageId: 'st-9',
      stageName: 'Perdida',
      clientId: 'cli-6',
      clientName: 'Frutícola Río Cato',
      estimatedValue: 7300000,
      weightedValue: 0,
      probability: 0,
      expectedCloseDate: '2026-10-30',
      lostReasonId: 'lr-1',
      lostReasonName: 'Precio',
      lostReasonText: 'Quedaron 18% sobre la oferta local.',
      assignedToName: 'Josefa Lagos',
    ),
  ];

  final Map<String, List<FollowUpItem>> _activities = {
    'opp-1': [
      FollowUpItem(
        id: 'act-hoy',
        description: 'Llamar al APR Valle del Itata',
        activityType: 'CALL',
        scheduledAt: DateTime.now(),
        createdByName: 'Josefa Lagos',
        opportunityId: 'opp-1',
      ),
      FollowUpItem(
        id: 'act-1',
        description: 'Presentación de propuesta en junta de vecinos APR',
        activityType: 'MEETING',
        categoryId: 'cat-2',
        categoryName: 'Revisión de propuesta',
        scheduledAt: DateTime(2026, 10, 25, 11),
        createdByName: 'Josefa Lagos',
        opportunityId: 'opp-1',
      ),
      FollowUpItem(
        id: 'act-2',
        description: 'Levantamiento hidráulico de los 18 puntos completado',
        activityType: 'TASK',
        categoryId: 'cat-1',
        categoryName: 'Visita técnica',
        isCompleted: true,
        scheduledAt: DateTime(2026, 10, 18, 9, 30),
        createdByName: 'Héctor Muñoz',
        opportunityId: 'opp-1',
      ),
    ],
  };

  final Map<String, List<ProposalItem>> _proposals = {
    'opp-1': [
      const ProposalItem(
        id: 'prop-1',
        productName: 'Datalogger SmartHydro N1 + Telemetría',
        quantity: 18,
        unitPrice: 1250000,
        totalPrice: 22500000,
        notes: 'Incluye gabinete IP67 y panel solar',
      ),
      const ProposalItem(
        id: 'prop-2',
        serviceName: 'Puesta en marcha y habilitación DGA MEE',
        quantity: 1,
        unitPrice: 6100000,
        totalPrice: 6100000,
        notes: 'Certificación y pruebas de transmisión',
      ),
    ],
  };

  int _seq = 100;

  @override
  Future<CrmDashboardSummary> summary({String? start, String? end}) async {
    var openCount = 0;
    var wonCount = 0;
    var openVal = 0.0;
    var weightedVal = 0.0;
    var wonVal = 0.0;
    for (final opp in _opportunities) {
      final st = _stages.where((s) => s.id == opp.stageId).firstOrNull;
      if (st != null && st.isWon) {
        wonCount++;
        wonVal += opp.actualValue > 0 ? opp.actualValue : opp.estimatedValue;
      } else if (st == null || !st.isClosed) {
        openCount++;
        openVal += opp.estimatedValue;
        weightedVal += opp.estimatedValue * ((st?.probability ?? 20) / 100.0);
      }
    }
    return CrmDashboardSummary(
      newLeads: _leads.where((l) => l.status != 'CONVERTED').length,
      convertedLeads: _leads.where((l) => l.status == 'CONVERTED').length,
      openOpportunities: openCount,
      openValue: openVal,
      openWeightedValue: weightedVal,
      wonCount: wonCount,
      wonValue: wonVal,
      completedActivities: 4,
      overdueActivities: 1,
      todayActivities: 2,
      totalCustomers: 12,
    );
  }

  @override
  Future<List<LeadSourceItem>> leadSources() async =>
      List.unmodifiable(_sources);

  @override
  Future<List<FollowUpCategoryItem>> followUpCategories() async =>
      List.unmodifiable(_categories);

  @override
  Future<List<LeadItem>> leads({
    String? status,
    String? search,
    String? sourceId,
  }) async {
    return _leads.where((lead) {
      if (status != null && status.isNotEmpty && lead.status != status) {
        return false;
      }
      if (sourceId != null &&
          sourceId.isNotEmpty &&
          lead.sourceId != sourceId) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        final hay = '${lead.name} ${lead.company ?? ''} ${lead.email ?? ''}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  @override
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
    final src = _sources.where((s) => s.id == sourceId).firstOrNull;
    final item = LeadItem(
      id: 'lead-${++_seq}',
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      notes: notes,
      sourceId: sourceId,
      sourceName: src?.name,
      score: score,
    );
    _leads.insert(0, item);
    return item;
  }

  @override
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
    final idx = _leads.indexWhere((l) => l.id == id);
    if (idx < 0) return _leads.first;
    final prev = _leads[idx];
    final nextSrcId = sourceId ?? prev.sourceId;
    final src = _sources.where((s) => s.id == nextSrcId).firstOrNull;
    final updated = LeadItem(
      id: prev.id,
      firstName: firstName,
      lastName: lastName ?? prev.lastName,
      email: email ?? prev.email,
      phone: phone ?? prev.phone,
      company: company ?? prev.company,
      notes: notes ?? prev.notes,
      status: status ?? prev.status,
      score: score ?? prev.score,
      sourceId: nextSrcId,
      sourceName: src?.name ?? prev.sourceName,
      convertedClientId: prev.convertedClientId,
    );
    _leads[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteLead(String id) async =>
      _leads.removeWhere((l) => l.id == id);

  @override
  Future<void> setLeadStatus({
    required String id,
    required String status,
  }) async {
    final prev = _leads.where((l) => l.id == id).firstOrNull;
    if (prev != null) {
      await updateLead(id: id, firstName: prev.firstName, status: status);
    }
  }

  @override
  Future<LeadItem> convertLead(String id) async {
    final idx = _leads.indexWhere((l) => l.id == id);
    if (idx < 0) return _leads.first;
    final prev = _leads[idx];
    final converted = LeadItem(
      id: prev.id,
      firstName: prev.firstName,
      lastName: prev.lastName,
      email: prev.email,
      phone: prev.phone,
      company: prev.company,
      notes: prev.notes,
      status: 'CONVERTED',
      score: prev.score,
      sourceId: prev.sourceId,
      sourceName: prev.sourceName,
      convertedClientId: 'cli-1',
    );
    _leads[idx] = converted;
    return converted;
  }

  @override
  Future<List<OpportunityStageItem>> stages() async =>
      List.unmodifiable(_stages);

  @override
  Future<void> seedWaterStages() async {}

  @override
  Future<List<OpportunityItem>> opportunities({
    String? clientId,
    String? stageId,
    String? search,
  }) async {
    return _opportunities.where((opp) {
      if (clientId != null && clientId.isNotEmpty && opp.clientId != clientId) {
        return false;
      }
      if (stageId != null && stageId.isNotEmpty && opp.stageId != stageId) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        if (!'${opp.title} ${opp.clientName ?? ''}'.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<OpportunityItem> retrieve(String id) async => _opportunities
      .firstWhere((o) => o.id == id, orElse: () => _opportunities.first);

  @override
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
    final stage = _stages.where((s) => s.id == stageId).firstOrNull;
    final item = OpportunityItem(
      id: 'opp-${++_seq}',
      title: title,
      description: description ?? notes,
      stageId: stageId,
      stageName: stage?.name,
      clientId: clientId,
      clientName: clientId != null ? 'Cliente asociado' : null,
      estimatedValue: estimatedValue,
      actualValue: actualValue,
      weightedValue: estimatedValue * ((stage?.probability ?? 20) / 100.0),
      expectedCloseDate: expectedCloseDate,
    );
    _opportunities.insert(0, item);
    return item;
  }

  @override
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
    final idx = _opportunities.indexWhere((o) => o.id == id);
    if (idx < 0) return _opportunities.first;
    final prev = _opportunities[idx];
    final nextStageId = stageId ?? prev.stageId;
    final stage = _stages.where((s) => s.id == nextStageId).firstOrNull;
    final nextVal = estimatedValue ?? prev.estimatedValue;
    final updated = _touch(
      prev,
      title: title,
      description: description ?? notes ?? prev.description,
      stageId: nextStageId,
      stageName: stage?.name ?? prev.stageName,
      clientId: clientId ?? prev.clientId,
      estimatedValue: nextVal,
      actualValue: actualValue ?? prev.actualValue,
      weightedValue: nextVal * ((stage?.probability ?? prev.probability) / 100),
      probability: stage?.probability ?? prev.probability,
      expectedCloseDate: expectedCloseDate ?? prev.expectedCloseDate,
    );
    _opportunities[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteOpportunity(String id) async =>
      _opportunities.removeWhere((o) => o.id == id);

  @override
  Future<void> move({
    required String id,
    required String stageId,
    String? lostReasonId,
    String? lostReasonText,
  }) async {
    final index = _opportunities.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final opp = _opportunities[index];
    final stage = _stages.where((item) => item.id == stageId).firstOrNull;
    if (stage != null &&
        stage.isLost &&
        (lostReasonId == null || lostReasonId.isEmpty)) {
      throw StateError('Marcar Perdida exige un motivo.');
    }
    final reason = _lost.where((item) => item.id == lostReasonId).firstOrNull;
    _opportunities[index] = _touch(
      opp,
      stageId: stageId,
      stageName: stage?.name ?? opp.stageName,
      probability: stage?.probability ?? opp.probability,
      weightedValue: opp.estimatedValue * ((stage?.probability ?? 0) / 100),
      actualValue: (stage?.isWon ?? false)
          ? opp.estimatedValue
          : opp.actualValue,
      lostReasonId: lostReasonId ?? opp.lostReasonId,
      lostReasonName: reason?.name ?? opp.lostReasonName,
      lostReasonText: lostReasonText ?? opp.lostReasonText,
    );
    _activities
        .putIfAbsent(id, () => [])
        .insert(
          0,
          FollowUpItem(
            id: 'act-${++_seq}',
            description: lostReasonText ?? 'Cambio de etapa',
            activityType: 'STAGE_CHANGE',
            createdByName: 'Demo',
          ),
        );
  }

  @override
  Future<List<FollowUpItem>> todayActivities() async {
    final today = DateTime.now();
    return [
      for (final list in _activities.values)
        for (final item in list)
          if (!item.isCompleted &&
              item.scheduledAt != null &&
              item.scheduledAt!.year == today.year &&
              item.scheduledAt!.month == today.month &&
              item.scheduledAt!.day == today.day)
            item,
    ];
  }

  @override
  Future<List<FollowUpItem>> activities(String opportunityId) async =>
      List.unmodifiable(_activities[opportunityId] ?? const []);

  @override
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
    final cat = _categories.where((c) => c.id == categoryId).firstOrNull;
    _activities
        .putIfAbsent(opportunityId, () => [])
        .insert(
          0,
          FollowUpItem(
            id: 'act-${++_seq}',
            description: description,
            activityType: activityType,
            categoryId: categoryId,
            categoryName: cat?.name,
            scheduledAt: scheduledAt,
            createdByName: 'Demostración',
            opportunityId: opportunityId,
          ),
        );
  }

  @override
  Future<void> deleteActivity(String id) async {
    for (final list in _activities.values) {
      list.removeWhere((a) => a.id == id);
    }
  }

  @override
  Future<void> completeActivity(String id) async {
    for (final list in _activities.values) {
      final idx = list.indexWhere((a) => a.id == id);
      if (idx >= 0) {
        final prev = list[idx];
        list[idx] = FollowUpItem(
          id: prev.id,
          description: prev.description,
          activityType: prev.activityType,
          categoryId: prev.categoryId,
          categoryName: prev.categoryName,
          scheduledAt: prev.scheduledAt,
          completedAt: DateTime.now(),
          isCompleted: true,
          createdByName: prev.createdByName,
        );
      }
    }
  }

  @override
  Future<List<ProposalItem>> proposals(String opportunityId) async =>
      List.unmodifiable(_proposals[opportunityId] ?? const []);

  @override
  Future<void> createProposal({
    required String opportunityId,
    String? productId,
    String? serviceId,
    double quantity = 1,
    double unitPrice = 0,
    double discount = 0,
    String? notes,
  }) async {
    _proposals
        .putIfAbsent(opportunityId, () => [])
        .add(
          ProposalItem(
            id: 'prop-${++_seq}',
            productId: productId,
            productName: notes != null && notes.isNotEmpty
                ? notes
                : 'Ítem comercial',
            quantity: quantity,
            unitPrice: unitPrice,
            discount: discount,
            totalPrice: quantity * unitPrice * (1 - discount / 100),
            notes: notes,
          ),
        );
  }

  @override
  Future<void> deleteProposal(String id) async {
    for (final list in _proposals.values) {
      list.removeWhere((p) => p.id == id);
    }
  }

  @override
  Future<LeadItem> registerContact({
    required String leadId,
    required String channel,
    required String outcome,
    String? requirementText,
    String? reason,
  }) async {
    final index = _leads.indexWhere((lead) => lead.id == leadId);
    if (index < 0) {
      return LeadItem(id: leadId, firstName: 'Prospecto');
    }
    final current = _leads[index];
    final next = LeadItem(
      id: current.id,
      firstName: current.firstName,
      lastName: current.lastName,
      email: current.email,
      phone: current.phone,
      company: current.company,
      status: 'CONTACTED',
      score: current.score,
      sourceId: current.sourceId,
      sourceName: current.sourceName,
      notes: current.notes,
      requirementOutcome: outcome,
      requirementText: requirementText,
      noRequirementReason: reason,
    );
    _leads[index] = next;
    return next;
  }

  final List<KildeQuote> _quotes = [
    const KildeQuote(
      id: 'q-1042',
      number: 'COT-1042 · APR Valle del Itata',
      status: 'draft',
      discountStatus: 'approved',
      total: 28600000,
      version: 2,
      validUntil: '2026-12-15',
      opportunityId: 'opp-1',
      clientName: 'APR Valle del Itata',
      observation: 'Telemetría de pozo y puesta en marcha.',
      lines: [
        QuoteLine(
          name: 'Datalogger de pozo',
          quantity: 2,
          unitPrice: 9800000,
        ),
        QuoteLine(name: 'Puesta en marcha', quantity: 1, unitPrice: 9000000),
      ],
    ),
    const KildeQuote(
      id: 'q-1051',
      number: 'COT-1051 · Viña Lonquén',
      status: 'draft',
      discountStatus: 'pending',
      total: 9600000,
      version: 1,
      validUntil: '2026-11-30',
      opportunityId: 'opp-2',
      clientName: 'Viña Lonquén',
      observation: 'Caudalímetro y tablero.',
      lines: [
        QuoteLine(name: 'Caudalímetro', quantity: 1, unitPrice: 9600000),
      ],
    ),
    const KildeQuote(
      id: 'q-1033',
      number: 'COT-1033 · Segunda etapa pivotes',
      status: 'accepted',
      total: 15400000,
      version: 3,
      validUntil: '2026-11-30',
      receptionConfirmed: true,
      responseOn: '2026-10-12',
      poNumber: 'OC-4412',
      poReceivedOn: '2026-10-18',
      poNet: 15400000,
      immutable: true,
      opportunityId: 'opp-3',
    ),
    const KildeQuote(
      id: 'q-1020',
      number: 'COT-1020 · Pivote norte',
      status: 'objected',
      objection: 'El comité pide bajar la puesta en marcha.',
      total: 22100000,
      version: 1,
      opportunityId: 'opp-6',
    ),
  ];

  final List<KildeRfi> _rfis = [
    const KildeRfi(
      id: 'rfi-1',
      number: 'RFI-14',
      question: '¿La caseta de Lonquén tiene energía trifásica estable?',
      blocking: true,
      status: 'open',
      quotationId: 'q-1051',
      opportunityId: 'opp-2',
    ),
    const KildeRfi(
      id: 'rfi-2',
      number: 'RFI-9',
      question: '¿El estanque de San Nicolás tiene tapa visitable?',
      blocking: false,
      status: 'answered',
      answer: 'Sí, tapa de 60 cm al lado norte.',
      opportunityId: 'opp-5',
    ),
  ];

  final List<LostReasonItem> _lost = [
    const LostReasonItem(id: 'lr-1', name: 'Precio'),
    const LostReasonItem(id: 'lr-2', name: 'Plazo de entrega'),
    const LostReasonItem(id: 'lr-3', name: 'Competencia local'),
  ];

  final Set<String> _derived = {};

  @override
  Future<KildeIndicators> kildeIndicators() async {
    final open = _opportunities.where((item) => !item.isWon && !item.isLost);
    final sales = _quotes.where((item) => item.acceptedWithPo);
    return KildeIndicators(
      contacted: _leads.where((lead) => !lead.notContacted).length,
      withRequirement: _leads
          .where((lead) => lead.requirementOutcome == 'with_requirement')
          .length,
      withoutRequirement: _leads
          .where((lead) => lead.requirementOutcome == 'without_requirement')
          .length,
      notContacted: _leads.where((lead) => lead.notContacted).length,
      quotesWithResponse: _quotes
          .where(
            (item) => const {
              'accepted',
              'objected',
              'rejected',
            }.contains(item.status),
          )
          .length,
      quotesWithoutResponse: _quotes
          .where((item) => item.status == 'sent')
          .length,
      quotesAccepted: _quotes.where((item) => item.status == 'accepted').length,
      quotesObjected: _quotes.where((item) => item.status == 'objected').length,
      quotesRejected: _quotes.where((item) => item.status == 'rejected').length,
      salesCount: sales.length,
      salesNet: sales.fold<double>(0, (sum, item) => sum + (item.poNet ?? 0)),
      weighted: open.fold<double>(0, (sum, item) => sum + item.weightedValue),
      missingNext: open
          .where((item) => (item.nextActionType ?? '').isEmpty)
          .length,
      overdue: 1,
      openRfis: _rfis.where((item) => item.isOpen).length,
      periodLabel: '1 nov 2026 – 30 nov 2026',
    );
  }

  @override
  Future<List<KildeMember>> kildeTeam() async {
    return [
      _member(
        'Josefa Lagos',
        overdue: 0,
        week: 6,
        agenda: const ['Reunión · Junta APR Valle del Itata, 11:00'],
      ),
      _member(
        'Martín Soto',
        overdue: 1,
        week: 3,
        agenda: const ['Llamada · Viña Lonquén, confirmar energía trifásica'],
      ),
    ];
  }

  KildeMember _member(
    String name, {
    required int overdue,
    required int week,
    required List<String> agenda,
  }) {
    final mine = _opportunities.where((item) => item.assignedToName == name);
    final open = mine.where((item) => !item.isWon && !item.isLost);
    return KildeMember(
      userId: name,
      name: name,
      openOpportunities: open.length,
      weightedValue: open.fold<double>(
        0,
        (sum, item) => sum + item.weightedValue,
      ),
      missingNext: open
          .where((item) => (item.nextActionType ?? '').isEmpty)
          .length,
      overdue: overdue,
      wonPeriod: mine.where((item) => item.isWon).length,
      weekActivities: week,
      todayAgenda: agenda,
    );
  }

  @override
  Future<List<KildeRenewal>> kildeRenewals() async => const [
    KildeRenewal(
      id: 'ct-1',
      title: 'Mantención anual de telemetría',
      clientName: 'APR Valle del Itata',
      clientId: 'cli-1',
      endDate: '2026-12-15',
      contractNumber: 'CT-2024-18',
      contractType: 'Mantención',
      autoRenewal: true,
    ),
    KildeRenewal(
      id: 'ct-2',
      title: 'SLA de calibración de caudal',
      clientName: 'Viña Lonquén',
      clientId: 'cli-2',
      endDate: '2026-11-30',
      contractNumber: 'CT-2025-04',
      contractType: 'Servicio',
    ),
  ];

  @override
  Future<String> openRenewal(String contractId) async {
    final id = 'opp-ren-$contractId';
    if (_opportunities.every((item) => item.id != id)) {
      _opportunities.insert(
        0,
        OpportunityItem(
          id: id,
          title: 'Renovación $contractId',
          description: 'Oportunidad abierta desde el aviso de vencimiento.',
          stageId: 'st-1',
          stageName: 'Prospección',
          clientName: contractId == 'ct-2'
              ? 'Viña Lonquén'
              : 'APR Valle del Itata',
          clientId: contractId == 'ct-2' ? 'cli-2' : 'cli-1',
          estimatedValue: 4200000,
          weightedValue: 420000,
          probability: 10,
          expectedCloseDate: '2026-12-31',
          nextActionAt: '2026-11-27T10:00:00',
          nextActionType: 'CALL',
          assignedToName: 'Josefa Lagos',
        ),
      );
    }
    return id;
  }

  @override
  Future<Map<String, dynamic>> client360(String clientId) async {
    final opps = _opportunities
        .where((item) => item.clientId == clientId)
        .toList();
    final name = opps.isEmpty
        ? 'Cliente $clientId'
        : (opps.first.clientName ?? clientId);
    final ids = opps.map((item) => item.id).toSet();
    const quoteLabels = {
      'draft': 'Borrador',
      'sent': 'Enviada',
      'accepted': 'Aceptada',
      'objected': 'Objetada',
      'rejected': 'Rechazada',
    };
    final quotes = _quotes.where((item) => ids.contains(item.opportunityId));
    final derived = opps.any((item) => _derived.contains(item.id));
    return {
      'client': {'id': clientId, 'name': name},
      'opportunities': [
        for (final item in opps)
          {'id': item.id, 'title': item.title, 'stage_name': item.stageName},
      ],
      'quotations': [
        for (final item in quotes)
          {
            'id': item.id,
            'status': quoteLabels[item.status] ?? item.status,
            'version': item.version,
          },
      ],
      'purchase_orders': [
        for (final item in quotes)
          if ((item.poNumber ?? '').isNotEmpty)
            {'client_po_number': item.poNumber},
      ],
      'surveys': [
        for (final item in opps)
          if ((item.surveyId ?? '').isNotEmpty)
            {'id': item.surveyId, 'title': 'Levantamiento ${item.title}'},
      ],
      'rfis': [
        for (final item in _rfis)
          if (ids.contains(item.opportunityId)) {'question': item.question},
      ],
      'derivation': {
        'status': derived ? 'derived' : 'pending_derivation',
      },
      'milestones': derived
          ? [
              {
                'channel': 'strom_install',
                'at': '2026-11-21',
                'description': 'Proyecto creado en Strøm',
              },
            ]
          : const <Map<String, String>>[],
      'follow_up': [
        for (final item in opps)
          if (item.nextActionLabel != null)
            {'description': '${item.title}: ${item.nextActionLabel}'},
      ],
      'contracts': [
        if (clientId == 'cli-1') {'title': 'CT-2024-18 · Mantención anual'},
        if (clientId == 'cli-2')
          {'title': 'CT-2025-04 · Calibración de caudal'},
      ],
      'nps': clientId == 'cli-1'
          ? {'latest_score': 9, 'count': 2}
          : {'latest_score': 7, 'count': 1},
    };
  }

  @override
  Future<String> openLevantamiento({
    required String opportunityId,
    required String title,
    String? quoteResponseOn,
    String? openQuestions,
    String? resolutionMeetingOn,
    bool? resolutionMeetingDone,
  }) async {
    final index = _opportunities.indexWhere((item) => item.id == opportunityId);
    final surveyId = 'sv-$opportunityId';
    if (index >= 0) {
      _opportunities[index] = _touch(
        _opportunities[index],
        surveyId: surveyId,
      );
    }
    return surveyId;
  }

  @override
  Future<void> uploadClientPoFile({
    required String quotationId,
    required List<int> bytes,
    required String filename,
  }) async {
    final index = _quotes.indexWhere((item) => item.id == quotationId);
    if (index < 0) return;
    _quotes[index] = _retouch(_quotes[index], poFile: filename);
  }

  @override
  Future<List<KildeRfi>> rfis() async => List.unmodifiable(_rfis);

  @override
  Future<void> createRfi({
    required String question,
    required bool blocking,
  }) async {
    _rfis.insert(
      0,
      KildeRfi(
        id: 'rfi-${++_seq}',
        number: 'RFI-$_seq',
        question: question,
        blocking: blocking,
        status: 'open',
      ),
    );
  }

  @override
  Future<void> answerRfi({required String id, required String answer}) async {
    _replaceRfi(
      id,
      (current) => _copyRfi(current, status: 'answered', answer: answer),
    );
  }

  @override
  Future<void> assignRfi({required String id, required String userId}) async {
    _replaceRfi(
      id,
      (current) => _copyRfi(
        current,
        status: 'assigned',
        assignedToId: userId,
        assignedToName: userId,
      ),
    );
  }

  @override
  Future<void> closeRfi(String id) async {
    _replaceRfi(id, (current) => _copyRfi(current, status: 'closed'));
  }

  @override
  Future<void> reopenRfi({required String id, required String reason}) async {
    _replaceRfi(
      id,
      (current) => _copyRfi(
        current,
        status: 'reopened',
        reopenReason: reason,
      ),
    );
  }

  void _replaceRfi(String id, KildeRfi Function(KildeRfi current) build) {
    final index = _rfis.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _rfis[index] = build(_rfis[index]);
  }

  KildeRfi _copyRfi(
    KildeRfi current, {
    String? status,
    String? answer,
    String? reopenReason,
    String? assignedToId,
    String? assignedToName,
  }) {
    return KildeRfi(
      id: current.id,
      question: current.question,
      number: current.number,
      status: status ?? current.status,
      blocking: current.blocking,
      answer: answer ?? current.answer,
      reopenReason: reopenReason ?? current.reopenReason,
      assignedToId: assignedToId ?? current.assignedToId,
      assignedToName: assignedToName ?? current.assignedToName,
      quotationId: current.quotationId,
      opportunityId: current.opportunityId,
    );
  }

  @override
  Future<List<KildeQuote>> quotations() async => List.unmodifiable(_quotes);

  @override
  Future<KildeQuote> quotation(String id) async {
    for (final row in _quotes) {
      if (row.id == id) return row;
    }
    throw const ApiError(message: 'No encontramos esta cotización.');
  }

  @override
  Future<KildeQuote> createQuotation(QuoteDraft draft) async {
    final quote = KildeQuote(
      id: 'q-${++_seq}',
      number: 'COT-$_seq · ${draft.clientName}',
      clientName: draft.clientName,
      observation: draft.glosa,
      total: draft.total,
      validUntil: draft.validUntil,
      lines: [
        QuoteLine(
          name: draft.glosa,
          quantity: draft.quantity,
          unitPrice: draft.unitPrice,
        ),
      ],
    );
    _quotes.insert(0, quote);
    return quote;
  }

  @override
  Future<List<int>> quotationPdf(String id) async {
    return utf8.encode(quoteDocument(await quotation(id)));
  }

  @override
  Future<void> quoteAction(
    String id,
    String action, [
    Map<String, dynamic>? body,
  ]) async {
    final index = _quotes.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = _quotes[index];
    final today = _today();
    _quotes[index] = switch (action) {
      'send' => _retouch(current, status: 'sent'),
      'confirm_reception' => _retouch(current, receptionConfirmed: true),
      'accept' => _retouch(current, status: 'accepted', responseOn: today),
      'object' => _retouch(
        current,
        status: 'objected',
        objection: '${body?['objection'] ?? ''}',
        responseOn: today,
      ),
      'reject' => _retouch(
        current,
        status: 'rejected',
        rejectionReason: '${body?['rejection_reason'] ?? ''}',
        responseOn: today,
      ),
      'approve_discount' => _retouch(current, discountStatus: 'approved'),
      'reject_discount' => _retouch(current, discountStatus: 'rejected'),
      'register_client_po' => _retouch(
        current,
        status: 'accepted',
        poNumber: '${body?['client_po_number'] ?? ''}',
        poReceivedOn: '${body?['client_po_received_on'] ?? today}',
        poNet:
            double.tryParse('${body?['client_po_net_amount']}') ??
            current.poNet,
      ),
      _ => current,
    };
  }

  @override
  Future<List<LostReasonItem>> lostReasons() async => List.unmodifiable(_lost);

  @override
  Future<void> createLostReason(String name) async {
    _lost.add(LostReasonItem(id: 'lr-${++_seq}', name: name));
  }

  @override
  Future<String> deriveToStrom(String opportunityId) async {
    _derived.add(opportunityId);
    _activities
        .putIfAbsent(opportunityId, () => [])
        .insert(
          0,
          FollowUpItem(
            id: 'act-${++_seq}',
            description: 'Derivada a Strøm. Proyecto proy-$opportunityId.',
            activityType: 'NOTE',
            createdByName: 'Josefa Lagos',
          ),
        );
    return 'proy-$opportunityId';
  }

  OpportunityItem _touch(
    OpportunityItem prev, {
    String? title,
    String? description,
    String? stageId,
    String? stageName,
    String? clientId,
    double? estimatedValue,
    double? actualValue,
    double? weightedValue,
    double? probability,
    String? expectedCloseDate,
    String? surveyId,
    String? lostReasonId,
    String? lostReasonName,
    String? lostReasonText,
  }) {
    return OpportunityItem(
      id: prev.id,
      title: title ?? prev.title,
      description: description ?? prev.description,
      stageId: stageId ?? prev.stageId,
      stageName: stageName ?? prev.stageName,
      clientId: clientId ?? prev.clientId,
      clientName: prev.clientName,
      leadId: prev.leadId,
      leadName: prev.leadName,
      estimatedValue: estimatedValue ?? prev.estimatedValue,
      actualValue: actualValue ?? prev.actualValue,
      weightedValue: weightedValue ?? prev.weightedValue,
      expectedCloseDate: expectedCloseDate ?? prev.expectedCloseDate,
      closedAt: prev.closedAt,
      assignedToName: prev.assignedToName,
      nextActionAt: prev.nextActionAt,
      nextActionType: prev.nextActionType,
      surveyId: surveyId ?? prev.surveyId,
      lostReasonId: lostReasonId ?? prev.lostReasonId,
      lostReasonName: lostReasonName ?? prev.lostReasonName,
      lostReasonText: lostReasonText ?? prev.lostReasonText,
      probability: probability ?? prev.probability,
    );
  }

  KildeQuote _retouch(
    KildeQuote current, {
    String? status,
    String? discountStatus,
    String? poNumber,
    double? poNet,
    String? poReceivedOn,
    String? poFile,
    String? objection,
    String? rejectionReason,
    bool? receptionConfirmed,
    String? responseOn,
  }) {
    return KildeQuote(
      id: current.id,
      number: current.number,
      status: status ?? current.status,
      discountStatus: discountStatus ?? current.discountStatus,
      poNumber: poNumber ?? current.poNumber,
      total: current.total,
      version: current.version,
      validUntil: current.validUntil,
      objection: objection ?? current.objection,
      rejectionReason: rejectionReason ?? current.rejectionReason,
      receptionConfirmed: receptionConfirmed ?? current.receptionConfirmed,
      responseOn: responseOn ?? current.responseOn,
      opportunityId: current.opportunityId,
      parentId: current.parentId,
      immutable: current.immutable,
      poReceivedOn: poReceivedOn ?? current.poReceivedOn,
      poNet: poNet ?? current.poNet,
      poFile: poFile ?? current.poFile,
      clientName: current.clientName,
      observation: current.observation,
      lines: current.lines,
    );
  }

  String _today() {
    final today = DateTime.now();
    final month = today.month.toString().padLeft(2, '0');
    final day = today.day.toString().padLeft(2, '0');
    return '${today.year}-$month-$day';
  }
}
