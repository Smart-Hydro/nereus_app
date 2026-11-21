import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';

class MyDaySection extends ConsumerWidget {
  const MyDaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(todayActivitiesProvider);
    final rows = snap.value ?? const <FollowUpItem>[];
    final ink = NereusTokens.text(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mi día',
            style: TextStyle(
              color: ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (snap.isLoading)
            const LinearProgressIndicator()
          else if (rows.isEmpty)
            Text(
              'No hay actividades para hoy.',
              style: TextStyle(color: ink, fontSize: 13.5),
            )
          else
            for (final row in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(row.description, style: TextStyle(color: ink)),
                subtitle: Text(
                  activityTypeLabel(row.activityType),
                  style: TextStyle(color: ink, fontSize: 12.5),
                ),
                trailing: (row.opportunityId ?? '').isEmpty
                    ? null
                    : TextButton(
                        onPressed: () =>
                            context.go('/pipeline/${row.opportunityId}'),
                        child: const Text('Abrir'),
                      ),
              ),
        ],
      ),
    );
  }
}
