const express = require('express');
const Groq = require('groq-sdk');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();
router.use(authMiddleware);

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const MODEL = 'llama-3.3-70b-versatile';

async function buildUserContext(userId) {
  const homeRes = await query('SELECT * FROM v_user_home WHERE user_id = $1', [userId]);
  const u = homeRes.rows[0] || {};

  const txRes = await query(
    `SELECT tipo, monto, moneda, puntos_generados, megas_generadas, cashback_viva, fecha
     FROM v_transaction_history
     WHERE user_id = $1 AND fecha >= date_trunc('month', NOW())
     ORDER BY fecha DESC LIMIT 10`,
    [userId]
  );

  const gastoRes = await query(
    `SELECT COALESCE(SUM(monto), 0) AS gasto_mes, COUNT(*) AS n_pagos
     FROM transactions
     WHERE user_id = $1
       AND tipo IN ('card_payment_qr', 'card_payment_online', 'pago_qr', 'pago_online')
       AND fecha >= date_trunc('month', NOW())`,
    [userId]
  );

  const ptsRes = await query(
    `SELECT origen, delta_puntos, fecha
     FROM points_log WHERE user_id = $1
     ORDER BY fecha DESC LIMIT 5`,
    [userId]
  );

  const viva = parseFloat(u.saldo_viva ?? 0);
  const usdt = parseFloat(u.saldo_usdt ?? 0);
  const puntos = parseInt(u.puntos ?? 0);
  const cardSaldo = parseFloat(u.card_saldo ?? 0);
  const megas = parseFloat(u.megas_acumuladas ?? 0);
  const gastoMes = parseFloat(gastoRes.rows[0]?.gasto_mes ?? 0);
  const nPagos = parseInt(gastoRes.rows[0]?.n_pagos ?? 0);
  const earnActivo = u.earn_activo === true;
  const tier = u.tier ?? 'basic';
  const kyc = parseInt(u.kyc_nivel ?? 0);

  const txLines = txRes.rows.map(t =>
    `  - ${t.tipo}: ${parseFloat(t.monto).toFixed(4)} ${t.moneda} (${new Date(t.fecha).toLocaleDateString('es-BO')})`
  ).join('\n') || '  (sin transacciones este mes)';

  const ptsLines = ptsRes.rows.map(p =>
    `  - ${p.origen}: ${p.delta_puntos > 0 ? '+' : ''}${p.delta_puntos} pts`
  ).join('\n') || '  (sin movimientos)';

  return `Eres TATA, el asistente financiero inteligente de Pocket, la billetera digital de VIVA/ALVA en Bolivia.
Hablas en español boliviano, de forma amigable, directa y sin tecnicismos financieros.
Usas emojis con moderación. Nunca repites el nombre del usuario innecesariamente.
Tus respuestas son cortas (máximo 4 oraciones), concretas y útiles.
Cuando mencionas montos en $VIVA siempre escribes "$VIVA" después del número.

CONTEXTO DEL USUARIO ACTUAL:
- Nombre: ${u.nombre ?? 'Usuario'}
- Teléfono: ${u.telefono ?? '—'}
- KYC nivel: ${kyc} ${kyc === 2 ? '(completo)' : kyc === 1 ? '(básico)' : '(sin verificar)'}
- Tier tarjeta: ${tier.toUpperCase()} ${tier === 'viva' ? '(2 pts/$VIVA · 0.5 MB/$VIVA · 1% cashback)' : '(1 pt/$VIVA)'}
- EARN activo: ${earnActivo ? 'SÍ — 20% APY generando rendimientos' : 'NO'}

SALDOS:
- Wallet $VIVA: ${viva.toFixed(4)} $VIVA ${earnActivo ? `(generando ~${(viva * 0.20 / 365 * 2).toFixed(6)} $VIVA cada 48h)` : ''}
- Wallet USDT: ${usdt.toFixed(4)} USDT
- Tarjeta Pocket: ${cardSaldo.toFixed(4)} $VIVA

ACTIVIDAD ESTE MES:
- Pagos con tarjeta: ${nPagos} pagos · total ${gastoMes.toFixed(4)} $VIVA
- Puntos Pocket acumulados: ${puntos} pts
- Megas VIVA acumuladas: ${megas.toFixed(1)} MB

ÚLTIMAS TRANSACCIONES DEL MES:
${txLines}

ÚLTIMOS MOVIMIENTOS DE PUNTOS:
${ptsLines}

TASAS DEMO ACTUALES:
- 1 Bs = 0.14 $VIVA (cash-in QR interbancario)
- 1 $VIVA = 0.01 USDT
- Swap fee: 2%
- EARN mínimo: 200 $VIVA

Si el usuario pregunta algo fuera de finanzas personales o Pocket, recuérdale amablemente que eres un asistente financiero de Pocket.`;
}

// Historial de conversación por usuario (en memoria, se reinicia con el servidor)
// Estructura: { [userId]: { systemPrompt: string, messages: [{role, content}] } }
const conversations = {};

router.post('/chat', async (req, res) => {
  const { message } = req.body;
  if (!message?.trim()) {
    return res.status(400).json({ error: 'Mensaje vacío' });
  }

  try {
    const userId = req.user.id;

    if (!conversations[userId]) {
      const systemPrompt = await buildUserContext(userId);
      conversations[userId] = { systemPrompt, messages: [] };
    }

    const conv = conversations[userId];
    conv.messages.push({ role: 'user', content: message.trim() });

    const completion = await groq.chat.completions.create({
      model: MODEL,
      messages: [
        { role: 'system', content: conv.systemPrompt },
        ...conv.messages,
      ],
      temperature: 0.7,
      max_tokens: 400,
    });

    const reply = completion.choices[0]?.message?.content?.trim() || 'Sin respuesta';
    conv.messages.push({ role: 'assistant', content: reply });

    // Mantener historial acotado (últimos 20 mensajes)
    if (conv.messages.length > 20) {
      conv.messages = conv.messages.slice(-20);
    }

    res.json({ reply });
  } catch (err) {
    console.error('TATA Groq error:', err.message);
    res.json({
      reply: 'Estoy teniendo problemas para conectarme. Intenta de nuevo en un momento. 🙏',
    });
  }
});

router.post('/reset', (req, res) => {
  delete conversations[req.user.id];
  res.json({ ok: true });
});

module.exports = router;
