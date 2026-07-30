-- =====================================================================
--  ADMINISTRACIÓN DE LOCALES COMERCIALES - Esquema de base de datos
--  Edificio esquina San Lorenzo Oeste y Paula Albarracín de Sarmiento
--  Sur - Rawson, San Juan.  Propietario: Godoy, Miguel Ángel.
--
--  Cómo usarlo:
--  1) Entrá a tu proyecto de Supabase.
--  2) Menú lateral -> "SQL Editor" -> "New query".
--  3) Pegá TODO este archivo y presioná "Run".
-- =====================================================================

-- ---------- LOCALES ----------
create table if not exists public.locales (
  id            bigint generated always as identity primary key,
  nombre        text not null,
  superficie_m2 numeric,
  descripcion   text,
  estado        text not null default 'libre'
                check (estado in ('ocupado','libre','refaccion')),
  created_at    timestamptz default now()
);

-- ---------- INQUILINOS ----------
create table if not exists public.inquilinos (
  id           bigint generated always as identity primary key,
  nombre       text not null,
  dni_cuit     text,
  telefono     text,
  email        text,
  domicilio    text,
  notas        text,
  created_at   timestamptz default now()
);

-- ---------- CONTRATOS ----------
create table if not exists public.contratos (
  id                bigint generated always as identity primary key,
  local_id          bigint references public.locales(id) on delete set null,
  inquilino_id      bigint references public.inquilinos(id) on delete set null,
  fecha_inicio      date,
  fecha_fin         date,
  monto_alquiler    numeric not null default 0,
  moneda            text not null default 'ARS' check (moneda in ('ARS','USD')),
  dia_vencimiento   int default 10,          -- día del mes en que vence el alquiler
  ajuste_indice     text default 'ICL'
                    check (ajuste_indice in ('ICL','IPC','CASA_PROPIA','FIJO','NINGUNO')),
  ajuste_periodo    text,                    -- frecuencia en meses (ej: '3')
  ajuste_porcentaje numeric,                 -- % por período (solo si ajuste_indice='FIJO')
  deposito_garantia numeric,
  estado            text not null default 'activo'
                    check (estado in ('activo','finalizado','pendiente')),
  notas             text,
  created_at        timestamptz default now()
);

-- ---------- PAGOS DE ALQUILER ----------
create table if not exists public.pagos (
  id            bigint generated always as identity primary key,
  contrato_id   bigint references public.contratos(id) on delete cascade,
  periodo       text not null,               -- ej: '2026-07' (mes que se paga)
  monto         numeric not null default 0,
  moneda        text not null default 'ARS' check (moneda in ('ARS','USD')),
  fecha_pago    date,
  medio         text,                        -- efectivo / transferencia / cheque
  estado        text not null default 'pendiente'
                check (estado in ('pagado','pendiente','parcial')),
  recibo_nro    text,
  notas         text,
  created_at    timestamptz default now()
);

-- ---------- GASTOS Y SERVICIOS ----------
create table if not exists public.gastos (
  id           bigint generated always as identity primary key,
  local_id     bigint references public.locales(id) on delete set null, -- null = gasto general del edificio
  categoria    text not null,                -- luz / agua / gas / impuesto / expensa / mantenimiento / otro
  descripcion  text,
  monto        numeric not null default 0,
  moneda       text not null default 'ARS' check (moneda in ('ARS','USD')),
  fecha        date,
  pagado_por   text,                         -- propietario / inquilino
  estado       text not null default 'pagado'
               check (estado in ('pagado','pendiente')),
  created_at   timestamptz default now()
);

-- ---------- CUENTAS Y SERVICIOS (impuestos, agua, energía) ----------
create table if not exists public.cuentas_servicio (
  id            bigint generated always as identity primary key,
  tipo          text not null,   -- impuesto / agua / energia
  organismo     text not null,   -- DGR, Municipalidad, OSSE, Naturgy, Energía SJ
  nro_cuenta    text not null,
  titular       text,
  local_id      bigint references public.locales(id) on delete set null,
  estado        text not null default 'activo'
                check (estado in ('activo','retirado')),
  con_deuda     boolean not null default false,
  observaciones text,
  created_at    timestamptz default now()
);

-- ---------- DATOS INICIALES: los 3 locales ----------
insert into public.locales (nombre, superficie_m2, estado, descripcion)
select * from (values
  ('Local 1', null::numeric, 'libre', 'Local 1 · Esquina San Lorenzo y Paula Albarracín de Sarmiento'),
  ('Local 2', null::numeric, 'libre', 'Local 2 · Sobre Paula Albarracín de Sarmiento Sur'),
  ('Local 3', null::numeric, 'libre', 'Local 3 · Sobre San Lorenzo Oeste')
) as t(nombre, superficie_m2, estado, descripcion)
where not exists (select 1 from public.locales);

-- ---------- DATOS INICIALES: cuentas de servicios e impuestos ----------
insert into public.cuentas_servicio
  (tipo, organismo, nro_cuenta, titular, local_id, estado, con_deuda, observaciones)
select v.tipo, v.organismo, v.nro_cuenta, v.titular,
       (select id from public.locales where nombre = v.local limit 1),
       v.estado, v.con_deuda, v.obs
from (values
  ('impuesto','DGR (Dirección General de Rentas)','042061303000000','Miguel Ángel Godoy', null,'activo',false,'Impuesto inmobiliario provincial'),
  ('impuesto','Municipalidad de Rawson','IM206130300000','Miguel Ángel Godoy', null,'activo',false,'Tasa municipal'),
  ('agua','OSSE (Obras Sanitarias Sociedad del Estado)','119-0066581-000/6','Miguel Ángel Godoy', null,'activo',false,'Medidor a nombre del propietario'),
  ('energia','Naturgy','20004660492','Miguel Ángel Godoy','Local 1','activo',false,'Local 1 (esquina)'),
  ('energia','Naturgy','20004660479','Miguel Ángel Godoy','Local 2','activo',false,'Local 2 (Paula A. de Sarmiento)'),
  ('energia','Naturgy','20003841440','Mercedes Alicia Iramain','Local 3','activo',false,'Local 3 (San Lorenzo). Medidor a nombre de tercero'),
  ('energia','Energía San Juan','20004513374','Abel Arroyo (ex inquilino)','Local 1','retirado',true,'Medidor retirado con deuda'),
  ('energia','Energía San Juan','20003020493','Mercedes Alicia Iramain','Local 1','retirado',true,'Medidor retirado con deuda'),
  ('energia','Energía San Juan','20000897544','Rafael Godoy','Local 2','retirado',true,'Medidor retirado con deuda')
) as v(tipo, organismo, nro_cuenta, titular, local, estado, con_deuda, obs)
where not exists (select 1 from public.cuentas_servicio);

-- =====================================================================
--  SEGURIDAD (RLS): los datos solo son accesibles para usuarios logueados
-- =====================================================================
alter table public.locales           enable row level security;
alter table public.inquilinos        enable row level security;
alter table public.contratos         enable row level security;
alter table public.pagos             enable row level security;
alter table public.gastos            enable row level security;
alter table public.cuentas_servicio  enable row level security;

-- Permite todo (leer/crear/editar/borrar) SOLO a usuarios autenticados.
do $$
declare t text;
begin
  foreach t in array array['locales','inquilinos','contratos','pagos','gastos','cuentas_servicio']
  loop
    execute format(
      'drop policy if exists "acceso_autenticado" on public.%I;', t);
    execute format(
      'create policy "acceso_autenticado" on public.%I
         for all to authenticated using (true) with check (true);', t);
  end loop;
end $$;
