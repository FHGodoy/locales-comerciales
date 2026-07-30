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

-- ---------- DATOS INICIALES: los 3 locales ----------
insert into public.locales (nombre, superficie_m2, estado, descripcion)
select * from (values
  ('Local 1', null::numeric, 'libre', 'Local sobre esquina / San Lorenzo Oeste'),
  ('Local 2', null::numeric, 'libre', 'Local central'),
  ('Local 3', null::numeric, 'libre', 'Local sobre Paula Albarracín de Sarmiento Sur')
) as t(nombre, superficie_m2, estado, descripcion)
where not exists (select 1 from public.locales);

-- =====================================================================
--  SEGURIDAD (RLS): los datos solo son accesibles para usuarios logueados
-- =====================================================================
alter table public.locales    enable row level security;
alter table public.inquilinos enable row level security;
alter table public.contratos  enable row level security;
alter table public.pagos      enable row level security;
alter table public.gastos     enable row level security;

-- Permite todo (leer/crear/editar/borrar) SOLO a usuarios autenticados.
do $$
declare t text;
begin
  foreach t in array array['locales','inquilinos','contratos','pagos','gastos']
  loop
    execute format(
      'drop policy if exists "acceso_autenticado" on public.%I;', t);
    execute format(
      'create policy "acceso_autenticado" on public.%I
         for all to authenticated using (true) with check (true);', t);
  end loop;
end $$;
