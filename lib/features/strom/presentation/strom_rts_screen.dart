import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromRtsScreen extends ConsumerWidget {
  const StromRtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = opsQuery(context, 'ot');
    return OpsBrowse<OpsRts>(
      title: 'RTS y bodega',
      subtitle: 'La reserva descuenta el stock una sola vez. Sin bodega, baja la cantidad del producto.',
      value: ref.watch(opsRtsProvider).whenData((items) {
        if (orderId == null) return items;
        return items.where((item) => item.workOrder == orderId).toList();
      }),
      onRetry: () => ref.invalidate(opsRtsProvider),
      emptyMessage: 'No hay RTS. Crea una para la OT.',
      action: FilledButton(
        onPressed: () => _create(context, ref, orderId),
        child: const Text('Crear'),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: 'RTS ${specialtyLabel(item.specialty)}',
        subtitle: '${item.items.length} ítems · ${item.notes}',
        status: opsLabel(item.status, rtsStatusLabels),
        onTap: () => context.go('/strom/rts/${item.id}'),
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    String? orderId,
  ) async {
    final lookups = OpsLookups(ref);
    final values = await askOpsFields(
      context,
      title: 'Nueva RTS',
      fields: [
        if (orderId == null)
          OpsField(
            key: 'ot',
            label: 'Orden de trabajo',
            required: true,
            choices: lookups.orders(),
          )
        else
          OpsField(
            key: 'ot',
            label: 'Orden de trabajo',
            required: true,
            locked: true,
            initial: orderId,
            lockedLabel: 'OT de esta orden',
            choices: lookups.orders(),
          ),
        OpsField(
          key: 'product',
          label: 'Producto',
          required: true,
          choices: lookups.products,
        ),
        const OpsField(
          key: 'qty',
          label: 'Cantidad',
          initial: '1',
          required: true,
        ),
        const OpsField(key: 'unit', label: 'Unidad'),
        const OpsField(key: 'notes', label: 'Notas'),
      ],
    );
    if (values == null || !context.mounted) return;
    final order = requireOpsInt(context, values['ot']!, 'OT');
    final product = requireOpsInt(context, values['product']!, 'producto');
    if (order == null || product == null) return;
    final ok = await runOps(
      context,
      title: 'Crear RTS',
      message: 'Sin bodega elegida, el stock baja en el producto. Una bodega de otra sucursal se rechaza.',
      action: () => ref
          .read(rtsRepositoryProvider)
          .create(
            workOrderId: order,
            notes: values['notes'] ?? '',
            items: [
              {
                'product_id': product,
                'quantity': values['qty'],
                'unit': values['unit'] ?? '',
              },
            ],
          ),
    );
    if (ok) ref.invalidate(opsRtsProvider);
  }
}

class StromRtsDetailScreen extends ConsumerWidget {
  const StromRtsDetailScreen({super.key, required this.rtsId});

  final String rtsId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rts = ref.watch(opsRtsDetailProvider(rtsId));
    return OpsAsync(
      isLoading: rts.isLoading,
      error: rts.hasError ? rts.error : null,
      onRetry: () => ref.invalidate(opsRtsDetailProvider(rtsId)),
      child: rts.asData == null
          ? const SizedBox.shrink()
          : _Body(rts: rts.asData!.value),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.rts});

  final OpsRts rts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsDetail(
      title: 'RTS ${specialtyLabel(rts.specialty)}',
      subtitle: opsLabel(rts.status, rtsStatusLabels),
      children: [
        OpsNote(opsNextAction(rts.status)),
        const OpsNote(
          'La reserva descuenta el stock una sola vez. La salida no vuelve a descontar.',
        ),
        OpsNote(rts.notes),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OpsButton('Preparar', () => _act(context, ref, 'prepare')),
            OpsButton('Reservar', () => _act(context, ref, 'reserve')),
            OpsButton('Dar salida', () => _act(context, ref, 'issue')),
            OpsButton('Vincular OC', () => _link(context, ref)),
          ],
        ),
        for (final item in rts.items)
          OpsTile(
            title: item.productName.isEmpty ? 'Producto' : item.productName,
            subtitle:
                '${item.quantity} ${item.unit} · stock ${item.stockQuantity}',
            status: opsLabel(item.status, rtsItemLabels),
          ),
      ],
    );
  }

  Future<void> _reload(WidgetRef ref) async {
    ref.invalidate(opsRtsDetailProvider(rts.id));
    ref.invalidate(opsRtsProvider);
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    final reserve = action == 'reserve';
    final ok = await runOps(
      context,
      title: reserve
          ? 'Reservar'
          : (action == 'issue' ? 'Dar salida' : 'Preparar'),
      message: reserve
          ? 'La reserva descuenta el stock una sola vez. La salida no vuelve a descontar.'
          : 'Se actualiza la RTS de esta OT.',
      action: () {
        final repo = ref.read(rtsRepositoryProvider);
        return switch (action) {
          'prepare' => repo.prepare(rts.id),
          'reserve' => repo.reserve(rts.id),
          _ => repo.issue(rts.id),
        };
      },
    );
    if (ok) await _reload(ref);
  }

  Future<void> _link(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Orden de compra',
      fields: [
        OpsField(
          key: 'po',
          label: 'Orden de compra',
          required: true,
          choices: OpsLookups(ref).purchaseOrders,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    const int? reception = null;
    final ok = await runOps(
      context,
      title: 'Vincular OC',
      message: 'La RTS queda ligada a la orden de compra.',
      action: () => ref
          .read(rtsRepositoryProvider)
          .linkPurchaseOrder(
            rts.id,
            purchaseOrderId: values['po']!,
            receptionId: reception,
          ),
    );
    if (ok) await _reload(ref);
  }
}
