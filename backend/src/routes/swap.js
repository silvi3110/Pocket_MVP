const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapUserHome, CONFIG } = require('../utils/helpers');
const { swapVivaToUsdt, swapUsdtToViva } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

/** Info previa: tasas y saldos del usuario */
router.get('/preview', async (req, res) => {
  try {
    const r = await query('SELECT saldo_viva, saldo_usdt FROM wallets WHERE user_id = $1', [req.user.id]);
    res.json({
      saldo_viva: parseFloat(r.rows[0]?.saldo_viva ?? 0),
      saldo_usdt: parseFloat(r.rows[0]?.saldo_usdt ?? 0),
      viva_to_usdt_rate: CONFIG.VIVA_TO_USDT_RATE,
      swap_fee_pct: CONFIG.SWAP_FEE * 100,
      nota: `Comisión ${CONFIG.SWAP_FEE * 100}% aplicada al monto recibido`,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/** Swap $VIVA → USDT (2% comisión) */
router.post('/viva-usdt', async (req, res) => {
  try {
    const { monto_viva, amount } = req.body;
    const result = await swapVivaToUsdt(req.user.id, monto_viva ?? amount);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      ...result,
      message: `${result.viva_enviado} $VIVA → ${result.usdt_recibido} USDT (comisión: ${result.comision_usdt} USDT)`,
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

/** Swap USDT → $VIVA (2% comisión) */
router.post('/usdt-viva', async (req, res) => {
  try {
    const { monto_usdt, amount } = req.body;
    const result = await swapUsdtToViva(req.user.id, monto_usdt ?? amount);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      ...result,
      message: `${result.usdt_enviado} USDT → ${result.viva_recibido} $VIVA (comisión: ${result.comision_viva} $VIVA)`,
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
