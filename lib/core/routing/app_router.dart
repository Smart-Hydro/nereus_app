import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/alerts/presentation/alerts_screen.dart';
import 'package:nereus_app/features/auth/presentation/branch_picker_screen.dart';
import 'package:nereus_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:nereus_app/features/auth/presentation/login_screen.dart';
import 'package:nereus_app/features/auth/presentation/reset_password_screen.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/catalog/presentation/catalog_screen.dart';
import 'package:nereus_app/features/crm/presentation/kilde_screens.dart';
import 'package:nereus_app/features/crm/presentation/cotizacion_public_screen.dart';
import 'package:nereus_app/features/crm/presentation/kilde_quotes_screen.dart';
import 'package:nereus_app/features/crm/presentation/opportunity_screen.dart';
import 'package:nereus_app/features/crm/presentation/pipeline_screen.dart';
import 'package:nereus_app/features/crm/presentation/prospectos_screen.dart';
import 'package:nereus_app/features/customers/presentation/clients_screen.dart';
import 'package:nereus_app/features/fichas/presentation/client_360_screen.dart';
import 'package:nereus_app/features/fichas/presentation/ficha_admin_screen.dart';
import 'package:nereus_app/features/fichas/presentation/fichas_screen.dart';
import 'package:nereus_app/features/fichas/presentation/encuesta_public_screen.dart';
import 'package:nereus_app/features/fichas/presentation/levantamiento_edit_screen.dart';
import 'package:nereus_app/features/fichas/presentation/levantamiento_fill_screen.dart';
import 'package:nereus_app/features/fichas/presentation/levantamientos_screen.dart';
import 'package:nereus_app/features/devices/presentation/device_detail_screen.dart';
import 'package:nereus_app/features/devices/presentation/devices_screen.dart';
import 'package:nereus_app/features/equipment/presentation/equipment_screen.dart';
import 'package:nereus_app/features/home/presentation/home_shell.dart';
import 'package:nereus_app/features/home/presentation/home_screen.dart';
import 'package:nereus_app/features/inventory/presentation/inventory_screen.dart';
import 'package:nereus_app/features/org/presentation/org_screen.dart';
import 'package:nereus_app/features/points/presentation/points_screen.dart';
import 'package:nereus_app/features/profile/presentation/profile_screen.dart';
import 'package:nereus_app/features/settings/presentation/settings_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_activities_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_audit_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_config_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_coordination_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_costs_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_desk.dart';
import 'package:nereus_app/features/strom/presentation/strom_dev_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_field_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_indicators_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_installations_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_orders_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_project_form.dart';
import 'package:nereus_app/features/strom/presentation/strom_project_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_projects_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_reports_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_rts_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_technical_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_visit_form.dart';
import 'package:nereus_app/features/strom/presentation/strom_visit_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_visits_screen.dart';
import 'package:nereus_app/features/tickets/presentation/ticket_create_screen.dart';
import 'package:nereus_app/features/tickets/presentation/ticket_detail_screen.dart';
import 'package:nereus_app/features/tickets/presentation/tickets_screen.dart';
import 'package:nereus_app/features/tour/presentation/tour_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider).value;
      final loc = state.matchedLocation;
      final isReset = loc.startsWith('/reset-password');
      final isPublicLink =
          loc.startsWith('/encuesta') || loc.startsWith('/cotizacion');
      final loggingIn = loc == '/login' || loc == '/forgot-password';
      if (session == null || isPublicLink) return null;
      if (isReset) return null;
      if (!session.isAuthenticated) {
        return loggingIn ? null : '/login';
      }
      if (session.needsBranch) {
        return loc == '/branch' ? null : '/branch';
      }
      if (loggingIn || loc == '/branch') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password/:token',
        builder: (context, state) => ResetPasswordScreen(
          token: state.pathParameters['token'] ?? '',
        ),
      ),
      GoRoute(path: '/branch', builder: (_, __) => const BranchPickerScreen()),
      GoRoute(
        path: '/encuesta/:slug',
        builder: (context, state) => EncuestaPublicScreen(
          slug: state.pathParameters['slug'] ?? '',
          demo: state.uri.queryParameters['demo'] == '1',
        ),
      ),
      GoRoute(
        path: '/cotizacion/:id',
        builder: (context, state) => CotizacionPublicScreen(
          id: state.pathParameters['id'] ?? '',
          demo: state.uri.queryParameters['demo'] == '1',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
              GoRoute(path: '/tour', builder: (_, __) => const TourScreen()),
              GoRoute(
                path: '/alerts',
                builder: (_, __) => const AlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalog',
                builder: (_, __) => const CatalogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (_, __) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/clients',
                builder: (_, __) => const ClientsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => Client360Screen(
                      clientId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/prospectos',
                builder: (_, __) => const ProspectosScreen(),
              ),
              GoRoute(
                path: '/kilde/indicadores',
                builder: (_, __) => const KildeIndicatorsScreen(),
              ),
              GoRoute(
                path: '/kilde/equipo',
                builder: (_, __) => const KildeTeamScreen(),
              ),
              GoRoute(
                path: '/kilde/renovaciones',
                builder: (_, __) => const KildeRenewalsScreen(),
              ),
              GoRoute(
                path: '/kilde/consultas',
                builder: (_, __) => const KildeRfiScreen(),
              ),
              GoRoute(
                path: '/kilde/cotizaciones',
                builder: (_, __) => const KildeQuotesScreen(),
              ),
              GoRoute(
                path: '/kilde/motivos',
                builder: (_, __) => const KildeLostReasonsScreen(),
              ),
              GoRoute(
                path: '/pipeline',
                builder: (context, state) => PipelineScreen(
                  clientId: state.uri.queryParameters['client'],
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OpportunityScreen(
                      opportunityId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/fichas',
                builder: (_, __) => const FichasScreen(),
              ),
              GoRoute(
                path: '/fichas/admin',
                builder: (_, __) => const FichaAdminScreen(),
              ),
              GoRoute(
                path: '/levantamientos',
                builder: (_, __) => const LevantamientosScreen(),
                routes: [
                  GoRoute(
                    path: 'fill/:id',
                    builder: (context, state) => LevantamientoFillScreen(
                      surveyId: state.pathParameters['id'] ?? '',
                      clientId: state.uri.queryParameters['client'],
                    ),
                  ),
                  GoRoute(
                    path: 'editar/:id',
                    builder: (context, state) => LevantamientoEditScreen.survey(
                      surveyId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'plantilla/:id/editar',
                    builder: (context, state) =>
                        LevantamientoEditScreen.template(
                          templateId: state.pathParameters['id'] ?? '',
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/points',
                builder: (_, __) => const PointsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/equipment',
                builder: (_, __) => const EquipmentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/devices',
                builder: (_, __) => const DevicesScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => DeviceDetailScreen(
                      deviceId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (_, __) => const TicketsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => TicketCreateScreen(
                      deviceId: state.uri.queryParameters['device'],
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => TicketDetailScreen(
                      ticketId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) => StromDesk(
                  location: state.uri.path,
                  child: child,
                ),
                routes: [
                  GoRoute(
                    path: '/strom',
                    builder: (_, __) => const StromProjectsScreen(),
                    routes: [
                      GoRoute(
                        path: 'dev',
                        builder: (_, __) => const StromDevScreen(),
                      ),
                      GoRoute(
                        path: 'nuevo',
                        builder: (_, __) => const StromProjectCreateScreen(),
                      ),
                      GoRoute(
                        path: 'instalaciones',
                        builder: (_, __) => const StromInstallationsScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) =>
                                StromInstallationScreen(
                                  installationId: state.pathParameters['id']!,
                                ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'ordenes',
                        builder: (_, __) => const StromOrdersScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => StromOrderScreen(
                              orderId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'visitas',
                        builder: (_, __) => const StromVisitsScreen(),
                        routes: [
                          GoRoute(
                            path: 'nueva',
                            builder: (context, state) => StromVisitCreateScreen(
                              workOrderId: state.uri.queryParameters['ot'],
                            ),
                          ),
                          GoRoute(
                            path: ':visitId',
                            builder: (context, state) => StromVisitScreen(
                              visitId: state.pathParameters['visitId']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'actividades',
                        builder: (_, __) => const StromActivitiesScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => StromActivityScreen(
                              activityId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'terreno',
                        builder: (_, __) => const StromFieldScreen(),
                      ),
                      GoRoute(
                        path: 'tecnico',
                        builder: (_, __) => const StromTechnicalScreen(),
                      ),
                      GoRoute(
                        path: 'rts',
                        builder: (_, __) => const StromRtsScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => StromRtsDetailScreen(
                              rtsId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'informes',
                        builder: (_, __) => const StromReportsScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => StromReportScreen(
                              reportId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'aclaraciones',
                        builder: (_, __) => const StromClarificationsScreen(),
                      ),
                      GoRoute(
                        path: 'costos',
                        builder: (_, __) => const StromCostsScreen(),
                      ),
                      GoRoute(
                        path: 'auditoria',
                        builder: (_, __) => const StromAuditScreen(),
                        routes: [
                          GoRoute(
                            path: ':id',
                            builder: (context, state) => StromTransitionScreen(
                              transitionId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                      GoRoute(
                        path: 'indicadores',
                        builder: (_, __) => const StromIndicatorsScreen(),
                      ),
                      GoRoute(
                        path: 'configuracion',
                        builder: (_, __) => const StromConfigScreen(),
                      ),
                      GoRoute(
                        path: ':projectId',
                        builder: (context, state) => StromProjectScreen(
                          projectId: state.pathParameters['projectId']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'editar',
                            builder: (context, state) =>
                                StromProjectCreateScreen(
                                  projectId: state.pathParameters['projectId'],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (_, __) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'org',
                    builder: (_, __) => const OrgScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
