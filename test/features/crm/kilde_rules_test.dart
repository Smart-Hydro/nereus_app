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
