import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/app_theme.dart';
import 'package:nereus_app/features/fichas/data/fixture_ficha_repository.dart';
import 'package:nereus_app/features/fichas/data/fixture_levantamiento_repository.dart';
import 'package:nereus_app/features/fichas/data/fixture_store.dart';
import 'package:nereus_app/features/fichas/domain/ensure_water_templates.dart';
import 'package:nereus_app/features/fichas/presentation/encuesta_public_screen.dart';
import 'package:nereus_app/features/fichas/presentation/levantamientos_screen.dart';

void main() {
  test('la demo deja publicados tenencias y captacion', () async {
    final repo = FixtureLevantamientoRepository(FixtureStore.seeded());
    final tenencias = await repo.bySlug('ficha-de-tenencias');
    final captacion = await repo.bySlug('levantamiento-de-captacion');
    expect(
      tenencias.questions
          .firstWhere((question) => question.id == 'tipo_derecho')
          .options,
      contains('Consuntivo'),
    );
    expect(
      captacion.questions
          .firstWhere((question) => question.id == 'tipo_punto')
          .options,
      contains('Pozo'),
    );
  });

  testWidgets('levantamientos muestra el enlace para compartir', (
    tester,
  ) async {
    final store = FixtureStore.seeded();
    final fichas = FixtureFichaRepository(store);
    final levantamientos = FixtureLevantamientoRepository(store);
    await ensureWaterTemplates(fichas: fichas, levantamientos: levantamientos);
    tester.view.physicalSize = const Size(1280, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(debug: true, dataMode: NereusDataMode.fixture),
          ),
          fixtureStoreProvider.overrideWithValue(store),
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
          fichaRepositoryProvider.overrideWithValue(fichas),
          levantamientoRepositoryProvider.overrideWithValue(levantamientos),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const LevantamientosScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('/encuesta/ficha-de-tenencias?demo=1'),
      findsOneWidget,
    );
    expect(find.text('Copiar enlace'), findsWidgets);
    expect(find.text('Vista previa'), findsWidgets);
    expect(find.text('Editar formulario'), findsWidgets);
  });

  testWidgets('la vista publica muestra las opciones del formulario', (
    tester,
  ) async {
    final store = FixtureStore.seeded();
    final levantamientos = FixtureLevantamientoRepository(store);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataModeProvider.overrideWithValue(NereusDataMode.fixture),
          levantamientoRepositoryProvider.overrideWithValue(levantamientos),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const EncuestaPublicScreen(slug: 'levantamiento-de-captacion'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pozo'), findsOneWidget);
    expect(find.text('Enviar respuesta'), findsOneWidget);
  });
}
