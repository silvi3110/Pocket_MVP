const bcrypt = require('bcryptjs');

const CONFIG = {
  nextRewardAt: 900,
  alvaToPocketRatio: 0.5,
};

function generateCardNumber() {
  let suffix = '';
  for (let i = 0; i < 12; i++) suffix += Math.floor(Math.random() * 10);
  return `4000${suffix}`;
}

function formatCardDisplay(num) {
  if (!num) return '**** **** **** ****';
  const c = num.replace(/\s/g, '');
  return `${c.slice(0, 4)} ${c.slice(4, 8)} ${c.slice(8, 12)} ${c.slice(12, 16)}`;
}

function generateGiftCode() {
  const seg = () => Math.random().toString(36).substring(2, 6).toUpperCase();
  return `GC-${seg()}-${seg()}`;
}

async function verifyPin(input, stored) {
  if (!stored) return false;
  if (stored.startsWith('$2a$') || stored.startsWith('$2b$')) {
    return bcrypt.compare(input, stored);
  }
  return input === stored;
}

async function hashPin(pin) {
  return bcrypt.hash(pin, 10);
}

function mapUserHome(row) {
  if (!row) return null;
  return {
    id: row.user_id,
    phone: row.telefono,
    full_name: row.nombre,
    ci: row.ci,
    kyc_level: row.kyc_nivel,
    easy_mode: row.modo_facil,
    bob_balance: parseFloat(row.saldo_bob ?? 0),
    viva_balance: parseFloat(row.saldo_viva ?? 0),
    alva_points: row.puntos ?? 0,
    pocket_points: row.puntos ?? 0,
    card_number: formatCardDisplay(row.numero_virtual),
    numero_virtual: row.numero_virtual,
    tier: row.tier ?? null,
    card_balance: parseFloat(row.card_saldo ?? 0),
    card_status: row.card_activa ? 'active' : row.numero_virtual ? 'inactive' : 'none',
    daily_limit: parseFloat(row.card_limite ?? 0),
    limite_mensual: parseFloat(row.card_limite ?? 0),
    consumo_mes: parseFloat(row.card_consumo_mes ?? 0),
    viva_linked: !!row.numero_linea,
    viva_line_active: !!row.numero_linea,
    next_reward_at: CONFIG.nextRewardAt,
    megas_acumuladas: parseFloat(row.megas_acumuladas ?? 0),
    puntos_alva_omg: row.puntos_alva_omg ?? 0,
  };
}

function mapTransaction(tx) {
  const tipoMap = {
    pago_qr: 'qr',
    pago_online: 'online',
    carga_saldo: 'topup',
    conversion_puntos: 'convert',
    conversion_megas: 'convert',
  };
  return {
    id: tx.id,
    type: tipoMap[tx.tipo] ?? tx.tipo,
    tipo: tx.tipo,
    merchant: _merchantLabel(tx.tipo),
    amount: parseFloat(tx.monto),
    points_earned: tx.puntos_generados,
    megas_earned: parseFloat(tx.megas_generadas ?? 0),
    viva_cashback: parseFloat(tx.cashback_viva ?? 0),
    created_at: tx.fecha,
    fecha: tx.fecha,
    card_tier: tx.card_tier,
  };
}

function _merchantLabel(tipo) {
  const labels = {
    pago_qr: 'Comercio QR',
    pago_online: 'Tienda Online',
    carga_saldo: 'Carga a tarjeta',
    conversion_puntos: 'Conversión ALVA → Pocket',
    conversion_megas: 'Conversión megas',
    cashback: 'Cashback $VIVA',
  };
  return labels[tipo] ?? tipo;
}

function mapGiftCard(gc) {
  return {
    id: gc.id,
    name: gc.nombre,
    value_bob: parseFloat(gc.valor_bob),
    points_cost: gc.costo_puntos,
    active: gc.activa,
  };
}

function mapPointsLog(pl) {
  const delta = pl.delta_puntos ?? 0;
  return {
    id: pl.id,
    type: delta >= 0 ? 'earn' : 'redeem',
    amount: Math.abs(delta),
    delta_puntos: delta,
    delta_puntos_alva: pl.delta_puntos_alva ?? 0,
    description: pl.origen,
    origen: pl.origen,
    created_at: pl.fecha,
    fecha: pl.fecha,
  };
}

/** Próximo premio según catálogo y puntos actuales */
async function getNextReward(queryFn, puntosActuales) {
  const r = await queryFn(
    `SELECT nombre, valor_bob, costo_puntos FROM gift_cards_catalog
     WHERE activa = TRUE AND costo_puntos > $1 ORDER BY costo_puntos LIMIT 1`,
    [puntosActuales]
  );
  if (!r.rows.length) return null;
  const g = r.rows[0];
  return {
    nombre: g.nombre,
    valor_bob: parseFloat(g.valor_bob),
    costo_puntos: g.costo_puntos,
    faltan: g.costo_puntos - puntosActuales,
  };
}

module.exports = {
  CONFIG,
  generateCardNumber,
  formatCardDisplay,
  generateGiftCode,
  verifyPin,
  hashPin,
  mapUserHome,
  mapTransaction,
  mapGiftCard,
  mapPointsLog,
  getNextReward,
};
