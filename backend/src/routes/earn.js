const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapUserHome, CONFIG } = require('../utils/helpers');
const { activateEarn, acreditarEarn } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

/** Estado del programa EARN para el usuario */
router.get('/status', async (req, res) => {
  try {
    const r = await query(
      'SELECT saldo_viva, earn_activo, earn_desde FROM wallets WHERE user_id = $1',
      [req.user.id]
    );
    const w = r.rows[0];
    const saldoViva = parseFloat(w?.saldo_viva ?? 0);
    const puedeActivar = saldoViva >= CONFIG.EARN_MIN_VIVA;

    res.json({
      earn_activo: w?.earn_activo ?? false,
      earn_desde: w?.earn_desde ?? null,
      saldo_viva: saldoViva,
      apy: CONFIG.EARN_APY,
      min_viva: CONFIG.EARN_MIN_VIVA,
      puede_activar: puedeActivar,
      rendimiento_estimado_anual: parseFloat((saldoViva * CONFIG.EARN_APY).toFixed(4)),
      rendimiento_estimado_48h: parseFloat((saldoViva * (CONFIG.EARN_APY / 365) * 2).toFixed(6)),
      nota: 'Rendimiento 20% APY, capitalizable cada 48 horas',
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/** Activar EARN (requiere KYC + 200 $VIVA mínimo) */
router.post('/activate', async (req, res) => {
  try {
    const result = await activateEarn(req.user.id);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      ...result,
      message: `EARN activado — 20% APY sobre tu saldo $VIVA`,
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

/** Acreditar rendimiento EARN (demo: simula ciclo de 48hs) */
router.post('/acreditar', async (req, res) => {
  try {
    const result = await acreditarEarn(req.user.id);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      rendimiento: result.rendimiento,
      earn_apy: result.earn_apy,
      message: `+${result.rendimiento.toFixed(6)} $VIVA acreditados por rendimiento EARN`,
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
