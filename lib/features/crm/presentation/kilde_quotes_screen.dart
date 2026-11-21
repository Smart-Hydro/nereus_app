import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/widgets/async_body.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/core/widgets/page_header.dart';
import 'package:nereus_app/features/auth/providers/session_controller.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';
import 'package:nereus_app/features/crm/presentation/kilde_flow.dart';
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          const PageHeader(
            kicker: 'Kilde',
            title: 'Cotizaciones',
            subtitle: 'Envío, descuento del líder y orden de compra',
          ),
          Expanded(
            child: AsyncBody(
              isLoading: snap.isLoading,
              hasError: snap.hasError,
              isEmpty: rows.isEmpty && !snap.isLoading && !snap.hasError,
              emptyMessage: 'No hay cotizaciones.',
              errorMessage: userFacingErrorMessage(snap.error ?? 'Error'),
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
                  final pending = row.discountStatus == 'pending';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.number, style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            [
                              'v${row.version}',
                              if (row.status.isNotEmpty) quoteStatusLabel(row.status),
                              clp(row.total),
                              if (row.validUntil != null) 'vigente hasta ${row.validUntil}',
                              if (pending) 'pendiente del Líder',
                              if (row.discountStatus == 'approved') 'descuento aprobado',
                              if (row.discountStatus == 'rejected') 'descuento rechazado',
                              if (row.receptionConfirmed) 'recepción confirmada',
                              if (row.responseOn != null) 'respuesta ${row.responseOn}',
                              if (row.poNumber != null) 'OC ${row.poNumber}',
                            ].join(' · '),
                          ),
                          if ((row.objection ?? '').isNotEmpty)
                            Text('Objeción: ${row.objection}'),
                          if ((row.rejectionReason ?? '').isNotEmpty)
                            Text('Rechazo: ${row.rejectionReason}'),
                          if (row.parentId != null)
                            Text('Versión anterior: ${row.parentId}'),
                          if (blocking)
                            const Text('RFI bloqueante abierta: no se puede enviar.'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: sendBlocked || row.immutable
                                    ? null
                                    : () => _run(context, ref, row.id, 'send'),
                                child: const Text('Enviar'),
                              ),
                              OutlinedButton(
                                onPressed: row.immutable
                                    ? null
                                    : () => _run(context, ref, row.id, 'confirm_reception'),
                                child: const Text('Recepción'),
                              ),
                              OutlinedButton(
                                onPressed: sendBlocked || row.immutable
                                    ? null
                                    : () => _run(context, ref, row.id, 'accept'),
                                child: const Text('Aceptar'),
                              ),
                              OutlinedButton(
                                onPressed: row.immutable
                                    ? null
                                    : () => _textAction(
                                          context,
                                          ref,
                                          row.id,
                                          'object',
                                          'Objeción',
                                          'objection',
                                        ),
                                child: const Text('Objetar'),
                              ),
                              OutlinedButton(
                                onPressed: row.immutable
                                    ? null
                                    : () => _textAction(
                                          context,
                                          ref,
                                          row.id,
                                          'reject',
                                          'Motivo de rechazo',
                                          'rejection_reason',
                                        ),
                                child: const Text('Rechazar'),
                              ),
                              if (showDiscountDecision(
                                roleCode: role,
                                discountStatus: row.discountStatus,
                              )) ...[
                                OutlinedButton(
                                  onPressed: () => _run(
                                    context,
                                    ref,
                                    row.id,
                                    'approve_discount',
                                  ),
                                  child: const Text('Aprobar descuento'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _run(
                                    context,
                                    ref,
                                    row.id,
                                    'reject_discount',
                                  ),
                                  child: const Text('Rechazar descuento'),
                                ),
                              ],
                              OutlinedButton(
                                onPressed: row.immutable
                                    ? null
                                    : () => _po(context, ref, row.id),
                                child: const Text('Registrar OC'),
                              ),
                            ],
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
      await ref.read(crmRepositoryProvider).quoteAction(id, action, {field: text});
      ref.invalidate(kildeQuotesProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }

  Future<void> _po(BuildContext context, WidgetRef ref, String id) async {
    final number = TextEditingController();
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Orden de compra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: number,
              decoration: const InputDecoration(labelText: 'Número'),
            ),
            TextField(
              controller: amount,
              decoration: const InputDecoration(labelText: 'Monto neto'),
              keyboardType: TextInputType.number,
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
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final po = number.text.trim();
    final net = amount.text.trim();
    number.dispose();
    amount.dispose();
    if (ok != true || po.isEmpty || net.isEmpty) return;
    final today = DateTime.now();
    final day =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      await ref.read(crmRepositoryProvider).quoteAction(
        id,
        'register_client_po',
        {
          'client_po_number': po,
          'client_po_received_on': day,
          'client_po_net_amount': net,
        },
      );
      ref.invalidate(kildeQuotesProvider);
      if (!context.mounted) return;
      final picked = await FilePicker.platform.pickFiles(withData: true);
      final file = picked?.files.singleOrNull;
      final bytes = file?.bytes;
      if (bytes == null || file == null) return;
      await ref.read(crmRepositoryProvider).uploadClientPoFile(
            quotationId: id,
            bytes: bytes,
            filename: file.name,
          );
      ref.invalidate(kildeQuotesProvider);
    } on Object catch (error) {
      if (context.mounted) showFriendlyError(context, error);
    }
  }
}
