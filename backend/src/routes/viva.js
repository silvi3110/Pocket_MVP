const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapUserHome } = require('../utils/helpers');
const { linkVivaLine } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

router.post('/link', async (req, res) => {
  try {
    await linkVivaLine(req.user.id, req.body.phone || req.body.numero_linea);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({ message: 'Línea VIVA vinculada', user: mapUserHome(home.rows[0]) });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get('/line', async (req, res) => {
  const r = await query(
    `SELECT vl.*, u.telefono,
            (vl.user_id IS NOT NULL) AS viva_linked,
            c.tier
     FROM users u
     LEFT JOIN viva_link vl ON vl.user_id = u.id
     LEFT JOIN cards c ON c.user_id = u.id
     WHERE u.id = $1`,
    [req.user.id]
  );
  const row = r.rows[0] || {};
  res.json({
    megas_acumuladas: parseFloat(row.megas_acumuladas ?? 0),
    megas_from_payments: parseFloat(row.megas_acumuladas ?? 0),
    puntos_alva_omg: row.puntos_alva_omg ?? 0,
    alva_omg_points: row.puntos_alva_omg ?? 0,
    numero_linea: row.numero_linea,
    tipo_plan: row.tipo_plan,
    viva_linked: !!row.numero_linea,
    tier: row.tier,
  });
});

module.exports = router;
