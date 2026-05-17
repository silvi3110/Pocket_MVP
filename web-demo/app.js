// Misma IP y puerto que la pagina (funciona en celular)
const API = window.location.origin;

let token = localStorage.getItem('pocket_token');

function log(msg) {
  const el = document.getElementById('log');
  if (el) el.textContent = `[${new Date().toLocaleTimeString()}] ${msg}\n` + el.textContent;
}

async function api(method, path, body) {
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json' },
  };
  if (token) opts.headers.Authorization = `Bearer ${token}`;
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(API + path, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function switchTab(name) {
  document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === name));
  document.getElementById('tab-wallet').classList.toggle('hidden', name !== 'wallet');
  document.getElementById('tab-tata').classList.toggle('hidden', name !== 'tata');
  document.getElementById('tab-mascota').classList.toggle('hidden', name !== 'mascota');
}

async function loadInsights() {
  try {
    const res = await api('GET', '/api/insights');
    const box = document.getElementById('insights-box');
    if (!res.insights?.length) {
      box.classList.add('hidden');
      return;
    }
    box.classList.remove('hidden');
    box.innerHTML = res.insights
      .slice(0, 3)
      .map((i) => `<div class="insight-item"><strong>${i.titulo}</strong>${(i.mensaje || '').replace(/\*\*/g, '')}</div>`)
      .join('');
  } catch (_) {}
}

async function loadMascota() {
  try {
    const m = await api('GET', '/api/mascota');
    const emojis = { feliz: '🐕', triste: '🥺', extraña: '😢', neutral: '🐶' };
    document.getElementById('mascota-emoji').textContent = emojis[m.humor] || '🐶';
    document.getElementById('mascota-nivel').textContent = `Nivel ${m.nivel} · Energía ${m.energia}%`;
    document.getElementById('mascota-energy-fill').style.width = m.energia + '%';
    document.getElementById('mascota-msg').textContent = m.mensaje;
    document.getElementById('mascota-accesorios').textContent =
      m.accesorios?.length ? 'Accesorios: ' + m.accesorios.join(', ') : 'Completa misiones para desbloquear accesorios';
  } catch (_) {}
}

async function askTata(msg) {
  document.getElementById('tata-msg').value = msg;
  await sendTata();
}

async function sendTata() {
  const msg = document.getElementById('tata-msg').value.trim();
  if (!msg) return;
  document.getElementById('tata-reply').textContent = 'Pensando...';
  try {
    const res = await api('POST', '/api/tata/chat', { message: msg });
    document.getElementById('tata-reply').textContent = (res.reply || '').replace(/\*\*/g, '');
    log('TATA: ' + msg.slice(0, 40));
  } catch (e) {
    document.getElementById('tata-reply').textContent = 'Error: ' + e.message;
  }
}

function showHome(u) {
  document.getElementById('login-section').classList.add('hidden');
  document.getElementById('home-section').classList.remove('hidden');
  document.getElementById('kyc-badge').textContent = `KYC Nivel ${u.kyc_level}`;
  loadInsights();
  loadMascota();
  document.getElementById('pocket-card').innerHTML = `
    <div style="display:flex;justify-content:space-between;align-items:center">
      <strong style="font-size:1.2rem;letter-spacing:2px">POCKET</strong>
      <span style="background:#C8FF2A;color:#2D3A00;padding:4px 10px;border-radius:12px;font-size:11px;font-weight:bold">${(u.tier || 'basic').toUpperCase()}</span>
    </div>
    <div class="num">${u.card_number || 'Sin tarjeta'}</div>
    <div class="bal">Bs ${Number(u.card_balance || 0).toFixed(2)}</div>
  `;
  document.getElementById('bob').textContent = 'Bs ' + Number(u.bob_balance).toFixed(0);
  document.getElementById('viva').textContent = Number(u.viva_balance).toFixed(1);
  document.getElementById('pts').textContent = u.alva_points;
}

async function refresh() {
  const u = await api('GET', '/api/me/home');
  showHome(u);
  return u;
}

async function login() {
  try {
    const phone = document.getElementById('phone').value.trim();
    const pin = document.getElementById('pin').value;
    const res = await api('POST', '/api/auth/login', { phone, pin });
    token = res.token;
    localStorage.setItem('pocket_token', token);
    showHome(res.user);
    log('Bienvenido ' + res.user.full_name);
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

async function deposit() {
  try {
    const res = await api('POST', '/api/wallet/deposit', { monto: 100 });
    showHome(res.user);
    log('Wallet +Bs 100');
  } catch (e) { alert(e.message); }
}

async function loadCard() {
  try {
    const res = await api('POST', '/api/card/load', { monto: 50 });
    showHome(res.user);
    log('Tarjeta +Bs 50');
  } catch (e) { alert(e.message); }
}

async function pay() {
  try {
    const res = await api('POST', '/api/transactions/pay', {
      amount: 20,
      type: 'qr',
      merchant: 'Demo QR',
    });
    showHome(res.user);
    log(`Pago +${res.points_earned} pts`);
    loadInsights();
    loadMascota();
  } catch (e) { alert(e.message); }
}

async function convertAlva() {
  try {
    const res = await api('POST', '/api/points/convert-alva', { cantidad_alva: 100 });
    showHome(res.user);
    log(res.message);
  } catch (e) { alert(e.message); }
}

async function redeem() {
  try {
    const catalog = await api('GET', '/api/points/gift-cards/catalog');
    const res = await api('POST', '/api/points/gift-cards/redeem', {
      gift_card_id: catalog[0].id,
    });
    showHome(res.user);
    log('Gift Card: ' + res.codigo_canje);
  } catch (e) { alert(e.message); }
}

if (token) {
  refresh().then(() => log('Sesion OK')).catch(() => {
    token = null;
    localStorage.removeItem('pocket_token');
  });
}
