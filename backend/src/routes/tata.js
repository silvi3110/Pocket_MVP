const express = require('express');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

const VIVA_PRECIO_BOB = 0.85;
const VARIACION_HOY = 2.14;

router.post('/chat', async (req, res) => {
  const { message } = req.body;
  const msg = (message || '').toLowerCase().trim();
  let reply = '';

  const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
  const u = home.rows[0] || {};
  const bob = parseFloat(u.saldo_bob ?? 0);
  const cardBob = parseFloat(u.card_saldo ?? 0);
  const viva = parseFloat(u.saldo_viva ?? 0);
  const puntos = u.puntos ?? 0;

  const txMes = await query(
    `SELECT COALESCE(SUM(monto),0) as gasto, COUNT(*) as n
     FROM transactions WHERE user_id = $1 AND tipo IN ('pago_qr','pago_online')
     AND fecha >= date_trunc('month', NOW())`,
    [req.user.id]
  );
  const gastoMes = parseFloat(txMes.rows[0].gasto);

  if (msg.includes('cómo voy') || msg.includes('como voy') || msg.includes('este mes')) {
    reply = `Este mes llevas **Bs ${gastoMes.toFixed(0)}** en compras con Pocket Card. Tienes **Bs ${bob.toFixed(0)}** en wallet y **Bs ${cardBob.toFixed(0)}** en tarjeta. ${gastoMes > 500 ? 'Vas un poco alto — revisa delivery y EMTAGAS.' : 'Vas bien, sigue así.'}`;
  } else if (msg.includes('convertir') && (msg.includes('viva') || msg.includes('$viva'))) {
  const valorViva = (viva * VIVA_PRECIO_BOB).toFixed(2);
    reply = `$VIVA subió **${VARIACION_HOY}%** hoy. Tienes **${viva.toFixed(2)} $VIVA** (≈ Bs ${valorViva}). ${VARIACION_HOY > 1.5 ? 'Buen momento para convertir si necesitas bolivianos para EMTAGAS o delivery.' : 'Puedes esperar un poco si no tienes prisa.'}`;
  } else if (msg.includes('delivery') || msg.includes('150') || msg.includes('gastar') || msg.includes('puedo')) {
    const monto = parseInt(msg.match(/\d+/)?.[0] || '150');
    const ok = cardBob >= monto;
    reply = ok
      ? `Sí, puedes gastar **Bs ${monto}** en delivery. Tu tarjeta tiene Bs ${cardBob.toFixed(0)}. Te quedarían Bs ${(cardBob - monto).toFixed(0)} — cómodo para el resto del mes.`
      : `Mejor espera: solo tienes **Bs ${cardBob.toFixed(0)}** en tarjeta y quieres gastar Bs ${monto}. Recarga desde wallet o pasa menos en delivery esta semana.`;
  } else if (msg.includes('pasanaku') || msg.includes('emtagas')) {
    reply = `Para **EMTAGAS** o tu **pasanaku**, usa Pocket Card QR — ganas puntos y megas VIVA. Con Bs ${cardBob.toFixed(0)} en tarjeta estás listo para pagos del día a día.`;
  } else if (msg.includes('punto')) {
    reply = `Tienes **${puntos} puntos Pocket**. Cada compra con tarjeta suma más. Canjéalos en Gift Cards cuando quieras.`;
  } else if (msg.includes('mega')) {
    reply = `En tu línea VIVA llevas **${parseFloat(u.megas_acumuladas ?? 0).toFixed(1)} megas** por pagar con Pocket Card.`;
  } else if (msg.includes('hola') || msg.includes('tata')) {
    reply =
      '¡Hola! Soy **TATA**, tu asistente financiero Pocket. Pregúntame sin tecnicismos:\n• "¿Cómo voy este mes?"\n• "¿Me conviene convertir mis $VIVA ahora?"\n• "¿Puedo gastar Bs 150 en delivery?"\n• Pasanaku, EMTAGAS, puntos...';
  } else {
    reply =
      'No entendí bien. Prueba: "¿Cómo voy este mes?", "¿Me conviene convertir mis $VIVA ahora?" o "¿Puedo gastar Bs 150 en delivery?"';
  }

  res.json({ reply, viva_variacion_hoy: VARIACION_HOY, viva_precio_bob: VIVA_PRECIO_BOB });
});

module.exports = router;
