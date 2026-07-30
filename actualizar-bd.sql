-- =====================================================================
--  ACTUALIZACIÓN: índices de ajuste en contratos (ICL / IPC / Casa Propia)
--  Correr UNA sola vez en Supabase → SQL Editor → New query → Run.
--  (Solo para bases que ya fueron creadas con el schema.sql anterior.
--   Si vas a crear la base desde cero, usá schema.sql y no este archivo.)
-- =====================================================================

alter table public.contratos
  add column if not exists ajuste_indice text default 'ICL';

alter table public.contratos
  drop constraint if exists contratos_ajuste_indice_check;

alter table public.contratos
  add constraint contratos_ajuste_indice_check
  check (ajuste_indice in ('ICL','IPC','CASA_PROPIA','FIJO','NINGUNO'));
