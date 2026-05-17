/**
 * Reglas de negocio §3.3 — beneficios por transacción según tier de tarjeta.
 * Valores calculados al momento del pago y persistidos en transactions.
 */
function calcBenefits(monto, tier) {
  const amount = Number(monto);
  if (tier === 'viva') {
    return {
      puntos_generados: Math.floor(amount * 2),
      megas_generadas: amount * 0.5,
      cashback_viva: amount * 0.01,
    };
  }
  return {
    puntos_generados: Math.floor(amount * 1),
    megas_generadas: 0,
    cashback_viva: 0,
  };
}

/** Ratio ALVA OMG → puntos Pocket (100 ALVA = 50 Pocket) */
function convertAlvaToPocket(cantidadAlva) {
  return Math.floor(cantidadAlva * 0.5);
}

module.exports = { calcBenefits, convertAlvaToPocket };
