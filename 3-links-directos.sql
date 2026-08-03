-- =====================================================================
--  PASO 3 · Enlaces directos al detalle de deuda
--
--  Estos links ya incluyen el número de cuenta, así que abren la deuda
--  directamente, sin tener que completar el formulario del sitio.
--
--  Correr en Supabase → SQL Editor → New query → Run.
--  Se puede correr solo: crea por su cuenta las columnas que necesita.
-- =====================================================================

-- ---------- Columnas necesarias (por si falta correr actualizar-bd.sql) ----------
alter table public.cuentas_servicio add column if not exists url_consulta text;
alter table public.cuentas_servicio add column if not exists a_cargo text default 'inquilino';

alter table public.gastos add column if not exists vencimiento date;
alter table public.gastos add column if not exists periodo     text;
alter table public.gastos add column if not exists nro_cuenta  text;
alter table public.gastos add column if not exists cuenta_id   bigint
  references public.cuentas_servicio(id) on delete set null;
alter table public.gastos add column if not exists a_cargo     text default 'inquilino';

-- Municipalidad de Rawson (ID contribuyente 206130300000, tipo IM)
update public.cuentas_servicio
   set url_consulta = 'https://www.municipioonline.com.ar/newsite/Views/resumenDeudaGet.php?m=rawson&tipoCo=IM&idCo=206130300000'
 where organismo ilike '%municip%';

-- OSSE (cuenta 119-0066581-000/6)
update public.cuentas_servicio
   set url_consulta = 'https://facturaweb.osse.com.ar/detalle-deuda/UKa8f225f4-b206-42b6-b61e-5c5b3afee806'
 where tipo = 'agua';

-- Naturgy: los 3 suministros están asociados a una misma cuenta de la
-- oficina virtual, así que el botón lleva al resumen de cuentas. Iniciá
-- sesión una vez en tu navegador y la sesión queda guardada.
--
-- IMPORTANTE: no se guardan usuarios ni contraseñas en esta base de datos.
update public.cuentas_servicio
   set url_consulta = 'https://oficinavirtual.naturgysj.com.ar/pagos'
 where organismo ilike '%naturgy%';

-- Si más adelante conseguís un link que incluya el número de suministro
-- (consultando el suministro y copiando la URL de la barra de direcciones),
-- pegalo acá para que abra directo la factura de cada local:
--
-- update public.cuentas_servicio set url_consulta='PEGAR_LINK_LOCAL_1'
--  where nro_cuenta='20004660492';
-- update public.cuentas_servicio set url_consulta='PEGAR_LINK_LOCAL_2'
--  where nro_cuenta='20004660479';
-- update public.cuentas_servicio set url_consulta='PEGAR_LINK_LOCAL_3'
--  where nro_cuenta='20003841440';

-- DGR · Impuesto inmobiliario provincial.
-- Es a cargo del LOCADOR (cláusula 5ª), lo paga el propietario.
-- El sitio pide completar los datos, así que se copia el n° de cuenta.
update public.cuentas_servicio
   set url_consulta = 'https://rentas.dgrsj.gob.ar/Deudas',
       a_cargo      = 'propietario'
 where organismo ilike '%rentas%' or organismo ilike '%DGR%';

-- Refresca el caché para que la app vea las columnas nuevas
notify pgrst, 'reload schema';

-- Control: debe listar las 6 cuentas activas, 5 de ellas con link
select organismo, nro_cuenta, a_cargo, url_consulta
  from public.cuentas_servicio
 where estado='activo'
 order by tipo, id;
