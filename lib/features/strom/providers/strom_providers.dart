import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/features/strom/data/activities_repository.dart';
import 'package:nereus_app/features/strom/data/audit_repository.dart';
import 'package:nereus_app/features/strom/data/coordination_repository.dart';
import 'package:nereus_app/features/strom/data/costs_repository.dart';
import 'package:nereus_app/features/strom/data/field_repository.dart';
import 'package:nereus_app/features/strom/data/indicators_repository.dart';
import 'package:nereus_app/features/strom/data/installations_repository.dart';
import 'package:nereus_app/features/strom/data/ops_http.dart';
import 'package:nereus_app/features/strom/data/projects_repository.dart';
import 'package:nereus_app/features/strom/data/reports_repository.dart';
import 'package:nereus_app/features/strom/data/rts_repository.dart';
import 'package:nereus_app/features/strom/data/visits_repository.dart';
import 'package:nereus_app/features/strom/data/work_orders_repository.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';

OpsHttp _http(Ref ref) => OpsHttp(ref.watch(dioProvider));

final projectsRepositoryProvider = Provider<ProjectsRepository>(
  (ref) => ProjectsRepository(_http(ref)),
);
final installationsRepositoryProvider = Provider<InstallationsRepository>(
  (ref) => InstallationsRepository(_http(ref)),
);
final workOrdersRepositoryProvider = Provider<WorkOrdersRepository>(
  (ref) => WorkOrdersRepository(_http(ref)),
);
final visitsRepositoryProvider = Provider<VisitsRepository>(
  (ref) => VisitsRepository(_http(ref)),
);
final activitiesRepositoryProvider = Provider<ActivitiesRepository>(
  (ref) => ActivitiesRepository(_http(ref)),
);
final fieldRepositoryProvider = Provider<FieldRepository>(
  (ref) => FieldRepository(_http(ref)),
);
final rtsRepositoryProvider = Provider<RtsRepository>((ref) => RtsRepository(_http(ref)));
final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(_http(ref)),
);
final coordinationRepositoryProvider = Provider<CoordinationRepository>(
  (ref) => CoordinationRepository(_http(ref)),
);
final costsRepositoryProvider = Provider<CostsRepository>(
  (ref) => CostsRepository(_http(ref)),
);
final indicatorsRepositoryProvider = Provider<IndicatorsRepository>(
  (ref) => IndicatorsRepository(_http(ref)),
);
final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(_http(ref)),
);

final opsProjectsProvider = FutureProvider.autoDispose<List<OpsProject>>((ref) {
  return ref.watch(projectsRepositoryProvider).list();
});

final opsProjectProvider = FutureProvider.autoDispose.family<OpsProject, String>((ref, id) {
  return ref.watch(projectsRepositoryProvider).get(id);
});

final opsInstallationsProvider = FutureProvider.autoDispose<List<OpsInstallation>>((ref) {
  return ref.watch(installationsRepositoryProvider).list();
});

final opsInstallationProvider =
    FutureProvider.autoDispose.family<OpsInstallation, String>((ref, id) {
  return ref.watch(installationsRepositoryProvider).get(id);
});

final opsEquipmentProvider = FutureProvider.autoDispose<List<OpsEquipment>>((ref) {
  return ref.watch(installationsRepositoryProvider).equipment();
});

final opsSiteRequirementsProvider =
    FutureProvider.autoDispose<List<OpsSiteRequirement>>((ref) {
  return ref.watch(installationsRepositoryProvider).siteRequirements();
});

final opsObligationsProvider = FutureProvider.autoDispose<List<OpsObligation>>((ref) {
  return ref.watch(installationsRepositoryProvider).obligations();
});

final opsOrdersProvider = FutureProvider.autoDispose<List<OpsWorkOrder>>((ref) {
  return ref.watch(workOrdersRepositoryProvider).list();
});

final opsOrderProvider = FutureProvider.autoDispose.family<OpsWorkOrder, String>((ref, id) {
  return ref.watch(workOrdersRepositoryProvider).get(id);
});

final opsScopeChangesProvider =
    FutureProvider.autoDispose.family<List<OpsScopeChange>, String>((ref, id) {
  return ref.watch(workOrdersRepositoryProvider).scopeChanges(id);
});

final opsVisitsProvider = FutureProvider.autoDispose<List<OpsVisit>>((ref) {
  return ref.watch(visitsRepositoryProvider).list();
});

final opsVisitProvider = FutureProvider.autoDispose.family<OpsVisit, String>((ref, id) {
  return ref.watch(visitsRepositoryProvider).get(id);
});

final opsCrewProvider = FutureProvider.autoDispose<List<OpsCrewMember>>((ref) {
  return ref.watch(visitsRepositoryProvider).crew();
});

final opsActivitiesProvider = FutureProvider.autoDispose<List<OpsActivity>>((ref) {
  return ref.watch(activitiesRepositoryProvider).list();
});

final opsActivityProvider = FutureProvider.autoDispose.family<OpsActivity, String>((ref, id) {
  return ref.watch(activitiesRepositoryProvider).get(id);
});

final opsFieldChecksProvider = FutureProvider.autoDispose<List<OpsFieldCheck>>((ref) {
  return ref.watch(fieldRepositoryProvider).checks();
});

final opsEvidencesProvider = FutureProvider.autoDispose<List<OpsEvidence>>((ref) {
  return ref.watch(fieldRepositoryProvider).evidences();
});

final opsRtsProvider = FutureProvider.autoDispose<List<OpsRts>>((ref) {
  return ref.watch(rtsRepositoryProvider).list();
});

final opsRtsDetailProvider = FutureProvider.autoDispose.family<OpsRts, String>((ref, id) {
  return ref.watch(rtsRepositoryProvider).get(id);
});

final opsReportsProvider = FutureProvider.autoDispose<List<OpsReport>>((ref) {
  return ref.watch(reportsRepositoryProvider).list();
});

final opsReportProvider = FutureProvider.autoDispose.family<OpsReport, String>((ref, id) {
  return ref.watch(reportsRepositoryProvider).get(id);
});

final opsClarificationsProvider = FutureProvider.autoDispose<List<OpsClarification>>((ref) {
  return ref.watch(coordinationRepositoryProvider).clarifications();
});

final opsOutOfScopeProvider = FutureProvider.autoDispose<List<OpsOutOfScope>>((ref) {
  return ref.watch(coordinationRepositoryProvider).outOfScope();
});

final opsDailyCostsProvider = FutureProvider.autoDispose<List<OpsDailyCost>>((ref) {
  return ref.watch(costsRepositoryProvider).daily();
});

final opsDashboardProvider = FutureProvider.autoDispose<OpsDashboard>((ref) {
  return ref.watch(indicatorsRepositoryProvider).dashboard();
});

final opsTargetsProvider = FutureProvider.autoDispose<List<OpsIndicatorTarget>>((ref) {
  return ref.watch(indicatorsRepositoryProvider).targets();
});

final opsConfigurableProvider =
    FutureProvider.autoDispose<List<OpsConfigurableIndicator>>((ref) {
  return ref.watch(indicatorsRepositoryProvider).configurable();
});

final opsTransitionsProvider = FutureProvider.autoDispose<List<OpsTransition>>((ref) {
  return ref.watch(auditRepositoryProvider).list();
});

final opsTransitionProvider =
    FutureProvider.autoDispose.family<OpsTransition, String>((ref, id) {
  return ref.watch(auditRepositoryProvider).get(id);
});
