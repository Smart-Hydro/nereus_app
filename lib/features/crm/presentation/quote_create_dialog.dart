import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/config/app_config.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/widgets/form_fields.dart';
import 'package:nereus_app/features/catalog/domain/journey_models.dart';
import 'package:nereus_app/features/catalog/providers/journey_providers.dart';
import 'package:nereus_app/features/crm/domain/crm_models.dart';
import 'package:nereus_app/features/crm/providers/crm_providers.dart';
import 'package:nereus_app/features/crm/providers/kilde_providers.dart';
import 'package:nereus_app/features/customers/domain/client_models.dart';

Future<void> showQuoteCreateDialog(BuildContext context, WidgetRef ref) async {
  final fixture = ref.read(dataModeProvider) == NereusDataMode.fixture;
  final created = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      child: SizedBox(
        width: 480,
        height: 560,
        child: fixture
            ? const QuoteCreateForm(products: [])
            : const _LiveQuoteCreate(),
      ),
    ),
  );
  if (created ?? false) {
    ref.invalidate(kildeQuotesProvider);
  }
}

class _LiveQuoteCreate extends ConsumerWidget {
  const _LiveQuoteCreate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products =
        ref.watch(productsProvider()).value ?? const <ProductItem>[];
    return QuoteCreateForm(products: products);
  }
}

class QuoteCreateForm extends ConsumerStatefulWidget {
  const QuoteCreateForm({required this.products, super.key});

  final List<ProductItem> products;

  @override
  ConsumerState<QuoteCreateForm> createState() => _QuoteCreateFormState();
}

class _QuoteCreateFormState extends ConsumerState<QuoteCreateForm> {
  final _glosa = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _price = TextEditingController();
  String? _clientId;
  String? _productId;
  DateTime? _until;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _glosa.dispose();
    _qty.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save(List<ClientItem> clients) async {
    final fixture = ref.read(dataModeProvider) == NereusDataMode.fixture;
    final clientId =
        _clientId ?? (clients.length == 1 ? clients.single.id : null);
    final client = clients.where((item) => item.id == clientId).firstOrNull;
    final glosa = _glosa.text.trim();
    final quantity = double.tryParse(_qty.text.replaceAll(',', '.')) ?? 0;
    final price = _money(_price.text);
    if (client == null) {
      setState(() => _error = 'Elige el cliente.');
      return;
    }
    if (glosa.isEmpty) {
      setState(() => _error = 'Escribe qué se está cotizando.');
      return;
    }
    if (quantity <= 0 || price == null || price <= 0) {
      setState(() => _error = 'Indica cantidad y precio unitario.');
      return;
    }
    if (!fixture && (_productId == null || _productId!.isEmpty)) {
      setState(
        () => _error = 'Elige un producto del catálogo. En vivo el total sale de ese ítem.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final until = _until;
    try {
      await ref
          .read(crmRepositoryProvider)
          .createQuotation(
            QuoteDraft(
              clientId: client.id,
              clientName: client.name,
              glosa: glosa,
              quantity: quantity,
              unitPrice: price,
              productId: _productId,
              validUntil: until == null
                  ? null
                  : '${until.year.toString().padLeft(4, '0')}-'
                        '${until.month.toString().padLeft(2, '0')}-'
                        '${until.day.toString().padLeft(2, '0')}',
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = userFacingErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients =
        ref.watch(customerClientsProvider).value ?? const <ClientItem>[];
    final selected =
        _clientId ?? (clients.length == 1 ? clients.single.id : null);
    final until = _until;
    return FormPad(
      busy: _busy,
      error: _error,
      onSubmit: () => _save(clients),
      submitLabel: 'Crear cotización',
      children: [
        Text('Nueva cotización', style: Theme.of(context).textTheme.titleLarge),
        if (clients.isEmpty)
          const Text('No hay clientes cargados.')
        else
          DropdownButtonFormField<String>(
            isExpanded: true,
            // This Flutter SDK still reads `value` on DropdownButtonFormField.
            // ignore: deprecated_member_use
            value: selected,
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: [
              for (final client in clients)
                DropdownMenuItem(value: client.id, child: Text(client.name)),
            ],
            onChanged: (value) => setState(() => _clientId = value),
          ),
        TextField(
          controller: _glosa,
          decoration: const InputDecoration(
            labelText: 'Qué se cotiza',
            hintText: 'Telemetría de pozo',
          ),
        ),
        if (widget.products.isNotEmpty)
          DropdownButtonFormField<String?>(
            isExpanded: true,
            // This Flutter SDK still reads `value` on DropdownButtonFormField.
            // ignore: deprecated_member_use
            value: _productId,
            decoration: const InputDecoration(
              labelText: 'Producto del catálogo',
            ),
            items: [
              const DropdownMenuItem(child: Text('Sin producto')),
              for (final product in widget.products)
                DropdownMenuItem(value: product.id, child: Text(product.name)),
            ],
            onChanged: (value) => setState(() => _productId = value),
          ),
        TextField(
          controller: _qty,
          decoration: const InputDecoration(labelText: 'Cantidad'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _price,
          decoration: const InputDecoration(
            labelText: 'Precio unitario',
            hintText: '1500000',
          ),
          keyboardType: TextInputType.number,
        ),
        OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate:
                  until ?? DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _until = picked);
          },
          child: Text(
            until == null
                ? 'Vigente hasta'
                : 'Vigente hasta ${until.day}/${until.month}/${until.year}',
          ),
        ),
      ],
    );
  }
}

double? _money(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  return double.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
}
