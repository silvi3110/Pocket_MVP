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

// KYC nivel 1 — vinculación básica (registro sin fotos)
// Se llama cuando el usuario solo se registra (ya ocurre en register si viva_linked)
// o cuando vincula su línea VIVA desde el modal KYC
router.post('/kyc-upgrade', async (req, res) => {
  try {
    const { rows } = await query('SELECT kyc_nivel FROM users WHERE id = $1', [req.user.id]);
    const currentKyc = rows[0]?.kyc_nivel ?? 0;
    if (currentKyc >= 1) {
      // Si ya tiene nivel 1, intentar subir a nivel 2 (carnet + selfie completado)
      if (currentKyc >= 2) {
        return res.status(400).json({ error: 'KYC ya está completo (nivel 2)' });
      }
      await query('UPDATE users SET kyc_nivel = 2 WHERE id = $1', [req.user.id]);
      // Actualizar límite de tarjeta si existe
      await query('UPDATE cards SET limite_mensual = 999999 WHERE user_id = $1', [req.user.id]);
      const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
      return res.json({ message: 'KYC Nivel 2 completado — sin límite mensual', user: mapUserHome(home.rows[0]) });
    }
    await query('UPDATE users SET kyc_nivel = 1 WHERE id = $1', [req.user.id]);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({ message: 'KYC Nivel 1 completado — límite Bs 500/mes', user: mapUserHome(home.rows[0]) });
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
