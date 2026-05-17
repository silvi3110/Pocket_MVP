const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.get('/', async (req, res) => {
  const userId = req.user.id;

  const tx = await query(
    `SELECT COUNT(*) as pagos,
            COALESCE(SUM(puntos_generados),0) as pts,
            MAX(fecha) as ultima
     FROM transactions WHERE user_id = $1 AND tipo IN ('pago_qr','pago_online')`,
    [userId]
  );
  const cargas = await query(
    `SELECT COUNT(*) as n FROM transactions WHERE user_id = $1 AND tipo = 'carga_saldo'`,
    [userId]
  );
  const canjes = await query(`SELECT COUNT(*) as n FROM rewards WHERE user_id = $1`, [userId]);

  const pagos = parseInt(tx.rows[0].pagos);
  const pts = parseInt(tx.rows[0].pts);
  const ultima = tx.rows[0].ultima;
  const diasSin = ultima ? Math.floor((Date.now() - new Date(ultima)) / 86400000) : 30;

  let nivel = 1;
  if (pagos >= 20) nivel = 5;
  else if (pagos >= 12) nivel = 4;
  else if (pagos >= 6) nivel = 3;
  else if (pagos >= 3) nivel = 2;

  const energia = Math.min(100, pagos * 8 + parseInt(cargas.rows[0].n) * 5);
  const humor = diasSin >= 5 ? 'triste' : diasSin >= 3 ? 'extraña' : energia > 70 ? 'feliz' : 'neutral';

  const accesorios = [];
  if (pagos >= 1) accesorios.push('collar_viva');
  if (pagos >= 5) accesorios.push('gorro_pocket');
  if (parseInt(canjes.rows[0].n) >= 1) accesorios.push('mochila_gift');
  if (pts >= 500) accesorios.push('lentes_cool');
  if (nivel >= 4) accesorios.push('capa_heroe');

  const mensaje =
    humor === 'triste'
      ? '¡Te extrañé! Hace días que no pagas con Pocket. ¡Vamos, un QR y recuperamos energía!'
      : humor === 'extraña'
        ? '¿Todo bien? Extraño cuando no usas tu Pocket Card...'
        : `¡Guau! Llevas ${pagos} pagos con QR. Energía al ${energia}%.`;

  res.json({
    nombre: 'Cachuchín',
    nivel,
    energia,
    humor,
    mensaje,
    accesorios,
    dias_sin_actividad: diasSin,
    pagos_totales: pagos,
  });
});

router.post('/actividad', async (req, res) => {
  const { tipo } = req.body;
  const bonus = tipo === 'pago_qr' ? 15 : tipo === 'mision' ? 25 : 10;
  res.json({ energia_ganada: bonus, mensaje: '¡Cachuchín está feliz! +' + bonus + ' energía' });
});

module.exports = router;
