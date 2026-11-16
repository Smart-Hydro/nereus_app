import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/widgets/confirm_dialog.dart';
import 'package:nereus_app/features/strom/domain/field_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
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
      subtitle: rtsReserveNote,
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
        OpsField(
          key: 'warehouse',
          label: 'Bodega',
          choices: lookups.warehouses,
          searchHint: 'Busca por nombre',
        ),
        const OpsField(key: 'notes', label: 'Notas'),
      ],
    );
    if (values == null || !context.mounted) return;
    final order = requireOpsInt(context, values['ot']!, 'OT');
    final product = requireOpsInt(context, values['product']!, 'producto');
    if (order == null || product == null) return;
    final warehouseRaw = values['warehouse'] ?? '';
    int? warehouseId;
    if (warehouseRaw.isNotEmpty) {
      warehouseId = requireOpsInt(context, warehouseRaw, 'bodega');
      if (warehouseId == null) return;
    }
    final ok = await runOps(
      context,
      title: 'Crear RTS',
      message:
          '$rtsReserveNote Si no eliges otra, se usa la bodega de la sucursal.',
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
                if (warehouseId != null) 'warehouse_id': warehouseId,
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
        const OpsNote(rtsReserveNote),
        const OpsNote('La salida no vuelve a descontar.'),
        if (rts.purchaseCaption.isNotEmpty) OpsNote(rts.purchaseCaption),
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
            subtitle: item.stockLine,
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
          ? '$rtsReserveNote La salida no vuelve a descontar.'
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
    final lookups = OpsLookups(ref);
    final project = await _projectOf(ref, rts.workOrder);
    if (!context.mounted) return;
    final values = await askOpsFields(
      context,
      title: 'Orden de compra',
      fields: [
        OpsField(
          key: 'po',
          label: 'Orden de compra',
          required: true,
          searchHint: 'Busca por número o proveedor',
          choices: lookups.purchaseOrders(project: project),
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final purchaseOrderId = values['po']!;
    final reception = await _reception(context, ref, purchaseOrderId);
    if (reception.cancelled || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Vincular OC',
      message: 'La RTS queda ligada a la orden de compra.',
      action: () => ref
          .read(rtsRepositoryProvider)
          .linkPurchaseOrder(
            rts.id,
            purchaseOrderId: purchaseOrderId,
            receptionId: reception.id,
          ),
    );
    if (ok) await _reload(ref);
  }

  Future<String?> _projectOf(WidgetRef ref, String workOrderId) async {
    if (workOrderId.isEmpty) return null;
    try {
      final order = await ref
          .read(workOrdersRepositoryProvider)
          .get(workOrderId);
      return order.project.isEmpty ? null : order.project;
    } on ApiError {
      return null;
    }
  }

  /// Recepción opcional. Cancelada si cierra el diálogo o si el listado falla.
  Future<_ReceptionPick> _reception(
    BuildContext context,
    WidgetRef ref,
    String purchaseOrderId,
  ) async {
    final List<OpsChoice>? choices;
    try {
      choices = await OpsLookups(ref).receptions(purchaseOrderId);
    } on ApiError catch (error) {
      if (context.mounted) showFriendlyError(context, error);
      return const _ReceptionPick.cancelled();
    }
    if (choices == null || choices.isEmpty || !context.mounted) {
      return const _ReceptionPick();
    }
    final available = choices;
    final picked = await askOpsFields(
      context,
      title: 'Recepción',
      fields: [
        OpsField(
          key: 'reception',
          label: 'Recepción',
          searchHint: 'Busca por la nota',
          choices: (query) async {
            final needle = query.trim().toLowerCase();
            if (needle.isEmpty) return available;
            return [
              for (final choice in available)
                if ('${choice.label} ${choice.detail}'.toLowerCase().contains(
                  needle,
                ))
                  choice,
            ];
          },
        ),
      ],
    );
    if (picked == null || !context.mounted) {
      return const _ReceptionPick.cancelled();
    }
    final raw = picked['reception'] ?? '';
    if (raw.isEmpty) return const _ReceptionPick();
    final id = requireOpsInt(context, raw, 'recepción');
    if (id == null) return const _ReceptionPick.cancelled();
    return _ReceptionPick(id: id);
  }
}

class _ReceptionPick {
  const _ReceptionPick({this.id}) : cancelled = false;

  const _ReceptionPick.cancelled() : id = null, cancelled = true;

  final int? id;
  final bool cancelled;
}
