/// Reglas de UI de Kilde. El API sigue siendo quien rechaza la acción.
library;

import 'package:nereus_app/features/crm/domain/crm_models.dart';

const kildeSalesLead = 'KILDE_SALES_LEAD';
const kildeSalesRep = 'KILDE_SALES_REP';

const kildeTeamRoles = {'KILDE_SALES_LEAD', 'OWNER', 'ADMIN_LOCAL'};

bool kildeIsLead(String? roleCode) => roleCode == kildeSalesLead;

bool kildeSeesTeam(String? roleCode) => kildeTeamRoles.contains(roleCode);

/// Equipo y Motivos. Con el rol todavía desconocido se muestran, para no
/// ocultarlos en el arranque. El Ejecutivo no los ve: el API responde 403.
bool showLeadOnlyDestination({
  required String? roleCode,
  required bool leadOnly,
}) {
  if (!leadOnly) return true;
  if (roleCode == null || roleCode.isEmpty) return true;
  return kildeSeesTeam(roleCode);
}

/// Cotización aceptada con OC de esta oportunidad, la de mayor versión.
/// Una v1 sin OC no tapa a la v2 que sí la tiene.
KildeQuote? acceptedQuoteWithPo(
  Iterable<KildeQuote> quotes, {
  String? opportunityId,
}) {
  KildeQuote? best;
  for (final quote in quotes) {
    if (opportunityId != null && quote.opportunityId != opportunityId) {
      continue;
    }
    if (!quote.acceptedWithPo) continue;
    if (best == null || quote.version > best.version) best = quote;
  }
  return best;
}

/// El ejecutivo no aprueba descuentos. Solo el Líder, y solo si está pendiente.
bool showDiscountDecision({
  required String? roleCode,
  required String discountStatus,
}) =>
    kildeIsLead(roleCode) && discountStatus == 'pending';

/// Texto que ve el vendedor mientras el Líder no decide el descuento.
const pendingDiscountLabel = 'Descuento pendiente de aprobación';

/// CA-04: pendiente del Líder no se envía. Una RFI bloqueante abierta tampoco.
bool quoteSendBlocked({
  required String discountStatus,
  required bool blockingRfiOpen,
}) =>
    discountStatus == 'pending' || blockingRfiOpen;

/// R-09: el botón existe solo para el Líder y se apaga sin ficha, cotización aceptada y OC.
bool deriveEnabled({
  required String? roleCode,
  required bool hasSurvey,
  required bool hasAcceptedQuoteWithPo,
}) =>
    kildeIsLead(roleCode) && hasSurvey && hasAcceptedQuoteWithPo;

bool stageIsLost({required bool isClosed, required bool isWon, required String name}) =>
    (isClosed && !isWon) || name.toLowerCase().contains('perdid');

/// Texto del botón Aceptar cuando la vigencia ya pasó.
const expiredQuoteAcceptLabel = 'Vencida: crea una versión nueva';

/// `detail` que devuelve el API al aceptar una cotización vencida.
const expiredQuoteAcceptDetail = 'Cotización vencida: crea una versión nueva.';

/// Día de calendario de `valid_until` (AAAA-MM-DD). Null si no se puede leer.
DateTime? quoteValidUntilDay(String? raw) {
  if (raw == null) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw.trim());
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

bool isIsoDate(String value) {
  final trimmed = value.trim();
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return false;
  return quoteValidUntilDay(trimmed) != null;
}

/// CA-06: vencida solo si la vigencia es anterior a hoy. Hoy todavía vale.
bool quoteIsExpired(String? validUntil, {DateTime? today}) {
  final day = quoteValidUntilDay(validUntil);
  if (day == null) return false;
  final now = today ?? DateTime.now();
  final todayDay = DateTime(now.year, now.month, now.day);
  return day.isBefore(todayDay);
}

bool quoteShowsExpired({required String status, required String? validUntil, DateTime? today}) =>
    status == 'expired' || quoteIsExpired(validUntil, today: today);

/// R-07: la OC se registra sobre la cotización aceptada.
bool canRegisterClientPo(String status) => status == 'accepted';
