const { withTransaction } = require('../db');
const { calcBenefits, convertAlvaToPocket } = require('./benefits');
const { generateCardNumber, generateGiftCode } = require('../utils/helpers');

const BONO_VINCULACION_PUNTOS = 50;
const LIMITE_BASIC = 2000;
const LIMITE_VIVA = 5000;

/** §3.4 — Pago con tarjeta (atómico) */
async function processPayment(userId, { monto, tipo, comercio }) {
  const amount = Number(monto);
  if (!amount || amount <= 0) throw new Error('Monto inválido');

  const tipoTx = tipo === 'qr' || tipo === 'pago_qr' ? 'pago_qr' : 'pago_online';

  return withTransaction(async (client) => {
    const userR = await client.query('SELECT kyc_nivel FROM users WHERE id = $1 FOR UPDATE', [userId]);
    if (!userR.rows.length) throw new Error('Usuario no encontrado');

    const cardR = await client.query('SELECT * FROM cards WHERE user_id = $1 FOR UPDATE', [userId]);
    const card = cardR.rows[0];
    if (!card || !card.activa) throw new Error('Activa tu Pocket Card primero');
    if (parseFloat(card.saldo_disponible) < amount) {
      throw new Error('Saldo de tarjeta insuficiente. Carga saldo desde tu wallet.');
    }
    if (parseFloat(card.consumo_mes) + amount > parseFloat(card.limite_mensual)) {
      throw new Error('Límite mensual de tarjeta excedido');
    }

    const kyc = userR.rows[0].kyc_nivel;
    if (kyc < 1) throw new Error('KYC Nivel 1 requerido para pagar');
    if (card.tier === 'viva' && kyc < 2) {
      throw new Error('KYC Nivel 2 requerido para pagar con tarjeta tier VIVA');
    }

    const benefits = calcBenefits(amount, card.tier);

    await client.query(
      `UPDATE cards SET saldo_disponible = saldo_disponible - $1, consumo_mes = consumo_mes + $1 WHERE id = $2`,
      [amount, card.id]
    );

    const txR = await client.query(
      `INSERT INTO transactions (user_id, card_id, tipo, monto, moneda, puntos_generados, megas_generadas, cashback_viva)
       VALUES ($1,$2,$3,$4,'BOB',$5,$6,$7) RETURNING *`,
      [userId, card.id, tipoTx, amount, benefits.puntos_generados, benefits.megas_generadas, benefits.cashback_viva]
    );

    await client.query(
      `UPDATE wallets SET puntos = puntos + $1, saldo_viva = saldo_viva + $2 WHERE user_id = $3`,
      [benefits.puntos_generados, benefits.cashback_viva, userId]
    );

    if (card.tier === 'viva' && benefits.megas_generadas > 0) {
      await client.query(
        `UPDATE viva_link SET megas_acumuladas = megas_acumuladas + $1 WHERE user_id = $2`,
        [benefits.megas_generadas, userId]
      );
    }

    await client.query(
      `INSERT INTO points_log (user_id, transaction_id, origen, delta_puntos)
       VALUES ($1, $2, 'pago_tarjeta', $3)`,
      [userId, txR.rows[0].id, benefits.puntos_generados]
    );

    return { transaction: txR.rows[0], benefits, card_tier: card.tier, comercio };
  });
}

/** §3.5 — Carga wallet → tarjeta (atómico) */
async function loadCardFromWallet(userId, monto) {
  const amount = Number(monto);
  if (!amount || amount <= 0) throw new Error('Monto inválido');

  return withTransaction(async (client) => {
    const walletR = await client.query('SELECT saldo_bob FROM wallets WHERE user_id = $1 FOR UPDATE', [userId]);
    if (parseFloat(walletR.rows[0].saldo_bob) < amount) {
      throw new Error('Saldo BOB insuficiente en wallet');
    }

    const cardR = await client.query('SELECT id, activa FROM cards WHERE user_id = $1 FOR UPDATE', [userId]);
    if (!cardR.rows.length || !cardR.rows[0].activa) {
      throw new Error('Activa tu Pocket Card antes de cargar saldo');
    }

    await client.query('UPDATE wallets SET saldo_bob = saldo_bob - $1 WHERE user_id = $2', [amount, userId]);
    await client.query('UPDATE cards SET saldo_disponible = saldo_disponible + $1 WHERE user_id = $2', [
      amount,
      userId,
    ]);

    const txR = await client.query(
      `INSERT INTO transactions (user_id, card_id, tipo, monto, moneda, puntos_generados, megas_generadas, cashback_viva)
       VALUES ($1, $2, 'carga_saldo', $3, 'BOB', 0, 0, 0) RETURNING *`,
      [userId, cardR.rows[0].id, amount]
    );

    return txR.rows[0];
  });
}

/** Simula ingreso de BOB a wallet (demo, sin pasarela) */
async function simulateWalletDeposit(userId, monto) {
  const amount = Number(monto);
  if (!amount || amount <= 0) throw new Error('Monto inválido');

  await withTransaction(async (client) => {
    await client.query('UPDATE wallets SET saldo_bob = saldo_bob + $1 WHERE user_id = $2', [amount, userId]);
  });
}

/** §3.2 — Activar / crear tarjeta */
async function activateCard(userId) {
  return withTransaction(async (client) => {
    const userR = await client.query('SELECT kyc_nivel FROM users WHERE id = $1', [userId]);
    if (userR.rows[0].kyc_nivel < 1) {
      throw new Error('KYC Nivel 1 requerido. Vincula tu línea VIVA primero.');
    }

    const vivaR = await client.query('SELECT 1 FROM viva_link WHERE user_id = $1', [userId]);
    const tier = vivaR.rows.length ? 'viva' : 'basic';
    const limite = tier === 'viva' ? LIMITE_VIVA : LIMITE_BASIC;

    const existing = await client.query('SELECT id FROM cards WHERE user_id = $1', [userId]);

    if (existing.rows.length) {
      const r = await client.query(
        `UPDATE cards SET activa = TRUE, tier = $1, limite_mensual = $2 WHERE user_id = $3 RETURNING *`,
        [tier, limite, userId]
      );
      return r.rows[0];
    }

    const r = await client.query(
      `INSERT INTO cards (user_id, numero_virtual, tier, saldo_disponible, limite_mensual, activa)
       VALUES ($1, $2, $3, 0, $4, TRUE) RETURNING *`,
      [userId, generateCardNumber(), tier, limite]
    );
    return r.rows[0];
  });
}

/** §3.6 — ALVA OMG → puntos Pocket (atómico) */
async function convertAlvaPoints(userId, cantidadAlva) {
  const alva = Number(cantidadAlva);
  if (!alva || alva <= 0) throw new Error('Cantidad ALVA inválida');

  return withTransaction(async (client) => {
    const lineR = await client.query(
      'SELECT puntos_alva_omg FROM viva_link WHERE user_id = $1 FOR UPDATE',
      [userId]
    );
    if (!lineR.rows.length || lineR.rows[0].puntos_alva_omg < alva) {
      throw new Error('Puntos ALVA OMG insuficientes');
    }

    const pocketPoints = convertAlvaToPocket(alva);

    await client.query('UPDATE viva_link SET puntos_alva_omg = puntos_alva_omg - $1 WHERE user_id = $2', [
      alva,
      userId,
    ]);
    await client.query('UPDATE wallets SET puntos = puntos + $1 WHERE user_id = $2', [pocketPoints, userId]);

    const cardR = await client.query('SELECT id FROM cards WHERE user_id = $1', [userId]);
    const txR = await client.query(
      `INSERT INTO transactions (user_id, card_id, tipo, monto, moneda, puntos_generados)
       VALUES ($1, $2, 'conversion_puntos', $3, 'BOB', $4) RETURNING *`,
      [userId, cardR.rows[0]?.id, pocketPoints, pocketPoints]
    );

    await client.query(
      `INSERT INTO points_log (user_id, transaction_id, origen, delta_puntos, delta_puntos_alva)
       VALUES ($1, $2, 'conversion_alva', $3, $4)`,
      [userId, txR.rows[0].id, pocketPoints, -alva]
    );

    return { alva_usados: alva, puntos_pocket: pocketPoints, transaction: txR.rows[0] };
  });
}

/** §3.7 — Canje gift card (atómico) */
async function redeemGiftCard(userId, giftCardId) {
  return withTransaction(async (client) => {
    const gcR = await client.query(
      'SELECT * FROM gift_cards_catalog WHERE id = $1 AND activa = TRUE',
      [giftCardId]
    );
    if (!gcR.rows.length) throw new Error('Gift Card no encontrada');
    const gc = gcR.rows[0];

    const walletR = await client.query('SELECT puntos FROM wallets WHERE user_id = $1 FOR UPDATE', [userId]);
    if (walletR.rows[0].puntos < gc.costo_puntos) {
      throw new Error('Puntos insuficientes');
    }

    const userR = await client.query('SELECT kyc_nivel FROM users WHERE id = $1', [userId]);
    if (userR.rows[0].kyc_nivel < 1) throw new Error('KYC Nivel 1 requerido para canjear');

    const code = generateGiftCode();

    await client.query('UPDATE wallets SET puntos = puntos - $1 WHERE user_id = $2', [
      gc.costo_puntos,
      userId,
    ]);

    const rewardR = await client.query(
      `INSERT INTO rewards (user_id, gift_card_catalog_id, puntos_usados, codigo_canje)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [userId, giftCardId, gc.costo_puntos, code]
    );

    await client.query(
      `INSERT INTO points_log (user_id, origen, delta_puntos) VALUES ($1, 'canje_gift_card', $2)`,
      [userId, -gc.costo_puntos]
    );

    return { codigo_canje: code, reward: rewardR.rows[0], gift_card: gc };
  });
}

/** Vincular línea VIVA — sube KYC 0→1 y bono */
async function linkVivaLine(userId, numeroLinea) {
  return withTransaction(async (client) => {
    const userR = await client.query('SELECT kyc_nivel, telefono FROM users WHERE id = $1 FOR UPDATE', [userId]);
    const linea = numeroLinea || userR.rows[0].telefono;
    const wasKyc0 = userR.rows[0].kyc_nivel === 0;

    await client.query(
      `INSERT INTO viva_link (user_id, numero_linea, tipo_plan, puntos_alva_omg)
       VALUES ($1, $2, 'prepago', 250)
       ON CONFLICT (user_id) DO UPDATE SET numero_linea = $2, vinculado_at = NOW()`,
      [userId, linea]
    );

    if (wasKyc0) {
      await client.query('UPDATE users SET kyc_nivel = 1 WHERE id = $1', [userId]);
      await client.query('UPDATE wallets SET puntos = puntos + $1 WHERE user_id = $2', [
        BONO_VINCULACION_PUNTOS,
        userId,
      ]);
      await client.query(
        `INSERT INTO points_log (user_id, origen, delta_puntos) VALUES ($1, 'bono_vinculacion', $2)`,
        [userId, BONO_VINCULACION_PUNTOS]
      );
    }
  });
}

/** Reset consumo mensual §3.8 */
async function resetMonthlyConsumption() {
  const r = await withTransaction(async (client) => {
    const result = await client.query('UPDATE cards SET consumo_mes = 0 RETURNING id');
    return result.rowCount;
  });
  return r;
}

module.exports = {
  processPayment,
  loadCardFromWallet,
  simulateWalletDeposit,
  activateCard,
  convertAlvaPoints,
  redeemGiftCard,
  linkVivaLine,
  resetMonthlyConsumption,
  LIMITE_BASIC,
  LIMITE_VIVA,
};
