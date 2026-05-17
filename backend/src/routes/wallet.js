const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { simulateWalletDeposit } = require('../services/operations');
const { mapUserHome, CONFIG } = require('../utils/helpers');

const router = express.Router();
router.use(authMiddleware);

/**
 * Cash-in QR: el usuario paga BOB vía QR interbancario y se acreditan $VIVA.
 * Demo sin pasarela — en producción llegaría por webhook del banco.
 */
router.post('/deposit', async (req, res) => {
  try {
    const { monto } = req.body;
    const result = await simulateWalletDeposit(req.user.id, monto);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      message: `Cash-in OK: Bs ${Number(monto).toFixed(2)} → ${result.viva_acreditado.toFixed(4)} $VIVA (tasa: ${CONFIG.BOB_TO_VIVA_RATE} $VIVA/Bs)`,
      bob_pagado: result.bob_pagado,
      viva_acreditado: result.viva_acreditado,
      tasa: result.tasa,
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

/** Info de tasas de cambio para mostrar en el frontend */
router.get('/rates', (req, res) => {
  res.json({
    bob_to_viva: CONFIG.BOB_TO_VIVA_RATE,
    viva_to_usdt: CONFIG.VIVA_TO_USDT_RATE,
    swap_fee: CONFIG.SWAP_FEE,
    earn_apy: CONFIG.EARN_APY,
    earn_min_viva: CONFIG.EARN_MIN_VIVA,
    max_cashin_bob: 5000,
    nota: 'Tasas fijas para demo del hackathon',
  });
});

module.exports = router;
