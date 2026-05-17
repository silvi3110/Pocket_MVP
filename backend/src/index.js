require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/auth');
const meRoutes = require('./routes/me');
const walletRoutes = require('./routes/wallet');
const cardRoutes = require('./routes/card');
const transactionsRoutes = require('./routes/transactions');
const pointsRoutes = require('./routes/points');
const vivaRoutes = require('./routes/viva');
const adminRoutes = require('./routes/admin');
const tataRoutes = require('./routes/tata');
const insightsRoutes = require('./routes/insights');
const mascotaRoutes = require('./routes/mascota');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (_, res) =>
  res.json({ status: 'ok', app: 'Pocket Card API', version: 'mvp-2' })
);

const webDemoPath = path.join(__dirname, '..', '..', 'web-demo');
app.use('/app', express.static(webDemoPath));
app.get('/app', (_, res) => res.sendFile(path.join(webDemoPath, 'index.html')));
app.get('/', (_, res) => res.redirect('/app'));

// Pagina con URL para celular (evita about:blank)
app.get('/celular', (req, res) => {
  const host = req.headers.host || 'localhost:3000';
  res.send(`<!DOCTYPE html><html><head><meta charset=utf-8>
<meta name=viewport content="width=device-width,initial-scale=1">
<meta http-equiv=refresh content="0;url=http://${host}/app">
<title>Pocket</title></head><body style="font-family:sans-serif;text-align:center;padding:40px;background:#5C2FA0;color:white">
<h1>POCKET</h1><p>Redirigiendo...</p>
<p><a href="http://${host}/app" style="color:#C8FF2A;font-size:18px">Toca aqui si no carga</a></p>
</body></html>`);
});

app.use('/api/auth', authRoutes);
app.use('/api/me', meRoutes);
app.use('/api/wallet', walletRoutes);
app.use('/api/card', cardRoutes);
app.use('/api/transactions', transactionsRoutes);
app.use('/api/points', pointsRoutes);
app.use('/api/viva', vivaRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/tata', tataRoutes);
app.use('/api/insights', insightsRoutes);
app.use('/api/mascota', mascotaRoutes);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Pocket Card API → http://localhost:${PORT}`);
  console.log('Red local: usa la IP de tu PC en el puerto', PORT);
  console.log('Endpoints: /api/me/home · /api/wallet/deposit · /api/transactions/pay');
});
