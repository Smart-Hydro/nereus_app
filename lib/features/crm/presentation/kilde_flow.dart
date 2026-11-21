import 'package:flutter/material.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/domain/kilde_rules.dart';

Future<String?> askLostReason(
  BuildContext context,
  List<LostReasonItem> reasons,
) {
  if (reasons.isEmpty) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sin motivos'),
        content: const Text(
          'Carga un motivo de pérdida en Kilde antes de marcar la etapa.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Motivo de pérdida'),
      children: [
        for (final reason in reasons)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, reason.id),
            child: Text(reason.name),
          ),
      ],
    ),
  );
}

bool movingToLost(List<OpportunityStageItem> stages, String stageId) {
  for (final stage in stages) {
    if (stage.id != stageId) continue;
    return stageIsLost(
      isClosed: stage.isClosed,
      isWon: stage.isWon,
      name: stage.name,
    );
  }
  return false;
}

const quoteStatusLabels = <String, String>{
  'draft': 'Borrador',
  'sent': 'Enviada',
  'accepted': 'Aceptada',
  'objected': 'Objetada',
  'rejected': 'Rechazada',
  'expired': 'Vencida',
};

String quoteStatusLabel(String code) => quoteStatusLabels[code] ?? code;

const derivationLabels = <String, String>{
  'pending_derivation': 'Por derivar',
  'derived': 'Derivada',
  'observed': 'Observada',
};
