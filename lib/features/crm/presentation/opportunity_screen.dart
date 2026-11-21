import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/access.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/theme/glass.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/catalog/domain/journey_models.dart';
import 'package:nereus_app/features/catalog/providers/journey_providers.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/presentation/kilde_flow.dart';
import 'package:nereus_app/features/crm/presentation/opportunity_actions.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';
import 'package:nereus_app/features/crm/presentation/opportunity_form.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';
import 'package:nereus_app/features/customers/domain/client_models.dart';

part 'opportunity_panels.dart';

String _when(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day}/${value.month}/${value.year} $hour:$minute';
}

class OpportunityScreen extends ConsumerWidget {
  const OpportunityScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = Access(ref.watch(sessionProvider).value);
    final canWrite = access.canWrite(NereusModules.customers);
    final detail = ref.watch(opportunityDetailProvider(opportunityId));
    final stages = ref.watch(opportunityStagesProvider);
    final activities = ref.watch(opportunityActivitiesProvider(opportunityId));
    final proposals = ref.watch(opportunityProposalsProvider(opportunityId));
    final clients = ref.watch(customerClientsProvider);
    final quotes = ref.watch(kildeQuotesProvider);
    final role = ref.watch(sessionProvider).value?.currentBranch?.roleCode;
    final deal = detail.value;
    final hasPo = (quotes.value ?? const <KildeQuote>[]).any(
      (quote) => quote.opportunityId == deal?.id && quote.acceptedWithPo,
    );
    final canDerive = deriveEnabled(
      roleCode: role,
      hasSurvey: (deal?.surveyId ?? '').isNotEmpty,
      hasAcceptedQuoteWithPo: hasPo,
    );

    Future<void> reload() async {
      ref.invalidate(opportunityDetailProvider(opportunityId));
      ref.invalidate(opportunityActivitiesProvider(opportunityId));
      ref.invalidate(opportunityProposalsProvider(opportunityId));
      ref.invalidate(opportunitiesProvider());
      ref.invalidate(crmSummaryProvider);
    }

    Future<void> move(String stageId) async {
      String? lostReasonId;
      if (movingToLost(stages.value ?? const [], stageId)) {
        final reasons = await ref.read(lostReasonsProvider.future);
        if (!context.mounted) return;
        lostReasonId = await askLostReason(context, reasons);
        if (lostReasonId == null || lostReasonId.isEmpty) return;
      }
      try {
        await ref
            .read(crmRepositoryProvider)
            .move(
              id: opportunityId,
              stageId: stageId,
              lostReasonId: lostReasonId,
            );
        await reload();
      } on Object catch (error) {
        if (context.mounted) showFriendlyError(context, error);
      }
    }

    Future<void> editDeal() async {
      if (deal == null) return;
      final saved = await showEntitySheet<bool>(
        context: context,
        title: 'Editar oportunidad',
        child: OpportunityForm(
          stages: stages.value ?? const <OpportunityStageItem>[],
          clients: clients.value ?? const <ClientItem>[],
          initial: deal,
        ),
      );
      if (saved ?? false) await reload();
    }

    Future<void> deleteDeal() async {
      if (deal == null) return;
      final ok = await confirmAction(
        context,
        title: 'Eliminar oportunidad',
        message: '¿Seguro que deseas eliminar "${deal.title}"?',
        confirmLabel: 'Eliminar',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      try {
        await ref.read(crmRepositoryProvider).deleteOpportunity(opportunityId);
        ref.invalidate(opportunitiesProvider());
        ref.invalidate(crmSummaryProvider);
        if (context.mounted) context.go('/pipeline');
      } on Object catch (error) {
        if (context.mounted) showFriendlyError(context, error);
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            kicker: 'Negocio',
            title: deal?.title ?? 'Oportunidad',
            subtitle: [
              if (deal?.clientName != null) deal!.clientName!,
              if (deal != null) clp(deal.estimatedValue),
              if (deal?.expectedCloseDate != null)
                'Cierre ${deal!.expectedCloseDate}',
              if (deal != null && deal.probability > 0)
                '${deal.probability.round()}%',
              if ((deal?.lostReasonName ?? deal?.lostReasonText ?? '')
                  .isNotEmpty)
                'Pérdida: ${deal!.lostReasonName ?? deal.lostReasonText}',
            ].join(' · '),
            actions: [
              OutlinedButton.icon(
                onPressed: () => context.go('/pipeline'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Pipeline'),
              ),
              if (deal?.clientId != null)
                OutlinedButton.icon(
                  onPressed: () => context.go('/clients/${deal!.clientId}'),
                  icon: const Icon(Icons.assignment_ind_outlined, size: 16),
                  label: const Text('Ficha 360'),
                ),
              if (canWrite && deal != null)
                OutlinedButton.icon(
                  onPressed: () => _openSurvey(context, ref, deal),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: Text(
                    deal.surveyId == null ? 'Crear ficha' : 'Abrir ficha',
                  ),
                ),
              if (kildeIsLead(role) && deal != null)
                OutlinedButton.icon(
                  onPressed: canDerive
                      ? () => _derive(context, ref, deal)
                      : null,
                  icon: const Icon(Icons.alt_route, size: 16),
                  label: const Text('Derivar a Strøm'),
                ),
              if (canWrite && deal != null) ...[
                OutlinedButton.icon(
                  onPressed: editDeal,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                ),
                IconButton(
                  tooltip: 'Eliminar oportunidad',
                  onPressed: deleteDeal,
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ],
          ),
          Expanded(
            child: AsyncBody(
              isLoading: detail.isLoading,
              hasError: detail.hasError,
              isEmpty: detail.hasError || detail.isLoading,
              errorMessage: userFacingErrorMessage(detail.error ?? 'Error'),
              isNetworkError: isNetworkFailure(detail.error ?? 'Error'),
              onRetry: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  if (kildeIsLead(role) && deal != null && !canDerive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Derivar a Strøm se habilita con la ficha de '
                        'levantamiento y una cotización aceptada que tenga '
                        'orden de compra.',
                        style: TextStyle(
                          color: NereusTokens.text(context),
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (deal != null)
                    _StagePicker(
                      stages: stages.value ?? const [],
                      currentId: deal.stageId,
                      notes: deal.notes,
                      enabled: canWrite,
                      onMove: move,
                    ),
                  const SizedBox(height: 16),
                  _Proposals(
                    items: proposals.value ?? const [],
                    loading: proposals.isLoading,
                    onAdd: canWrite
                        ? () => _addProposal(context, ref, reload)
                        : null,
                    onDelete: canWrite
                        ? (id) => _deleteProposal(context, ref, id, reload)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _FollowUps(
                    items: activities.value ?? const [],
                    loading: activities.isLoading,
                    onAdd: canWrite
                        ? () => _addFollowUp(context, ref, reload)
                        : null,
                    onComplete: canWrite
                        ? (id) => _complete(context, ref, id, reload)
                        : null,
                    onDelete: canWrite
                        ? (id) => _deleteActivity(context, ref, id, reload)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSurvey(
    BuildContext context,
    WidgetRef ref,
    OpportunityItem deal,
  ) async {
    final existing = deal.surveyId;
    if (existing != null && existing.isNotEmpty) {
      context.go(
        '/levantamientos/fill/$existing?client=${deal.clientId ?? ''}',
      );
      return;
    }
    final questions = TextEditingController();
    final responseOn = TextEditingController();
    final meetingOn = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ficha de levantamiento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: responseOn,
              decoration: const InputDecoration(
                labelText: 'Fecha de respuesta de la cotización (AAAA-MM-DD)',
              ),
            ),
            TextField(
              controller: questions,
              decoration: const InputDecoration(
                labelText: 'Dudas u objeciones',
              ),
              maxLines: 3,
            ),
            TextField(
              controller: meetingOn,
              decoration: const InputDecoration(
                labelText: 'Reunión de resolución (AAAA-MM-DD)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    final doubts = questions.text.trim();
    final response = responseOn.text.trim();
    final meeting = meetingOn.text.trim();
    questions.dispose();
    responseOn.dispose();
    meetingOn.dispose();
    if (ok != true) return;
    try {
      final id = await ref
          .read(crmRepositoryProvider)
          .openLevantamiento(
            opportunityId: deal.id,
            title: 'Levantamiento ${deal.title}',
            quoteResponseOn: response.isEmpty ? null : response,
            openQuestions: doubts.isEmpty ? null : doubts,
            resolutionMeetingOn: meeting.isEmpty ? null : meeting,
            resolutionMeetingDone: meeting.isNotEmpty,
          );
      ref.invalidate(opportunityDetailProvider(opportunityId));
      if (context.mounted) {
        context.go('/levantamientos/fill/$id?client=${deal.clientId ?? ''}');
      }
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _derive(
    BuildContext context,
    WidgetRef ref,
    OpportunityItem deal,
  ) async {
    final quotes = ref.read(kildeQuotesProvider).value ?? const <KildeQuote>[];
    final related = [
      for (final quote in quotes)
        if (quote.opportunityId == deal.id) quote,
    ];
    final accepted = related.where((quote) => quote.status == 'accepted');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Derivar a Strøm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${deal.clientName ?? 'sin cliente'}'),
            Text('Ficha: ${deal.surveyId ?? 'falta'}'),
            Text(
              accepted.isEmpty
                  ? 'Cotización aceptada: falta'
                  : 'Cotización: ${accepted.first.number}',
            ),
            Text(
              'OC: ${accepted.where((quote) => quote.poNumber != null).map((quote) => quote.poNumber).join(', ')}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Se copia lo que ya está en la ficha. No se vuelve a escribir.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Derivar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final projectId = await ref
          .read(crmRepositoryProvider)
          .deriveToStrom(deal.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              projectId.isEmpty
                  ? 'Derivado a Strøm.'
                  : 'Derivado a Strøm ($projectId).',
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _addProposal(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() reload,
  ) async {
    var products = const <ProductItem>[];
    try {
      products = await ref.read(productsProvider().future);
    } on Object {
      products = const [];
    }
    if (!context.mounted) return;
    final saved = await showEntitySheet<bool>(
      context: context,
      title: 'Agregar a la propuesta',
      child: ProposalForm(
        opportunityId: opportunityId,
        products: products,
      ),
    );
    if (saved ?? false) await reload();
  }

  Future<void> _deleteProposal(
    BuildContext context,
    WidgetRef ref,
    String id,
    Future<void> Function() reload,
  ) async {
    try {
      await ref.read(crmRepositoryProvider).deleteProposal(id);
      await reload();
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _addFollowUp(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() reload,
  ) async {
    final saved = await showEntitySheet<bool>(
      context: context,
      title: 'Nuevo seguimiento',
      child: FollowUpForm(opportunityId: opportunityId),
    );
    if (saved ?? false) await reload();
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    String id,
    Future<void> Function() reload,
  ) async {
    try {
      await ref.read(crmRepositoryProvider).completeActivity(id);
      await reload();
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _deleteActivity(
    BuildContext context,
    WidgetRef ref,
    String id,
    Future<void> Function() reload,
  ) async {
    try {
      await ref.read(crmRepositoryProvider).deleteActivity(id);
      await reload();
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }
}
