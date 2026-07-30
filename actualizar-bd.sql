-- =====================================================================
--  ACTUALIZACIÓN de la base de datos
--  Correr UNA sola vez en Supabase → SQL Editor → New query → Run.
--  (Solo para bases ya creadas. Si creás la base desde cero, usá
--   schema.sql y no hace falta este archivo.)
--
--  Incluye:
--   1) Índices de ajuste en contratos (ICL / IPC / Casa Propia)
--   2) Cuentas y servicios (impuestos, agua, energía) con datos cargados
-- =====================================================================

-- ---------- 1) Índice de ajuste en contratos ----------
alter table public.contratos
  add column if not exists ajuste_indice text default 'ICL';

alter table public.contratos
  drop constraint if exists contratos_ajuste_indice_check;

alter table public.contratos
  add constraint contratos_ajuste_indice_check
  check (ajuste_indice in ('ICL','IPC','CASA_PROPIA','FIJO','NINGUNO'));


-- ---------- 2) Cuentas y servicios ----------
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

alter table public.cuentas_servicio enable row level security;
drop policy if exists "acceso_autenticado" on public.cuentas_servicio;
create policy "acceso_autenticado" on public.cuentas_servicio
  for all to authenticated using (true) with check (true);

-- Identificación de los locales según el edificio
update public.locales set descripcion='Local 1 · Esquina San Lorenzo y Paula Albarracín de Sarmiento'
  where nombre='Local 1';
update public.locales set descripcion='Local 2 · Sobre Paula Albarracín de Sarmiento Sur'
  where nombre='Local 2';
update public.locales set descripcion='Local 3 · Sobre San Lorenzo Oeste'
  where nombre='Local 3';

-- Carga de cuentas (solo si la tabla está vacía)
insert into public.cuentas_servicio
  (tipo, organismo, nro_cuenta, titular, local_id, estado, con_deuda, observaciones)
select v.tipo, v.organismo, v.nro_cuenta, v.titular,
       (select id from public.locales where nombre = v.local limit 1),
       v.estado, v.con_deuda, v.obs
from (values
  -- IMPUESTOS (todo el inmueble)
  ('impuesto','DGR (Dirección General de Rentas)','042061303000000','Miguel Ángel Godoy', null,'activo',false,'Impuesto inmobiliario provincial'),
  ('impuesto','Municipalidad de Rawson','IM206130300000','Miguel Ángel Godoy', null,'activo',false,'Tasa municipal'),
  -- AGUA / CLOACA
  ('agua','OSSE (Obras Sanitarias Sociedad del Estado)','119-0066581-000/6','Miguel Ángel Godoy', null,'activo',false,'Medidor a nombre del propietario'),
  -- ENERGÍA ACTUAL
  ('energia','Naturgy','20004660492','Miguel Ángel Godoy','Local 1','activo',false,'Local 1 (esquina)'),
  ('energia','Naturgy','20004660479','Miguel Ángel Godoy','Local 2','activo',false,'Local 2 (Paula A. de Sarmiento)'),
  ('energia','Naturgy','20003841440','Mercedes Alicia Iramain','Local 3','activo',false,'Local 3 (San Lorenzo). Medidor a nombre de tercero'),
  -- ENERGÍA RETIRADOS CON DEUDA
  ('energia','Energía San Juan','20004513374','Abel Arroyo (ex inquilino)','Local 1','retirado',true,'Medidor retirado con deuda'),
  ('energia','Energía San Juan','20003020493','Mercedes Alicia Iramain','Local 1','retirado',true,'Medidor retirado con deuda'),
  ('energia','Energía San Juan','20000897544','Rafael Godoy','Local 2','retirado',true,'Medidor retirado con deuda')
) as v(tipo, organismo, nro_cuenta, titular, local, estado, con_deuda, obs)
where not exists (select 1 from public.cuentas_servicio);
