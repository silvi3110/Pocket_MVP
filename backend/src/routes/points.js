const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapGiftCard, mapPointsLog, mapUserHome } = require('../utils/helpers');
const { convertAlvaPoints, redeemGiftCard } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

router.get('/', async (req, res) => {
  const r = await query('SELECT puntos FROM wallets WHERE user_id = $1', [req.user.id]);
  res.json({ puntos: r.rows[0]?.puntos ?? 0, alva_points: r.rows[0]?.puntos ?? 0 });
});

router.get('/log', async (req, res) => {
  const r = await query(
    'SELECT * FROM points_log WHERE user_id = $1 ORDER BY fecha DESC LIMIT 50',
    [req.user.id]
  );
  res.json(r.rows.map(mapPointsLog));
});

router.get('/history', (req, res, next) => {
  req.url = '/log';
  router.handle(req, res, next);
});

router.post('/convert-alva', async (req, res) => {
  try {
    const cantidad = req.body.points ?? req.body.cantidad_alva ?? req.body.cantidad;
    const result = await convertAlvaPoints(req.user.id, cantidad);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      alva_usados: result.alva_usados,
      puntos_pocket: result.puntos_pocket,
      user: mapUserHome(home.rows[0]),
      message: `${result.alva_usados} ALVA → ${result.puntos_pocket} pts Pocket`,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get('/gift-cards/catalog', async (req, res) => {
  const r = await query('SELECT * FROM gift_cards_catalog WHERE activa = TRUE ORDER BY costo_puntos');
  res.json(r.rows.map(mapGiftCard));
});

router.get('/gift-cards', (req, res, next) => {
  req.url = '/gift-cards/catalog';
  router.handle(req, res, next);
});

router.post('/gift-cards/redeem', async (req, res) => {
  try {
    const id = req.body.gift_card_id ?? req.body.gift_card_catalog_id;
    const result = await redeemGiftCard(req.user.id, id);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({
      code: result.codigo_canje,
      codigo_canje: result.codigo_canje,
      gift_card: mapGiftCard(result.gift_card),
      user: mapUserHome(home.rows[0]),
      message: 'Gift Card canjeada',
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/redeem-gift-card', (req, res, next) => {
  req.url = '/gift-cards/redeem';
  router.handle(req, res, next);
});

module.exports = router;
