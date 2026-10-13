# Changelog — Por km

## v1.5 — 2026-10-13

### Corrigido
- **Data trocada depois das 21h**: o app usava o horário de Londres (UTC) e, das 21h à meia-noite, gravava turnos e abastecimentos com a data do dia seguinte. Agora usa o horário do celular.
- **Turno que passa da meia-noite**: o turno aberto num dia agora pode ser fechado no dia seguinte, e as horas (ex.: 22:00 → 02:00 = 4h) são contadas certo. Antes davam 0h.
- **Bônus sumia**: ao fechar o turno, o bônus de Uber/99 era gravado como 0 no total e não entrava no lucro. O SQL da v1.5 recupera o bônus dos turnos antigos.
- **Lucro do Diário x Dashboard**: o Diário passou a usar os mesmos custos do ciclo que o Dashboard usa.
- **Custos fixos em períodos curtos**: parcela, IPVA e seguro agora são proporcionais aos dias quando o período não é um ciclo completo.
- **Média de consumo**: km/L e preço médio agora são total de km ÷ total de litros (antes era a média simples de cada abastecimento).
- **Gráfico semanal**: o título dizia "Lucro por semana", mas o gráfico mostra o bruto. Agora o título diz "Bruto por semana".
- **Cadastro**: nome e WhatsApp vão junto no cadastro e são gravados no primeiro login. As configurações também são criadas no primeiro login, caso não existam.

### Segurança
- A tabela `usuarios_controle` (nome, e-mail, telefone) podia ser lida por qualquer pessoa, sem login. O SQL da v1.5 fecha isso: cada motorista vê só a própria linha, o admin vê todas, e só o admin muda plano, ativação e vencimento.
- Análise IA: a chamada sai do navegador e passa para a Edge Function `analise-ia` do Supabase, que guarda a chave da Anthropic.

### Organização
- Removido `Por km.html` (cópia antiga do app).
- `porkm_setup.sql` atualizado com todas as tabelas e colunas que o app usa.

### Para ativar (uma vez)
1. Supabase → SQL Editor: rodar `supabase/2026-10-13_seguranca_e_correcoes.sql`.
2. Análise IA (opcional), com a Supabase CLI:
   - `supabase secrets set ANTHROPIC_API_KEY=<sua chave>`
   - `supabase functions deploy analise-ia`
