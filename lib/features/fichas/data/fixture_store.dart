import 'package:nereus_app/features/fichas/domain/ficha_mapping.dart';
import 'package:nereus_app/features/fichas/domain/water_templates.dart';

class FixtureStore {
  FixtureStore();

  factory FixtureStore.seeded() {
    final store = FixtureStore();
    store.clients[demoClientId] = {
      'id': demoClientId,
      'name': 'Agrícola Santa Rosa SpA',
      'email': 'operaciones@santarosa.cl',
      'phone_number': '+56 9 8765 4321',
      'address': 'Camino Los Pozos 100, Ñuble',
      'dni': '76.543.210-K',
      'client_code': 'SR-01',
      'is_active': true,
    };
    store.clients['2'] = {
      'id': '2',
      'name': 'Comunidad de Aguas El Huape',
      'email': 'contacto@elhuape.cl',
      'phone_number': '+56 9 1122 3344',
      'address': 'El Huape, Pemuco',
      'dni': '65.111.222-3',
      'client_code': 'EH-02',
      'is_active': true,
    };
    _seedSurvey(
      store,
      id: 'sv-tenencias',
      title: tenenciasTemplateName,
      fields: tenenciasSection.fields,
    );
    _seedSurvey(
      store,
      id: 'sv-captacion',
      title: captacionTemplateName,
      fields: captacionSection.fields,
    );
    store.responses['rsp-captacion'] = {
      'id': 'rsp-captacion',
      'survey': 'sv-captacion',
      'answers': {'tipo_punto': 'Pozo'},
      'created': '2026-11-20T15:00:00',
    };
    return store;
  }

  static const demoClientId = '1';

  final Map<String, Map<String, dynamic>> clients = {};
  final Map<String, Map<String, dynamic>> groups = {};
  final Map<String, Map<String, dynamic>> fieldDefs = {};
  final Map<String, Map<String, dynamic>> values = {};
  final Map<String, Map<String, dynamic>> templates = {};
  final Map<String, Map<String, dynamic>> surveys = {};
  final Map<String, Map<String, dynamic>> responses = {};
  final Map<String, Map<String, dynamic>> cardTemplates = {};

  int _seq = 0;

  String nextId([String prefix = 'fx']) => '$prefix-${++_seq}';
}

void _seedSurvey(
  FixtureStore store, {
  required String id,
  required String title,
  required List<WaterFieldSpec> fields,
}) {
  store.surveys[id] = {
    'id': id,
    'title': title,
    'slug': slugify(title),
    'status': 'ACTIVE',
    'questions': [
      for (final field in fields)
        {
          'id': field.key,
          'label': field.name,
          'type': questionTypeForField(field.fieldType).name,
          'required': field.required,
          if (field.options.isNotEmpty) 'options': field.options,
        },
    ],
  };
}
