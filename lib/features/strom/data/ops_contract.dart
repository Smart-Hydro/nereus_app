/// Rutas de la ronda 2. Un 404 deja el selector en el aviso, sin pedir un id.
const stromPurchaseOrdersPath = '/api/operations/purchase-orders/';

/// Recepciones de una OC. Si el GET no existe, la RTS se vincula sin recepción.
String stromPurchaseOrderReceptionsPath(String purchaseOrderId) =>
    '/api/operations/purchase-orders/$purchaseOrderId/receptions/';

const stromWarehousesPath = '/api/inventory/warehouses/';
