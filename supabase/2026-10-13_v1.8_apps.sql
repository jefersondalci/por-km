-- =============================================================
-- Por km v1.8 — rodar UMA vez no SQL Editor do Supabase
-- "Apps que uso" (Ajustes) passa a ficar salvo na conta, valendo em qualquer celular.
-- Sem este SQL o app funciona igual, mas guarda a escolha só no celular.
-- =============================================================
alter table public.configuracoes add column if not exists apps text[] default array['uber','99','part'];
