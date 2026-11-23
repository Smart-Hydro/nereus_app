import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/domain/quote_file.dart';
import 'package:nereus_app/features/crm/domain/quote_share.dart';
import 'package:nereus_app/features/crm/presentation/kilde_flow.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';

final publicQuoteProvider = FutureProvider.autoDispose
    .family<KildeQuote, String>((
      ref,
      id,
    ) {
      return ref.watch(crmRepositoryProvider).quotation(id);
    });

/// Vista pública de una cotización. En la demo no pide sesión.
class CotizacionPublicScreen extends ConsumerStatefulWidget {
  const CotizacionPublicScreen({
    required this.id,
    this.demo = false,
    super.key,
  });

  final String id;
  final bool demo;

  @override
  ConsumerState<CotizacionPublicScreen> createState() =>
      _CotizacionPublicScreenState();
}

class _CotizacionPublicScreenState
    extends ConsumerState<CotizacionPublicScreen> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.demo) {
      ref.read(dataModeProvider.notifier).useFixture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = ref.watch(publicQuoteProvider(widget.id));
    final ink = NereusTokens.text(context);
    final live =
        !widget.demo && ref.watch(dataModeProvider) != NereusDataMode.fixture;
    return Scaffold(
      body: AsyncBody(
        isLoading: quote.isLoading,
        hasError: quote.hasError,
        isEmpty: quote.value == null && !quote.isLoading && !quote.hasError,
        onRetry: () => ref.invalidate(publicQuoteProvider(widget.id)),
        emptyMessage: 'No encontramos esta cotización.',
        errorMessage: _errorMessage(quote, live: live),
        child: quote.value == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                children: [
                  Text(
                    'Cotización',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quote.value!.number,
                    style: TextStyle(
                      color: ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.demo
                        ? 'Vista pública de la demostración. Puedes descargarla o aprobarla sin entrar a Nereus.'
                        : live
                        ? 'Cotización de Nereus. Descargar PDF y aprobar usan tu sesión.'
                        : 'Vista pública. Puedes descargar el resumen o aprobar la cotización.',
                    style: TextStyle(color: ink, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _QuoteBody(quote: quote.value!, ink: ink),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _download(quote.value!, live),
                        child: Text(live ? 'Descargar PDF' : 'Descargar'),
                      ),
                      FilledButton(
                        onPressed: _busy || !_canAnswer(quote.value!)
                            ? null
                            : () => _act('accept'),
                        child: Text(
                          _expired(quote.value!)
                              ? expiredQuoteAcceptLabel
                              : 'Aprobar',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _busy || !_canAnswer(quote.value!)
                            ? null
                            : _reject,
                        child: const Text('Rechazar'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _errorMessage(AsyncValue<KildeQuote> quote, {required bool live}) {
    if (!quote.hasError) return 'No encontramos esta cotización.';
    if (live) {
      return 'En vivo esta cotización se abre con tu sesión de Nereus. '
          'El enlace de la demostración no pide cuenta.';
    }
    return userFacingErrorMessage(quote.error ?? 'Error');
  }

  bool _expired(KildeQuote quote) => quoteShowsExpired(
    status: quote.status,
    validUntil: quote.validUntil,
  );

  bool _canAnswer(KildeQuote quote) {
    if (_expired(quote)) return false;
    if (quote.immutable) return false;
    if (quote.discountStatus == 'pending') return false;
    return quote.status != 'accepted' && quote.status != 'rejected';
  }

  Future<void> _download(KildeQuote quote, bool live) async {
    setState(() => _busy = true);
    try {
      final List<int> bytes;
      final String mime;
      final String filename;
      if (live) {
        bytes = await ref.read(crmRepositoryProvider).quotationPdf(quote.id);
        mime = 'application/pdf';
        filename = 'cotizacion_${quote.id}.pdf';
      } else {
        bytes = utf8.encode(quoteDocument(quote));
        mime = 'text/plain;charset=utf-8';
        filename = 'cotizacion_${quote.id}.txt';
      }
      saveQuoteBytes(filename: filename, bytes: bytes, mime: mime);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(live ? 'PDF descargado.' : 'Resumen descargado.'),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _act(String action, [Map<String, dynamic>? body]) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(crmRepositoryProvider)
          .quoteAction(widget.id, action, body);
      ref.invalidate(publicQuoteProvider(widget.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'accept'
                ? 'Cotización aprobada.'
                : 'Cotización rechazada.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFacingErrorMessage(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motivo de rechazo'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    controller.dispose();
    if (ok != true || text.isEmpty || !mounted) return;
    await _act('reject', {'rejection_reason': text});
  }
}

class _QuoteBody extends StatelessWidget {
  const _QuoteBody({required this.quote, required this.ink});

  final KildeQuote quote;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final pending = quote.discountStatus == 'pending';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: NereusTokens.panel(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NereusTokens.hairline(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.clientName ?? 'Cliente',
              style: TextStyle(
                color: ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                quoteStatusLabel(quote.status),
                if (quoteShowsExpired(
                  status: quote.status,
                  validUntil: quote.validUntil,
                ))
                  'Vencida',
                if ((quote.validUntil ?? '').isNotEmpty)
                  'vigente hasta ${quote.validUntil}',
                if (pending) pendingDiscountLabel,
              ].join(' · '),
              style: TextStyle(color: ink, fontSize: 13.5, height: 1.4),
            ),
            if ((quote.observation ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                quote.observation!,
                style: TextStyle(color: ink, fontSize: 14),
              ),
            ],
            const SizedBox(height: 12),
            if (quote.lines.isEmpty)
              Text(clp(quote.total), style: TextStyle(color: ink, fontSize: 18))
            else
              for (final line in quote.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${_qty(line.quantity)} × ${line.name} · ${clp(line.total)}',
                    style: TextStyle(color: ink, fontSize: 14, height: 1.35),
                  ),
                ),
            const SizedBox(height: 8),
            Text(
              'Total ${clp(quote.total)}',
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (quote.status == 'accepted')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'El cliente ya aprobó esta cotización.',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _qty(double quantity) {
  if (quantity == quantity.roundToDouble()) return quantity.round().toString();
  return quantity.toString();
}
