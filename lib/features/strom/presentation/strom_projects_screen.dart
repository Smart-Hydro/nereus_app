import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/project_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromProjectsScreen extends ConsumerStatefulWidget {
  const StromProjectsScreen({super.key});

  @override
  ConsumerState<StromProjectsScreen> createState() =>
      _StromProjectsScreenState();
}

class _StromProjectsScreenState extends ConsumerState<StromProjectsScreen> {
  var _kind = 'todos';
  var _status = '';
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(opsProjectsProvider);
    return OpsBrowse<OpsProject>(
      title: 'Proyectos',
      value: projects.whenData((items) {
        return items.where((item) {
          if (_kind == 'support' && item.serviceType != 'support') return false;
          if (_kind == 'project' && item.serviceType != 'project') return false;
          if (_kind == 'maintenance' && item.serviceType != 'maintenance') {
            return false;
          }
          if (_status.isNotEmpty && item.status != _status) return false;
          if (_query.isEmpty) return true;
          final blob = '${item.name} ${item.code} ${item.clientPoNumber}'
              .toLowerCase();
          return blob.contains(_query.toLowerCase());
        }).toList();
      }),
      onRetry: () => ref.invalidate(opsProjectsProvider),
      emptyMessage: 'No hay proyectos en esta sucursal.',
      emptyAction: FilledButton(
        onPressed: () => context.go('/strom/nuevo'),
        child: const Text('Crear proyecto'),
      ),
      action: StromCreateButton(onPressed: () => context.go('/strom/nuevo')),
      header: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar proyecto, código u OC',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in const {
                  'todos': 'Todos',
                  'project': 'Proyecto',
                  'support': 'Soporte',
                  'maintenance': 'Mantención',
                }.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _kind == entry.key,
                    onSelected: (_) => setState(() => _kind = entry.key),
                  ),
                for (final entry in const {
                  '': 'Cualquier estado',
                  'preparation': 'Preparación',
                  'execution': 'Ejecución',
                  'closed': 'Cerrado',
                  'suspended': 'Suspendido',
                }.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _status == entry.key,
                    onSelected: (_) => setState(() => _status = entry.key),
                  ),
              ],
            ),
          ),
        ],
      ),
      itemBuilder: (context, project) => OpsTile(
        title: project.name,
        subtitle: [
          if (project.code.isNotEmpty) project.code,
          if (project.clientName.isNotEmpty) project.clientName,
          if (project.clientPoNumber.isNotEmpty) 'OC ${project.clientPoNumber}',
          if (project.committedOn.isNotEmpty) project.committedOn,
        ].join(' · '),
        status:
            '${serviceTypeLabel(project.serviceType)} · ${projectStatusLabel(project.status)}',
        onTap: () => context.go('/strom/${project.id}'),
      ),
    );
  }
}
