import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';

final kildeIndicatorsProvider = FutureProvider<KildeIndicators>((ref) {
  return ref.watch(crmRepositoryProvider).kildeIndicators();
});

final kildeTeamProvider = FutureProvider<List<KildeMember>>((ref) {
  return ref.watch(crmRepositoryProvider).kildeTeam();
});

final todayActivitiesProvider = FutureProvider<List<FollowUpItem>>((ref) {
  return ref.watch(crmRepositoryProvider).todayActivities();
});

final kildeRenewalsProvider = FutureProvider<List<KildeRenewal>>((ref) {
  return ref.watch(crmRepositoryProvider).kildeRenewals();
});

final kildeRfisProvider = FutureProvider<List<KildeRfi>>((ref) {
  return ref.watch(crmRepositoryProvider).rfis();
});

final kildeQuotesProvider = FutureProvider<List<KildeQuote>>((ref) {
  return ref.watch(crmRepositoryProvider).quotations();
});

final opportunityQuotesProvider =
    FutureProvider.family<List<KildeQuote>, String>((ref, opportunityId) {
  return ref.watch(crmRepositoryProvider).quotations(
        opportunityId: opportunityId,
      );
});

final lostReasonsProvider = FutureProvider<List<LostReasonItem>>((ref) {
  return ref.watch(crmRepositoryProvider).lostReasons();
});
