import 'package:flutter/foundation.dart';
import 'package:nereus_app/core/json_util.dart';

const receiverTypes = ['PERSONA_NATURAL', 'EMPRESA'];
const documentTypes = ['BOLETA', 'FACTURA'];

String receiverTypeLabel(String code) {
  return code == 'EMPRESA' ? 'Empresa' : 'Persona natural';
}

String documentTypeLabel(String code) {
  return code == 'FACTURA' ? 'Factura electrónica' : 'Boleta electrónica';
}

@immutable
class ClientItem {
  const ClientItem({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.branchName,
    this.dni,
    this.clientCode,
    this.commercialBusiness,
    this.receiverType = 'PERSONA_NATURAL',
    this.defaultDocumentType = 'BOLETA',
    this.region,
    this.province,
    this.commune,
    this.sector,
    this.tags = const [],
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? branchName;
  final String? dni;
  final String? clientCode;
  final String? commercialBusiness;
  final String receiverType;
  final String defaultDocumentType;
  final String? region;
  final String? province;
  final String? commune;
  final String? sector;
  final List<String> tags;
  final bool isActive;

  factory ClientItem.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'];
    return ClientItem(
      id: asString(json['id']),
      name: asString(json['name'], fallback: 'Cliente'),
      email: asStringOrNull(json['email']),
      phone: asStringOrNull(json['phone_number']),
      address: asStringOrNull(json['address']),
      branchName: asStringOrNull(json['branch_name'] ?? json['branch']),
      dni: asStringOrNull(json['dni']),
      clientCode: asStringOrNull(json['client_code']),
      commercialBusiness: asStringOrNull(json['commercial_business']),
      receiverType: asString(
        json['receiver_type'],
        fallback: 'PERSONA_NATURAL',
      ),
      defaultDocumentType: asString(
        json['default_document_type'],
        fallback: 'BOLETA',
      ),
      region: asStringOrNull(json['region']),
      province: asStringOrNull(json['province']),
      commune: asStringOrNull(json['commune']),
      sector: asStringOrNull(json['sector']),
      tags: [
        if (tags is List)
          for (final tag in tags)
            if ('$tag'.trim().isNotEmpty) '$tag'.trim(),
      ],
      isActive: json['is_active'] != false,
    );
  }

  @override
  bool operator ==(Object other) => other is ClientItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
