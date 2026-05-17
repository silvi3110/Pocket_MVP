const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { query } = require('../db');
const { simulateWalletDeposit } = require('../services/operations');
const { mapUserHome } = require('../utils/helpers');

const router = express.Router();
router.use(authMiddleware);

/** Simula carga de BOB en wallet (demo, sin pasarela) */
router.post('/deposit', async (req, res) => {
  try {
    const { monto } = req.body;
    await simulateWalletDeposit(req.user.id, monto);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      message: `Bs ${Number(monto).toFixed(2)} acreditados en wallet`,
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
