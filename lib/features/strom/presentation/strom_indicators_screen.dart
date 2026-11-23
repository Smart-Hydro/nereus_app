import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/json_util.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

String _kpiName(String code) {
  final match = RegExp(r'(\d+)').firstMatch(code);
  if (match != null) return 'KPI-${match.group(1)}';
  return code;
}

List<Widget> _alertTiles(BuildContext context, WidgetRef ref) {
  final alerts = ref.watch(opsAlertsProvider);
  return alerts.when(
    loading: () => const [OpsNote('Cargando alertas.')],
    error: (_, __) => const [OpsNote('No se pudieron cargar las alertas.')],
    data: (rows) {
      final open = rows.where((row) => row.status != 'resolved').toList();
      if (open.isEmpty) return const [OpsNote('Sin alertas abiertas.')];
      return [
        for (final alert in open)
          OpsTile(
            title: alert.indicatorName.isEmpty ? 'Indicador' : alert.indicatorName,
            subtitle: [
              if (alert.projectName.isNotEmpty) alert.projectName,
              if (alert.message.isNotEmpty) alert.message,
              'Valor ${alert.value} · meta ${alert.target}',
            ].join(' · '),
            status: alert.severity == 'critical' ? 'Crítica' : 'Aviso',
            onTap: () async {
              final ok = await runOps(
                context,
                title: 'Alerta',
                message: 'Puedes marcarla como vista o resuelta.',
                confirmLabel: 'Marcar vista',
                action: () => ref
                    .read(indicatorsRepositoryProvider)
                    .markAlert(alert.id, resolve: false),
              );
              if (ok) ref.invalidate(opsAlertsProvider);
            },
          ),
      ];
    },
  );
}

String _projectTitle(WidgetRef ref, String id) {
  final projects = ref.watch(opsProjectsProvider).asData?.value ?? const [];
  for (final project in projects) {
    if (project.id == id) return project.name;
  }
  return 'Proyecto';
}

class StromIndicatorsScreen extends ConsumerWidget {
  const StromIndicatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(opsDashboardProvider);
    final targets = ref.watch(opsTargetsProvider);
    final custom = ref.watch(opsConfigurableProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StromChrome(
        title: 'Indicadores',
        subtitle: 'KPI-1 a KPI-9 y atrasos. Zona America/Santiago.',
        action: IconButton(
          onPressed: () {
            ref.invalidate(opsDashboardProvider);
            ref.invalidate(opsTargetsProvider);
            ref.invalidate(opsConfigurableProvider);
            ref.invalidate(opsAlertsProvider);
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        child: dashboard.when(
          loading: () => const ShimmerList(),
          error: (error, _) => OpsAsync(
            isLoading: false,
            error: error,
            onRetry: () => ref.invalidate(opsDashboardProvider),
            child: const SizedBox.shrink(),
          ),
          data: (data) => ListView(
            children: [
              const OpsNote(
                'La meta de KPI-9 es un rango de puntos de captación: mínimo y máximo.',
              ),
              const SizedBox(height: 8),
              if (data.timezone.isNotEmpty) OpsNote('Zona ${data.timezone}'),
              for (final entry in data.kpis.entries)
                _KpiCard(code: entry.key, value: entry.value),
              const SizedBox(height: 12),
              Text(
                'Alertas del agente',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const OpsNote(
                'El agente revisa cada hora las metas de la sucursal. No usa un modelo de lenguaje.',
              ),
              ..._alertTiles(context, ref),
              const SizedBox(height: 12),
              Text('Atrasos', style: Theme.of(context).textTheme.titleMedium),
              if (data.delayProjects.isEmpty && data.delayOrders.isEmpty)
                const OpsNote('Sin atrasos en esta sucursal.')
              else ...[
                for (final row in data.delayProjects)
                  OpsTile(
                    title: _projectTitle(ref, asString(row['project_id'])),
                    subtitle: 'Compromiso ${asString(row['committed_on'])}',
                    status: row['overdue'] == true
                        ? 'Atrasado'
                        : projectStatusLabel(asString(row['status'])),
                  ),
                for (final row in data.delayOrders)
                  OpsTile(
                    title: 'OT ${specialtyLabel(asString(row['specialty']))}',
                    subtitle: _projectTitle(ref, asString(row['project_id'])),
                    status: workOrderStatusLabel(asString(row['status'])),
                  ),
              ],
              const SizedBox(height: 12),
              Text('Metas', style: Theme.of(context).textTheme.titleMedium),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () => _target(context, ref),
                  child: const Text('Nueva meta'),
                ),
              ),
              targets.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => OpsNote('$error'),
                data: (items) => Column(
                  children: [
                    for (final item in items)
                      OpsTile(
                        title: '${_kpiName(item.kpiCode)} · ${item.category}',
                        subtitle:
                            'Puntos ${item.capturePointsMin} a ${item.capturePointsMax.isEmpty ? 'sin máximo' : item.capturePointsMax} · ${item.targetCalendarDays} días',
                        status: 'Meta',
                        onTap: () => _deleteTarget(context, ref, item),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Indicadores configurables',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () => _custom(context, ref),
                  child: const Text('Nuevo indicador'),
                ),
              ),
              custom.when(
                loading: () => const SizedBox.shrink(),
                error: (error, _) => OpsNote('$error'),
                data: (items) => Column(
                  children: [
                    for (final item in items)
                      OpsTile(
                        title: item.name,
                        subtitle:
                            '${opsLabel(item.startEvent, eventLabels)} → ${opsLabel(item.endEvent, eventLabels)}',
                        status: opsLabel(item.dayType, dayTypeLabels),
                        onTap: () => _compute(context, ref, item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _target(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Meta KPI-9',
      fields: const [
        OpsField(
          key: 'kpi',
          label: 'Indicador',
          initial: 'kpi_9',
          options: {'kpi_9': 'KPI-9'},
        ),
        OpsField(key: 'category', label: 'Categoría'),
        OpsField(
          key: 'min',
          label: 'Puntos mínimos',
          initial: '1',
          required: true,
        ),
        OpsField(
          key: 'max',
          label: 'Puntos máximos',
          hint: 'Vacío si no hay tope',
        ),
        OpsField(key: 'days', label: 'Días corridos meta', required: true),
        OpsField(key: 'notes', label: 'Notas'),
      ],
    );
    if (values == null || !context.mounted) return;
    final min = requireOpsInt(context, values['min']!, 'mínimo');
    final days = requireOpsInt(context, values['days']!, 'días');
    if (min == null || days == null) return;
    final max = (values['max'] ?? '').isEmpty
        ? null
        : requireOpsInt(context, values['max']!, 'máximo');
    if ((values['max'] ?? '').isNotEmpty && max == null) return;
    final ok = await runOps(
      context,
      title: 'Guardar meta',
      message: 'KPI-9 usa un rango de puntos de captación, no un número fijo.',
      action: () => ref.read(indicatorsRepositoryProvider).createTarget({
        'kpi_code': values['kpi'],
        'category': values['category'],
        'capture_points_min': min,
        'capture_points_max': max,
        'target_calendar_days': days,
        'notes': values['notes'],
      }),
    );
    if (ok) ref.invalidate(opsTargetsProvider);
  }

  Future<void> _deleteTarget(
    BuildContext context,
    WidgetRef ref,
    OpsIndicatorTarget item,
  ) async {
    final ok = await runOps(
      context,
      title: 'Eliminar meta',
      message: 'Se quita la meta ${_kpiName(item.kpiCode)}.',
      destructive: true,
      confirmLabel: 'Eliminar',
      action: () =>
          ref.read(indicatorsRepositoryProvider).deleteTarget(item.id),
    );
    if (ok) ref.invalidate(opsTargetsProvider);
  }

  Future<void> _custom(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Indicador configurable',
      fields: const [
        OpsField(key: 'name', label: 'Nombre', required: true),
        OpsField(
          key: 'start',
          label: 'Hito inicial',
          initial: 'official_plan',
          options: eventLabels,
        ),
        OpsField(
          key: 'end',
          label: 'Hito final',
          initial: 'report_sent',
          options: eventLabels,
        ),
        OpsField(
          key: 'days',
          label: 'Tipo de día',
          initial: 'calendar',
          options: dayTypeLabels,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Crear indicador',
      message: 'El cálculo es en consulta. No se guarda un resultado manual.',
      action: () => ref.read(indicatorsRepositoryProvider).createConfigurable({
        'name': values['name'],
        'start_event': values['start'],
        'end_event': values['end'],
        'day_type': values['days'],
        'deduct_pauses': true,
      }),
    );
    if (ok) ref.invalidate(opsConfigurableProvider);
  }

  Future<void> _compute(
    BuildContext context,
    WidgetRef ref,
    OpsConfigurableIndicator item,
  ) async {
    final project = await askOpsEntity(
      context,
      title: 'Calcular ${item.name}',
      label: 'Proyecto',
      load: OpsLookups(ref).projects,
    );
    if (project == null || !context.mounted) return;
    await runOps(
      context,
      title: 'Calcular',
      message: 'Se cuentan días corridos o hábiles entre los hitos.',
      confirm: false,
      action: () async {
        final result = await ref
            .read(indicatorsRepositoryProvider)
            .compute(
              item.id,
              projectId: project.id,
            );
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item.name),
            content: Text(
              'Días ${asString(result['days'] ?? result['calendar_days'])}\n'
              '${opsLabel(asString(result['day_type']), dayTypeLabels)}',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  final host = Navigator.of(context);
                  final ok = await runOps(
                    context,
                    title: 'Eliminar indicador',
                    message: 'Se quita ${item.name}.',
                    destructive: true,
                    confirmLabel: 'Eliminar',
                    action: () => ref
                        .read(indicatorsRepositoryProvider)
                        .deleteConfigurable(item.id),
                  );
                  if (ok) {
                    ref.invalidate(opsConfigurableProvider);
                    host.pop();
                  }
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.code, required this.value});

  final String code;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final raw = value;
    final count = raw is List ? '${raw.length} filas' : _brief(raw);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        child: ListTile(
          title: Text(_kpiLabel(code)),
          subtitle: Text(count),
        ),
      ),
    );
  }

  String _kpiLabel(String code) {
    final match = RegExp(r'(\d+)').firstMatch(code);
    if (match != null) return 'KPI-${match.group(1)}';
    return code;
  }

  String _brief(Object? value) {
    if (value is Map) {
      final map = Map<Object?, Object?>.from(value);
      final days = map['calendar_days'] ?? map['count'] ?? map['value'];
      if (days != null) return asString(days);
      return '${map.length} campos';
    }
    return asString(value);
  }
}
