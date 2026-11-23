import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/domain/work_models.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

final opsAgendaProvider = FutureProvider.autoDispose
    .family<List<OpsAgendaRow>, String>((ref, key) {
      final parts = key.split('|');
      return ref
          .watch(visitsRepositoryProvider)
          .agenda(from: parts[0], to: parts[1], specialty: parts[2]);
    });

class StromAgendaScreen extends ConsumerStatefulWidget {
  const StromAgendaScreen({super.key});

  @override
  ConsumerState<StromAgendaScreen> createState() => _StromAgendaScreenState();
}

class _StromAgendaScreenState extends ConsumerState<StromAgendaScreen> {
  late DateTime _monday;
  var _specialty = '';
  var _week = true;

  @override
  void initState() {
    super.initState();
    _monday = _mondayOf(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final sunday = _monday.add(const Duration(days: 6));
    final key = '${_iso(_monday)}|${_iso(sunday)}|$_specialty';
    final rows = ref.watch(opsAgendaProvider(key));
    return OpsBrowse<OpsAgendaRow>(
      title: 'Agenda',
      subtitle: _week
          ? 'Vista semana, del ${_iso(_monday)} al ${_iso(sunday)}. Hora de Chile.'
          : 'Vista lista, del ${_iso(_monday)} al ${_iso(sunday)}. Hora de Chile.',
      value: rows,
      onRetry: () => ref.invalidate(opsAgendaProvider(key)),
      emptyMessage: 'No hay visitas en esta semana.',
      header: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => setState(
              () => _monday = _monday.subtract(const Duration(days: 7)),
            ),
            child: const Text('Semana anterior'),
          ),
          OutlinedButton(
            onPressed: () => setState(
              () => _monday = _monday.add(const Duration(days: 7)),
            ),
            child: const Text('Semana siguiente'),
          ),
          OutlinedButton(
            onPressed: () => setState(() => _week = !_week),
            child: Text(_week ? 'Ver lista' : 'Ver semana'),
          ),
          for (final entry in const {
            '': 'Todas',
            'hydraulic': 'Hidráulica',
            'electric': 'Eléctrica',
          }.entries)
            ChoiceChip(
              label: Text(entry.value),
              selected: _specialty == entry.key,
              onSelected: (_) => setState(() => _specialty = entry.key),
            ),
        ],
      ),
      itemBuilder: (context, item) {
        final crew = item.crew.join(', ');
        return OpsTile(
          title: item.projectName.isEmpty ? 'Proyecto' : item.projectName,
          subtitle: [
            item.when,
            if (item.clientName.isNotEmpty) item.clientName,
            'OT ${specialtyLabel(item.specialty)}',
            if (crew.isNotEmpty) crew,
            if (item.kind == 'date_proposal') 'Fecha propuesta',
            if (item.reason.isNotEmpty) item.reason,
          ].join(' · '),
          status: item.kind == 'date_proposal'
              ? 'Propuesta'
              : visitStatusLabel(item.status),
          onTap: item.visitId.isEmpty
              ? null
              : () => context.go('/strom/visitas/${item.visitId}'),
        );
      },
    );
  }
}

DateTime _mondayOf(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  return date.subtract(Duration(days: date.weekday - DateTime.monday));
}

String _iso(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}
