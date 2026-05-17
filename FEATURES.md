# Pocket Card MVP — Features y modificaciones sobre el estado base

Este documento describe cada funcionalidad nueva o modificada respecto al estado original de Pocket, explicando qué hace, cómo fluye y por qué existe.

---

## Contexto: qué es el "estado base" de Pocket

La app real de Pocket (antes de este MVP) es una billetera de criptoactivos dentro de la Super App VIVA/ALVA. Sus funciones originales son:

- Guardar y visualizar saldo en **$VIVA** y **USDT**
- **Cash-in** con QR interbancario: el usuario paga bolivianos desde su banco y recibe $VIVA
- **Swap** $VIVA ↔ USDT con comisión del 2%
- **EARN**: rendimiento del 20% APY sobre saldo $VIVA, capitalizable cada 48h
- **Gift Cards**: canjear puntos acumulados en la Super App por tarjetas de valor
- **Historial** de transacciones
- **Programa de referidos**

Lo que Pocket **no tenía** es una tarjeta de pago que conecte ese saldo con el mundo real.

---

## Feature 1 — Pocket Card (tarjeta virtual prepagada)

### Qué es
Una tarjeta virtual prepagada vinculada al saldo $VIVA del usuario, que le permite pagar en comercios con QR o en tiendas online, igual que una tarjeta de débito pero operando sobre $VIVA.

### Flujo
1. El usuario tiene KYC Nivel 1 (requisito mínimo)
2. Entra a la sección **Tarjeta** y toca **"Activar tarjeta"**
3. El backend evalúa si tiene línea VIVA vinculada:
   - **Sí tiene línea VIVA** → tier `viva`, límite 5.000 $VIVA/mes
   - **No tiene línea** → tier `basic`, límite 2.000 $VIVA/mes
4. Se genera un número virtual (`4000XXXXXXXXXXXX`) y la tarjeta queda activa
5. El usuario transfiere $VIVA desde su wallet a la tarjeta
6. Usa la tarjeta para pagar (QR simulado o formulario online en el MVP)

### Por qué
Pocket tenía saldo en $VIVA pero sin forma de gastarlo en el mundo real. La tarjeta es el puente entre el cripto y la vida cotidiana. Es el diferencial central de la propuesta: convierte a Pocket de "billetera para entendidos de cripto" a "tarjeta de uso diario del boliviano".

### Datos técnicos
- **Backend**: `POST /api/card/activate` → `services/operations.js → activateCard()`
- **Tabla**: `cards` (numero_virtual, tier, saldo_disponible, limite_mensual, consumo_mes)
- **Reset mensual**: `consumo_mes` se resetea a 0 el día 1 de cada mes (`POST /api/admin/reset-monthly`)

---

## Feature 2 — Dos tiers de tarjeta: Basic y VIVA

### Qué es
La tarjeta existe en dos niveles con beneficios distintos dependiendo de si el usuario es cliente de VIVA con línea activa.

| Característica | Tier Basic | Tier VIVA |
|---|---|---|
| Requisito | KYC Nivel 1 | KYC Nivel 1 + línea VIVA vinculada |
| Límite mensual | 2.000 $VIVA | 5.000 $VIVA |
| Puntos por pago | 1 pt/$VIVA | 2 pts/$VIVA |
| Megas por pago | 0 | 0.5 MB/$VIVA gastado |
| Cashback $VIVA | 0 | 1% del monto |

### Flujo
El tier se asigna automáticamente al activar la tarjeta. No es una decisión del usuario — el sistema detecta si tiene `viva_link` registrado y asigna el tier correspondiente.

### Por qué
El tier es el mecanismo de incentivo para que los usuarios de VIVA vinculen su línea. Un cliente que vincula su línea obtiene el doble de puntos, megas reales en su celular y cashback. Esto crea un ciclo: más uso de la tarjeta → más beneficios → más razones para seguir en el ecosistema VIVA. El tier Basic existe para no excluir a usuarios sin línea VIVA, ampliando el mercado.

---

## Feature 3 — Sistema de beneficios por transacción

### Qué es
Cada pago con Pocket Card genera automáticamente tres tipos de beneficios calculados en el momento del pago y guardados permanentemente en la transacción.

### Cálculo (tier VIVA)
```
Puntos Pocket  = monto × 2       (2 puntos por cada $VIVA gastado)
Megas VIVA     = monto × 0.5     (0.5 MB por cada $VIVA gastado)
Cashback $VIVA = monto × 0.01    (1% del monto devuelto en $VIVA)
```

### Cálculo (tier Basic)
```
Puntos Pocket  = monto × 1       (1 punto por cada $VIVA gastado)
Megas VIVA     = 0
Cashback $VIVA = 0
```

### Flujo
1. Usuario confirma pago → `POST /api/transactions/pay`
2. Backend valida saldo, límite mensual y KYC
3. Calcula beneficios según tier de la tarjeta
4. En una **transacción atómica** (BEGIN/COMMIT):
   - Descuenta saldo de tarjeta
   - Suma puntos y cashback $VIVA al wallet
   - Suma megas a la línea VIVA (solo tier VIVA)
   - Registra en `transactions` y `points_log`
5. Frontend muestra el resumen: `+N puntos · +X MB · +$VIVA Y`

### Por qué
Los valores se calculan **al momento del pago y se guardan**. No se recalculan después. Esto es crítico: si las reglas de negocio cambian en el futuro, las transacciones históricas mantienen sus beneficios originales. La atomicidad garantiza que nunca haya un pago donde se descuente el saldo pero no se acrediten los puntos (o viceversa).

### Datos técnicos
- **Backend**: `services/benefits.js → calcBenefits(monto, tier)`
- **Tabla**: `transactions` (puntos_generados, megas_generadas, cashback_viva)
- **Log**: cada movimiento de puntos se registra en `points_log` con su origen

---

## Feature 4 — Cash-in QR con conversión BOB → $VIVA

### Qué es
El mecanismo por el cual el usuario ingresa bolivianos a Pocket. El usuario paga con el QR interbancario de su banco (Tigo Money, banco real, etc.) y recibe $VIVA en su wallet.

### Flujo
1. Usuario toca **"Cash-in QR"** en el wallet panel
2. Ingresa el monto en bolivianos (máx. Bs 5.000 por transacción)
3. El sistema muestra la tasa de conversión y el $VIVA que recibirá
4. Confirma → `POST /api/wallet/deposit`
5. Backend convierte: `$VIVA = BOB × 0.14` (tasa fija en el demo)
6. Se acredita $VIVA en `wallets.saldo_viva`
7. Se registra como transacción tipo `cashin_qr`

### Por qué
Esta es la realidad de Pocket: **no guarda bolivianos**. El campo `saldo_bob` en la base de datos es solo un fondo en tránsito (normalmente cero). El saldo operativo real es `saldo_viva`. El flujo anterior del MVP trataba `saldo_bob` como el saldo principal, lo cual era incorrecto respecto a cómo funciona la app real. La corrección alinea el MVP con la realidad del producto.

### Nota demo
La tasa `1 BOB = 0.14 $VIVA` es fija para el hackathon. En producción vendría de un oráculo de precios en tiempo real.

---

## Feature 5 — Swap $VIVA ↔ USDT

### Qué es
Conversión directa entre los dos activos de Pocket con una comisión del 2%.

### Flujo
1. Usuario abre el swap desde el Wallet Panel
2. Selecciona dirección: `$VIVA → USDT` o `USDT → $VIVA`
3. Ingresa el monto — el sistema muestra en tiempo real cuánto recibirá descontada la comisión
4. Confirma → `POST /api/swap/viva-usdt` o `POST /api/swap/usdt-viva`
5. Backend ejecuta en una transacción atómica:
   - Descuenta el saldo de origen
   - Acredita el saldo destino menos la comisión (2%)
   - Registra en `transactions`

### Cálculo
```
$VIVA → USDT:  USDT_recibido = ($VIVA × 0.01) × 0.98
USDT → $VIVA:  $VIVA_recibido = (USDT / 0.01) × 0.98
```

### Por qué
El swap es una funcionalidad existente de Pocket (2% de comisión según la cartilla informativa). Se integró al MVP para que el flujo de demostración sea completo: usuario puede entrar con BOB, convertir a USDT para proteger valor, o volver a $VIVA para activar EARN. Es parte del loop financiero real del producto.

---

## Feature 6 — EARN: rendimiento 20% APY sobre $VIVA

### Qué es
Programa de rendimientos pasivos sobre el saldo en $VIVA. El saldo inactivo genera un 20% de interés anual, capitalizable cada 48 horas.

### Flujo
1. Usuario tiene KYC aprobado y mínimo 200 $VIVA en wallet
2. Entra a **"EARN — Rendimientos"** desde el Wallet Panel
3. Ve su rendimiento estimado anual y por cada 48h
4. Toca **"Activar EARN"** → `POST /api/earn/activate`
5. El badge `EARN 20%` aparece en el tile de $VIVA del home
6. Cada 48 horas, el sistema acredita el rendimiento → `POST /api/earn/acreditar`
   - En el demo esto es un botón manual para simular el ciclo

### Cálculo del rendimiento
```
Rendimiento_48h = saldo_viva × (0.20 / 365 / 24) × 48h
```

### Por qué
EARN existe en la app real de Pocket (20% APY según la cartilla). Se incluyó en el MVP porque es uno de los argumentos más fuertes para retener saldo en la plataforma: el usuario tiene un incentivo concreto para no retirar su $VIVA. Para la demo muestra que Pocket no es solo un medio de pago sino también una herramienta de ahorro.

---

## Feature 7 — KYC progresivo por niveles (0 → 1 → 2)

### Qué es
Sistema de verificación de identidad por niveles que desbloquea funcionalidades progresivamente.

| Nivel | Cómo se alcanza | Qué desbloquea |
|---|---|---|
| 0 | Registro inicial | Ver wallet, recibir $VIVA |
| 1 | Vincular línea VIVA (datos pre-cargados) | Activar tarjeta Basic, pagar, canjear Gift Cards |
| 2 | KYC completo (simulado en demo) | Tarjeta tier VIVA, límites altos |

### Flujo de subida de KYC 0 → 1
1. Usuario nuevo tiene KYC 0 automáticamente
2. Va a **"Mi VIVA"** y toca **"Vincular línea VIVA"**
3. El sistema registra la línea en `viva_link`
4. Si era KYC 0 → sube automáticamente a KYC 1
5. Recibe **bono de 50 puntos** Pocket (registrado en `points_log` con origen `bono_vinculacion`)
6. El badge del home cambia de "KYC 0" a "KYC 1"

### Por qué
El KYC es el muro que causa el **90% de abandono** en Pocket real (dato de la cartilla informativa). El KYC progresivo elimina esa fricción: el usuario puede empezar a usar la app con mínima verificación y subir de nivel cuando necesite más funcionalidades. La vinculación de línea VIVA como equivalente a KYC 1 es el atajo clave — VIVA ya verificó al cliente cuando activó su chip.

---

## Feature 8 — Registro unificado con prefill desde Viva App

### Qué es
Al registrarse, el usuario ingresa su número de teléfono VIVA y el sistema pre-carga automáticamente su nombre y CI desde los datos de VIVA. El registro toma un toque en lugar de llenar un formulario completo.

### Flujo
1. Usuario ingresa su número en la pantalla de registro
2. Toca el ícono de búsqueda → `GET /api/auth/viva-prefill/:phone`
3. Si el número existe en VIVA: nombre y CI se autocompletan, aparece badge "Cliente VIVA detectado"
4. Si tiene línea activa: el botón dice **"Confirmar con 1 toque"** y el registro automáticamente vincula la línea (KYC 1 desde el inicio)
5. Si no está en VIVA: formulario manual normal

### Números disponibles en el demo
| Teléfono | Nombre | Línea activa |
|---|---|---|
| 70000001 | Demo Pocket | Sí (KYC 1 automático) |
| 70012345 | María López | Sí |
| 70098765 | Carlos Mendoza | Sí |
| 70111222 | Ana Quispe | No |

### Por qué
Es la solución directa al problema de abandono en onboarding. En la app real el usuario tiene que completar CI + foto + reconocimiento facial desde cero, aunque VIVA ya lo verificó. El prefill elimina el trabajo duplicado y convierte el registro en algo de segundos.

---

## Feature 9 — Conversión ALVA OMG → Puntos Pocket

### Qué es
Los puntos ALVA OMG que el usuario acumula en Viva App (navegando, viendo contenido, manteniendo rachas) pueden convertirse en Puntos Pocket para canjear Gift Cards.

### Flujo
1. Usuario tiene puntos ALVA OMG en su línea VIVA vinculada
2. Va a **"Mi VIVA"** o al botón **"ALVA → Pocket"**
3. Convierte en bloques de 100 ALVA → `POST /api/points/convert-alva`
4. Backend ejecuta atómicamente:
   - Descuenta `puntos_alva_omg` en `viva_link`
   - Suma `puntos` en `wallets`
   - Registra en `points_log` con origen `conversion_alva`

### Ratio
```
100 pts ALVA OMG = 50 pts Pocket  (ratio 0.5)
```

### Por qué
Este puente ya existe conceptualmente en el ecosistema VIVA pero la Pocket Card le da un nuevo motor: ahora el usuario acumula ALVA OMG no solo navegando en ALVA sino también pagando en el mundo real con su tarjeta. Más puntos en circulación → más canjes → más rotación del marketplace VIVA → ingresos directos para VIVA.

---

## Feature 10 — Modelo de datos corregido: $VIVA como moneda operativa

### Qué cambió
El MVP original (antes de las correcciones) trataba `saldo_bob` como el saldo principal de Pocket. Esto era incorrecto. La corrección alinea el modelo con la realidad:

| Campo | Antes | Ahora |
|---|---|---|
| `saldo_bob` | Saldo principal de pago | Fondo de cash-in en tránsito (normalmente 0) |
| `saldo_viva` | Saldo secundario | **Saldo principal operativo** |
| `saldo_usdt` | No existía | Saldo en USDT |
| `earn_activo` | No existía | Estado del programa EARN |
| `earn_desde` | No existía | Fecha de activación para calcular rendimientos |

### Por qué
Pocket opera en blockchain Solana con $VIVA y USDT. No guarda bolivianos. El cash-in convierte BOB a $VIVA al momento del depósito. La tarjeta Pocket Card descuenta $VIVA (no BOB). Las transacciones se registran en $VIVA. Tener `saldo_bob` como saldo principal confundía el modelo y haría que la demo no reflejara el producto real.

---

## Modificación: pantalla de tarjeta carga desde $VIVA (no BOB)

### Qué cambió
El botón **"Wallet → Tarjeta"** antes descontaba `saldo_bob`. Ahora descuenta `saldo_viva`.

### Por qué
La tarjeta opera en $VIVA. Cuando el usuario "carga" la tarjeta, está moviendo $VIVA de su wallet a su tarjeta. El saldo disponible de la tarjeta está en $VIVA. Los pagos con la tarjeta descontaban $VIVA pero la recarga venía de BOB — era inconsistente.

---

## Modificación: historial de transacciones enriquecido

### Qué cambió
Cada transacción en el historial ahora muestra:
- Tipo de operación (pago QR, pago online, cash-in, swap, earn, carga a tarjeta)
- Monto y moneda correcta ($VIVA, USDT o BOB según el caso)
- Puntos generados, megas ganadas y cashback $VIVA (cuando aplica)

### Por qué
El historial es la prueba tangible del valor que genera cada transacción. En la demo, el usuario puede ver exactamente qué ganó con cada compra. Es el elemento que cierra el loop de valor de la propuesta.

---

## Resumen del loop completo (flujo de demo)

```
1. Registro con número VIVA → KYC 1 automático
2. Cash-in QR: paga Bs 500 → recibe 70 $VIVA
3. Activa Pocket Card → tier VIVA (por tener línea)
4. Transfiere 50 $VIVA de wallet a tarjeta
5. Paga Bs 30 con QR en comercio → gana 60 pts + 15 MB + 0.30 $VIVA cashback
6. Paga Bs 20 online → gana 40 pts + 10 MB + 0.20 $VIVA
7. Ve en el home: puntos subieron, megas subieron, cashback acumulado
8. Convierte 100 ALVA OMG → 50 puntos Pocket
9. Canjea Gift Card Bs 25 (500 pts) → recibe código GC-XXXX-XXXX
10. Activa EARN sobre sus $VIVA restantes → 20% APY pasivo
```

Cada paso toma menos de 30 segundos. El jurado ve el ecosistema completo funcionando en una sola sesión de demo.
