const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapUserHome, getNextReward } = require('../utils/helpers');
const { linkVivaLine } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

router.get('/home', async (req, res) => {
  const r = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
  if (!r.rows.length) return res.status(404).json({ error: 'Usuario no encontrado' });

  const home = mapUserHome(r.rows[0]);
  const nextReward = await getNextReward(query, home.alva_points);

  const monthR = await query(
    `SELECT COALESCE(SUM(puntos_generados),0) AS puntos_mes,
            COALESCE(SUM(megas_generadas),0) AS megas_mes
     FROM transactions WHERE user_id = $1 AND fecha >= date_trunc('month', NOW())`,
    [req.user.id]
  );

  res.json({
    ...home,
    proximo_premio: nextReward,
    stats_mes: {
      puntos_ganados: parseInt(monthR.rows[0].puntos_mes),
      megas_ganadas: parseFloat(monthR.rows[0].megas_mes),
    },
  });
});

router.patch('/modo-facil', async (req, res) => {
  await query('UPDATE users SET modo_facil = $1 WHERE id = $2', [!!req.body.enabled, req.user.id]);
  res.json({ modo_facil: !!req.body.enabled });
});

router.post('/vincular-viva', async (req, res) => {
  try {
    const numero = req.body.numero_linea || req.body.phone;
    await linkVivaLine(req.user.id, numero);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      message: 'Línea VIVA vinculada. KYC subió a nivel 1 si aplicaba.',
      user: mapUserHome(home.rows[0]),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/rewards', async (req, res) => {
  const r = await query(
    `SELECT r.*, g.nombre, g.valor_bob FROM rewards r
     JOIN gift_cards_catalog g ON g.id = r.gift_card_catalog_id
     WHERE r.user_id = $1 ORDER BY r.fecha DESC`,
    [req.user.id]
  );
  res.json(r.rows);
});

module.exports = router;
