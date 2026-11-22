import 'package:flutter/material.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/presentation/kilde_flow.dart';

Future<void> showQuoteVersionsDialog(
  BuildContext context,
  List<QuoteVersion> versions,
) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Versiones'),
      content: SizedBox(
        width: 520,
        child: QuoteVersionsPanel(versions: versions),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

class QuoteVersionsPanel extends StatefulWidget {
  const QuoteVersionsPanel({required this.versions, super.key});

  final List<QuoteVersion> versions;

  @override
  State<QuoteVersionsPanel> createState() => _QuoteVersionsPanelState();
}

class _QuoteVersionsPanelState extends State<QuoteVersionsPanel> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.versions.isEmpty ? 0 : widget.versions.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final ink = NereusTokens.text(context);
    if (widget.versions.isEmpty) {
      return Text(
        'No hay versiones guardadas.',
        style: TextStyle(color: ink, fontSize: 14),
      );
    }
    final selected = widget.versions[_index.clamp(0, widget.versions.length - 1)];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < widget.versions.length; i++)
                ChoiceChip(
                  label: Text('Versión ${widget.versions[i].version}'),
                  selected: i == _index,
                  onSelected: (_) => setState(() => _index = i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          QuoteVersionDiffView(version: selected),
        ],
      ),
    );
  }
}

class QuoteVersionDiffView extends StatelessWidget {
  const QuoteVersionDiffView({required this.version, super.key});

  final QuoteVersion version;

  @override
  Widget build(BuildContext context) {
    final ink = NereusTokens.text(context);
    final style = TextStyle(color: ink, fontSize: 14, height: 1.4);
    final diff = version.diff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          [
            'Versión ${version.version}',
            if (version.status.isNotEmpty) quoteStatusLabel(version.status),
            clp(version.total),
            if ((version.validUntil ?? '').isNotEmpty)
              'vigente hasta ${version.validUntil}',
          ].join(' · '),
          style: style.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (diff == null)
          Text('Tal como quedó. No hay una versión anterior.', style: style)
        else ...[
          Text('Cambios respecto de la versión anterior', style: style),
          const SizedBox(height: 6),
          if (diff.added.isEmpty && diff.removed.isEmpty && diff.changed.isEmpty)
            Text('Sin cambios de líneas.', style: style),
          if (diff.added.isNotEmpty) ...[
            Text('Agregadas', style: style.copyWith(fontWeight: FontWeight.w700)),
            for (final line in diff.added) Text(_line(line), style: style),
          ],
          if (diff.removed.isNotEmpty) ...[
            Text('Quitadas', style: style.copyWith(fontWeight: FontWeight.w700)),
            for (final line in diff.removed) Text(_line(line), style: style),
          ],
          if (diff.changed.isNotEmpty) ...[
            Text('Cambiadas', style: style.copyWith(fontWeight: FontWeight.w700)),
            for (final change in diff.changed)
              Text(
                '${change.productName} · ${quoteDiffFieldLabel(change.field)}: '
                '${quoteDiffValue(change.field, change.before)} → '
                '${quoteDiffValue(change.field, change.after)}',
                style: style,
              ),
          ],
          const SizedBox(height: 6),
          Text(
            'Total: ${_money(diff.totalBefore)} → ${_money(diff.totalAfter)}',
            style: style,
          ),
          Text(
            'Vigencia: ${_day(diff.validUntilBefore)} → ${_day(diff.validUntilAfter)}',
            style: style,
          ),
        ],
        if (version.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Líneas', style: style.copyWith(fontWeight: FontWeight.w700)),
          for (final line in version.items) Text(_line(line), style: style),
        ],
      ],
    );
  }

  String _line(QuoteVersionItem line) {
    final qty = line.quantity == line.quantity.roundToDouble()
        ? '${line.quantity.round()}'
        : '${line.quantity}';
    return '$qty × ${line.productName} · ${clp(line.total)}';
  }

  String _money(double? value) => value == null ? '—' : clp(value);

  String _day(String? value) => (value == null || value.isEmpty) ? '—' : value;
}
