import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';

class StromDevScreen extends StatelessWidget {
  const StromDevScreen({super.key});

  static const steps = [
    _Step(
      'Proyectos',
      'Alta, estado, alcance, hitos, costo y cierre.',
      '/strom',
    ),
    _Step(
      'Instalaciones',
      'Punto de captación, equipo y requisitos.',
      '/strom/instalaciones',
    ),
    _Step(
      'OT técnica',
      'Distinta de la visita. Por especialidad.',
      '/strom/ordenes',
    ),
    _Step('Visitas', 'La primera nace planificada.', '/strom/visitas'),
    _Step(
      'Actividades',
      'Por punto. Ejecución y validación.',
      '/strom/actividades',
    ),
    _Step('Check de terreno', 'No cierra el proyecto.', '/strom/terreno'),
    _Step(
      'Check técnico',
      'Lo valida el líder de la especialidad.',
      '/strom/tecnico',
    ),
    _Step('RTS', rtsReserveNote, '/strom/rts'),
    _Step(
      'Informes',
      'Con especialidad, su líder. Sin especialidad, Operaciones o cualquier líder.',
      '/strom/informes',
    ),
    _Step(
      'Aclaraciones',
      'Preguntas y trabajo fuera de alcance.',
      '/strom/aclaraciones',
    ),
    _Step('Costos', 'Costo diario vigente de la cuadrilla.', '/strom/costos'),
    _Step(
      'Indicadores',
      'KPI-1 a KPI-9. La meta de KPI-9 es un rango.',
      '/strom/indicadores',
    ),
    _Step('Auditoría', 'Transiciones de negocio.', '/strom/auditoria'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final panel = dark ? NereusTokens.darkRaised : NereusTokens.surface;
    final line = dark ? NereusTokens.darkLine : NereusTokens.line;
    final ink = dark ? NereusTokens.darkInk : NereusTokens.ink;
    final muted = dark ? NereusTokens.darkMuted : NereusTokens.inkMuted;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: 'Dev',
        subtitle: 'Strøm — Operaciones sobre /api/operations/.',
        child: ListView.separated(
          itemCount: steps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final step = steps[index];
            return Material(
              color: panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NereusTokens.radiusLg),
                side: BorderSide(color: line),
              ),
              child: InkWell(
                onTap: () => context.go(step.path),
                splashFactory: NoSplash.splashFactory,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(NereusTokens.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: NereusTokens.hydroOlive,
                        foregroundColor: Colors.white,
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(step.detail, style: TextStyle(color: muted)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: muted),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Step {
  const _Step(this.title, this.detail, this.path);

  final String title;
  final String detail;
  final String path;
}
