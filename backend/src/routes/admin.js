const express = require('express');
const { resetMonthlyConsumption } = require('../services/operations');

const router = express.Router();

/** §3.8 — Reset manual de consumo_mes (demo) */
router.post('/reset-monthly', async (req, res) => {
  const count = await resetMonthlyConsumption();
  res.json({ message: 'consumo_mes reseteado en todas las tarjetas', cards_updated: count });
});

module.exports = router;
