import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';

void main() {
  test('el ejecutivo no aprueba descuentos y el pendiente bloquea el envío', () {
    expect(
      showDiscountDecision(roleCode: kildeSalesRep, discountStatus: 'pending'),
      isFalse,
    );
    expect(
      showDiscountDecision(roleCode: kildeSalesLead, discountStatus: 'pending'),
      isTrue,
    );
    expect(
      quoteSendBlocked(discountStatus: 'pending', blockingRfiOpen: false),
      isTrue,
    );
    expect(
      quoteSendBlocked(discountStatus: 'approved', blockingRfiOpen: true),
      isTrue,
    );
    expect(
      quoteSendBlocked(discountStatus: '', blockingRfiOpen: false),
      isFalse,
    );
  });

  test('derivar exige líder, ficha y OC de una cotización aceptada', () {
    expect(
      deriveEnabled(
        roleCode: kildeSalesRep,
        hasSurvey: true,
        hasAcceptedQuoteWithPo: true,
      ),
      isFalse,
    );
    expect(
      deriveEnabled(
        roleCode: kildeSalesLead,
        hasSurvey: false,
        hasAcceptedQuoteWithPo: true,
      ),
      isFalse,
    );
    expect(
      deriveEnabled(
        roleCode: kildeSalesLead,
        hasSurvey: true,
        hasAcceptedQuoteWithPo: true,
      ),
      isTrue,
    );
  });

  test('sin requerimiento no convierte y el equipo trae la agenda', () {
    const blocked = LeadItem(
      id: '1',
      firstName: 'Ana',
      status: 'CONTACTED',
      requirementOutcome: 'without_requirement',
    );
    expect(blocked.canConvert, isFalse);
    expect(
      const LeadItem(id: '2', firstName: 'Ana', status: 'NEW').notContacted,
      isTrue,
    );
    final member = KildeMember.fromJson(const {
      'user_id': '9',
      'username': 'invited_josefa',
      'name': 'Josefa Lagos',
      'open_opportunities': 2,
      'week_activities': 4,
      'missing_next_action': 1,
      'today_agenda': [
        {'activity_type': 'CALL', 'description': 'Llamar al APR'},
      ],
    });
    expect(member.label, 'Josefa Lagos');
    expect(
      KildeMember.fromJson(const {
        'user_id': '171',
        'username': 'invited_171',
      }).label,
      'Ejecutivo',
    );
    expect(member.weekActivities, 4);
    expect(member.todayAgenda.single, contains('Llamada'));
    expect(member.missingNext, 1);
  });

  test('la cotización lee versión, vigencia y OC', () {
    final quote = KildeQuote.fromJson(const {
      'id': 'q',
      'order_number': 'COT-2',
      'kilde_quote_status': 'accepted',
      'version': 2,
      'valid_until': '2026-12-01',
      'parent_quotation': 'q-1',
      'client_po_number': 'OC-9',
      'client_po_net_amount': '1000',
      'discount_approval_status': 'pending',
    });
    expect(quote.version, 2);
    expect(quote.parentId, 'q-1');
    expect(quote.acceptedWithPo, isTrue);
    expect(quote.validUntil, '2026-12-01');
  });

  test('la OC de la versión mayor habilita derivar aunque la v1 no la tenga', () {
    const v1 = KildeQuote(
      id: 'v1',
      number: 'B1-261122-0001',
      status: 'accepted',
      version: 1,
      opportunityId: 'opp',
    );
    const v2 = KildeQuote(
      id: 'v2',
      number: 'B1-261122-0002',
      status: 'accepted',
      version: 2,
      opportunityId: 'opp',
      poNumber: 'OC-PRUEBA',
      poNet: 1000,
    );
    const draft = KildeQuote(
      id: 'v3',
      number: 'B1-261122-0003',
      status: 'draft',
      version: 3,
      opportunityId: 'opp',
      poNumber: 'NO',
      poNet: 1,
    );
    final chosen = acceptedQuoteWithPo([v1, draft, v2], opportunityId: 'opp');
    expect(chosen?.number, 'B1-261122-0002');
    expect(
      deriveEnabled(
        roleCode: kildeSalesLead,
        hasSurvey: true,
        hasAcceptedQuoteWithPo: chosen != null,
      ),
      isTrue,
    );
    expect(acceptedQuoteWithPo([v1], opportunityId: 'opp'), isNull);
    expect(showLeadOnlyDestination(roleCode: kildeSalesRep, leadOnly: true), isFalse);
    expect(showLeadOnlyDestination(roleCode: kildeSalesLead, leadOnly: true), isTrue);
    expect(showLeadOnlyDestination(roleCode: null, leadOnly: true), isTrue);
  });

  test('las consultas pendientes se agrupan por persona y oportunidad', () {
    final indicators = KildeIndicators.fromJson(const {
      'open_rfis': [
        {
          'assigned_to_name': 'Ana Soto',
          'count': 2,
          'oldest_at': '2026-11-02T10:00:00',
          'opportunities': [
            {'id': '1', 'title': 'PRUEBA Pozo'},
          ],
        },
      ],
    });
    expect(indicators.openRfis, 2);
    expect(indicators.openRfiPeople.single.name, 'Ana Soto');
    expect(indicators.openRfiPeople.single.opportunities, ['PRUEBA Pozo']);
    final handoff = KildeHandoff.fromJson(const {
      'client': {'id': 'c', 'name': 'Agrícola El Roble'},
      'contacts': [
        {'first_name': 'Ana', 'last_name': 'Soto', 'email': 'ana@roble.test'},
      ],
      'wells': [
        {'name': 'Pozo Norte'},
      ],
      'quotation': {
        'order_number': 'B1-261122-0002',
        'version': 2,
        'total_amount': '19300000',
      },
      'equipment': [
        {'product_name': 'Caudalímetro', 'quantity': 3},
      ],
      'survey': {'id': 's', 'title': 'Ficha 3 pozos'},
      'closed_rfis': [
        {
          'id': 'r',
          'question': '¿Caudal?',
          'answer': '12 L/s',
          'answered_by_name': 'Josefa Lagos',
        },
      ],
    });
    expect(handoff.clientName, 'Agrícola El Roble');
    expect(handoff.quotation, contains('B1-261122-0002'));
    expect(handoff.wells, ['Pozo Norte']);
    expect(handoff.surveyTitle, 'Ficha 3 pozos');
    expect(handoff.closedRfis.single.answeredBy, 'Josefa Lagos');
  });

  test('una cotización vence el día después de valid_until', () {
    final today = DateTime(2026, 11, 22);
    expect(quoteIsExpired('2026-11-22', today: today), isFalse);
    expect(quoteIsExpired('2026-11-21', today: today), isTrue);
    expect(quoteIsExpired('2026-11-21T23:30:00', today: today), isTrue);
    expect(quoteIsExpired(null, today: today), isFalse);
    expect(quoteIsExpired('mañana', today: today), isFalse);
    expect(isIsoDate('2026-11-22'), isTrue);
    expect(isIsoDate('2026-02-31'), isFalse);
    expect(canRegisterClientPo('accepted'), isTrue);
    expect(canRegisterClientPo('sent'), isFalse);
    expect(
      quoteShowsExpired(status: 'expired', validUntil: '2026-12-01', today: today),
      isTrue,
    );
  });
}
