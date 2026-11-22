import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/catalog/providers/journey_providers.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/presentation/my_day_section.dart';
import 'package:nereus_app/features/crm/presentation/rfi_actions.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';
import 'package:nereus_app/features/customers/domain/client_models.dart';

String _rfiHistoryLine(KildeRfiAnswer item) {
  final who = item.answeredBy;
  final showWho =
      who != null &&
      who.isNotEmpty &&
      !technicalPersonHandle(who);
  final when = item.answeredAt;
  return [
    item.answer,
    if (showWho) who,
    if (when != null && when.isNotEmpty) formatKildeStamp(when),
  ].join(' · ');
}

TextStyle _kildeLabel(BuildContext context) => TextStyle(
  color: NereusTokens.text(context),
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 1.3,
);

TextStyle _kildeValue(BuildContext context) => TextStyle(
  color: NereusTokens.text(context),
  fontSize: 22,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

TextStyle _kildeMeta(BuildContext context) => TextStyle(
  color: NereusTokens.text(context),
  fontSize: 13.5,
  height: 1.45,
);

Card _panel(BuildContext context, {required Widget child}) {
  return Card(
    color: NereusTokens.panel(context),
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: NereusTokens.hairline(context)),
    ),
    child: child,
  );
}

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
              errorMessage: snap.hasError
                  ? userFacingErrorMessage(snap.error!)
                  : 'No pudimos cargar esta vista.',
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeIndicatorsProvider),
              child: _IndicatorGrid(
                data: snap.value ?? const KildeIndicators(),
              ),
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
      ('Consultas pendientes', '${data.openRfis}'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        if (data.periodLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Período ${data.periodLabel}',
              style: TextStyle(
                color: NereusTokens.text(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (data.openRfiPeople.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Consultas pendientes por persona',
              style: _kildeLabel(context),
            ),
          ),
          for (final person in data.openRfiPeople)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                [
                  person.name,
                  '${person.count}',
                  if ((person.since ?? '').isNotEmpty)
                    'desde ${formatKildeStamp(person.since!)}',
                  if (person.opportunities.isNotEmpty)
                    person.opportunities.join(', '),
                ].join(' · '),
                style: _kildeMeta(context),
              ),
            ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tile in tiles)
              SizedBox(
                width: 220,
                child: _panel(
                  context,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tile.$1, style: _kildeLabel(context)),
                        const SizedBox(height: 8),
                        Text(tile.$2, style: _kildeValue(context)),
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
          const MyDaySection(),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage: 'No hay ejecutivos Kilde en esta sucursal.',
              errorMessage: snap.hasError
                  ? userFacingErrorMessage(snap.error!)
                  : 'No pudimos cargar esta vista.',
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeTeamProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _panel(
                    context,
                    child: ListTile(
                      title: Text(
                        row.missingNext > 0
                            ? '${row.label} · sin próxima acción'
                            : row.label,
                        style: _kildeLabel(context),
                      ),
                      subtitle: Text(
                        '${row.openOpportunities} abiertas · ${clp(row.weightedValue)} ponderado\n'
                        '${row.weekActivities} de la semana · ${row.overdue} atrasadas · ${row.wonPeriod} ganadas'
                        '${row.todayAgenda.isEmpty ? '' : '\nAgenda: ${row.todayAgenda.join(' · ')}'}',
                        style: _kildeMeta(context),
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
              errorMessage: snap.hasError
                  ? userFacingErrorMessage(snap.error!)
                  : 'No pudimos cargar esta vista.',
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeRenewalsProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _panel(
                    context,
                    child: ListTile(
                      title: Text(row.title, style: _kildeLabel(context)),
                      subtitle: Text(
                        [
                          if (row.clientName != null) row.clientName!,
                          if (row.contractType != null) row.contractType!,
                          if (row.endDate != null) 'Vence ${row.endDate}',
                          if (row.autoRenewal) 'Automática',
                          if (!row.autoRenewal) 'Sin renovación automática',
                          if (row.contractNumber != null) row.contractNumber!,
                        ].join(' · '),
                        style: _kildeMeta(context),
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
                                      content: Text(
                                        'Oportunidad de renovación abierta.',
                                      ),
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
  String? _clientId;
  String? _opportunityId;
  String? _quotationId;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final text = _question.text.trim();
    if (text.isEmpty) return;
    final live = ref.read(dataModeProvider) != NereusDataMode.fixture;
    if (live && (_clientId == null || _clientId!.isEmpty)) {
      showFriendlyError(
        context,
        const ApiError(message: 'Elige el cliente de la consulta.'),
      );
      return;
    }
    if (_blocking &&
        (_opportunityId == null || _opportunityId!.isEmpty) &&
        (_quotationId == null || _quotationId!.isEmpty)) {
      showFriendlyError(
        context,
        const ApiError(
          message:
              'Una consulta bloqueante va ligada a una oportunidad o a una cotización.',
        ),
      );
      return;
    }
    try {
      await ref
          .read(crmRepositoryProvider)
          .createRfi(
            question: text,
            blocking: _blocking,
            clientId: _clientId,
            opportunityId: _opportunityId,
            quotationId: _quotationId,
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
    final team = ref.watch(kildeTeamProvider).value ?? const <KildeMember>[];
    final live = ref.watch(dataModeProvider) != NereusDataMode.fixture;
    final clients = live
        ? ref.watch(customerClientsProvider).value ?? const <ClientItem>[]
        : const <ClientItem>[];
    final opportunities =
        ref.watch(opportunitiesProvider()).value ?? const <OpportunityItem>[];
    final quotes = ref.watch(kildeQuotesProvider).value ?? const <KildeQuote>[];
    final visibleQuotes = _opportunityId == null
        ? quotes
        : quotes
              .where((quote) => quote.opportunityId == _opportunityId)
              .toList();
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
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (clients.isNotEmpty)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // This Flutter SDK still reads `value`.
                      // ignore: deprecated_member_use
                      value: _clientId,
                      decoration: const InputDecoration(labelText: 'Cliente'),
                      items: [
                        for (final client in clients)
                          DropdownMenuItem(
                            value: client.id,
                            child: Text(client.name, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (value) => setState(() => _clientId = value),
                    ),
                  ),
                if (opportunities.isNotEmpty)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // This Flutter SDK still reads `value`.
                      // ignore: deprecated_member_use
                      value: _opportunityId,
                      decoration: const InputDecoration(labelText: 'Oportunidad'),
                      items: [
                        for (final deal in opportunities)
                          DropdownMenuItem(
                            value: deal.id,
                            child: Text(deal.title, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _opportunityId = value;
                        final quote = quotes.cast<KildeQuote?>().firstWhere(
                          (item) => item?.id == _quotationId,
                          orElse: () => null,
                        );
                        if (quote != null && quote.opportunityId != value) {
                          _quotationId = null;
                        }
                        final deal = opportunities.cast<OpportunityItem?>().firstWhere(
                          (item) => item?.id == value,
                          orElse: () => null,
                        );
                        if (_clientId == null && deal?.clientId != null) {
                          _clientId = deal!.clientId;
                        }
                      }),
                    ),
                  ),
                if (visibleQuotes.isNotEmpty)
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      // This Flutter SDK still reads `value`.
                      // ignore: deprecated_member_use
                      value: _quotationId,
                      decoration: const InputDecoration(labelText: 'Cotización'),
                      items: [
                        for (final quote in visibleQuotes)
                          DropdownMenuItem(
                            value: quote.id,
                            child: Text(quote.number, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (value) => setState(() {
                        _quotationId = value;
                        final quote = quotes.cast<KildeQuote?>().firstWhere(
                          (item) => item?.id == value,
                          orElse: () => null,
                        );
                        if (quote == null) return;
                        _opportunityId ??= quote.opportunityId;
                        _clientId ??= quote.clientId;
                      }),
                    ),
                  ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _question,
                    decoration: const InputDecoration(
                      labelText: 'Pregunta',
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Bloquea envío'),
                  selected: _blocking,
                  onSelected: (value) => setState(() => _blocking = value),
                ),
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
              errorMessage: snap.hasError
                  ? userFacingErrorMessage(snap.error!)
                  : 'No pudimos cargar esta vista.',
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeRfisProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return _panel(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            row.question,
                            style: _kildeLabel(context),
                          ),
                          subtitle: Text(
                            [
                              if (row.number != null) row.number!,
                              if ((row.opportunityTitle ?? '').isNotEmpty)
                                row.opportunityTitle!,
                              if ((row.assignedToName ?? '').isNotEmpty)
                                'Asignada a ${row.assignedToName}',
                              if ((row.assignedAt ?? '').isNotEmpty)
                                'desde ${formatKildeStamp(row.assignedAt!)}',
                              if (row.isOpen) 'Abierta',
                              if (!row.isOpen) 'Respondida',
                              if (row.blocking) 'bloqueante',
                              if (row.answer != null) row.answer!,
                              if ((row.reopenReason ?? '').isNotEmpty)
                                'Motivo de reapertura: ${row.reopenReason}',
                            ].join(' · '),
                            style: _kildeMeta(context),
                          ),
                          isThreeLine: true,
                          trailing: row.answer == null && row.status != 'closed'
                              ? TextButton(
                                  onPressed: () => _answer(row),
                                  child: const Text('Responder'),
                                )
                              : null,
                        ),
                        if (row.history.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historial de respuestas',
                                  style: _kildeLabel(context),
                                ),
                                for (final item in row.history)
                                  Text(
                                    _rfiHistoryLine(item),
                                    style: _kildeMeta(context),
                                  ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                          child: RfiActions(row: row, team: team),
                        ),
                      ],
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
      await ref
          .read(crmRepositoryProvider)
          .answerRfi(id: row.id, answer: answer);
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

class _KildeLostReasonsScreenState
    extends ConsumerState<KildeLostReasonsScreen> {
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
    final role = ref.watch(sessionProvider).value?.currentBranch?.roleCode;
    final canManage = role == null || kildeSeesTeam(role);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Kilde',
            title: 'Motivos de pérdida',
            subtitle: 'Catálogo de la sucursal',
          ),
          if (canManage)
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
                      await ref
                          .read(crmRepositoryProvider)
                          .createLostReason(name);
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
              errorMessage: snap.hasError
                  ? userFacingErrorMessage(snap.error!)
                  : 'No pudimos cargar esta vista.',
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(lostReasonsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _panel(
                        context,
                        child: ListTile(
                          title: Text(row.name, style: _kildeLabel(context)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
