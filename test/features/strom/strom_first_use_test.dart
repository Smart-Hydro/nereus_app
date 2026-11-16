import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/network/fixture_api.dart';
import 'package:nereus_app/core/network/session_controller.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/strom/presentation/strom_activities_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_costs_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_field_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_indicators_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_installations_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_orders_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_project_form.dart';
import 'package:nereus_app/features/strom/presentation/strom_project_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_projects_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_reports_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_rts_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_visit_form.dart';
import 'package:nereus_app/features/strom/presentation/strom_visit_screen.dart';
import 'package:nereus_app/features/strom/presentation/strom_visits_screen.dart';

part 'strom_first_use_support.dart';

void main() {
  testWidgets('primer uso de Strøm con selectores, sin escribir ids', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final session = SessionController()..token = 'fixture-token';
    final dio = Dio(BaseOptions(baseUrl: 'https://gateway.smarthydro.app'))
      ..interceptors.add(FixtureApiInterceptor(session));
    addTearDown(dio.close);

    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await _until(tester, find.text('Instalación Norte'));

    await _tapButton(tester, 'Crear');
    await _until(tester, find.text('Crear proyecto'));
    _expectNoIdField(tester);
    await _fill(tester, 'Nombre', 'Pozo El Huape');
    await _tapText(tester, 'Ana Lagos');
    await _tapButton(tester, 'Guardar');
    await _until(tester, find.text('Pozo El Huape'));
    final projectId = router.state.uri.pathSegments.last;

    await _tapButton(tester, 'Importar alcance');
    await _until(tester, find.text('Pozo 1'));
    _expectNoIdField(tester);
    await _tapText(tester, 'Pozo 1');
    await _tapButton(tester, 'Guardar');
    await _until(tester, find.text('Actividad del alcance'));
    await _fill(tester, 'Actividad', 'Medir caudal del pozo nuevo');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Medir caudal del pozo nuevo'));
    await _tapButton(tester, 'Confirmar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('Confirmado'));

    await _tapButton(tester, 'Instalaciones');
    await _until(tester, find.text('Pozo Norte'));
    await _tapButton(tester, 'Crear');
    await _until(tester, find.text('Puntos de la instalación'));
    _expectNoIdField(tester);
    await _tapText(tester, 'Pozo 1');
    await _tapButton(tester, 'Listo');
    await _until(tester, find.text('Nueva instalación'));
    await _fill(tester, 'Nombre', 'Batería El Huape');
    await _tapText(tester, 'Agrícola Santa Rosa SpA');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('1 puntos de captación'));

    router.go('/strom/ordenes?proyecto=$projectId');
    await _until(tester, find.text('Sugerir'));
    await _tapButton(tester, 'Sugerir');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('OT Hidráulica'));
    await _tapText(tester, 'OT Hidráulica');
    await _until(tester, find.text('Nueva visita'));
    final orderId = router.state.uri.pathSegments.last;

    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Referencia comercial'));
    _expectNoIdField(tester);
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('Confirmada'));

    await _tapButton(tester, 'Nueva visita');
    await _until(
      tester,
      find.text('La primera visita de la OT queda planificada.'),
    );
    _expectNoIdField(tester);
    expect(find.text('OT Hidráulica'), findsWidgets);
    await _tapButton(tester, 'Crear visita');
    await _until(tester, find.textContaining('Planificada'));
    final visitId = router.state.uri.pathSegments.last;

    await _tapButton(tester, 'Programar');
    await _until(tester, find.byIcon(Icons.calendar_today));
    await tester.tap(find.byIcon(Icons.calendar_today).last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(DateTime.now().day.toString()).last);
    await tester.pump(const Duration(milliseconds: 200));
    final accept = find.text('OK');
    await tester.tap(
      (accept.evaluate().isNotEmpty ? accept : find.text('Aceptar')).last,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('Programada'));

    await _tapButton(tester, 'Sumar cuadrilla');
    await _until(tester, find.text('Cuadrilla Sur'));
    _expectNoIdField(tester);
    await _tapText(tester, 'Cuadrilla Sur');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('En la visita'));

    await _tapButton(tester, 'Actividades');
    await _until(tester, find.text('Materializar'));
    await _tapButton(tester, 'Materializar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Medir caudal del pozo'));

    router.go('/strom/terreno?visita=$visitId');
    await _until(tester, find.text('Registrar'));
    await _tapButton(tester, 'Registrar');
    await _until(tester, find.text('Visita de esta ficha'));
    _expectNoIdField(tester);
    await _tapText(tester, 'Medir caudal del pozo');
    await _fill(tester, 'Observación', 'Caudal en rango');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Caudal en rango'));

    await _selectTab(tester, 'Evidencias');
    await _tapButton(tester, 'Agregar');
    await _until(tester, find.text('Visita de esta ficha'));
    await _fill(tester, 'Descripción', 'Tablero del pozo nuevo');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Tablero del pozo nuevo'));
    await _tapText(tester, 'Tablero del pozo nuevo');
    await _until(tester, find.text('Vincular Drive'));
    await _tapText(tester, 'Vincular Drive');
    await _until(tester, find.textContaining('Enlace de Drive'));
    await _fill(
      tester,
      'Enlace de Drive',
      'https://drive.google.com/file/d/tablero-huape/view',
    );
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('tablero-huape'));

    router.go('/strom/rts?ot=$orderId');
    await _until(tester, find.text('Crear'));
    await _tapButton(tester, 'Crear');
    await _until(tester, find.text('OT de esta orden'));
    _expectNoIdField(tester);
    await _tapText(tester, 'Sensor caudal');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('RTS Hidráulica'));
    await _tapText(tester, 'RTS Hidráulica');
    await _until(tester, find.text('Reservar'));
    await _tapButton(tester, 'Reservar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('stock 5'));
    await _tapButton(tester, 'Dar salida');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Con salida'));

    router.go('/strom/informes?proyecto=$projectId');
    await _until(tester, find.text('Generar'));
    await _tapButton(tester, 'Generar');
    await _until(tester, find.text('Proyecto de esta ficha'));
    _expectNoIdField(tester);
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Informe versión 1'));
    await _tapText(tester, 'Informe versión 1');
    await _until(tester, find.text('Enviar a revisión'));
    await _tapButton(tester, 'Enviar a revisión');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Aprobar'));
    await _tapButton(tester, 'Aprobar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.text('Enviar'));
    await _tapButton(tester, 'Enviar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('Enviado'));

    router.go('/strom/costos?proyecto=$projectId&ot=$orderId');
    await _until(tester, find.text('Costo del proyecto'));
    await _tapButton(tester, 'Costo del proyecto');
    await _until(tester, find.textContaining('Total'));
    expect(find.text('1 OT'), findsOneWidget);
    await _tapButton(tester, 'Cerrar');
    await _tapButton(tester, 'Costo de la OT');
    await _until(tester, find.textContaining('Total'));
    await _tapButton(tester, 'Cerrar');

    router.go('/strom/indicadores');
    await _until(tester, find.text('KPI-9'));
    expect(find.text('Falla de logger'), findsOneWidget);
    expect(find.text('OT Hidráulica'), findsWidgets);
    await _tapButton(tester, 'Nueva meta');
    await _until(tester, find.text('KPI-9'));
    _expectNoIdField(tester);
    await _fill(tester, 'Puntos mínimos', '1');
    await _fill(tester, 'Puntos máximos', '3');
    await _fill(tester, 'Días corridos meta', '20');
    await _tapButton(tester, 'Guardar');
    await _tapButton(tester, 'Confirmar');
    await _until(tester, find.textContaining('KPI-9 ·'));
    await _tapText(tester, 'Plan a informe');
    await _until(tester, find.text('Pozo El Huape'));
    await _tapText(tester, 'Pozo El Huape');
    await _tapButton(tester, 'Guardar');
    await _until(tester, find.textContaining('Días'));
  }, timeout: const Timeout(Duration(minutes: 3)));
}

GoRouter _router() {
  return GoRouter(
    initialLocation: '/strom',
    routes: [
      GoRoute(
        path: '/strom',
        builder: (_, __) => const StromProjectsScreen(),
        routes: [
          GoRoute(
            path: 'nuevo',
            builder: (_, __) => const StromProjectCreateScreen(),
          ),
          GoRoute(
            path: 'instalaciones',
            builder: (_, __) => const StromInstallationsScreen(),
          ),
          GoRoute(
            path: 'ordenes',
            builder: (_, __) => const StromOrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    StromOrderScreen(orderId: state.pathParameters['id']!),
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
                builder: (context, state) =>
                    StromVisitScreen(visitId: state.pathParameters['visitId']!),
              ),
            ],
          ),
          GoRoute(
            path: 'actividades',
            builder: (_, __) => const StromActivitiesScreen(),
          ),
          GoRoute(
            path: 'terreno',
            builder: (_, __) => const StromFieldScreen(),
          ),
          GoRoute(
            path: 'rts',
            builder: (_, __) => const StromRtsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    StromRtsDetailScreen(rtsId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: 'informes',
            builder: (_, __) => const StromReportsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    StromReportScreen(reportId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: 'costos', builder: (_, __) => const StromCostsScreen()),
          GoRoute(
            path: 'indicadores',
            builder: (_, __) => const StromIndicatorsScreen(),
          ),
          GoRoute(
            path: ':projectId',
            builder: (context, state) => StromProjectScreen(
              projectId: state.pathParameters['projectId']!,
            ),
          ),
        ],
      ),
    ],
  );
}
