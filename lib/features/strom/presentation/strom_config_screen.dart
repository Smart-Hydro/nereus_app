import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

/// Cuadrilla sin cuenta. No crea usuarios.
class StromConfigScreen extends ConsumerWidget {
  const StromConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsCrewMember>(
      title: 'Configuración',
      subtitle: 'Cuadrilla sin cuenta. No tiene usuario ni clave.',
      value: ref.watch(opsCrewProvider),
      onRetry: () => ref.invalidate(opsCrewProvider),
      action: FilledButton(onPressed: () => _create(context, ref), child: const Text('Agregar')),
      itemBuilder: (context, item) => OpsTile(
        title: item.name,
        subtitle: '${item.company} · ${item.contact}',
        status: item.isActive ? specialtyLabel(item.specialty) : 'Inactivo',
        onTap: () => _edit(context, ref, item),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final values = await _fields(context);
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Agregar integrante',
      message: 'Queda en la cuadrilla de la sucursal, sin cuenta.',
      action: () => ref.read(visitsRepositoryProvider).createCrew({
        'name': values['name'],
        'company': values['company'],
        'specialty': values['specialty'],
        'contact': values['contact'],
        'is_active': true,
      }),
    );
    if (ok) ref.invalidate(opsCrewProvider);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, OpsCrewMember item) async {
    final values = await _fields(
      context,
      name: item.name,
      company: item.company,
      specialty: item.specialty,
      contact: item.contact,
      active: item.isActive ? 'yes' : 'no',
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Actualizar integrante',
      message: 'No se crea un usuario.',
      action: () => ref.read(visitsRepositoryProvider).updateCrew(item.id, {
        'name': values['name'],
        'company': values['company'],
        'specialty': values['specialty'],
        'contact': values['contact'],
        'is_active': values['active'] != 'no',
      }),
    );
    if (ok) ref.invalidate(opsCrewProvider);
  }

  Future<Map<String, String>?> _fields(
    BuildContext context, {
    String name = '',
    String company = '',
    String specialty = 'hydraulic',
    String contact = '',
    String active = 'yes',
  }) {
    return askOpsFields(
      context,
      title: 'Integrante',
      fields: [
        OpsField(key: 'name', label: 'Nombre', initial: name, required: true),
        OpsField(key: 'company', label: 'Empresa', initial: company),
        OpsField(
          key: 'specialty',
          label: 'Especialidad',
          initial: specialty.isEmpty ? 'hydraulic' : specialty,
          options: specialtyLabels,
        ),
        OpsField(key: 'contact', label: 'Contacto', initial: contact),
        OpsField(
          key: 'active',
          label: 'Estado',
          initial: active,
          options: const {'yes': 'Activo', 'no': 'Inactivo'},
        ),
      ],
    );
  }
}
