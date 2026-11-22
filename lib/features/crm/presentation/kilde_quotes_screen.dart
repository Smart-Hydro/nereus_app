import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/domain/quote_file.dart';
import 'package:nereus_app/features/crm/domain/quote_share.dart';
import 'package:nereus_app/features/crm/presentation/client_po_dialog.dart';
import 'package:nereus_app/features/crm/presentation/quote_create_dialog.dart';
import 'package:nereus_app/features/crm/presentation/quote_new_version_dialog.dart';
import 'package:nereus_app/features/crm/presentation/quote_seller_card.dart';
import 'package:nereus_app/features/crm/presentation/quote_versions_dialog.dart';
import 'package:nereus_app/features/crm/presentation/rfi_create_dialog.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';

class KildeQuotesScreen extends ConsumerWidget {
  const KildeQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(kildeQuotesProvider);
    final rows = snap.value ?? const <KildeQuote>[];
    final rfis = ref.watch(kildeRfisProvider).value ?? const <KildeRfi>[];
    final role = ref.watch(sessionProvider).value?.currentBranch?.roleCode;
    final demo = ref.watch(dataModeProvider) == NereusDataMode.fixture;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PageHeader(
            kicker: 'Kilde',
            title: 'Cotizaciones',
            subtitle: 'Crea la cotización y comparte el enlace público.',
            actions: [
              FilledButton(
                onPressed: () => showQuoteCreateDialog(context, ref),
                child: const Text('Nueva cotización'),
              ),
            ],
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage:
                  'No hay cotizaciones. Crea la primera con Nueva cotización.',
              errorMessage: snap.hasError
                  ? userFacingErrorMessage(snap.error ?? 'Error')
                  : 'No pudimos cargar las cotizaciones.',
              isNetworkError: isNetworkFailure(snap.error ?? 'Error'),
              onRetry: () => ref.invalidate(kildeQuotesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final blocking = rfis.any(
                    (rfi) =>
                        rfi.isOpen &&
                        rfi.blocking &&
                        (rfi.quotationId == row.id ||
                            (row.opportunityId != null &&
                                rfi.opportunityId == row.opportunityId)),
                  );
                  final sendBlocked = quoteSendBlocked(
                    discountStatus: row.discountStatus,
                    blockingRfiOpen: blocking,
                  );
                  return QuoteSellerCard(
                    quote: row,
                    demo: demo,
                    roleCode: role,
                    sendBlocked: sendBlocked,
                    blocking: blocking,
                    onAction: (action) => _run(context, ref, row.id, action),
                    onText: (action, label, field) => _textAction(
                      context,
                      ref,
                      row.id,
                      action,
                      label,
                      field,
                    ),
                    onPo: () => _po(context, ref, row),
                    onDownload: () => _download(context, ref, row, demo),
                    onVersions: () => _versions(context, ref, row.id),
                    onNewVersion: row.status == 'sent' && !row.immutable
                        ? () => _newVersion(context, ref, row)
                        : null,
                    onRfi: () => _rfi(context, ref, row),
                    onPoFile: (row.poFile ?? '').startsWith('http')
                        ? () => _downloadPo(context, ref, row)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    WidgetRef ref,
    KildeQuote quote,
    bool demo,
  ) async {
    try {
      final bytes = demo
          ? utf8.encode(quoteDocument(quote))
          : await ref.read(crmRepositoryProvider).quotationPdf(quote.id);
      saveQuoteBytes(
        filename: demo
            ? 'cotizacion_${quote.id}.txt'
            : 'cotizacion_${quote.id}.pdf',
        bytes: bytes,
        mime: demo ? 'text/plain;charset=utf-8' : 'application/pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(demo ? 'Resumen descargado.' : 'PDF descargado.'),
        ),
      );
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
  ) async {
    try {
      await ref.read(crmRepositoryProvider).quoteAction(id, action);
      ref.invalidate(kildeQuotesProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _textAction(
    BuildContext context,
    WidgetRef ref,
    String id,
    String action,
    String label,
    String field,
  ) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty) return;
    try {
      await ref.read(crmRepositoryProvider).quoteAction(id, action, {
        field: text,
      });
      ref.invalidate(kildeQuotesProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _newVersion(
    BuildContext context,
    WidgetRef ref,
    KildeQuote quote,
  ) async {
    final draft = await askNewQuoteVersion(context, quote);
    if (draft == null || !context.mounted) return;
    try {
      await ref.read(crmRepositoryProvider).saveQuotationVersion(
        id: quote.id,
        validUntil: draft.validUntil,
        total: draft.total,
        items: draft.items,
      );
      ref.invalidate(kildeQuotesProvider);
      ref.invalidate(opportunitiesProvider());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Versión nueva creada.')),
      );
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _rfi(BuildContext context, WidgetRef ref, KildeQuote quote) async {
    final draft = await askRfi(context);
    if (draft == null || !context.mounted) return;
    final live = ref.read(dataModeProvider) != NereusDataMode.fixture;
    if (live && (quote.clientId == null || quote.clientId!.isEmpty)) {
      showFriendlyError(
        context,
        const ApiError(message: 'La cotización no tiene cliente.'),
      );
      return;
    }
    try {
      await ref.read(crmRepositoryProvider).createRfi(
        question: draft.question,
        blocking: draft.blocking,
        clientId: quote.clientId,
        opportunityId: quote.opportunityId,
        quotationId: quote.id,
      );
      ref.invalidate(kildeRfisProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta creada.')),
      );
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _downloadPo(
    BuildContext context,
    WidgetRef ref,
    KildeQuote quote,
  ) async {
    try {
      final bytes = await ref.read(crmRepositoryProvider).clientPoFile(quote.id);
      saveQuoteBytes(
        filename: 'oc_${quote.id}.pdf',
        bytes: bytes,
        mime: 'application/pdf',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OC descargada.')),
      );
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _versions(BuildContext context, WidgetRef ref, String id) async {
    try {
      final versions = await ref
          .read(crmRepositoryProvider)
          .quotationVersions(id);
      if (!context.mounted) return;
      await showQuoteVersionsDialog(context, versions);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _po(BuildContext context, WidgetRef ref, KildeQuote quote) async {
    final input = await askClientPo(context);
    if (input == null || !context.mounted) return;
    try {
      await ref.read(crmRepositoryProvider).registerClientPo(
        quotationId: quote.id,
        number: input.number,
        receivedOn: input.receivedOn,
        netAmount: input.netAmount,
        fileBytes: input.file?.bytes,
        filename: input.file?.name,
      );
      ref.invalidate(kildeQuotesProvider);
      ref.invalidate(opportunitiesProvider());
      final opportunityId = quote.opportunityId;
      if (opportunityId != null && opportunityId.isNotEmpty) {
        ref.invalidate(opportunityDetailProvider(opportunityId));
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OC registrada. La oportunidad quedó ganada.'),
        ),
      );
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }
}
