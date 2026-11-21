import 'package:dio/dio.dart';
import 'package:nereus_app/features/crm/data/crm_repository.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';

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
      notes: 'Solicita telemetría para 3 pozos profundos y nivel freático.',
    ),
    const LeadItem(
      id: 'lead-2',
      firstName: 'Carmen',
      lastName: 'Sepúlveda',
      company: 'APR San Nicolás Sur',
      email: 'comite@aprsannicolas.cl',
      phone: '+56 9 7654 1190',
      status: 'CONTACTED',
      score: 70,
      sourceId: 'src-1',
      sourceName: 'Referido APR',
      assignedToName: 'Josefa Lagos',
      notes: 'Requiere automatización de cloración y telemetría de estanque.',
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
      notes: 'Cumplimiento MEE DGA caudal mayor en dos bocatomas.',
    ),
  ];

  final List<OpportunityItem> _opportunities = [
    const OpportunityItem(
      id: 'opp-1',
      title: 'Ampliación 18 puntos de captación',
      description: 'Red de telemetría APR y monitoreo continuo de caudal.',
      stageId: 'st-3',
      stageName: 'Propuesta',
      clientId: 'cli-1',
      clientName: 'APR Valle del Itata',
      estimatedValue: 28600000,
      weightedValue: 17160000,
      expectedCloseDate: '2026-11-15',
      assignedToName: 'Josefa Lagos',
    ),
    const OpportunityItem(
      id: 'opp-2',
      title: 'SLA Oro sobre riego y telemetría',
      description: 'Mantención preventiva, calibración y soporte 8h.',
      stageId: 'st-2',
      stageName: 'Visita',
      clientId: 'cli-2',
      clientName: 'Viña Lonquén',
      estimatedValue: 9600000,
      weightedValue: 2880000,
      expectedCloseDate: '2026-11-05',
      assignedToName: 'Martín Soto',
    ),
    const OpportunityItem(
      id: 'opp-3',
      title: 'Segunda etapa pivotes + datalogger x12',
      description: 'Instalación completa en caseta de bombeo.',
      stageId: 'st-4',
      stageName: 'Ganada',
      clientId: 'cli-1',
      clientName: 'Fundo El Boldo',
      estimatedValue: 15400000,
      actualValue: 15400000,
      weightedValue: 15400000,
      expectedCloseDate: '2026-10-20',
      assignedToName: 'Héctor Muñoz',
    ),
    const OpportunityItem(
      id: 'opp-4',
      title: 'Estación meteorológica y aforo de cuenca',
      description: 'Integración de sensores de nivel y transmisión satelital.',
      stageId: 'st-1',
      stageName: 'Contacto',
      clientId: 'cli-2',
      clientName: 'Consorcio Riego Ñuble',
      estimatedValue: 11800000,
      weightedValue: 1180000,
      expectedCloseDate: '2026-12-01',
      assignedToName: 'Josefa Lagos',
    ),
  ];

  final Map<String, List<FollowUpItem>> _activities = {
    'opp-1': [
      FollowUpItem(
        id: 'act-1',
        description: 'Presentación de propuesta en junta de vecinos APR',
        activityType: 'MEETING',
        categoryId: 'cat-2',
        categoryName: 'Revisión de propuesta',
        scheduledAt: DateTime(2026, 10, 25, 11),
        createdByName: 'Josefa Lagos',
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
      if (sourceId != null && sourceId.isNotEmpty && lead.sourceId != sourceId) {
        return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.toLowerCase();
        final hay =
            '${lead.name} ${lead.company ?? ''} ${lead.email ?? ''}'.toLowerCase();
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
  Future<void> setLeadStatus({required String id, required String status}) async {
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
  Future<OpportunityItem> retrieve(String id) async =>
      _opportunities.firstWhere((o) => o.id == id, orElse: () => _opportunities.first);

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
    final updated = OpportunityItem(
      id: prev.id,
      title: title,
      description: description ?? notes ?? prev.description,
      stageId: nextStageId,
      stageName: stage?.name ?? prev.stageName,
      clientId: clientId ?? prev.clientId,
      clientName: prev.clientName,
      estimatedValue: nextVal,
      actualValue: actualValue ?? prev.actualValue,
      weightedValue: nextVal * ((stage?.probability ?? 20) / 100.0),
      expectedCloseDate: expectedCloseDate ?? prev.expectedCloseDate,
      assignedToName: prev.assignedToName,
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
    final opp = await retrieve(id);
    final stage = _stages.where((item) => item.id == stageId).firstOrNull;
    if (stage != null &&
        stage.isLost &&
        (lostReasonId == null || lostReasonId.isEmpty)) {
      throw StateError('Marcar Perdida exige un motivo.');
    }
    await updateOpportunity(id: id, title: opp.title, stageId: stageId);
    _activities.putIfAbsent(id, () => []).insert(
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
    _activities.putIfAbsent(opportunityId, () => []).insert(
          0,
          FollowUpItem(
            id: 'act-${++_seq}',
            description: description,
            activityType: activityType,
            categoryId: categoryId,
            categoryName: cat?.name,
            scheduledAt: scheduledAt,
            createdByName: 'Demostración',
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
    _proposals.putIfAbsent(opportunityId, () => []).add(
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

  @override
  Future<KildeIndicators> kildeIndicators() async => const KildeIndicators(
        contacted: 2,
        withRequirement: 1,
        quotesAccepted: 1,
        salesCount: 1,
        salesNet: 4500000,
        weighted: 1200000,
      );

  @override
  Future<List<KildeMember>> kildeTeam() async => const [
        KildeMember(
          userId: 'ejecutivo',
          openOpportunities: 3,
          weightedValue: 1200000,
          missingNext: 1,
        ),
      ];

  @override
  Future<List<KildeRenewal>> kildeRenewals() async => const [
        KildeRenewal(
          id: 'ct-1',
          title: 'Mantención anual',
          clientName: 'APR Demo',
          endDate: '2026-12-31',
        ),
      ];

  @override
  Future<String> openRenewal(String contractId) async => 'opp-renovacion';

  @override
  Future<Map<String, dynamic>> client360(String clientId) async => {
        'client': {'id': clientId, 'name': 'APR Demo'},
        'opportunities': [
          {'id': 'opp-1', 'title': 'Pozo Sur', 'stage_name': 'Cotización'},
        ],
        'quotations': [
          {'id': 'q-1', 'status': 'accepted', 'version': 1},
        ],
        'purchase_orders': [
          {'client_po_number': 'OC-1'},
        ],
        'surveys': [
          {'id': 'sv-1', 'title': 'Levantamiento'},
        ],
        'rfis': const [],
        'derivation': {'status': 'pending_derivation'},
        'milestones': [
          {
            'channel': 'strom_install',
            'at': '2026-11-01',
            'description': 'Instalación',
          },
        ],
        'follow_up': const [],
        'contracts': const [],
        'nps': {'latest_score': 9, 'count': 1},
      };

  @override
  Future<String> openLevantamiento({
    required String opportunityId,
    required String title,
    String? quoteResponseOn,
    String? openQuestions,
    String? resolutionMeetingOn,
    bool? resolutionMeetingDone,
  }) async =>
      'sv-demo';

  @override
  Future<void> uploadClientPoFile({
    required String quotationId,
    required List<int> bytes,
    required String filename,
  }) async {}

  @override
  Future<List<KildeRfi>> rfis() async => const [
        KildeRfi(
          id: 'rfi-1',
          number: 'RFI-1',
          question: '¿El pozo tiene energía trifásica?',
          blocking: true,
          status: 'open',
        ),
      ];

  @override
  Future<void> createRfi({
    required String question,
    required bool blocking,
  }) async {}

  @override
  Future<void> answerRfi({required String id, required String answer}) async {}

  @override
  Future<List<KildeQuote>> quotations() async => const [
        KildeQuote(
          id: 'q-1',
          number: 'COT-1',
          status: 'draft',
          total: 4500000,
        ),
      ];

  @override
  Future<void> quoteAction(
    String id,
    String action, [
    Map<String, dynamic>? body,
  ]) async {}

  @override
  Future<List<LostReasonItem>> lostReasons() async => const [
        LostReasonItem(id: 'lr-1', name: 'Precio'),
      ];

  @override
  Future<void> createLostReason(String name) async {}

  @override
  Future<String> deriveToStrom(String opportunityId) async => 'proy-demo';
}
