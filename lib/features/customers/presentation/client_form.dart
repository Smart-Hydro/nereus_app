import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nereus_app/core/network/api_error.dart';
import 'package:nereus_app/core/providers.dart';
import 'package:nereus_app/core/theme/tokens.dart';
import 'package:nereus_app/core/widgets/form_fields.dart';
import 'package:nereus_app/features/catalog/providers/journey_providers.dart';
import 'package:nereus_app/features/customers/domain/chile_places.dart';
import 'package:nereus_app/features/customers/domain/client_models.dart';
import 'package:nereus_app/features/customers/presentation/place_field.dart';
import 'package:nereus_app/features/devices/providers/devices_provider.dart';
import 'package:nereus_app/features/tickets/domain/ticket_models.dart';

class ClientForm extends ConsumerStatefulWidget {
  const ClientForm({super.key, this.existing});

  final ClientItem? existing;

  @override
  ConsumerState<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends ConsumerState<ClientForm> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _dni = TextEditingController();
  final _code = TextEditingController();
  final _giro = TextEditingController();
  final _province = TextEditingController();
  final _commune = TextEditingController();
  final _sector = TextEditingController();
  final _tags = TextEditingController();
  final _communeFocus = FocusNode();
  String _receiver = 'PERSONA_NATURAL';
  String _document = 'BOLETA';
  String? _region;
  bool _active = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing == null) return;
    _name.text = existing.name;
    _email.text = existing.email ?? '';
    _phone.text = existing.phone ?? '';
    _address.text = existing.address ?? '';
    _dni.text = existing.dni ?? '';
    _code.text = existing.clientCode ?? '';
    _giro.text = existing.commercialBusiness ?? '';
    _province.text = existing.province ?? '';
    _commune.text = existing.commune ?? '';
    _sector.text = existing.sector ?? '';
    _tags.text = existing.tags.join(', ');
    _receiver = existing.receiverType;
    _document = existing.defaultDocumentType;
    _region = existing.region;
    _active = existing.isActive;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _email,
      _phone,
      _address,
      _dni,
      _code,
      _giro,
      _province,
      _commune,
      _sector,
      _tags,
    ]) {
      controller.dispose();
    }
    _communeFocus.dispose();
    super.dispose();
  }

  String? _blank(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  List<String> _regionItems() {
    final names = chileRegionNames;
    final current = _region;
    if (current != null && current.isNotEmpty && !names.contains(current)) {
      return [current, ...names];
    }
    return names;
  }

  void _applyPlace(ChilePlace place) {
    setState(() {
      _region = place.region;
      _province.text = place.province;
      _commune.text = place.commune;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'El nombre es obligatorio.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final body = {
      'name': _name.text.trim(),
      'email': _blank(_email),
      'phone_number': _blank(_phone),
      'address': _blank(_address),
      'dni': _blank(_dni),
      'client_code': _blank(_code),
      'commercial_business': _blank(_giro),
      'receiver_type': _receiver,
      'default_document_type': _document,
      'region': _region,
      'province': _blank(_province),
      'commune': _blank(_commune),
      'sector': _blank(_sector),
      'tags': [
        for (final tag in _tags.text.split(','))
          if (tag.trim().isNotEmpty) tag.trim(),
      ],
      'is_active': _active,
    };
    try {
      final repo = ref.read(customersRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(body);
      } else {
        await repo.update(widget.existing!.id, body);
      }
      ref.invalidate(clientsProvider);
      ref.invalidate(customerClientsProvider);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on Object catch (error) {
      setState(() => _error = userFacingErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: NereusTokens.text(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormPad(
      busy: _busy,
      error: _error,
      onSubmit: _save,
      children: [
        _section('Identificación'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nombre o razón social'),
        ),
        TextField(
          controller: _code,
          decoration: const InputDecoration(
            labelText: 'Código de socio',
            helperText: 'Si lo dejas vacío, el sistema asigna uno.',
          ),
        ),
        TextField(
          controller: _dni,
          decoration: const InputDecoration(labelText: 'RUT'),
        ),
        SelectField<String>(
          label: 'Tipo de receptor',
          value: _receiver,
          items: receiverTypes,
          itemLabel: receiverTypeLabel,
          onChanged: (value) {
            if (value != null) setState(() => _receiver = value);
          },
        ),
        TextField(
          controller: _giro,
          decoration: const InputDecoration(labelText: 'Giro'),
        ),
        SelectField<String>(
          label: 'Documento por defecto',
          value: _document,
          items: documentTypes,
          itemLabel: documentTypeLabel,
          onChanged: (value) {
            if (value != null) setState(() => _document = value);
          },
        ),
        _section('Contacto'),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Teléfono'),
        ),
        _section('Ubicación'),
        SelectField<String>(
          label: 'Región',
          value: _region ?? '',
          items: ['', ..._regionItems()],
          itemLabel: (value) => value.isEmpty ? 'Todas las regiones' : value,
          onChanged: (value) {
            final next = (value == null || value.isEmpty) ? null : value;
            setState(() {
              _region = next;
              final current = placeForCommune(_commune.text);
              if (current != null && current.region != next) {
                _commune.clear();
                _province.clear();
              }
            });
          },
        ),
        PlaceField(
          commune: _commune,
          focusNode: _communeFocus,
          region: _region,
          onPlace: _applyPlace,
        ),
        TextField(
          controller: _province,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Provincia',
            helperText: 'Queda lista al elegir la comuna.',
          ),
        ),
        TextField(
          controller: _address,
          decoration: const InputDecoration(labelText: 'Dirección'),
        ),
        TextField(
          controller: _sector,
          decoration: const InputDecoration(labelText: 'Sector'),
        ),
        _section('Clasificación'),
        TextField(
          controller: _tags,
          decoration: const InputDecoration(
            labelText: 'Etiquetas',
            helperText: 'Sepáralas con coma. Ejemplo: APR, telemetría',
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Cliente activo'),
          value: _active,
          onChanged: (value) => setState(() => _active = value),
        ),
      ],
    );
  }
}
