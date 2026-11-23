import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nereus_app/features/strom/domain/coord_models.dart';
import 'package:nereus_app/features/strom/domain/ops_labels.dart';
import 'package:nereus_app/features/strom/presentation/ops_actions.dart';
import 'package:nereus_app/features/strom/presentation/ops_lookups.dart';
import 'package:nereus_app/features/strom/presentation/ops_nav.dart';
import 'package:nereus_app/features/strom/presentation/strom_browse.dart';
import 'package:nereus_app/features/strom/presentation/strom_chrome.dart';
import 'package:nereus_app/features/strom/providers/strom_providers.dart';

class StromClarificationsScreen extends StatelessWidget {
  const StromClarificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StromChrome(
          title: 'Aclaraciones',
          subtitle: 'Aclaraciones abiertas y trabajo fuera de alcance',
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Aclaraciones'),
                  Tab(text: 'Fuera de alcance'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Clarifications(),
                    _OutOfScope(),
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

class _Clarifications extends ConsumerWidget {
  const _Clarifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = opsQuery(context, 'proyecto');
    return OpsBrowse<OpsClarification>(
      title: 'Aclaraciones',
      bare: true,
      value: ref.watch(opsClarificationsProvider).whenData((items) {
        if (projectId == null) return items;
        return items.where((item) => item.project == projectId).toList();
      }),
      onRetry: () => ref.invalidate(opsClarificationsProvider),
      header: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => _ask(context, ref, projectId),
          child: const Text('Preguntar'),
        ),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.text,
        subtitle: item.answer.isEmpty ? 'Sin respuesta' : item.answer,
        status: opsLabel(item.status, clarificationLabels),
        onTap: item.status == 'open' ? () => _answer(context, ref, item) : null,
      ),
    );
  }

  Future<void> _ask(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Nueva aclaración',
      fields: [
        if (projectId == null)
          OpsField(
            key: 'project',
            label: 'Proyecto',
            required: true,
            choices: OpsLookups(ref).projects,
          )
        else
          OpsField(
            key: 'project',
            label: 'Proyecto',
            required: true,
            locked: true,
            initial: projectId,
            lockedLabel: 'Proyecto de esta ficha',
            choices: OpsLookups(ref).projects,
          ),
        const OpsField(key: 'text', label: 'Pregunta', required: true),
      ],
    );
    if (values == null || !context.mounted) return;
    final project = requireOpsInt(context, values['project']!, 'proyecto');
    if (project == null) return;
    final ok = await runOps(
      context,
      title: 'Registrar aclaración',
      message: 'Queda abierta hasta que alguien responda.',
      action: () => ref
          .read(coordinationRepositoryProvider)
          .ask(
            projectId: project,
            text: values['text']!,
          ),
    );
    if (ok) ref.invalidate(opsClarificationsProvider);
  }

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    OpsClarification item,
  ) async {
    final text = await askOpsText(
      context,
      title: 'Responder',
      label: 'Respuesta',
    );
    if (text == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Responder aclaración',
      message: 'La aclaración queda respondida.',
      action: () => ref
          .read(coordinationRepositoryProvider)
          .answer(item.id, answer: text),
    );
    if (ok) ref.invalidate(opsClarificationsProvider);
  }
}

class _OutOfScope extends ConsumerWidget {
  const _OutOfScope();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = opsQuery(context, 'proyecto');
    return OpsBrowse<OpsOutOfScope>(
      title: 'Fuera de alcance',
      bare: true,
      value: ref.watch(opsOutOfScopeProvider).whenData((items) {
        if (projectId == null) return items;
        return items.where((item) => item.project == projectId).toList();
      }),
      onRetry: () => ref.invalidate(opsOutOfScopeProvider),
      header: Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => _create(context, ref, projectId),
          child: const Text('Registrar'),
        ),
      ),
      itemBuilder: (context, item) => OpsTile(
        title: item.description,
        subtitle: [
          if (item.decisionReason.isNotEmpty) item.decisionReason,
          if (item.resultingWorkOrder.isNotEmpty)
            'OT adicional ${item.resultingWorkOrder}',
          if (item.resultingProject.isNotEmpty)
            'Proyecto nuevo ${item.resultingProject}',
        ].join(' · '),
        status: opsLabel(item.decision, outOfScopeLabels),
        onTap: item.decision == 'pending'
            ? () => _decide(context, ref, item)
            : item.resultingWorkOrder.isNotEmpty
            ? () => context.go('/strom/ordenes/${item.resultingWorkOrder}')
            : item.resultingProject.isNotEmpty
            ? () => context.go('/strom/${item.resultingProject}')
            : null,
      ),
    );
  }

  Future<void> _create(
    BuildContext context,
    WidgetRef ref,
    String? projectId,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Fuera de alcance',
      fields: [
        if (projectId == null)
          OpsField(
            key: 'project',
            label: 'Proyecto',
            required: true,
            choices: OpsLookups(ref).projects,
          )
        else
          OpsField(
            key: 'project',
            label: 'Proyecto',
            required: true,
            locked: true,
            initial: projectId,
            lockedLabel: 'Proyecto de esta ficha',
            choices: OpsLookups(ref).projects,
          ),
        const OpsField(
          key: 'description',
          label: 'Descripción',
          required: true,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final project = requireOpsInt(context, values['project']!, 'proyecto');
    if (project == null) return;
    final ok = await runOps(
      context,
      title: 'Registrar trabajo',
      message: 'No se agrega a la OT confirmada.',
      action: () => ref
          .read(coordinationRepositoryProvider)
          .registerOutOfScope(
            projectId: project,
            description: values['description']!,
          ),
    );
    if (ok) ref.invalidate(opsOutOfScopeProvider);
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    OpsOutOfScope item,
  ) async {
    final values = await askOpsFields(
      context,
      title: 'Decidir',
      fields: const [
        OpsField(
          key: 'decision',
          label: 'Decisión',
          initial: 'new_work_order',
          options: {
            'new_work_order': 'Nueva OT en el mismo proyecto',
            'new_project': 'Proyecto nuevo',
          },
        ),
        OpsField(key: 'reason', label: 'Motivo'),
        OpsField(
          key: 'specialty',
          label: 'Especialidad de la OT nueva',
          initial: 'hydraulic',
          options: specialtyLabels,
        ),
      ],
    );
    if (values == null || !context.mounted) return;
    final ok = await runOps(
      context,
      title: 'Decidir fuera de alcance',
      message:
          'OT nueva abre una adicional en el mismo proyecto. Proyecto nuevo queda enlazado.',
      action: () => ref
          .read(coordinationRepositoryProvider)
          .decide(
            item.id,
            decision: values['decision']!,
            reason: values['reason'] ?? '',
            specialty: values['decision'] == 'new_work_order'
                ? (values['specialty'] ?? '')
                : '',
          ),
    );
    if (ok) ref.invalidate(opsOutOfScopeProvider);
  }
}
