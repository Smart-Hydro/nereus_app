import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/features/crm/data/fixture_crm_repository.dart';

void main() {
  test('la demo deja un caso Kilde que se puede recorrer', () async {
    final repo = FixtureCrmRepository();
    final stages = await repo.stages();
    final stageIds = stages.map((stage) => stage.id).toSet();
    final stageNames = stages.map((stage) => stage.name).toSet();
    final deals = await repo.opportunities();
    expect(deals, isNotEmpty);
    for (final deal in deals) {
      expect(stageIds, contains(deal.stageId));
      expect(stageNames, contains(deal.stageName));
    }

    final leads = await repo.leads();
    expect(leads.where((lead) => lead.canConvert), isNotEmpty);
    expect(
      leads.where((lead) => lead.requirementOutcome == 'without_requirement'),
      isNotEmpty,
    );
    expect(leads.where((lead) => lead.notContacted), isNotEmpty);

    final ready = deals.singleWhere((deal) => deal.id == 'opp-3');
    expect(ready.surveyId, isNotNull);
    final quotes = await repo.quotations();
    expect(
      quotes.where(
        (quote) => quote.opportunityId == ready.id && quote.acceptedWithPo,
      ),
      isNotEmpty,
    );

    await repo.quoteAction('q-1051', 'approve_discount');
    final approved = (await repo.quotations()).singleWhere(
      (quote) => quote.id == 'q-1051',
    );
    expect(approved.discountStatus, 'approved');
    await repo.answerRfi(id: 'rfi-1', answer: 'Sí, la caseta es trifásica.');
    final answered = (await repo.rfis()).singleWhere(
      (row) => row.id == 'rfi-1',
    );
    expect(answered.isOpen, isFalse);

    final indicators = await repo.kildeIndicators();
    expect(indicators.notContacted, 1);
    expect(indicators.withRequirement, 1);
    expect(indicators.salesCount, 1);
    expect(indicators.openRfis, 0);
    expect(indicators.periodLabel, isNotNull);

    final team = await repo.kildeTeam();
    expect(team.map((member) => member.name), contains('Josefa Lagos'));
    expect(team.first.todayAgenda, isNotEmpty);
  });
}
