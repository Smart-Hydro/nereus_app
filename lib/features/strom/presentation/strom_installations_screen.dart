import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_choice.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/presentation/strom_equipment_panel.dart';
import 'package:nereus_app/features/strom/presentation/strom_requirements_panel.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromInstallationsScreen extends StatelessWidget {
  const StromInstallationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StromChrome(
          title: 'Instalaciones',
          subtitle: 'Punto de captación, equipo instalado y requisitos',
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Instalaciones'),
                  Tab(text: 'Equipos'),
                  Tab(text: 'Requisitos'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _InstallationsTab(),
                    StromEquipmentPanel(),
                    StromRequirementsPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallationsTab extends ConsumerWidget {
  const _InstallationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsInstallation>(
      title: 'Instalaciones',
      bare: true,
      value: ref.watch(opsInstallationsProvider),
      onRetry: () => ref.invalidate(opsInstallationsProvider),
      emptyMessage: 'No hay instalaciones. Crea una y elige sus puntos.',
      header: Align(
        alignment: Alignment.centerLeft,
        child: StromCreateButton(onPressed: () => _create(context, ref)),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.name,
        subtitle: [
          if (item.code.isNotEmpty) item.code,
          if (item.location.isNotEmpty) item.location,
          if (item.deviceIds.isNotEmpty)
            '${item.deviceIds.length} puntos de captación',
        ].join(' · '),
        status: item.isActive ? 'Activa' : 'Inactiva',
        onTap: () => context.go('/strom/instalaciones/${item.id}'),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final lookups = OpsLookups(ref);
    final points = await askOpsMany(
      context,
      title: 'Puntos de la instalación',
      load: lookups.points,
    );
    if (points == null || !context.mounted) return;
    final values = await askOpsFields(
      context,
      title: 'Nueva instalación',
      fields: [
        const OpsField(key: 'name', label: 'Nombre', required: true),
        const OpsField(key: 'code', label: 'Código'),
        const OpsField(key: 'location', label: 'Ubicación'),
        const OpsField(key: 'access', label: 'Requisitos de acceso'),
        OpsField(key: 'client', label: 'Cliente', choices: lookups.clients),
      ],
    );
    if (values == null || !context.mounted) return;
    final clientRaw = values['client'] ?? '';
    final client = clientRaw.isEmpty
        ? null
        : requireOpsInt(context, clientRaw, 'cliente');
    if (clientRaw.isNotEmpty && client == null) return;
    final ok = await runOps(
      context,
      title: 'Crear instalación',
      message:
          'Se vinculan los puntos de captación que ya existen en la sucursal.',
      action: () => ref.read(installationsRepositoryProvider).create({
        'name': values['name'],
        'code': values['code'],
        'location': values['location'],
        'access_requirements': values['access'],
        'device_ids': [
          for (final point in points)
            if (int.tryParse(point.id) != null) int.parse(point.id),
        ],
        if (client != null) 'client': client,
      }),
    );
    if (ok) ref.invalidate(opsInstallationsProvider);
  }
}

class StromInstallationScreen extends ConsumerWidget {
  const StromInstallationScreen({super.key, required this.installationId});

  final String installationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(opsInstallationProvider(installationId));
    return OpsAsync(
      isLoading: item.isLoading,
      error: item.hasError ? item.error : null,
      onRetry: () => ref.invalidate(opsInstallationProvider(installationId)),
      child: item.asData == null
          ? const SizedBox.shrink()
          : _InstallationBody(item: item.asData!.value),
    );
  }
}

class _InstallationBody extends ConsumerWidget {
  const _InstallationBody({required this.item});

  final OpsInstallation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsDetail(
      title: item.name,
      subtitle: item.location.isEmpty ? 'Instalación' : item.location,
      children: [
        OpsNote(
          'Código ${item.code.isEmpty ? 'sin código' : item.code}\n'
          'Acceso: ${item.accessRequirements.isEmpty ? 'sin requisitos' : item.accessRequirements}\n'
          '${item.deviceIds.length} puntos de captación',
        ),
        OpsButton('Editar', () => _edit(context, ref)),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final lookups = OpsLookups(ref);
    final current = [
      for (final id in item.deviceIds)
        OpsChoice(id: id, label: 'Punto de captación'),
    ];
    final points = await askOpsMany(
      context,
      title: 'Puntos de la instalación',
      load: lookups.points,
      initial: current,
    );
    if (points == null || !context.mounted) return;
    final values = await askOpsFields(
      context,
      title: 'Editar instalación',
      fields: [
        OpsField(
          key: 'name',
          label: 'Nombre',
          initial: item.name,
          required: true,
        ),
        OpsField(key: 'code', label: 'Código', initial: item.code),
        OpsField(key: 'location', label: 'Ubicación', initial: item.location),
        OpsField(
          key: 'access',
          label: 'Requisitos de acceso',
          initial: item.accessRequirements,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Guardar instalación',
      message: 'Se actualizan los datos y los puntos vinculados.',
      action: () => ref.read(installationsRepositoryProvider).update(item.id, {
        'name': values['name'],
        'code': values['code'],
        'location': values['location'],
        'access_requirements': values['access'],
        'device_ids': [
          for (final point in points)
            if (int.tryParse(point.id) != null) int.parse(point.id),
        ],
      }),
    );
    if (ok) {
      ref.invalidate(opsInstallationsProvider);
      ref.invalidate(opsInstallationProvider(item.id));
    }
  }
}
