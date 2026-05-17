const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapUserHome, mapTransaction } = require('../utils/helpers');
const { processPayment } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

router.post('/pay', async (req, res) => {
  try {
    const { amount, monto, type, merchant, comercio } = req.body;
    const result = await processPayment(req.user.id, {
      monto: monto ?? amount,
      tipo: type,
      comercio: comercio ?? merchant,
    });

    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);

    res.json({
      transaction: mapTransaction({ ...result.transaction, card_tier: result.card_tier }),
      points_earned: result.benefits.puntos_generados,
      megas_earned: result.benefits.megas_generadas,
      viva_cashback: result.benefits.cashback_viva,
      total_points: home.rows[0].puntos,
      user: mapUserHome(home.rows[0]),
      notification: {
        title: 'Compra exitosa',
        body: `+${result.benefits.puntos_generados} pts Pocket${
          result.benefits.megas_generadas > 0 ? ` · +${result.benefits.megas_generadas} MB` : ''
        }${result.benefits.cashback_viva > 0 ? ` · +\$VIVA ${result.benefits.cashback_viva}` : ''}`,
      },
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get('/history', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit) || 50, 100);
  const offset = parseInt(req.query.offset) || 0;
  const r = await query(
    `SELECT * FROM v_transaction_history WHERE user_id = $1 LIMIT $2 OFFSET $3`,
    [req.user.id, limit, offset]
  );
  res.json({
    items: r.rows.map(mapTransaction),
    limit,
    offset,
  });
});

module.exports = router;
