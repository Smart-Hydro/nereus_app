import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
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
                    _EquipmentTab(),
                    _RequirementsTab(),
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
      header: Align(
        alignment: Alignment.centerLeft,
        child: StromCreateButton(onPressed: () => _create(context, ref)),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.name,
        subtitle: [
          if (item.code.isNotEmpty) item.code,
          if (item.location.isNotEmpty) item.location,
          'Puntos: ${item.deviceIds.join(', ')}',
        ].join(' · '),
        status: item.isActive ? 'Activa' : 'Inactiva',
        onTap: () => context.go('/strom/instalaciones/${item.id}'),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Nueva instalación',
      fields: const [
        OpsField(key: 'name', label: 'Nombre', required: true),
        OpsField(key: 'code', label: 'Código'),
        OpsField(key: 'location', label: 'Ubicación'),
        OpsField(key: 'access', label: 'Requisitos de acceso'),
        OpsField(key: 'devices', label: 'Ids de puntos', hint: 'Separados por coma'),
        OpsField(key: 'client', label: 'Id del cliente'),
      ],
    );
    if (values == null || !context.mounted) return;
    final devices = [
      for (final part in (values['devices'] ?? '').split(','))
        if (opsIntSafe(part) != null) opsIntSafe(part)!,
    ];
    final client = (values['client'] ?? '').isEmpty ? null : requireOpsInt(context, values['client']!, 'cliente');
    if ((values['client'] ?? '').isNotEmpty && client == null) return;
    final ok = await runOps(
      context,
      title: 'Crear instalación',
      message: 'Se vinculan los puntos de captación que ya existen en la sucursal.',
      action: () => ref.read(installationsRepositoryProvider).create({
        'name': values['name'],
        'code': values['code'],
        'location': values['location'],
        'access_requirements': values['access'],
        'device_ids': devices,
        if (client != null) 'client': client,
      }),
    );
    if (ok) ref.invalidate(opsInstallationsProvider);
  }
}

int? opsIntSafe(String raw) => int.tryParse(raw.trim());

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
          'Código ${item.code}\nAcceso: ${item.accessRequirements}\nPuntos: ${item.deviceIds.join(', ')}',
        ),
        OpsButton('Editar', () => _edit(context, ref)),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Editar instalación',
      fields: [
        OpsField(key: 'name', label: 'Nombre', initial: item.name, required: true),
        OpsField(key: 'code', label: 'Código', initial: item.code),
        OpsField(key: 'location', label: 'Ubicación', initial: item.location),
        OpsField(key: 'access', label: 'Requisitos de acceso', initial: item.accessRequirements),
        OpsField(
          key: 'devices',
          label: 'Ids de puntos',
          initial: item.deviceIds.join(','),
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final devices = [
      for (final part in (values['devices'] ?? '').split(','))
        if (opsIntSafe(part) != null) opsIntSafe(part)!,
    ];
    final ok = await runOps(
      context,
      title: 'Guardar instalación',
      message: 'Se actualizan los datos y los puntos vinculados.',
      action: () => ref.read(installationsRepositoryProvider).update(item.id, {
        'name': values['name'],
        'code': values['code'],
        'location': values['location'],
        'access_requirements': values['access'],
        'device_ids': devices,
      }),
    );
    if (ok) {
      ref.invalidate(opsInstallationsProvider);
      ref.invalidate(opsInstallationProvider(item.id));
    }
  }
}

class _EquipmentTab extends ConsumerWidget {
  const _EquipmentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OpsBrowse<OpsEquipment>(
      title: 'Equipos instalados',
      bare: true,
      value: ref.watch(opsEquipmentProvider),
      onRetry: () => ref.invalidate(opsEquipmentProvider),
      header: Align(
        alignment: Alignment.centerLeft,
        child: StromCreateButton(onPressed: () => _install(context, ref)),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.modelName.isEmpty ? 'Equipo ${item.id}' : item.modelName,
        subtitle: 'Serie ${item.serial} · punto ${item.deviceId}',
        status: item.isCurrent ? 'Vigente' : 'Retirado',
        onTap: () => _menu(context, ref, item),
      ),
    );
  }

  Future<void> _install(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Instalar equipo',
      fields: const [
        OpsField(key: 'point', label: 'Id del punto de captación', required: true),
        OpsField(key: 'ot', label: 'Id de la OT', required: true),
        OpsField(key: 'model', label: 'Modelo'),
        OpsField(key: 'serial', label: 'Serie'),
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

  Future<void> _menu(BuildContext context, WidgetRef ref, OpsEquipment item) async {
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
        action: () => ref.read(installationsRepositoryProvider).removeEquipment(item.id),
      );
      if (ok) ref.invalidate(opsEquipmentProvider);
      return;
    }
    final values = await askOpsFields(
      context,
      title: 'Reemplazar equipo',
      fields: const [
        OpsField(key: 'ot', label: 'Id de la OT', required: true),
        OpsField(key: 'model', label: 'Modelo nuevo'),
        OpsField(key: 'serial', label: 'Serie nueva'),
      ],
    );
    if (values == null || !context.mounted) return;
    final order = requireOpsInt(context, values['ot']!, 'OT');
    if (order == null) return;
    final ok = await runOps(
      context,
      title: 'Reemplazar equipo',
      message: 'Se cierra el equipo anterior y queda el nuevo en el mismo punto.',
      action: () => ref.read(installationsRepositoryProvider).replaceEquipment(item.id, {
        'work_order_id': order,
        'model_name': values['model'],
        'serial': values['serial'],
      }),
    );
    if (ok) ref.invalidate(opsEquipmentProvider);
  }
}

class _RequirementsTab extends ConsumerWidget {
  const _RequirementsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = ref.watch(opsSiteRequirementsProvider);
    final duties = ref.watch(opsObligationsProvider);
    return ListView(
      children: [
        OpsButton('Nuevo requisito de sitio', () => _site(context, ref)),
        const SizedBox(height: 8),
        sites.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => OpsNote('$error'),
          data: (items) => Column(
            children: [
              for (final item in items)
                OpsTile(
                  title: opsLabel(item.kind, siteKindLabels),
                  subtitle: 'Proyecto ${item.project}. ${item.notes}',
                  status: opsLabel(item.status, siteStatusLabels),
                  onTap: () => _siteStatus(context, ref, item),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OpsButton('Nueva obligación del cliente', () => _duty(context, ref)),
        const SizedBox(height: 8),
        duties.when(
          loading: () => const SizedBox.shrink(),
          error: (error, _) => OpsNote('$error'),
          data: (items) => Column(
            children: [
              for (final item in items)
                OpsTile(
                  title: item.description,
                  subtitle: 'Responsable ${item.responsible}',
                  status: opsLabel(item.status, obligationLabels),
                  onTap: () => _dutyStatus(context, ref, item),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _site(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Requisito de sitio',
      fields: const [
        OpsField(key: 'project', label: 'Id del proyecto', required: true),
        OpsField(
          key: 'kind',
          label: 'Tipo',
          initial: 'entry_permit',
          options: siteKindLabels,
        ),
        OpsField(key: 'notes', label: 'Notas'),
      ],
    );
    if (values == null || !context.mounted) return;
    final project = requireOpsInt(context, values['project']!, 'proyecto');
    if (project == null) return;
    final ok = await runOps(
      context,
      title: 'Crear requisito',
      message: 'Queda pendiente hasta que se cumpla.',
      action: () => ref.read(installationsRepositoryProvider).createSite({
        'project': project,
        'kind': values['kind'],
        'status': 'pending',
        'notes': values['notes'],
      }),
    );
    if (ok) ref.invalidate(opsSiteRequirementsProvider);
  }

  Future<void> _siteStatus(BuildContext context, WidgetRef ref, OpsSiteRequirement item) async {
    final values = await askOpsFields(
      context,
      title: 'Estado del requisito',
      fields: [
        OpsField(
          key: 'status',
          label: 'Estado',
          initial: item.status,
          options: siteStatusLabels,
        ),
        OpsField(key: 'notes', label: 'Notas', initial: item.notes),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Actualizar requisito',
      message: 'El aviso de la visita usa este estado.',
      action: () => ref.read(installationsRepositoryProvider).updateSite(item.id, {
        'status': values['status'],
        'notes': values['notes'],
      }),
    );
    if (ok) ref.invalidate(opsSiteRequirementsProvider);
  }

  Future<void> _duty(BuildContext context, WidgetRef ref) async {
    final values = await askOpsFields(
      context,
      title: 'Obligación del cliente',
      fields: const [
        OpsField(key: 'ot', label: 'Id de la OT', required: true),
        OpsField(key: 'description', label: 'Descripción', required: true),
        OpsField(key: 'responsible', label: 'Responsable', required: true),
      ],
    );
    if (values == null || !context.mounted) return;
    final order = requireOpsInt(context, values['ot']!, 'OT');
    if (order == null) return;
    final ok = await runOps(
      context,
      title: 'Crear obligación',
      message: 'No marca pruebas ni cierra la actividad.',
      action: () => ref.read(installationsRepositoryProvider).createObligation({
        'work_order_id': order,
        'description': values['description'],
        'responsible': values['responsible'],
        'status': 'pending',
      }),
    );
    if (ok) ref.invalidate(opsObligationsProvider);
  }

  Future<void> _dutyStatus(BuildContext context, WidgetRef ref, OpsObligation item) async {
    final values = await askOpsFields(
      context,
      title: 'Estado de la obligación',
      fields: [
        OpsField(
          key: 'status',
          label: 'Estado',
          initial: item.status,
          options: obligationLabels,
        ),
        OpsField(key: 'notes', label: 'Notas', initial: item.notes),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Actualizar obligación',
      message: 'Queda el responsable y el estado.',
      action: () => ref.read(installationsRepositoryProvider).updateObligation(item.id, {
        'status': values['status'],
        'notes': values['notes'],
      }),
    );
    if (ok) ref.invalidate(opsObligationsProvider);
  }
}
