# Pocket Card MVP — COCHATECH 2026

Billetera digital de VIVA/ALVA con tarjeta virtual prepagada. El MVP demuestra el loop completo: cash-in QR en Bs → saldo $VIVA → pagos con Pocket Card → puntos → Gift Cards.

**Stack:** Flutter · Node.js/Express · PostgreSQL 16 (Docker)

**Colores VIVA:** lime `#C8FF2A` · purple `#5C2FA0`

---

## Inicio rápido

### 1. Base de datos

```powershell
cd Pocket_MVP
docker compose up -d
```

> El schema se carga automáticamente desde `backend/sql/schema.sql` al crear el volumen por primera vez.
> Puerto: **5441** (5432 puede estar ocupado por otros proyectos).

### 2. Backend

```powershell
cd backend
npm install
npm start
# → http://localhost:3000
```

### 3. App Flutter

```powershell
cd pocket_app
flutter pub get
flutter run -d chrome
# o en dispositivo:
flutter run --dart-define=API_URL=http://<IP-LOCAL>:3000
```

**Credenciales demo:** teléfono `70000001` · PIN `1234`
(KYC nivel 2, 250 $VIVA, 50 USDT, 1200 puntos, EARN activo, tarjeta VIVA lista)

---

## Arquitectura de pantallas

```
HomeScreen (BottomNavigationBar)
├── Inicio          — balance $VIVA/USDT, depositar, EARN countdown, accesos rápidos
├── Tarjeta         — sub-tabs: Wallet · Swap · EARN · Tarjeta
│   ├── Wallet      — saldos + QR propio para recibir depósitos en Bs
│   ├── Swap        — $VIVA ↔ USDT (2% fee)
│   ├── EARN        — activar/cobrar rendimiento 20% APY
│   └── Tarjeta     — activar, cargar $VIVA, pagar con QR
├── Beneficios      — puntos Pocket, catálogo Gift Cards, historial
└── TATA            — asistente IA financiero
```

---

## Modelo de negocio

| Concepto | Valor |
|---|---|
| Tasa cash-in | 1 Bs = 0.14 $VIVA |
| Tasa swap | 1 $VIVA = 0.01 USDT |
| Fee swap | 2% |
| EARN APY | 20% anual, capitalizable cada 48h |
| Mínimo EARN | 200 $VIVA |
| Tier Basic | 1 pt/$VIVA · límite Bs 1,000/mes |
| Tier VIVA | 2 pts/$VIVA · 0.5 MB/$VIVA · 1% cashback · límite Bs 5,000/mes |

### Reglas KYC

| Nivel | Requisito | Acceso |
|---|---|---|
| 0 | Solo registro | Wallet, recibir $VIVA |
| 1 | Vincular línea VIVA | Activar tarjeta, pagar, canjear |
| 2 | KYC completo (CI + foto) | Tier VIVA, EARN, swap |

---

## Endpoints API

### Auth
| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/api/auth/register` | Registro (prefill VIVA opcional) |
| `POST` | `/api/auth/login` | Login con teléfono + PIN |
| `GET` | `/api/auth/viva-prefill/:phone` | Pre-cargar datos desde línea VIVA |
| `POST` | `/api/auth/upgrade-kyc` | Subir nivel KYC |

### Wallet y perfil
| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/me/home` | Datos completos del usuario |
| `GET` | `/api/wallet/rates` | Tasas de cambio informativas |
| `POST` | `/api/wallet/deposit` | Cash-in QR: Bs → $VIVA |
| `POST` | `/api/me/vincular-viva` | Vincular línea VIVA (sube a KYC 1) |

### Tarjeta
| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/api/card/activate` | Activar Pocket Card virtual |
| `POST` | `/api/card/load` | Wallet $VIVA → saldo tarjeta |
| `POST` | `/api/transactions/pay` | Pago QR u online con tarjeta |
| `GET` | `/api/transactions/history` | Historial de movimientos |

### EARN
| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/earn/status` | Estado EARN y rendimientos estimados |
| `POST` | `/api/earn/activate` | Activar EARN (req. KYC≥1 y ≥200 $VIVA) |
| `POST` | `/api/earn/acreditar` | Cobrar rendimiento (simula ciclo 48h) |

### Swap
| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/swap/preview` | Vista previa de tasas y saldos |
| `POST` | `/api/swap/viva-usdt` | Swap $VIVA → USDT (2% fee) |
| `POST` | `/api/swap/usdt-viva` | Swap USDT → $VIVA (2% fee) |

### Puntos y beneficios
| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/points/gift-cards/catalog` | Catálogo de Gift Cards |
| `POST` | `/api/points/gift-cards/redeem` | Canjear Gift Card |
| `GET` | `/api/points/log` | Historial de puntos |
| `POST` | `/api/points/convert-alva` | Convertir puntos ALVA OMG → Pocket |
| `GET` | `/api/viva/line` | Info línea VIVA vinculada |

### Demo y admin
| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/api/admin/reset-monthly` | Reset consumo mensual (demo) |

---

## Flujo demo (≤30s por paso)

| # | Pantalla | Acción |
|---|---|---|
| 1 | Login | `70000001` / `1234` — perfil pre-cargado |
| 2 | Inicio | Ver balance $VIVA, toggle USDT, countdown EARN |
| 3 | Depositar | Cash-in QR: ingresar Bs → recibir $VIVA al instante |
| 4 | Tarjeta → Wallet | QR propio para recibir depósitos |
| 5 | Tarjeta → Swap | Swap $VIVA → USDT con preview de fee |
| 6 | Tarjeta → EARN | Mostrar 20% APY, cobrar rendimiento (simular 48h) |
| 7 | Tarjeta → Tarjeta | Cargar $VIVA a la card, pagar con QR |
| 8 | Beneficios | Ver puntos, canjear Gift Card |
| 9 | Mi VIVA | Vincular línea, ver megas |
| 10 | TATA | Consultar al asistente IA |

---

## Modelo de datos

**Tablas:** `users` · `wallets` · `cards` · `viva_link` · `transactions` · `points_log` · `gift_cards_catalog` · `rewards`

**Vistas:** `v_user_home` · `v_transaction_history`

**Tipos de transacción:** `cashin_qr` · `card_payment_qr` · `card_payment_online` · `card_load` · `swap_viva_usdt` · `swap_usdt_viva` · `earn_rendimiento` · `conversion_puntos`

**Schema:** `backend/sql/schema.sql`

**Monedas:** `saldo_viva NUMERIC(18,8)` · `saldo_usdt NUMERIC(18,8)` · `saldo_bob NUMERIC(12,2)` (solo cash-in en tránsito)

---

## Fuera del MVP

KYC real con reconocimiento facial · APIs blockchain Solana · pasarela de pago real QR interbancario · push notifications · Pasanaku grupal · monitoreo de precio $VIVA en tiempo real.
