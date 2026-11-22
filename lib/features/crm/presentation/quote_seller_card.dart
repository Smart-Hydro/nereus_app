import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/domain/quote_share.dart';
import 'package:nereus_app/features/crm/presentation/kilde_flow.dart';
import 'package:url_launcher/url_launcher.dart';

class QuoteSellerCard extends StatelessWidget {
  const QuoteSellerCard({
    required this.quote,
    required this.demo,
    required this.roleCode,
    required this.sendBlocked,
    required this.blocking,
    required this.onAction,
    required this.onText,
    required this.onPo,
    required this.onDownload,
    required this.onVersions,
    super.key,
  });

  final KildeQuote quote;
  final bool demo;
  final String? roleCode;
  final bool sendBlocked;
  final bool blocking;
  final void Function(String action) onAction;
  final void Function(String action, String label, String field) onText;
  final VoidCallback onPo;
  final VoidCallback onDownload;
  final VoidCallback onVersions;

  @override
  Widget build(BuildContext context) {
    final row = quote;
    final pending = row.discountStatus == 'pending';
    final expired = quoteShowsExpired(
      status: row.status,
      validUntil: row.validUntil,
    );
    final ink = NereusTokens.text(context);
    return Card(
      color: NereusTokens.panel(context),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: NereusTokens.hairline(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.number,
              style: TextStyle(
                color: ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((row.clientName ?? '').isNotEmpty)
              Text(
                row.clientName!,
                style: TextStyle(color: ink, fontSize: 13.5),
              ),
            if ((row.observation ?? '').isNotEmpty)
              Text(
                row.observation!,
                style: TextStyle(color: ink, fontSize: 13.5),
              ),
            const SizedBox(height: 4),
            Text(
              [
                'v${row.version}',
                if (row.status.isNotEmpty) quoteStatusLabel(row.status),
                if (expired) 'Vencida',
                clp(row.total),
                if (row.validUntil != null) 'vigente hasta ${row.validUntil}',
                if (pending) 'pendiente del Líder',
                if (row.discountStatus == 'approved') 'descuento aprobado',
                if (row.discountStatus == 'rejected') 'descuento rechazado',
                if (row.receptionConfirmed) 'recepción confirmada',
                if (row.responseOn != null) 'respuesta ${row.responseOn}',
                if (row.poNumber != null) 'OC ${row.poNumber}',
              ].join(' · '),
              style: TextStyle(color: ink, fontSize: 13.5, height: 1.4),
            ),
            if ((row.objection ?? '').isNotEmpty)
              Text(
                'Objeción: ${row.objection}',
                style: TextStyle(color: ink, fontSize: 13.5),
              ),
            if ((row.rejectionReason ?? '').isNotEmpty)
              Text(
                'Rechazo: ${row.rejectionReason}',
                style: TextStyle(color: ink, fontSize: 13.5),
              ),
            if (row.parentId != null)
              Text(
                'Versión anterior: ${row.parentId}',
                style: TextStyle(color: ink, fontSize: 13.5),
              ),
            if ((row.poFile ?? '').isNotEmpty) _PoFileLink(file: row.poFile!),
            if (blocking)
              Text(
                'RFI bloqueante abierta: no se puede enviar.',
                style: TextStyle(
                  color: ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 8),
            SelectableText(
              quoteShareUrl(row.id, demo: demo),
              style: TextStyle(color: ink, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final url = quoteShareUrl(row.id, demo: demo);
                    await Clipboard.setData(ClipboardData(text: url));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado')),
                    );
                  },
                  child: const Text('Compartir'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      context.go(quoteSharePath(row.id, demo: demo)),
                  child: const Text('Vista pública'),
                ),
                OutlinedButton(
                  onPressed: onDownload,
                  child: Text(demo ? 'Descargar resumen' : 'Descargar PDF'),
                ),
                OutlinedButton(
                  onPressed: onVersions,
                  child: const Text('Versiones'),
                ),
                OutlinedButton(
                  onPressed: sendBlocked || row.immutable
                      ? null
                      : () => onAction('send'),
                  child: const Text('Enviar'),
                ),
                OutlinedButton(
                  onPressed: row.immutable
                      ? null
                      : () => onAction('confirm_reception'),
                  child: const Text('Recepción'),
                ),
                OutlinedButton(
                  onPressed: expired || sendBlocked || row.immutable
                      ? null
                      : () => onAction('accept'),
                  child: Text(expired ? expiredQuoteAcceptLabel : 'Aceptar'),
                ),
                OutlinedButton(
                  onPressed: row.immutable
                      ? null
                      : () => onText('object', 'Objeción', 'objection'),
                  child: const Text('Objetar'),
                ),
                OutlinedButton(
                  onPressed: row.immutable
                      ? null
                      : () => onText(
                          'reject',
                          'Motivo de rechazo',
                          'rejection_reason',
                        ),
                  child: const Text('Rechazar'),
                ),
                if (showDiscountDecision(
                  roleCode: roleCode,
                  discountStatus: row.discountStatus,
                )) ...[
                  OutlinedButton(
                    onPressed: () => onAction('approve_discount'),
                    child: const Text('Aprobar descuento'),
                  ),
                  OutlinedButton(
                    onPressed: () => onAction('reject_discount'),
                    child: const Text('Rechazar descuento'),
                  ),
                ],
                OutlinedButton(
                  onPressed: canRegisterClientPo(row.status) ? onPo : null,
                  child: const Text('Registrar OC'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PoFileLink extends StatelessWidget {
  const _PoFileLink({required this.file});

  final String file;

  @override
  Widget build(BuildContext context) {
    final ink = NereusTokens.text(context);
    final http = file.startsWith('http://') || file.startsWith('https://');
    if (!http) {
      return SelectableText(
        'Archivo de OC: $file',
        style: TextStyle(
          color: ink,
          fontSize: 13.5,
          decoration: TextDecoration.underline,
        ),
      );
    }
    return TextButton(
      onPressed: () async {
        final uri = Uri.tryParse(file);
        final opened = uri != null &&
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
          showFriendlyError(
            context,
            const ApiError(message: 'No se pudo abrir el archivo de la OC.'),
          );
        }
      },
      child: const Text('Archivo de OC'),
    );
  }
}
