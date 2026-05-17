const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { mapUserHome } = require('../utils/helpers');
const { activateCard, loadCardFromWallet } = require('../services/operations');

const router = express.Router();
router.use(authMiddleware);

router.post('/activate', async (req, res) => {
  try {
    const card = await activateCard(req.user.id);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({ card, user: mapUserHome(home.rows[0]), message: 'Pocket Card activada' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/load', async (req, res) => {
  try {
    const { monto, amount } = req.body;
    await loadCardFromWallet(req.user.id, monto ?? amount);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({ user: mapUserHome(home.rows[0]), message: 'Saldo transferido a tarjeta' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/topup', async (req, res) => {
  try {
    const { monto, amount } = req.body;
    await loadCardFromWallet(req.user.id, monto ?? amount);
    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
    res.json({ user: mapUserHome(home.rows[0]), message: 'Saldo transferido a tarjeta' });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.get('/details', async (req, res) => {
  const r = await query('SELECT * FROM cards WHERE user_id = $1', [req.user.id]);
  res.json(r.rows[0] || null);
});

router.get('/', (req, res, next) => {
  req.url = '/details';
  router.handle(req, res, next);
});

module.exports = router;
