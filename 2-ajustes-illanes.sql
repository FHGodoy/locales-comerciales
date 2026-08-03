-- =====================================================================
--  PASO 2 · Ajustes del canon ya vencidos - Contrato Jaquelina Illanes
--
--  Correr DESPUÉS de actualizar-bd.sql, en Supabase → SQL Editor → Run.
--
--  Valores oficiales del ICL (BCRA, idVariable 40 · base 30.6.20 = 1),
--  consultados el 03/08/2026:
--     01/10/2025 (inicio)      27,75
--     01/02/2026 (1er ajuste)  30,03
--     01/06/2026 (2do ajuste)  33,27
--
--  Cálculo en cascada:
--     $520.000  × (30,03 / 27,75) = $562.724   → rige desde 01/02/2026
--     $562.724  × (33,27 / 30,03) = $623.437   → rige desde 01/06/2026
-- =====================================================================

insert into public.ajustes_contrato
  (contrato_id, fecha, indice, valor_desde, valor_hasta, factor,
   monto_anterior, monto_nuevo, origen, notas)
select c.id, v.fecha, 'ICL', v.vd, v.vh, v.factor, v.ant, v.nuevo, 'automatico', v.nota
from public.contratos c
join public.inquilinos i on i.id = c.inquilino_id
cross join (values
  ('2026-02-01'::date, 27.75, 30.03, 1.082162, 520000, 562724,
   '1er ajuste cuatrimestral · ICL 27,75 → 30,03 · +8,22%'),
  ('2026-06-01'::date, 30.03, 33.27, 1.107892, 562724, 623437,
   '2do ajuste cuatrimestral · ICL 30,03 → 33,27 · +10,79%')
) as v(fecha, vd, vh, factor, ant, nuevo, nota)
where i.dni_cuit = '25.550.495'
on conflict (contrato_id, fecha) do update
  set valor_desde=excluded.valor_desde, valor_hasta=excluded.valor_hasta,
      factor=excluded.factor, monto_anterior=excluded.monto_anterior,
      monto_nuevo=excluded.monto_nuevo, notas=excluded.notas;

-- Control: debe mostrar los 2 ajustes y el canon vigente $623.437
select a.fecha, a.valor_desde, a.valor_hasta,
       round(a.monto_anterior) as canon_anterior,
       round(a.monto_nuevo)    as canon_nuevo,
       a.notas
from public.ajustes_contrato a
join public.contratos c on c.id = a.contrato_id
join public.inquilinos i on i.id = c.inquilino_id
where i.dni_cuit = '25.550.495'
order by a.fecha;
