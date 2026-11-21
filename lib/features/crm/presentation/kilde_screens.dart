import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';

class KildeIndicatorsScreen extends ConsumerWidget {
  const KildeIndicatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(kildeIndicatorsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            kicker: 'Kilde',
            title: 'Indicadores',
            subtitle: 'Prospectos, cotizaciones y ventas del período',
            actions: [
              IconButton(
                tooltip: 'Actualizar',
                onPressed: () => ref.invalidate(kildeIndicatorsProvider),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: !snap.hasValue,
              errorMessage: userFacingErrorMessage(snap.error ?? 'Error'),
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeIndicatorsProvider),
              child: _IndicatorGrid(data: snap.value ?? const KildeIndicators()),
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicatorGrid extends StatelessWidget {
  const _IndicatorGrid({required this.data});

  final KildeIndicators data;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('Contactados', '${data.contacted}'),
      ('Con requerimiento', '${data.withRequirement}'),
      ('Sin requerimiento', '${data.withoutRequirement}'),
      ('No contactados', '${data.notContacted}'),
      ('Cotizaciones con respuesta', '${data.quotesWithResponse}'),
      ('Sin respuesta', '${data.quotesWithoutResponse}'),
      ('Aceptadas', '${data.quotesAccepted}'),
      ('Objetadas', '${data.quotesObjected}'),
      ('Rechazadas', '${data.quotesRejected}'),
      ('Ventas con OC', '${data.salesCount}'),
      ('Venta neta', clp(data.salesNet)),
      ('Embudo ponderado', clp(data.weighted)),
      ('Sin próxima acción', '${data.missingNext}'),
      ('Actividades atrasadas', '${data.overdue}'),
      ('RFI pendientes', '${data.openRfis}'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (data.periodLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Período ${data.periodLabel}'),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: 220,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tile.$1, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Text(tile.$2, style: Theme.of(context).textTheme.titleLarge),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class KildeTeamScreen extends ConsumerWidget {
  const KildeTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(kildeTeamProvider);
    final rows = snap.value ?? const <KildeMember>[];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Kilde',
            title: 'Equipo',
            subtitle: 'Embudo, atrasos y próxima acción por ejecutivo',
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage: 'No hay ejecutivos Kilde en esta sucursal.',
              errorMessage: userFacingErrorMessage(snap.error ?? 'Error'),
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeTeamProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        row.missingNext > 0
                            ? '${row.label} · sin próxima acción'
                            : row.label,
                      ),
                      subtitle: Text(
                        '${row.openOpportunities} abiertas · ${clp(row.weightedValue)} ponderado\n'
                        '${row.weekActivities} de la semana · ${row.overdue} atrasadas · ${row.wonPeriod} ganadas'
                        '${row.todayAgenda.isEmpty ? '' : '\nAgenda: ${row.todayAgenda.join(' · ')}'}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KildeRenewalsScreen extends ConsumerWidget {
  const KildeRenewalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(kildeRenewalsProvider);
    final rows = snap.value ?? const <KildeRenewal>[];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Kilde',
            title: 'Renovaciones',
            subtitle: 'Contratos dentro del plazo de aviso',
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage: 'Ningún contrato está en plazo de aviso.',
              errorMessage: userFacingErrorMessage(snap.error ?? 'Error'),
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeRenewalsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(row.title),
                      subtitle: Text(
                        [
                          if (row.clientName != null) row.clientName!,
                          if (row.contractType != null) row.contractType!,
                          if (row.endDate != null) 'Vence ${row.endDate}',
                          if (row.autoRenewal) 'Automática',
                          if (!row.autoRenewal) 'Sin renovación automática',
                          if (row.contractNumber != null) row.contractNumber!,
                        ].join(' · '),
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                        onPressed: () async {
                          try {
                            await ref
                                .read(crmRepositoryProvider)
                                .openRenewal(row.id);
                            ref.invalidate(kildeRenewalsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Oportunidad de renovación abierta.'),
                                ),
                              );
                            }
                          } on Object catch (error) {
                            if (context.mounted) {
                              showFriendlyError(context, error);
                            }
                          }
                        },
                        child: const Text('Renovación'),
                      ),
                          OutlinedButton(
                            onPressed: row.clientId == null
                                ? null
                                : () => context.go(
                                      '/pipeline?client=${row.clientId}',
                                    ),
                            child: const Text('Ampliación'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KildeRfiScreen extends ConsumerStatefulWidget {
  const KildeRfiScreen({super.key});

  @override
  ConsumerState<KildeRfiScreen> createState() => _KildeRfiScreenState();
}

class _KildeRfiScreenState extends ConsumerState<KildeRfiScreen> {
  final _question = TextEditingController();
  var _blocking = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final text = _question.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(crmRepositoryProvider).createRfi(
            question: text,
            blocking: _blocking,
          );
      _question.clear();
      ref.invalidate(kildeRfisProvider);
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(kildeRfisProvider);
    final rows = snap.value ?? const <KildeRfi>[];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Kilde',
            title: 'Consultas técnicas',
            subtitle: 'Una RFI bloqueante impide enviar la cotización',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _question,
                    decoration: const InputDecoration(
                      labelText: 'Pregunta',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Bloquea envío'),
                  selected: _blocking,
                  onSelected: (value) => setState(() => _blocking = value),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _create, child: const Text('Crear')),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage: 'No hay consultas.',
              errorMessage: userFacingErrorMessage(snap.error ?? 'Error'),
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeRfisProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Card(
                    child: ListTile(
                      title: Text(row.question),
                      subtitle: Text(
                        [
                          if (row.number != null) row.number!,
                          row.status,
                          if (row.assignedToId != null) 'asignada a ${row.assignedToId}',
                          if (row.blocking) 'bloqueante',
                          if (row.answer != null) row.answer!,
                        ].join(' · '),
                      ),
                      trailing: row.answer == null
                          ? TextButton(
                              onPressed: () => _answer(row),
                              child: const Text('Responder'),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _answer(KildeRfi row) async {
    final controller = TextEditingController();
    final answer = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder consulta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Respuesta'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (answer == null || answer.isEmpty || !mounted) return;
    try {
      await ref.read(crmRepositoryProvider).answerRfi(id: row.id, answer: answer);
      ref.invalidate(kildeRfisProvider);
    } on Object catch (error) {
      if (mounted) showFriendlyError(context, error);
    }
  }
}

class KildeLostReasonsScreen extends ConsumerStatefulWidget {
  const KildeLostReasonsScreen({super.key});

  @override
  ConsumerState<KildeLostReasonsScreen> createState() =>
      _KildeLostReasonsScreenState();
}

class _KildeLostReasonsScreenState extends ConsumerState<KildeLostReasonsScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(lostReasonsProvider);
    final rows = snap.value ?? const <LostReasonItem>[];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Kilde',
            title: 'Motivos de pérdida',
            subtitle: 'Catálogo de la sucursal',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Motivo'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final name = _name.text.trim();
                    if (name.isEmpty) return;
                    try {
                      await ref.read(crmRepositoryProvider).createLostReason(name);
                      _name.clear();
                      ref.invalidate(lostReasonsProvider);
                    } on Object catch (error) {
                      if (context.mounted) showFriendlyError(context, error);
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage: 'Todavía no hay motivos.',
              errorMessage: userFacingErrorMessage(snap.error ?? 'Error'),
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(lostReasonsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final row in rows)
                    ListTile(title: Text(row.name)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
