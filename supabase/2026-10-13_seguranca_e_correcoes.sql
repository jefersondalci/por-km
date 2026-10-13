-- =============================================================
-- Por km v1.5 — rodar UMA vez no SQL Editor do Supabase (banco que ja esta em uso)
-- Pode rodar de novo sem problema: cada passo confere antes de mudar.
-- =============================================================

-- 1. QUEM E ADMIN — conferido no servidor, nao so no app
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'jefersondalci@gmail.com';
$$;

-- 2. USUARIOS_CONTROLE — hoje qualquer pessoa SEM login consegue ler nome, e-mail e telefone.
--    Apaga as regras antigas desta tabela e cria as novas:
--    cada um ve so a propria linha; o admin ve e altera todas; so o admin exclui.
alter table public.usuarios_controle enable row level security;

do $$
declare p record;
begin
  for p in select policyname from pg_policies where schemaname = 'public' and tablename = 'usuarios_controle' loop
    execute format('drop policy %I on public.usuarios_controle', p.policyname);
  end loop;
end $$;

create policy "controle: ve a propria linha ou admin" on public.usuarios_controle
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

create policy "controle: altera a propria linha ou admin" on public.usuarios_controle
  for update to authenticated using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

create policy "controle: so admin exclui" on public.usuarios_controle
  for delete to authenticated using (public.is_admin());
-- (sem regra de INSERT: a linha continua sendo criada pelo gatilho do cadastro, como hoje)

-- O motorista so pode mudar o proprio NOME e TELEFONE.
-- Ativo, plano, vitalicio, vencimento etc. so o admin muda.
create or replace function public.proteger_usuarios_controle() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_admin()
     and (to_jsonb(new) - 'nome' - 'telefone') is distinct from (to_jsonb(old) - 'nome' - 'telefone') then
    raise exception 'Somente o administrador pode alterar plano, ativacao ou vencimento.';
  end if;
  return new;
end $$;

drop trigger if exists proteger_usuarios_controle on public.usuarios_controle;
create trigger proteger_usuarios_controle before update on public.usuarios_controle
  for each row execute function public.proteger_usuarios_controle();

-- 3. CONFIGURACOES — uma linha por motorista (o app passa a criar a linha no 1o login)
do $$
begin
  if exists (select 1 from pg_constraint where conname = 'configuracoes_user_id_key') then
    raise notice 'configuracoes: unicidade ja existe';
  elsif exists (select user_id from public.configuracoes group by user_id having count(*) > 1) then
    raise notice 'configuracoes: ha motoristas com mais de uma linha — limpar antes (ver consulta abaixo)';
  else
    alter table public.configuracoes add constraint configuracoes_user_id_key unique (user_id);
  end if;
end $$;
-- Para ver duplicados, se o aviso acima aparecer:
-- select user_id, count(*) from public.configuracoes group by user_id having count(*) > 1;

-- 4. BONUS DOS TURNOS ANTIGOS — ate a v1.4 o bonus de Uber/99 era gravado so por app
--    e o total ficava 0, entao nao entrava no lucro. Recupera o total a partir dos apps.
update public.turnos
   set bonus = coalesce(uber_bonus, 0) + coalesce(nov99_bonus, 0)
 where coalesce(bonus, 0) = 0
   and coalesce(uber_bonus, 0) + coalesce(nov99_bonus, 0) > 0;
