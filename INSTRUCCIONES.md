# Administración de Locales — Guía de instalación

App web para administrar los 3 locales comerciales del edificio en esquina de
San Lorenzo Oeste y Paula Albarracín de Sarmiento Sur, Rawson (San Juan).
Maneja inquilinos, contratos, pagos de alquiler, gastos/servicios y estado de
ocupación, en pesos (ARS) y dólares (USD).

Tenés dos archivos:

- **`index.html`** — la aplicación (se sube a Vercel).
- **`schema.sql`** — crea las tablas en Supabase (se corre una sola vez).

Son unos 15 minutos. Seguí los pasos en orden.

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
