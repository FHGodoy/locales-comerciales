-- =====================================================================
--  ACTUALIZACIÓN de la base de datos
--  Correr UNA sola vez en Supabase → SQL Editor → New query → Run.
--  Es seguro correrlo más de una vez (no duplica datos).
--
--  Incluye:
--   1) Índices de ajuste en contratos (ICL / IPC / Casa Propia)
--   2) Cuentas y servicios (impuestos, agua, energía)
--   3) Cláusulas de mora y datos del contrato (día de gracia, punitorios,
--      fiadores, administradora, depósito)
--   4) Carga del contrato de Jaquelina Elsa Illanes (Local 3)
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
  organismo     text not null,
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

update public.locales set descripcion='Local 1 · Esquina San Lorenzo y Paula Albarracín de Sarmiento'
  where nombre='Local 1';
update public.locales set descripcion='Local 2 · Sobre Paula Albarracín de Sarmiento Sur'
  where nombre='Local 2';
update public.locales set descripcion='Local 3 · Sobre San Lorenzo Oeste'
  where nombre='Local 3';

insert into public.cuentas_servicio
  (tipo, organismo, nro_cuenta, titular, local_id, estado, con_deuda, observaciones)
select v.tipo, v.organismo, v.nro_cuenta, v.titular,
       (select id from public.locales where nombre = v.local limit 1),
       v.estado, v.con_deuda, v.obs
from (values
  ('impuesto','DGR (Dirección General de Rentas)','042061303000000','Miguel Ángel Godoy', null,'activo',false,'Impuesto inmobiliario provincial · a cargo del LOCADOR (cláusula 5ª)'),
  ('impuesto','Municipalidad de Rawson','IM206130300000','Miguel Ángel Godoy', null,'activo',false,'Tasa municipal · a cargo del LOCATARIO'),
  ('agua','OSSE (Obras Sanitarias Sociedad del Estado)','119-0066581-000/6','Miguel Ángel Godoy', null,'activo',false,'Medidor a nombre del propietario · a cargo del LOCATARIO'),
  ('energia','Naturgy','20004660492','Miguel Ángel Godoy','Local 1','activo',false,'Local 1 (esquina)'),
  ('energia','Naturgy','20004660479','Miguel Ángel Godoy','Local 2','activo',false,'Local 2 (Paula A. de Sarmiento)'),
  ('energia','Naturgy','20003841440','Mercedes Alicia Iramain','Local 3','activo',false,'Local 3 (San Lorenzo). Medidor a nombre de tercero'),
  ('energia','Energía San Juan','20004513374','Abel Arroyo (ex inquilino)','Local 1','retirado',true,'Medidor retirado con deuda'),
  ('energia','Energía San Juan','20003020493','Mercedes Alicia Iramain','Local 1','retirado',true,'Medidor retirado con deuda'),
  ('energia','Energía San Juan','20000897544','Rafael Godoy','Local 2','retirado',true,'Medidor retirado con deuda')
) as v(tipo, organismo, nro_cuenta, titular, local, estado, con_deuda, obs)
where not exists (select 1 from public.cuentas_servicio);


-- ---------- 3) Cláusulas de mora y datos del contrato ----------
alter table public.contratos add column if not exists dia_gracia int default 10;
alter table public.contratos add column if not exists punitorio_diario numeric default 0.3;   -- % por día
alter table public.contratos add column if not exists tasa_bna_anual numeric default 75;      -- % anual (editable)
alter table public.contratos add column if not exists capitaliza_meses int default 6;
alter table public.contratos add column if not exists penal_ocupacion_pct numeric default 20; -- % del canon por día
alter table public.contratos add column if not exists rescision_pct numeric default 10;
alter table public.contratos add column if not exists dias_acreditar_servicios int default 30;
alter table public.contratos add column if not exists fiadores text;
alter table public.contratos add column if not exists administradora text;
alter table public.contratos add column if not exists destino text;
alter table public.contratos add column if not exists fecha_tenencia date;

alter table public.inquilinos add column if not exists dni_cuit text;  -- por si faltara


-- ---------- 4) Contrato de Jaquelina Elsa Illanes (Local 3) ----------
-- Inquilina
insert into public.inquilinos (nombre, dni_cuit, telefono, domicilio, notas)
select 'Jaquelina Elsa Illanes','25.550.495','2644163856',
       'Loteo Virgen de Fátima, Lote 33, Pocito, San Juan',
       'Contrato de locación comercial firmado el 16/10/2025. Administra: Habitar Propiedades.'
where not exists (select 1 from public.inquilinos where dni_cuit='25.550.495');

-- Contrato
insert into public.contratos (
  local_id, inquilino_id, fecha_inicio, fecha_fin, monto_alquiler, moneda,
  dia_vencimiento, dia_gracia, ajuste_indice, ajuste_periodo, deposito_garantia,
  punitorio_diario, tasa_bna_anual, capitaliza_meses, penal_ocupacion_pct,
  rescision_pct, dias_acreditar_servicios, fiadores, administradora, destino,
  fecha_tenencia, estado, notas
)
select
  (select id from public.locales where nombre='Local 3' limit 1),
  (select id from public.inquilinos where dni_cuit='25.550.495' limit 1),
  '2025-10-01','2027-09-30', 520000,'ARS',
  1, 10, 'ICL', '4', 520000,
  0.3, 75, 6, 20,
  10, 30,
  'Lucas Adrián Torregrosa (DNI 38.593.140, tel 2645444594) · Melina Soledad Illanes (DNI 30.152.408, tel 2644505402)',
  'Habitar Propiedades · Alto del Bono Shopping, Local 62, 1er piso · Tel 426-4983',
  'Depósito',
  '2025-10-17','activo',
  'Cláusula 3ª: canon $520.000 el primer cuatrimestre; se actualiza cada 4 meses por ICL (BCRA), supletoriamente IPC. Pago por adelantado el día 1, sin recargo hasta el día 10. Cláusula 8ª: la mora es automática desde el día 1 (se pierden los días de gracia); interés punitorio 0,3% diario más tasa activa del Banco Nación, capitalizables cada 6 meses. Cláusula 5ª: energía, gas, agua y tasa municipal a cargo del locatario; impuesto inmobiliario a cargo del locador. Debe acreditar el pago de servicios dentro de los 30 días del vencimiento. Cláusula 2ª: ocupación ilegítima 20% del último canon por día. Cláusula 11ª: rescisión anticipada 10% del canon futuro, con aviso de 15 días.'
where not exists (
  select 1 from public.contratos c
  join public.inquilinos i on i.id=c.inquilino_id
  where i.dni_cuit='25.550.495'
);

-- ---------- 5) Registro de ajustes del canon ----------
-- Cada actualización queda asentada acá. El canon vigente se calcula
-- encadenando estos ajustes desde el monto inicial del contrato, así el
-- valor no depende de que la app pueda conectarse al BCRA.
create table if not exists public.ajustes_contrato (
  id             bigint generated always as identity primary key,
  contrato_id    bigint references public.contratos(id) on delete cascade,
  fecha          date not null,          -- fecha en que rige el nuevo canon
  indice         text default 'ICL',
  valor_desde    numeric,                -- índice al inicio del período
  valor_hasta    numeric,                -- índice a la fecha del ajuste
  factor         numeric,                -- valor_hasta / valor_desde
  monto_anterior numeric,
  monto_nuevo    numeric not null,
  origen         text default 'manual'   -- manual / automatico
                 check (origen in ('manual','automatico')),
  notas          text,
  created_at     timestamptz default now(),
  unique (contrato_id, fecha)
);

alter table public.ajustes_contrato enable row level security;
drop policy if exists "acceso_autenticado" on public.ajustes_contrato;
create policy "acceso_autenticado" on public.ajustes_contrato
  for all to authenticated using (true) with check (true);

-- ---------- 6) Facturas de servicios: vencimiento y período ----------
alter table public.gastos add column if not exists vencimiento date;
alter table public.gastos add column if not exists periodo text;         -- ej: '2026-08'
alter table public.gastos add column if not exists nro_cuenta text;
alter table public.gastos add column if not exists cuenta_id bigint
  references public.cuentas_servicio(id) on delete set null;
alter table public.gastos add column if not exists a_cargo text default 'inquilino'
  check (a_cargo in ('inquilino','propietario'));

-- URL de consulta de cada servicio (para el acceso directo desde la app)
alter table public.cuentas_servicio add column if not exists url_consulta text;
alter table public.cuentas_servicio add column if not exists a_cargo text default 'inquilino';

update public.cuentas_servicio
   set url_consulta='https://oficinavirtual.naturgysj.com.ar/publico/pagos/consulta'
 where organismo ilike '%naturgy%';

update public.cuentas_servicio
   set url_consulta='https://facturaweb.osse.com.ar/'
 where organismo ilike '%osse%' or tipo='agua';

update public.cuentas_servicio
   set url_consulta='https://municipioderawson.gob.ar/geoportal/'
 where organismo ilike '%municip%';

-- El impuesto inmobiliario provincial (DGR) es a cargo del LOCADOR (cláusula 5ª)
update public.cuentas_servicio set a_cargo='propietario'
 where organismo ilike '%rentas%' or organismo ilike '%DGR%';

-- Refresca el caché de Supabase para que la app vea las tablas nuevas.
-- (Sin esto puede aparecer: "Could not find the table in the schema cache")
notify pgrst, 'reload schema';

-- El Local 3 pasa a ocupado
update public.locales set estado='ocupado'
where nombre='Local 3'
  and exists (select 1 from public.contratos c
              join public.inquilinos i on i.id=c.inquilino_id
              where i.dni_cuit='25.550.495' and c.estado='activo');
