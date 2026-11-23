import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';

class QuoteVersionDraft {
  const QuoteVersionDraft({
    required this.validUntil,
    required this.total,
    required this.items,
  });

  final String validUntil;
  final double total;
  final List<Map<String, dynamic>> items;
}

Future<QuoteVersionDraft?> askNewQuoteVersion(
  BuildContext context,
  KildeQuote quote,
) {
  return showDialog<QuoteVersionDraft>(
    context: context,
    builder: (context) => _NewVersionDialog(quote: quote),
  );
}

class _NewVersionDialog extends StatefulWidget {
  const _NewVersionDialog({required this.quote});

  final KildeQuote quote;

  @override
  State<_NewVersionDialog> createState() => _NewVersionDialogState();
}

class _LineControllers {
  _LineControllers(QuoteLine line)
    : name = line.name,
      productId = line.productId,
      quantity = TextEditingController(
        text: line.quantity == line.quantity.roundToDouble()
            ? '${line.quantity.round()}'
            : '${line.quantity}',
      ),
      unitPrice = TextEditingController(text: '${line.unitPrice.round()}'),
      discount = TextEditingController(text: '0');

  final String name;
  final String? productId;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  final TextEditingController discount;

  void dispose() {
    quantity.dispose();
    unitPrice.dispose();
    discount.dispose();
  }
}

class _NewVersionDialogState extends State<_NewVersionDialog> {
  late final TextEditingController _until;
  late final TextEditingController _total;
  late final List<_LineControllers> _lines;
  var _error = false;

  @override
  void initState() {
    super.initState();
    _until = TextEditingController(text: widget.quote.validUntil ?? '');
    _total = TextEditingController(text: '${widget.quote.total.round()}');
    _lines = [for (final line in widget.quote.lines) _LineControllers(line)];
  }

  @override
  void dispose() {
    _until.dispose();
    _total.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final total = double.tryParse(_total.text.trim().replaceAll(',', '.'));
    if (total == null) {
      setState(() => _error = true);
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final quantity = double.tryParse(line.quantity.text.trim());
      final price = double.tryParse(line.unitPrice.text.trim());
      if (quantity == null || price == null) {
        setState(() => _error = true);
        return;
      }
      final discount = double.tryParse(line.discount.text.trim().replaceAll(',', '.'));
      if (discount == null || discount < 0 || discount > 100) {
        setState(() => _error = true);
        return;
      }
      final product = int.tryParse(line.productId ?? '');
      items.add({
        'product_name': line.name,
        if (product != null) 'product': product,
        'quantity': quantity,
        'unit_price': price,
        if (discount > 0) 'discount_percentage': discount,
      });
    }
    Navigator.pop(
      context,
      QuoteVersionDraft(validUntil: _until.text.trim(), total: total, items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva versión'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in _lines) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(line.name),
                ),
                TextField(
                  controller: line.quantity,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Cantidad'),
                ),
                TextField(
                  controller: line.unitPrice,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Precio unitario'),
                ),
                TextField(
                  controller: line.discount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Descuento %',
                    helperText:
                        'Mayor a 0 queda pendiente de aprobación del Líder.',
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _total,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total'),
              ),
              TextField(
                controller: _until,
                decoration: const InputDecoration(
                  labelText: 'Vigencia (AAAA-MM-DD)',
                ),
              ),
              if (_error)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Revisa cantidades, precios, descuento y total.'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Crear versión')),
      ],
    );
  }
}
