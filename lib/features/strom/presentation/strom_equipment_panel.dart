import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromEquipmentPanel extends ConsumerWidget {
  const StromEquipmentPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsEquipment>(
      title: 'Equipos instalados',
      bare: true,
      value: ref.watch(opsEquipmentProvider),
      onRetry: () => ref.invalidate(opsEquipmentProvider),
      emptyMessage: 'No hay equipos instalados. Registra el vigente del punto.',
      header: Align(
        alignment: Alignment.centerLeft,
        child: StromCreateButton(onPressed: () => _install(context, ref)),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.modelName.isEmpty ? 'Equipo instalado' : item.modelName,
        subtitle: item.serial.isEmpty ? 'Sin serie' : 'Serie ${item.serial}',
        status: item.isCurrent ? 'Vigente' : 'Retirado',
        onTap: () => _menu(context, ref, item),
      ),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    final lookups = OpsLookups(ref);
    final values = await askOpsFields(
      context,
      title: 'Instalar equipo',
      fields: [
        OpsField(
          key: 'point',
          label: 'Punto de captación',
          required: true,
          choices: lookups.points,
        ),
        OpsField(
          key: 'ot',
          label: 'Orden de trabajo',
          required: true,
          choices: lookups.orders(),
        ),
        const OpsField(key: 'model', label: 'Modelo'),
        const OpsField(key: 'serial', label: 'Serie'),
      ],
    );
    if (values == null || !context.mounted) return;
    final point = requireOpsInt(context, values['point']!, 'punto');
    final order = requireOpsInt(context, values['ot']!, 'OT');
    if (point == null || order == null) return;
    final ok = await runOps(
      context,
      title: 'Instalar equipo',
      message: 'Queda como equipo vigente del punto.',
      action: () => ref.read(installationsRepositoryProvider).install({
        'project_point_id': point,
        'work_order_id': order,
        'model_name': values['model'],
        'serial': values['serial'],
      }),
    );
    if (ok) ref.invalidate(opsEquipmentProvider);
  }

  Future<void> _menu(
    BuildContext context,
    WidgetRef ref,
    OpsEquipment item,
  ) async {
    if (!item.isCurrent) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Reemplazar'),
            onTap: () => Navigator.pop(context, 'replace'),
          ),
          ListTile(
            title: const Text('Retirar'),
            onTap: () => Navigator.pop(context, 'remove'),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == 'remove') {
      final ok = await runOps(
        context,
        title: 'Retirar equipo',
        message: 'El equipo deja de estar vigente. No se pide destino.',
        destructive: true,
        confirmLabel: 'Retirar',
        action: () =>
            ref.read(installationsRepositoryProvider).removeEquipment(item.id),
      );
      if (ok) ref.invalidate(opsEquipmentProvider);
      return;
    }
    final values = await askOpsFields(
      context,
      title: 'Reemplazar equipo',
      fields: [
        OpsField(
          key: 'ot',
          label: 'Orden de trabajo',
          required: true,
          choices: OpsLookups(ref).orders(),
        ),
        const OpsField(key: 'model', label: 'Modelo nuevo'),
        const OpsField(key: 'serial', label: 'Serie nueva'),
      ],
    );
    if (values == null || !context.mounted) return;
    final order = requireOpsInt(context, values['ot']!, 'OT');
    if (order == null) return;
    final ok = await runOps(
      context,
      title: 'Reemplazar equipo',
      message:
          'Se cierra el equipo anterior y queda el nuevo en el mismo punto.',
      action: () =>
          ref.read(installationsRepositoryProvider).replaceEquipment(item.id, {
            'work_order_id': order,
            'model_name': values['model'],
            'serial': values['serial'],
          }),
    );
    if (ok) ref.invalidate(opsEquipmentProvider);
  }
}
