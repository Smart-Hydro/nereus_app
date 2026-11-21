/// Etiquetas en español de Chile. Un valor desconocido se muestra tal cual.
String opsLabel(
  String value,
  Map<String, String> known, {
  String empty = 'Sin estado',
}) {
  if (value.isEmpty) return empty;
  return known[value] ?? value;
}

const serviceTypeLabels = {
  'project': 'Proyecto',
  'installation': 'Instalación',
  'support': 'Soporte',
  'maintenance': 'Mantención',
};

const projectStatusLabels = {
  'preparation': 'Preparación',
  'execution': 'Ejecución',
  'report_approved': 'Informe aprobado',
  'closed': 'Cerrado',
  'suspended': 'Suspendido',
  'cancelled': 'Cancelado',
};

const specialtyLabels = {
  'hydraulic': 'Hidráulica',
  'electric': 'Eléctrica',
};

const workOrderStatusLabels = {
  'suggested': 'Sugerida',
  'confirmed': 'Confirmada',
  'planned': 'Planificada',
  'in_progress': 'En ejecución',
  'executed': 'Ejecutada',
  'blocked': 'Bloqueada',
  'cancelled': 'Cancelada',
};

const visitStatusLabels = {
  'proposed': 'Propuesta',
  'scheduled': 'Programada',
  'in_progress': 'En curso',
  'finished': 'Finalizada',
  'cancelled': 'Cancelada',
};

const visitTypeLabels = {
  'planned': 'Planificada',
  'rework': 'Retrabajo',
  'client_restriction': 'Restricción del cliente',
  'scope_change': 'Cambio de alcance',
  'other': 'Otra',
};

const executionLabels = {
  'pending': 'Pendiente',
  'partial': 'Parcial',
  'completed': 'Completada',
  'not_done': 'No realizada',
};

const validationLabels = {
  'pending': 'Pendiente',
  'approved': 'Aprobada',
  'approved_with_observations': 'Aprobada con observaciones',
  'requires_correction': 'Requiere corrección',
};

const scopeItemLabels = {
  'pending': 'Pendiente técnico',
  'pending_technical': 'Pendiente técnico',
  'confirmed': 'Confirmado',
};

const milestoneLabels = {
  'client_po': 'OC del cliente',
  'client_po_received': 'Recepción de la OC',
  'committed_date': 'Fecha comprometida',
  'official_plan': 'Planificación oficial',
  'first_visit': 'Primera visita',
  'work_orders_done': 'OT ejecutadas',
  'report_sent': 'Informe enviado',
  'closed': 'Cierre',
};

const siteKindLabels = {
  'entry_permit': 'Permiso de ingreso',
  'documentation': 'Documentación',
  'induction': 'Inducción',
};

const siteStatusLabels = {
  'pending': 'Pendiente',
  'fulfilled': 'Cumplido',
};

const obligationLabels = {
  'pending': 'Pendiente',
  'fulfilled': 'Cumplida',
  'not_fulfilled': 'No cumplida',
};

const rtsStatusLabels = {
  'draft': 'Borrador',
  'prepared': 'Preparada',
  'reserved': 'Reservada',
  'issued': 'Con salida',
  'partial': 'Parcial',
};

const rtsItemLabels = {
  'pending': 'Pendiente',
  'reserved': 'Reservado',
  'issued': 'Salida',
  'to_buy': 'Por comprar',
};

const reportStatusLabels = {
  'draft': 'Borrador',
  'review': 'Revisión',
  'approved': 'Aprobado',
  'sent': 'Enviado',
};

const reportKindLabels = {
  'project': 'Informe de proyecto',
  'maintenance': 'Informe de mantención',
};

const clarificationLabels = {
  'open': 'Abierta',
  'answered': 'Respondida',
};

const outOfScopeLabels = {
  'pending': 'Pendiente',
  'new_work_order': 'Nueva OT en el mismo proyecto',
  'new_project': 'Proyecto nuevo',
};

const entityLabels = {
  'project': 'Proyecto',
  'work_order': 'OT',
  'visit': 'Visita',
  'activity': 'Actividad',
  'validation': 'Validación',
  'scope': 'Alcance',
  'report': 'Informe',
};

const eventLabels = {
  'client_po_received': 'Recepción de la OC',
  'official_plan': 'Planificación oficial',
  'first_visit': 'Primera visita',
  'work_orders_done': 'OT ejecutadas',
  'report_sent': 'Informe enviado',
  'closed': 'Cierre',
  'work_order_confirmed': 'OT confirmada',
  'work_order_executed': 'OT ejecutada',
};

const dayTypeLabels = {
  'calendar': 'Días corridos',
  'business': 'Días hábiles',
};

String serviceTypeLabel(String value) =>
    opsLabel(value, serviceTypeLabels, empty: 'Proyecto');

String projectStatusLabel(String value) => opsLabel(value, projectStatusLabels);

String specialtyLabel(String value) =>
    opsLabel(value, specialtyLabels, empty: 'Sin especialidad');

String workOrderStatusLabel(String value) =>
    opsLabel(value, workOrderStatusLabels);

String visitStatusLabel(String value) => opsLabel(value, visitStatusLabels);

String visitTypeLabel(String value) =>
    opsLabel(value, visitTypeLabels, empty: 'Planificada');

/// La reserva de la RTS baja el stock una sola vez, en la bodega de la sucursal.
const rtsReserveNote =
    'La reserva descuenta una sola vez de la bodega de la sucursal.';

/// Con especialidad, Operaciones o el líder de esa especialidad.
/// Sin especialidad, Operaciones o cualquier líder.
String reportApproverNote(String specialty) {
  if (specialty.trim().isEmpty) {
    return 'Lo aprueba Operaciones o cualquier líder.';
  }
  return 'Lo aprueba Operaciones o el líder de la especialidad.';
}
