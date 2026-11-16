import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromAuditScreen extends ConsumerStatefulWidget {
  const StromAuditScreen({super.key});

  @override
  ConsumerState<StromAuditScreen> createState() => _StromAuditScreenState();
}

class _StromAuditScreenState extends ConsumerState<StromAuditScreen> {
  var _entity = '';

  @override
  Widget build(BuildContext context) {
    final rows = ref.watch(opsTransitionsProvider);
    return OpsBrowse<OpsTransition>(
      title: 'Auditoría',
      subtitle: 'Transiciones de negocio. No reemplaza el log HTTP.',
      value: rows.whenData((items) {
        if (_entity.isEmpty) return items;
        return items.where((item) => item.entityType == _entity).toList();
      }),
      onRetry: () => ref.invalidate(opsTransitionsProvider),
      header: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          children: [
            for (final entry in const {'': 'Todas', ...entityLabels}.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: _entity == entry.key,
                onSelected: (_) => setState(() => _entity = entry.key),
              ),
          ],
        ),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: '${opsLabel(item.entityType, entityLabels)} ${item.entityId}',
        subtitle: '${item.fromValue} → ${item.toValue}. ${item.reason}',
        status: item.occurredAt.length >= 16 ? item.occurredAt.substring(0, 16) : item.occurredAt,
        onTap: () => context.go('/strom/auditoria/${item.id}'),
      ),
    );
  }
}

class StromTransitionScreen extends ConsumerWidget {
  const StromTransitionScreen({super.key, required this.transitionId});

  final String transitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(opsTransitionProvider(transitionId));
    return OpsAsync(
      isLoading: row.isLoading,
      error: row.hasError ? row.error : null,
      onRetry: () => ref.invalidate(opsTransitionProvider(transitionId)),
      child: row.asData == null
          ? const SizedBox.shrink()
          : _Body(row: row.asData!.value),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.row});

  final OpsTransition row;

  @override
  Widget build(BuildContext context) {
    return OpsDetail(
      title: '${opsLabel(row.entityType, entityLabels)} ${row.entityId}',
      subtitle: row.occurredAt,
      children: [
        OpsNote(
          'De ${row.fromValue.isEmpty ? '—' : row.fromValue} a ${row.toValue}\n'
          'Motivo: ${row.reason.isEmpty ? '—' : row.reason}\n'
          'Alcance: ${row.scopeVersion.isEmpty ? '—' : row.scopeVersion}\n'
          'Quién: ${row.actor.isEmpty ? '—' : row.actor}',
        ),
      ],
    );
  }
}
