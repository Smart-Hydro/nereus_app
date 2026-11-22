import 'package:flutter/material.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';

class KildeHandoffPanel extends StatelessWidget {
  const KildeHandoffPanel({
    required this.handoff,
    this.title = 'Esto se envía a Strøm',
    super.key,
  });

  final KildeHandoff handoff;
  final String title;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final heading = Theme.of(context).textTheme.titleSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('No se vuelve a escribir.', style: style),
        const SizedBox(height: 8),
        _block(heading, style, 'Cliente', [handoff.clientName ?? 'Sin cliente']),
        _block(heading, style, 'Contactos', handoff.contacts, empty: 'Sin contactos'),
        _block(heading, style, 'Pozos', handoff.wells, empty: 'Sin pozos'),
        _block(
          heading,
          style,
          'Cotización',
          [handoff.quotation ?? 'Sin cotización'],
        ),
        _block(heading, style, 'Equipos', handoff.equipment, empty: 'Sin equipos'),
        _block(
          heading,
          style,
          'Ficha',
          [handoff.surveyLabel ?? 'Sin ficha de levantamiento'],
        ),
        Text('RFI cerradas', style: heading),
        if (handoff.closedRfis.isEmpty)
          Text('Sin RFI cerradas', style: style)
        else
          for (final rfi in handoff.closedRfis)
            Text(
              [
                rfi.question,
                if (rfi.answer.isNotEmpty) rfi.answer,
                if ((rfi.answeredBy ?? '').isNotEmpty) rfi.answeredBy!,
                if ((rfi.answeredAt ?? '').isNotEmpty) rfi.answeredAt!,
              ].join(' · '),
              style: style,
            ),
      ],
    );
  }

  Widget _block(
    TextStyle? heading,
    TextStyle? style,
    String label,
    List<String> rows, {
    String? empty,
  }) {
    final visible = rows.where((row) => row.trim().isNotEmpty).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: heading),
          if (visible.isEmpty)
            Text(empty ?? 'Sin datos', style: style)
          else
            for (final row in visible) Text(row, style: style),
        ],
      ),
    );
  }
}
