const express = require('express');
const jwt = require('jsonwebtoken');
const { query } = require('../db');
const { authMiddleware } = require('../middleware/auth');
const { hashPin, verifyPin, mapUserHome } = require('../utils/helpers');
const { linkVivaLine } = require('../services/operations');

const router = express.Router();

const VIVA_NUMBERS = {
  '70012345': { nombre: 'María López', ci: '4567890', viva_line_active: true },
  '70098765': { nombre: 'Carlos Mendoza', ci: '1234567', viva_line_active: true },
  '70111222': { nombre: 'Ana Quispe', ci: '9876543', viva_line_active: false },
  '70000001': { nombre: 'Demo Pocket', ci: '12345678', viva_line_active: true },
};

router.get('/viva-prefill/:phone', (req, res) => {
  const data = VIVA_NUMBERS[req.params.phone];
  if (!data) {
    return res.json({ found: false, message: 'Número no encontrado en VIVA. Registro manual.' });
  }
  res.json({
    found: true,
    full_name: data.nombre,
    nombre: data.nombre,
    ci: data.ci,
    viva_line_active: data.viva_line_active,
    kyc_level: data.viva_line_active ? 1 : 0,
  });
});

router.post('/register', async (req, res) => {
  try {
    const { phone, pin, full_name, nombre, ci, viva_linked } = req.body;
    const telefono = phone || req.body.telefono;
    const name = nombre || full_name || 'Usuario Pocket';

    if (!pin || pin.length < 6) {
      return res.status(400).json({ error: 'PIN de 6 dígitos requerido' });
    }
    if (!ci) return res.status(400).json({ error: 'CI requerido' });
    // Teléfono es opcional — si no viene, generamos uno interno
    const finalTelefono = telefono || `pocket_${Date.now()}`;

    const exists = await query('SELECT id FROM users WHERE ci = $1', [ci]);
    if (exists.rows.length) {
      return res.status(409).json({ error: 'CI ya registrado' });
    }
    if (telefono) {
      const phoneExists = await query('SELECT id FROM users WHERE telefono = $1', [telefono]);
      if (phoneExists.rows.length) {
        return res.status(409).json({ error: 'Teléfono ya registrado' });
      }
    }

    const pinStored = await hashPin(pin);

    const userResult = await query(
      `INSERT INTO users (nombre, ci, telefono, pin, kyc_nivel)
       VALUES ($1, $2, $3, $4, 0) RETURNING id`,
      [name, ci, finalTelefono, pinStored]
    );
    const userId = userResult.rows[0].id;

    await query(
      'INSERT INTO wallets (user_id, saldo_bob, saldo_viva, puntos) VALUES ($1, 0, 0, 0)',
      [userId]
    );

    if (viva_linked) {
      await linkVivaLine(userId, finalTelefono);
    }

    const token = jwt.sign(
      { id: userId, phone: finalTelefono },
      process.env.JWT_SECRET || 'pocket_hackathon_secret',
      { expiresIn: '7d' }
    );

    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [userId]);
    res.status(201).json({
      user: mapUserHome(home.rows[0]),
      token,
      message: viva_linked ? 'Registro OK — vincula y activa tu tarjeta' : 'Registro OK — kyc_nivel 0',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message || 'Error en registro' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const telefono = req.body.phone || req.body.telefono;
    const { pin } = req.body;

    const r = await query('SELECT * FROM users WHERE telefono = $1', [telefono]);
    if (!r.rows.length) return res.status(404).json({ error: 'Usuario no encontrado' });

    const user = r.rows[0];
    if (!(await verifyPin(pin, user.pin))) {
      return res.status(401).json({ error: 'PIN incorrecto' });
    }

    const token = jwt.sign(
      { id: user.id, phone: user.telefono },
      process.env.JWT_SECRET || 'pocket_hackathon_secret',
      { expiresIn: '7d' }
    );

    const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [user.id]);
    res.json({ user: mapUserHome(home.rows[0]), token });
  } catch (err) {
    res.status(500).json({ error: 'Error en login' });
  }
});

router.post('/verify-pin', authMiddleware, async (req, res) => {
  const { pin } = req.body;
  const r = await query('SELECT pin FROM users WHERE id = $1', [req.user.id]);
  const valid = await verifyPin(pin, r.rows[0].pin);
  res.json({ valid });
});

router.get('/me', authMiddleware, async (req, res) => {
  const r = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
  if (!r.rows.length) return res.status(404).json({ error: 'Usuario no encontrado' });
  res.json(mapUserHome(r.rows[0]));
});

router.patch('/easy-mode', authMiddleware, async (req, res) => {
  await query('UPDATE users SET modo_facil = $1 WHERE id = $2', [!!req.body.enabled, req.user.id]);
  res.json({ easy_mode: !!req.body.enabled });
});

router.post('/upgrade-kyc', authMiddleware, async (req, res) => {
  const { level } = req.body;
  if (level < 0 || level > 2) return res.status(400).json({ error: 'Nivel inválido' });
  await query('UPDATE users SET kyc_nivel = $1 WHERE id = $2', [level, req.user.id]);
  if (level === 2) {
    await query(
      `INSERT INTO points_log (user_id, origen, delta_puntos) VALUES ($1, 'bono_kyc', 25)`,
      [req.user.id]
    );
    await query('UPDATE wallets SET puntos = puntos + 25 WHERE user_id = $1', [req.user.id]);
  }
  const home = await query('SELECT * FROM v_user_home WHERE user_id = $1', [req.user.id]);
  res.json({ kyc_level: level, user: mapUserHome(home.rows[0]) });
});

module.exports = router;
