-- =============================================
-- Por km — Script de criação do banco de dados (INSTALAÇÃO NOVA)
-- Cole tudo isso no SQL Editor de um projeto Supabase vazio.
-- Para o banco que já está em uso, rode só supabase/2026-10-13_seguranca_e_correcoes.sql
-- =============================================

-- 1. TABELA DE CONFIGURAÇÕES DO MOTORISTA (metas e ciclo; uma linha por motorista)
create table if not exists configuracoes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null unique,
  meta_km numeric default 2.30,
  meta_viagem numeric default 13.20,
  meta_hora numeric default 39.00,
  parcela numeric default 0,
  ipva numeric default 0,
  seguro numeric default 0,
  pneu_total numeric default 1000,
  pneu_km numeric default 60000,
  revisao_km numeric default 0.30,
  emergencia_km numeric default 0.12,
  autonomia numeric default 7.0,
  preco_litro numeric default 4.89,
  dia_ciclo integer default 1,
  usar_media_comb boolean default false,
  apps text[] default array['uber','99','part'],
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. TABELA DE TURNOS (total + separado por app)
create table if not exists turnos (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  data date not null,
  num integer not null default 1,
  km_i numeric not null,
  km_f numeric not null,
  h_i text,
  h_f text,
  bruto numeric default 0,
  viagens integer default 0,
  bonus numeric default 0,
  uber_bruto numeric default 0,
  uber_viagens integer default 0,
  uber_bonus numeric default 0,
  nov99_bruto numeric default 0,
  nov99_viagens integer default 0,
  nov99_bonus numeric default 0,
  part_bruto numeric default 0,
  part_viagens integer default 0,
  created_at timestamp with time zone default now()
);

-- 3. TABELA DE ABASTECIMENTOS
create table if not exists abastecimentos (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  data date not null,
  tipo text default 'Gasolina',
  km_rod numeric not null,
  litros numeric not null,
  preco numeric not null,
  hodometro numeric,
  created_at timestamp with time zone default now()
);

-- 4. CUSTOS POR CICLO (cada ciclo guarda os custos que valiam nele)
create table if not exists custos_ciclo (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  ciclo_ini date not null,
  ciclo_fim date,
  parcela numeric default 0,
  ipva numeric default 0,
  seguro numeric default 0,
  pneu_total numeric default 1000,
  pneu_km numeric default 60000,
  revisao_km numeric default 0.30,
  emergencia_km numeric default 0.12,
  autonomia numeric default 7.0,
  preco_litro numeric default 4.89,
  created_at timestamp with time zone default now(),
  unique (user_id, ciclo_ini)
);

-- 5. CONTROLE DE ACESSO / PLANOS (uma linha por conta, criada no cadastro)
create table if not exists usuarios_controle (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null unique,
  email text,
  nome text,
  telefone text,
  ativo boolean default false,
  plano text default 'gratuito',
  vitalicio boolean default false,
  vencimento date,
  observacoes text,
  admin boolean default false,
  data_cadastro timestamp with time zone default now()
);

create or replace function public.criar_usuario_controle() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.usuarios_controle (user_id, email, nome, telefone)
  values (new.id, new.email, new.raw_user_meta_data ->> 'nome', new.raw_user_meta_data ->> 'telefone')
  on conflict (user_id) do nothing;
  return new;
end $$;

drop trigger if exists criar_usuario_controle on auth.users;
create trigger criar_usuario_controle after insert on auth.users
  for each row execute function public.criar_usuario_controle();

-- 6. SEGURANÇA — Cada motorista só vê seus próprios dados
alter table configuracoes enable row level security;
alter table turnos enable row level security;
alter table abastecimentos enable row level security;
alter table custos_ciclo enable row level security;
alter table usuarios_controle enable row level security;

-- Admin conferido no servidor
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce(auth.jwt() ->> 'email', '') = 'jefersondalci@gmail.com';
$$;

-- Conta liberada = admin, sem linha de controle, ou ativa e dentro do vencimento (vitalício nunca vence)
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

create policy "proprios dados com conta liberada" on configuracoes for all to authenticated
  using (auth.uid() = user_id and public.conta_liberada()) with check (auth.uid() = user_id and public.conta_liberada());

create policy "proprios dados com conta liberada" on turnos for all to authenticated
  using (auth.uid() = user_id and public.conta_liberada()) with check (auth.uid() = user_id and public.conta_liberada());

create policy "proprios dados com conta liberada" on abastecimentos for all to authenticated
  using (auth.uid() = user_id and public.conta_liberada()) with check (auth.uid() = user_id and public.conta_liberada());

create policy "proprios dados com conta liberada" on custos_ciclo for all to authenticated
  using (auth.uid() = user_id and public.conta_liberada()) with check (auth.uid() = user_id and public.conta_liberada());

create policy "controle: ve a propria linha ou admin" on usuarios_controle
  for select to authenticated using (user_id = auth.uid() or public.is_admin());

create policy "controle: altera a propria linha ou admin" on usuarios_controle
  for update to authenticated using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

create policy "controle: so admin exclui" on usuarios_controle
  for delete to authenticated using (public.is_admin());

-- O motorista só pode mudar o próprio nome e telefone
create or replace function public.proteger_usuarios_controle() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is not null and not public.is_admin()
     and (to_jsonb(new) - 'nome' - 'telefone') is distinct from (to_jsonb(old) - 'nome' - 'telefone') then
    raise exception 'Somente o administrador pode alterar plano, ativacao ou vencimento.';
  end if;
  return new;
end $$;

drop trigger if exists proteger_usuarios_controle on usuarios_controle;
create trigger proteger_usuarios_controle before update on usuarios_controle
  for each row execute function public.proteger_usuarios_controle();
