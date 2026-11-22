/// Semilla de Strøm para `NEREUS_DATA_MODE=fixture`.
/// Los números son del demo; la pantalla muestra nombres.
List<Map<String, dynamic>> stromSeedProjects() => [
  {
    'id': 41,
    'name': 'Instalación Norte',
    'code': 'PN-41',
    'service_type': 'project',
    'status': 'preparation',
    'status_reason': '',
    'committed_on': '2026-12-01',
    'owner': 7,
    'client_po_number': 'OC-1042',
    'client_po_received_on': '2026-11-02',
    'quotation': null,
    'ticket': null,
    'is_active': true,
    'milestones': [
      {
        'id': 1,
        'kind': 'committed_date',
        'occurred_on': '2026-12-01',
        'source': 'manual',
        'recorded_by': 7,
        'created': '2026-11-01T12:00:00Z',
      },
    ],
    'open_clarifications': <Map<String, dynamic>>[],
    'kilde_handoff': {
      'client': {'name': 'Agrícola Los Aromos'},
      'contacts': [
        {
          'first_name': 'Roberto',
          'last_name': 'Henríquez',
          'email': 'rhenriquez@losaromos.cl',
        },
      ],
      'wells': [
        {'name': 'Los Niches 1'},
        {'name': 'Los Niches 2'},
      ],
      'equipment': [
        {'product_name': 'Datalogger SmartHydro N1', 'quantity': 3},
      ],
      'survey': {'id': 'sv-opp-7', 'title': 'Levantamiento Pozos Los Niches'},
      'quotation': {'order_number': 'COT-1018', 'total': 8900000},
      'closed_rfis': [
        {
          'id': 'rfi-8',
          'question': '¿El pozo 2 tiene caudalímetro?',
          'answer': 'Sí, instalado en octubre.',
          'answered_by': 'Héctor Muñoz',
          'answered_at': '2026-10-16',
        },
      ],
    },
    'created': '2026-11-01T12:00:00Z',
    'modified': '2026-11-01T12:00:00Z',
  },
  {
    'id': 42,
    'name': 'Falla de logger',
    'code': 'PS-42',
    'service_type': 'support',
    'status': 'execution',
    'status_reason': '',
    'committed_on': '2026-11-20',
    'owner': 8,
    'client_po_number': '',
    'is_active': true,
    'milestones': <Map<String, dynamic>>[],
    'open_clarifications': [
      {
        'id': 3,
        'text': '¿El pozo tiene energía?',
        'asked_by': 8,
        'created': '2026-11-10T12:00:00Z',
      },
    ],
    'created': '2026-11-10T12:00:00Z',
    'modified': '2026-11-10T12:00:00Z',
  },
];

List<Map<String, dynamic>> stromSeedInstallations() => [
  {
    'id': 5,
    'name': 'Pozo Norte',
    'code': 'IN-5',
    'client': 12,
    'location': 'Camino Los Pozos 100, Ñuble',
    'access_requirements': 'Inducción del predio',
    'device_ids': [101, 102],
    'is_active': true,
  },
];

List<Map<String, dynamic>> stromSeedEquipment() => [
  {
    'id': 9,
    'project_point': 3,
    'device_id': 101,
    'product': 4,
    'model_name': 'Sensor caudal',
    'serial': 'SC-19',
    'work_order': 8,
    'is_current': true,
  },
];

List<Map<String, dynamic>> stromSeedOrders() => [
  {
    'id': 8,
    'project': 41,
    'service_type': 'project',
    'specialty': 'hydraulic',
    'status': 'suggested',
    'block_reason': '',
    'cancel_reason': '',
    'scope_version': 1,
    'commercial_reference': '',
    'pending_scope_changes': 1,
    'created': '2026-11-03T12:00:00Z',
  },
];

List<Map<String, dynamic>> stromSeedChanges() => [
  {
    'id': 2,
    'kind': 'added',
    'device': 101,
    'source_key': 'caudal',
    'activity': 'Medir caudal del pozo',
    'specialty': 'hydraulic',
    'mandatory': true,
    'status': 'pending',
  },
];

List<Map<String, dynamic>> stromSeedVisits() => [
  {
    'id': 15,
    'work_order': 8,
    'project': 41,
    'specialty': 'hydraulic',
    'visit_type': 'planned',
    'is_rework': false,
    'status': 'scheduled',
    'scheduled_for': '2026-11-18',
    'notes': 'Pozo 1',
    'crew': [
      {
        'id': 4,
        'name': 'Cuadrilla Sur',
        'company': 'SmartHydro',
        'specialty': 'hydraulic',
        'contact': '',
        'is_active': true,
      },
    ],
    'reschedules': <Map<String, dynamic>>[],
    'site_requirement_warnings': [
      {'message': 'Requisito de sitio pendiente: Permiso de ingreso.'},
    ],
    'rts_warnings': [
      {'message': 'La OT no tiene RTS de insumos.'},
    ],
  },
];

List<Map<String, dynamic>> stromSeedCrew() => [
  {
    'id': 4,
    'name': 'Cuadrilla Sur',
    'company': 'SmartHydro',
    'specialty': 'hydraulic',
    'contact': '+56 9 1111 2222',
    'is_active': true,
  },
];

List<Map<String, dynamic>> stromSeedActivities() => [
  {
    'id': 21,
    'work_order': 8,
    'specialty': 'hydraulic',
    'project_point': 3,
    'device': 101,
    'description': 'Medir caudal del pozo',
    'mandatory': true,
    'execution_status': 'pending',
    'validation_status': 'pending',
    'not_done_reason': '',
    'validation_notes': '',
  },
];

List<Map<String, dynamic>> stromSeedChecks() => [
  {
    'id': 6,
    'visit': 15,
    'work_order': 8,
    'activity': 21,
    'project_point': 3,
    'result': 'partial',
    'activity_execution_status': 'partial',
    'observation': 'Falta energizar',
    'measurement': '12 l/s',
    'pending_reason': 'Sin tablero',
    'pending_owner': 'Cliente',
  },
];

List<Map<String, dynamic>> stromSeedEvidences() => [
  {
    'id': 11,
    'visit': 15,
    'work_order': 8,
    'activity': 21,
    'caption': 'Tablero del pozo',
    'url': 'https://drive.google.com/file/d/demo-tablero',
    'file': '',
  },
];

List<Map<String, dynamic>> stromSeedRts() => [
  {
    'id': 3,
    'work_order': 8,
    'work_order_specialty': 'hydraulic',
    'status': 'draft',
    'notes': 'Sensores del pozo',
    'items': [
      {
        'id': 1,
        'product': 4,
        'product_name': 'Sensor caudal',
        'quantity': '1.0000',
        'unit': 'un',
        'status': 'pending',
        'stock_quantity': '6.0000',
      },
    ],
  },
];

List<Map<String, dynamic>> stromSeedReports() => [
  {
    'id': 2,
    'project': 41,
    'version': 1,
    'status': 'draft',
    'kind': 'project',
    'specialty': 'hydraulic',
    'body': {
      'text': 'Borrador del informe de puesta en marcha.',
      'activities': [
        {
          'id': 21,
          'activity_type': 'Medir caudal del pozo',
          'description': 'Medir caudal del pozo',
          'specialty': 'hydraulic',
          'execution_status': 'completed',
          'validation_status': 'approved',
          'validation_notes': '',
        },
      ],
      'tests_performed': [
        {
          'id': 6,
          'activity_id': 21,
          'result': 'completed',
          'measurement': '12 l/s',
          'observation': 'Caudal estable',
        },
      ],
      'evidences': [
        {
          'id': 11,
          'url': 'https://drive.google.com/file/d/demo-tablero',
          'caption': 'Tablero del pozo',
        },
      ],
      'pending_client_work': [
        {
          'id': 1,
          'description': 'Dejar energizado el tablero',
          'status': 'pending',
          'responsible': 'Cliente',
        },
      ],
    },
    'drive_url': 'https://drive.google.com/file/d/demo-informe',
  },
];

List<Map<String, dynamic>> stromSeedClarifications() => [
  {
    'id': 3,
    'project': 42,
    'text': '¿El pozo tiene energía?',
    'status': 'open',
    'answer': '',
  },
];

List<Map<String, dynamic>> stromSeedOutOfScope() => [
  {
    'id': 1,
    'project': 41,
    'description': 'Canaleta adicional no cotizada',
    'decision': 'pending',
    'decision_reason': '',
  },
];

List<Map<String, dynamic>> stromSeedCosts() => [
  {
    'id': 1,
    'specialty': 'hydraulic',
    'amount': '180000.00',
    'valid_from': '2026-11-01',
  },
];

List<Map<String, dynamic>> stromSeedTargets() => [
  {
    'id': 1,
    'kpi_code': 'kpi_9',
    'category': 'Dos puntos',
    'capture_points_min': 1,
    'capture_points_max': 3,
    'target_calendar_days': 20,
    'notes': 'Rango de puntos de captación',
  },
];

List<Map<String, dynamic>> stromSeedIndicators() => [
  {
    'id': 1,
    'name': 'Plan a informe',
    'start_event': 'official_plan',
    'end_event': 'report_sent',
    'day_type': 'business',
    'deduct_pauses': true,
  },
];

List<Map<String, dynamic>> stromSeedSites() => [
  {
    'id': 1,
    'project': 41,
    'kind': 'entry_permit',
    'status': 'pending',
    'notes': 'Aviso al administrador del predio',
  },
];

List<Map<String, dynamic>> stromSeedObligations() => [
  {
    'id': 1,
    'work_order': 8,
    'description': 'Dejar energizado el tablero',
    'status': 'pending',
    'responsible': 'Cliente',
    'notes': '',
  },
];

List<Map<String, dynamic>> stromSeedTransitions() => [
  {
    'id': 70,
    'entity_type': 'project',
    'entity_id': 41,
    'from_value': '',
    'to_value': 'preparation',
    'reason': 'Alta del proyecto',
    'scope_version': null,
    'actor': 7,
    'occurred_at': '2026-11-01T15:00:00Z',
  },
];
