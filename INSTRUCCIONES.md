# Administración de Locales — Guía de instalación

App web para administrar los 3 locales comerciales del edificio en esquina de
San Lorenzo Oeste y Paula Albarracín de Sarmiento Sur, Rawson (San Juan).
Maneja inquilinos, contratos, pagos de alquiler, gastos/servicios y estado de
ocupación, en pesos (ARS) y dólares (USD).

Archivos incluidos:

- **`index.html`** — la aplicación (se sube a Vercel).
- **`schema.sql`** — crea las tablas en Supabase (solo si empezás de cero).
- **`actualizar-bd.sql`** — si **ya** tenías la base creada antes, corré este
  archivo para agregar las tablas y columnas nuevas.
- **`2-ajustes-illanes.sql`** — carga los 2 ajustes de canon ya vencidos del
  contrato de Illanes, con los valores oficiales del ICL.
- **`INSTRUCCIONES.md`** — este documento.

> **Si tu base ya está creada, hacé esto en orden:**
> 1. Supabase → SQL Editor → New query → pegar **`actualizar-bd.sql`** → Run
> 2. New query → pegar **`2-ajustes-illanes.sql`** → Run
> 3. Volver a subir el `index.html` a Vercel y recargar con Ctrl+Shift+R
>
> **Error "Could not find the table 'public.ajustes_contrato' in the schema cache":**
> significa que falta el paso 1, o que Supabase todavía no refrescó su caché.
> El archivo ya incluye la orden `notify pgrst, 'reload schema'` que lo soluciona.
> Si persiste, esperá un minuto o entrá a Settings → API → *Reload schema*.

Si empezás de cero, son unos 15 minutos. Seguí los pasos en orden.

---

## Paso 1 — Crear el proyecto en Supabase (base de datos)

1. Entrá a **https://supabase.com** y creá una cuenta (podés usar tu cuenta de Google).
2. Clic en **New project**. Elegí un nombre (ej: *locales-godoy*), poné una
   contraseña para la base de datos (guardala) y una región (ej: *South America*).
3. Esperá 1–2 minutos a que el proyecto quede listo.

## Paso 2 — Crear las tablas

1. En el menú izquierdo, entrá a **SQL Editor** → **New query**.
2. Abrí el archivo **`schema.sql`**, copiá **todo** el contenido y pegalo.
3. Presioná **Run** (o Ctrl+Enter). Debería decir *Success*.
   Esto crea las tablas y ya deja cargados los 3 locales.

## Paso 3 — Copiar tus claves de Supabase

1. Menú izquierdo → **Project Settings** (ícono de engranaje) → **API**.
2. Anotá dos datos:
   - **Project URL** (algo como `https://abcdefgh.supabase.co`)
   - **anon public** key (una clave larga bajo "Project API keys").

## Paso 4 — Pegar las claves en la app

1. Abrí **`index.html`** con el Bloc de notas (clic derecho → Abrir con → Bloc de notas).
2. Cerca del comienzo vas a ver estas dos líneas:

   ```
   const SUPABASE_URL = "PEGAR_AQUI_TU_URL";
   const SUPABASE_ANON_KEY = "PEGAR_AQUI_TU_ANON_KEY";
   ```

3. Reemplazá los textos entre comillas por tu **Project URL** y tu **anon key**.
   Deben quedar así (con tus datos):

   ```
   const SUPABASE_URL = "https://abcdefgh.supabase.co";
   const SUPABASE_ANON_KEY = "eyJhbGciOi...tu_clave...";
   ```

4. Guardá el archivo.

## Paso 5 — Crear tu usuario para entrar a la app

La app pide email y contraseña para proteger los datos.

1. En Supabase, menú izquierdo → **Authentication** → **Users** → **Add user** →
   **Create new user**.
2. Poné tu email y una contraseña. **Importante:** activá / dejá marcada la
   opción *Auto Confirm User* (para no tener que confirmar por correo).
3. Ese email y contraseña son los que vas a usar para entrar.

## Paso 6 — Subir la app a Vercel

1. Entrá a **https://vercel.com** y creá una cuenta.
2. La forma más simple: en el panel de Vercel, arrastrá el archivo **`index.html`**
   a la zona de "deploy", o usá **Add New → Project → Deploy** y subí el archivo.
   - Alternativa: instalá la app de Vercel y, desde tu carpeta, ejecutá `vercel`.
3. Al terminar te da una dirección tipo `https://locales-godoy.vercel.app`.
   Abrila, ingresá con tu email y contraseña, y listo.

> Si preferís no usar Vercel, también podés abrir `index.html` directamente
> haciendo doble clic: funciona igual mientras completes las claves del Paso 4.

---

## Cómo se usa

- **Resumen:** panel con ocupación, ingreso mensual esperado, pagos pendientes y gastos del mes.
- **Locales:** los 3 locales y su estado (ocupado / libre / en refacción).
- **Inquilinos:** datos de cada locatario.
- **Contratos:** alquiler, moneda, plazos, día de vencimiento, ajustes y garantía.
  Al guardar un contrato *activo*, el local pasa automáticamente a "ocupado".
- **Pagos:** registrás cada cobro por mes y su estado (pagado / pendiente / parcial).
- **Gastos:** luz, agua, impuestos, expensas y mantenimiento, por local o generales del edificio.
- **Servicios:** números de cuenta de impuestos, agua y energía, con titular,
  local asociado y aviso de medidores retirados con deuda. El botón ⧉ copia
  el número de cuenta al portapapeles.

### Proyección de incrementos

En **Contratos** → botón **Proyección** calculás los aumentos futuros según el índice:

| Índice | Cómo se calcula | Datos |
|---|---|---|
| **ICL** (BCRA) | 50% inflación (IPC) + 50% salarios (RIPTE). Ajuste = ICL del día de ajuste ÷ ICL del ajuste anterior | Serie oficial diaria del BCRA (automático) |
| **IPC** (INDEC) | Producto de (1 + inflación mensual) de cada mes del período | Inflación mensual oficial (automático) |
| **Casa Propia** | El menor entre el promedio 12 meses de variación salarial (CVS, aforo 90%) y el promedio 12 meses de inflación | Sin API pública: se estima con % mensual. Coeficientes oficiales en argentina.gob.ar |
| **% fijo** | Nuevo alquiler = vigente × (1 + %/100) | Manual |

Los tramos ya transcurridos usan datos oficiales; los futuros son estimaciones.
Verificá siempre el índice del día del ajuste en la fuente oficial.

## Contrato cargado: Jaquelina Elsa Illanes (Local 3)

Datos tomados del contrato firmado el 16/10/2025:

| Dato | Valor |
|---|---|
| Locataria | Jaquelina Elsa Illanes · DNI 25.550.495 · tel 2644163856 |
| Local | Local 3 (San Lorenzo Oeste) · destino depósito |
| Vigencia | 01/10/2025 al 30/09/2027 (2 años) · tenencia desde 17/10/2025 |
| Canon inicial | $520.000 el primer cuatrimestre |
| Actualización | **Cuatrimestral por ICL** (BCRA); supletoriamente IPC (cláusula 3ª) |
| Vencimiento | Día 1 de cada mes, sin recargo hasta el día 10 |
| Mora | Automática desde el día 1 (se pierden los días de gracia) |
| Intereses | 0,3% diario punitorio + tasa activa BNA, capitalizables cada 6 meses (cláusula 8ª) |
| Depósito | $520.000 |
| Fiadores | Lucas Adrián Torregrosa (DNI 38.593.140) y Melina Soledad Illanes (DNI 30.152.408) |
| Administra | Habitar Propiedades · Alto del Bono Shopping |
| Servicios | Energía, gas, agua y tasa municipal a cargo de la locataria; **impuesto inmobiliario a cargo del locador**. Debe acreditar el pago dentro de los 30 días |

### Ajustes del canon (importante)

El alquiler se actualiza **en cascada**: cada ajuste se calcula sobre el monto que
quedó en el ajuste anterior, no sobre el canon original.

Para el contrato de Illanes (inicio 01/10/2025, cada 4 meses), con los valores
oficiales del ICL del BCRA consultados el 03/08/2026:

| Fecha | ICL | Cálculo | Canon |
|---|---|---|---|
| 01/10/2025 | 27,75 | canon inicial | **$520.000** |
| 01/02/2026 | 30,03 | 520.000 × (30,03 / 27,75) = +8,22% | **$562.724** |
| 01/06/2026 | 33,27 | 562.724 × (33,27 / 30,03) = +10,79% | **$623.437** |
| 01/10/2026 | — | sobre $623.437 | programado |
| 01/02/2027 · 01/06/2027 | — | y así hasta el fin del contrato | programados |

**Canon vigente hoy: $623.437** (+19,89% acumulado desde el inicio).

El archivo `2-ajustes-illanes.sql` deja estos dos ajustes ya cargados.

Cada ajuste queda **asentado en la base de datos**, así el valor no depende de que
la app logre conectarse al BCRA. En **Contratos** → botón **Ajustes** ves la
cadena completa: los aplicados, los vencidos sin aplicar y los programados a futuro.

Para cargar un ajuste, ponés el valor del ICL al inicio del período y a la fecha
del ajuste; la app calcula el factor y el nuevo canon. También podés escribir el
monto directamente. Si la app logró descargar la serie del BCRA, los valores
vienen precargados.

> **Si el alquiler aparece sin actualizar** verás un aviso rojo en el Resumen y el
> monto en color naranja. Significa que hay ajustes vencidos que todavía no se
> cargaron: entrá a *Ajustes* y aplicalos. El ICL diario se consulta en
> [bcra.gob.ar → Principales variables](https://www.bcra.gob.ar/PublicacionesEstadisticas/Principales_variables.asp).

### Alertas automáticas

El Resumen muestra avisos ordenados por urgencia:

- 🔴 Alquiler sin actualizar (hay ajustes vencidos sin aplicar)
- 🔵 Alquiler próximo a vencer (faltan 5 días o menos)
- 🟠 En período de gracia (entre el día 1 y el 10, aún sin recargo)
- 🔴 En mora (pasado el día 10), con la deuda estimada con intereses
- 🔵 Ajuste de canon dentro de los próximos 30 días
- 🟠 Vencimiento de contrato dentro de los próximos 90 días
- 🔴 Facturas vencidas, marcando las que superan los 30 días para acreditar
- 🟠 Facturas por vencer (7 días o menos)
- 🔵 Servicios del mes que todavía no se consultaron
- 🟠 Medidores retirados con deuda

### Cálculo de intereses por mora

En **Contratos** → botón **Mora**. Muestra por separado:

- **Punitorio:** 0,3% diario simple sobre el capital (art. 769 CCyC)
- **Moratorio:** tasa activa del Banco Nación, proporcional a los días (art. 768 CCyC)
- Capitalización cada 6 meses (art. 770 CCyC)

La tasa del BNA es un campo editable (valor inicial 75% anual): actualizala con la
tasa vigente antes de usar el cálculo en un reclamo. El resultado es orientativo,
consultá a tu abogado antes de una acción formal.

## Facturas de servicios

En **Gastos** hay un panel con las facturas del mes en curso. Cada tarjeta muestra
el servicio, el local y su número de cuenta, con tres estados: *sin consultar*,
*a pagar* (con importe y vencimiento) o *pagada*.

**Cómo cargar una factura:**

1. Tocá **Consultar**. La app copia el número de cuenta al portapapeles y abre
   el sitio del servicio en otra pestaña.
2. Pegá el número (Ctrl+V) en el campo del sitio y consultá.
3. Volvé a la app: el formulario ya está abierto con el servicio y el local
   cargados. Escribí el importe y la fecha de vencimiento, y guardá.

| Servicio | Sitio | Campo a completar |
|---|---|---|
| Naturgy | oficinavirtual.naturgysj.com.ar | SUMINISTRO |
| OSSE | facturaweb.osse.com.ar | Número de cuenta |
| Municipalidad de Rawson | municipioderawson.gob.ar/geoportal | ID contribuyente → *Pagar ahora* |

> **¿Por qué no se consultan solas?** Los tres sitios cargan sus datos por
> JavaScript y requieren completar un formulario. Además, los navegadores impiden
> por seguridad (CORS) que una página alojada en Vercel lea datos de otro dominio.
> Automatizarlo requeriría un servidor intermedio que consulte los sitios, algo
> más frágil (se rompe si cambian el sitio o agregan captcha) y que conviene
> revisar contra los términos de uso de cada organismo.

Una vez cargada la factura, la app se encarga del resto: avisa cuando está por
vencer (7 días o menos), cuando ya venció, y cuando supera los 30 días del plazo
para acreditar el pago que fija la cláusula 5ª del contrato.

## Prorrateo de servicios comunes

En **Locales** cada unidad muestra su medidor de energía activo y **1/3** de las
facturas de OSSE y Municipalidad, que se emiten por el inmueble completo.

Para que aparezcan los importes, cargá cada factura en **Gastos** dejando el campo
Local en *"General (edificio)"*. La app toma la última factura de cada servicio y la
divide entre los 3 locales.

## Cuentas registradas

**Impuestos** — DGR: 042061303000000 · Municipalidad de Rawson: IM206130300000
(ambos a nombre de Miguel Ángel Godoy).

**Agua/cloaca** — OSSE: 119-0066581-000/6 (Miguel Ángel Godoy).

**Energía activa (Naturgy)** — Local 1 esquina: 20004660492 · Local 2 Paula de
Sarmiento: 20004660479 (ambos Miguel Ángel Godoy) · Local 3 San Lorenzo:
20003841440 (Mercedes Alicia Iramain).

**Energía retirada con deuda (Energía San Juan)** — Local 1: 20004513374
(Abel Arroyo, ex inquilino) y 20003020493 (Mercedes Alicia Iramain) ·
Local 2: 20000897544 (Rafael Godoy).

## Notas de seguridad

- Los datos quedan en **tu** proyecto de Supabase, protegidos por login.
- La `anon key` es pública por diseño; la seguridad está en que las tablas solo
  permiten acceso a usuarios autenticados (ya configurado en `schema.sql`).
- Podés crear más usuarios (por ejemplo para un contador) repitiendo el Paso 5.

## Datos del inmueble (según planos)

- Propietario: **Godoy, Miguel Ángel**.
- Ubicación: esquina **San Lorenzo Oeste** y **Paula Albarracín de Sarmiento Sur**, Rawson, San Juan.
- Nomenclatura catastral: 09-20-613030 · Plano N° 04-18067.
- Superficie s/mensura: 194,30 m².
