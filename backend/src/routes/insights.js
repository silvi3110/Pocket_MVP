const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

router.get('/', async (req, res) => {
  const userId = req.user.id;
  const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [userId]);
  const u = home.rows[0] || {};

  const semanaActual = await query(
    `SELECT COALESCE(SUM(monto),0) as total FROM transactions
     WHERE user_id = $1 AND tipo IN ('pago_qr','pago_online')
     AND fecha >= NOW() - INTERVAL '7 days'`,
    [userId]
  );
  const semanaAnterior = await query(
    `SELECT COALESCE(SUM(monto),0) as total FROM transactions
     WHERE user_id = $1 AND tipo IN ('pago_qr','pago_online')
     AND fecha >= NOW() - INTERVAL '14 days' AND fecha < NOW() - INTERVAL '7 days'`,
    [userId]
  );

  const actual = parseFloat(semanaActual.rows[0].total);
  const anterior = parseFloat(semanaAnterior.rows[0].total) || 1;
  const pct = anterior > 0 ? Math.round(((actual - anterior) / anterior) * 100) : 0;

  const ultimoMov = await query(
    `SELECT MAX(fecha) as ultima FROM transactions WHERE user_id = $1`,
    [userId]
  );
  const diasSinMov = ultimoMov.rows[0].ultima
    ? Math.floor((Date.now() - new Date(ultimoMov.rows[0].ultima)) / 86400000)
    : 99;

  const viva = parseFloat(u.saldo_viva ?? 0);
  const earnSimulado = (viva * 0.02 * 30).toFixed(2);

  const insights = [];

  if (pct > 15) {
    insights.push({
      tipo: 'alerta',
      icono: 'trending_up',
      titulo: 'Gasto semanal',
      mensaje: `Gastaste **${pct}% más** en compras esta semana vs la anterior.`,
    });
  } else if (pct < -10 && actual > 0) {
    insights.push({
      tipo: 'positivo',
      icono: 'trending_down',
      titulo: 'Buen control',
      mensaje: `Bajaste **${Math.abs(pct)}%** en gastos esta semana. ¡Bien hecho!`,
    });
  }

  insights.push({
    tipo: 'info',
    icono: 'currency',
    titulo: '$VIVA hoy',
    mensaje: `El $VIVA subió **2.14%** hoy. Buen momento para convertir si necesitas bolivianos.`,
  });

  if (diasSinMov >= 3) {
    insights.push({
      tipo: 'recordatorio',
      icono: 'savings',
      titulo: 'Tu EARN sigue activo',
      mensaje: `Llevas **${diasSinMov} días** sin mover saldo — tu EARN acumuló ~Bs ${earnSimulado} en $VIVA.`,
    });
  }

  if (parseFloat(u.card_saldo ?? 0) < 50 && parseFloat(u.saldo_bob ?? 0) > 100) {
    insights.push({
      tipo: 'sugerencia',
      icono: 'card',
      titulo: 'Recarga tarjeta',
      mensaje: 'Tienes BOB en wallet pero poca en tarjeta. Pasa saldo para pagar con QR.',
    });
  }

  res.json({ insights, dias_sin_movimiento: diasSinMov, variacion_semanal_pct: pct });
});

module.exports = router;
