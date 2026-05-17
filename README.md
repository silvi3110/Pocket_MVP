# Pocket Card MVP — VIVA/ALVA

Stack: **Flutter** + **PostgreSQL** + **Node/Express**

Colores: verde `#00B140` · morado `#7B2CBF` · blanco

---

## Reglas de negocio (backend)

| Tier | Puntos/Bs | Megas/Bs | Cashback \$VIVA |
|------|-----------|----------|-----------------|
| **viva** | 2 | 0.5 MB | 1% |
| **basic** | 1 | 0 | 0 |

- **KYC 0:** solo wallet
- **KYC 1:** activar tarjeta basic, pagar, canjear
- **KYC 2:** pagar con tier VIVA
- **ALVA → Pocket:** 100 ALVA = 50 pts Pocket
- Todas las operaciones financieras usan **transacciones atómicas** (`BEGIN/COMMIT/ROLLBACK`)

---

## Inicio rápido

```powershell
cd e:\POCKET
docker compose up -d

cd backend
npm install
npm start
```

```powershell
cd pocket_app
flutter create . --project-name pocket_app
flutter pub get
flutter run --dart-define=API_URL=http://10.0.2.2:3000
```

---

## Flujo demo (10 pasos, §7)

| # | Acción | Endpoint |
|---|--------|----------|
| 1 | Registro | `POST /api/auth/register` |
| 2 | Vincular VIVA | `POST /api/me/vincular-viva` |
| 3 | Cargar BOB wallet | `POST /api/wallet/deposit` |
| 4 | Activar tarjeta | `POST /api/card/activate` |
| 5 | Wallet → tarjeta | `POST /api/card/load` |
| 6 | Pagos QR/online | `POST /api/transactions/pay` |
| 7 | Ver home | `GET /api/me/home` |
| 8 | ALVA → Pocket | `POST /api/points/convert-alva` |
| 9 | Canjear Gift Card | `POST /api/points/gift-cards/redeem` |
| 10 | Historial | `GET /api/transactions/history` |

**Usuario seed:** `70000001` / PIN `1234` (KYC 2, tarjeta VIVA lista)

**Reset consumo mensual (demo):** `POST /api/admin/reset-monthly`

---

## Modelo de datos

`users` · `wallets` · `cards` · `viva_link` · `transactions` · `points_log` · `gift_cards_catalog` · `rewards`

Vistas: `v_user_home` · `v_transaction_history`

Schema: `backend/sql/schema.sql`

---

## Fuera del MVP

KYC real, APIs VIVA/ALVA reales, pasarela de pago, QR real, TATA, mascota, Pasanaku, push notifications.
