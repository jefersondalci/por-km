-- =============================================
-- Por km — Script de criação do banco de dados
-- Cole tudo isso no SQL Editor do Supabase
-- =============================================

-- 1. TABELA DE CONFIGURAÇÕES DO MOTORISTA
create table if not exists configuracoes (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
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
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. TABELA DE TURNOS
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
  created_at timestamp with time zone default now()
);

-- 4. SEGURANÇA — Cada motorista só vê seus próprios dados
alter table configuracoes enable row level security;
alter table turnos enable row level security;
alter table abastecimentos enable row level security;

-- Políticas para configuracoes
create policy "usuario ve propria config" on configuracoes
  for all using (auth.uid() = user_id);

-- Políticas para turnos
create policy "usuario ve proprios turnos" on turnos
  for all using (auth.uid() = user_id);

-- Políticas para abastecimentos
create policy "usuario ve proprios abastecimentos" on abastecimentos
  for all using (auth.uid() = user_id);
