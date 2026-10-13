-- =============================================================
-- Por km v1.6 — rodar UMA vez no SQL Editor do Supabase (depois do SQL da v1.5)
-- Pode rodar de novo sem problema.
-- =============================================================

-- 1. HODÔMETRO NOS ABASTECIMENTOS (o app calcula sozinho os km rodados entre um e outro)
alter table public.abastecimentos add column if not exists hodometro numeric;

-- 2. CONTA LIBERADA — conferida no servidor, não só na tela do app.
--    Liberada = admin, OU sem linha de controle (contas antigas), OU ativa e dentro do vencimento.
--    Vitalício nunca vence. O dia do vencimento ainda vale (horário de Brasília).
create or replace function public.conta_liberada() returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_admin()
      or not exists (select 1 from public.usuarios_controle where user_id = auth.uid())
      or exists (
        select 1 from public.usuarios_controle
         where user_id = auth.uid()
           and ativo is true
           and (vitalicio is true or vencimento is null
                or vencimento >= (now() at time zone 'America/Sao_Paulo')::date)
      );
$$;

-- 3. Os dados do motorista (turnos, abastecimentos, configurações, custos) só abrem com a conta liberada.
--    Apaga as regras antigas dessas tabelas e cria as novas.
do $$
declare t text; p record;
begin
  foreach t in array array['turnos','abastecimentos','configuracoes','custos_ciclo'] loop
    execute format('alter table public.%I enable row level security', t);
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
    execute format(
      'create policy "proprios dados com conta liberada" on public.%I for all to authenticated
         using (auth.uid() = user_id and public.conta_liberada())
         with check (auth.uid() = user_id and public.conta_liberada())', t);
  end loop;
end $$;
