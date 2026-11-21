/// Reglas de UI de Kilde. El API sigue siendo quien rechaza la acción.
library;

const kildeSalesLead = 'KILDE_SALES_LEAD';
const kildeSalesRep = 'KILDE_SALES_REP';

const kildeTeamRoles = {'KILDE_SALES_LEAD', 'OWNER', 'ADMIN_LOCAL'};

bool kildeIsLead(String? roleCode) => roleCode == kildeSalesLead;

bool kildeSeesTeam(String? roleCode) => kildeTeamRoles.contains(roleCode);

/// El ejecutivo no aprueba descuentos. Solo el Líder, y solo si está pendiente.
bool showDiscountDecision({
  required String? roleCode,
  required String discountStatus,
}) =>
    kildeIsLead(roleCode) && discountStatus == 'pending';

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
