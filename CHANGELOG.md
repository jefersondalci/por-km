# Changelog — Por km

## v1.8 — 2026-10-13

### Novo Início
- **Bloco "Hoje" no topo**: quanto sobrou hoje (bruto menos combustível, pneu, revisão, reserva e a parte do dia dos custos fixos), com ▲/▼ das metas de R$/km e R$/hora, e o botão de abrir ou fechar turno ali mesmo.
- **"Ciclo até hoje"**: lucro até hoje com parcela, IPVA e seguro proporcionais aos dias que já passaram (o ciclo não começa mais no vermelho) e a estimativa de quanto sobra no fim do ciclo se mantiver o ritmo.
- Custos, gráfico semanal e outros números ficam recolhidos e abrem com um toque.

### Novo fechamento de turno
- **Só os apps que você usa**: escolha em Ajustes → "Apps que uso". Os outros aparecem com "+ nome do app" se precisar.
- Uma linha por app (bruto e viagens lado a lado); bônus fica em "+ bônus".
- Resumo fixo embaixo, junto do botão, com km, horas, total e R$/km/R$/hora atualizando enquanto você digita.

### Ajuste de conta
- Custos fixos de períodos parciais agora são divididos pelos dias reais do ciclo (ex.: 13 dias de um ciclo de 31 = 13/31), em todas as telas.

### Para ativar (uma vez)
- Supabase → SQL Editor: rodar `supabase/2026-10-13_v1.8_apps.sql` para "Apps que uso" valer em qualquer celular (sem ele, a escolha fica só no celular).

## v1.7 — 2026-10-13

### Novo
- **Funciona sem internet**: o app abre mesmo sem sinal, mostrando seus dados da última vez que conectou.
- **Registra sem sinal**: abrir/fechar turno, editar, excluir e abastecimentos feitos sem internet ficam guardados no celular e são enviados sozinhos quando o sinal volta. Uma faixa no topo mostra "Sem internet" e quantos registros aguardam envio.
- **Instalar na tela inicial**: no Android (Chrome → menu ⋮ → "Instalar app") ou no iPhone (Safari → Compartilhar → "Adicionar à Tela de Início"), o Por km abre como um aplicativo, com ícone próprio e sem a barra do navegador.
- **Abre mais rápido**: as bibliotecas ficam guardadas no celular depois da primeira abertura.

### Observações
- Os Ajustes só podem ser salvos com internet.
- Ao tocar em "Sair" com registros ainda não enviados, o app avisa antes, porque sair apaga a cópia do celular.

## v1.6 — 2026-10-13

### Novo
- **Modo escuro**: segue o modo do celular; em Ajustes → Aparência dá para fixar Claro ou Escuro.
- **Bloqueio por vencimento**: quem passa da data de vencimento (qualquer plano, menos vitalício) vê a tela "Seu plano venceu". O dia do vencimento ainda vale. O bloqueio também vale no servidor: conta vencida ou não ativada não lê nem grava dados.
- **Hodômetro no abastecimento**: digitando o km do painel, o app calcula sozinho os km rodados desde o abastecimento anterior.
- **Editar turno por app**: a edição mostra Uber, 99 e Particular separados (antes só os totais, e o filtro por app ficava com número velho). Turnos antigos, sem divisão, continuam editando os totais.

### Corrigido
- **Vírgula no teclado**: campos de valor abrem teclado com vírgula (no iPhone não dava para digitar "2,30").
- **Filtro "Uber / 99" somava o Particular**: agora são três opções — Todos, Uber / 99 e Particular. Os km e as horas do turno são divididos entre os apps pela proporção de viagens (antes cada app levava o km do turno inteiro, e o R$/km do Particular saía absurdo).
- **Gráfico de km/L** mostrava os valores como dinheiro ("R$ 11").
- Valores negativos aparecem como "−R$ 305,33".

### Visual e textos
- Letras maiores (mínimo 11–12px) e cinza mais escuro: mais legível no carro. Zoom do celular liberado.
- Números com largura fixa (alinham nas colunas); títulos continuam em Georgia.
- Ícones de traço no lugar dos emojis; abas com nome completo: Início, Diário, Combustível, Comparar, Ciclos, Ajustes ("Histórico" virou "Ciclos", e dentro do Diário a lista virou "Dias anteriores").
- "IE 0,85" virou "▼ 15% abaixo da meta", com barra que enche até a meta.
- Status com sinal além da cor (▲ lucro / ▼ prejuízo), para quem não distingue verde e vermelho.
- R$/km do turno diz "sem bônus" e o do dia diz "com bônus".
- Excluir turno/abastecimento fica dentro da tela de edição (não dá mais para apagar sem querer); botão "Editar" maior.
- Avisos no topo da tela, no lugar das janelas do navegador.
- Acentos em todos os textos; painel Admin na mesma paleta do app (e com modo escuro).
- Ajustes: aviso de que os custos valem para o ciclo atual e textos de ajuda para Revisão e Emergência.
- Dashboard: o custo de combustível diz de onde vem (estimado pela autonomia ou média dos abastecimentos).

### Para ativar (uma vez)
1. Supabase → SQL Editor: rodar `supabase/2026-10-13_v1.6_acesso_e_hodometro.sql`.
2. Botão de WhatsApp na tela de bloqueio: preencher `WHATSAPP_ADMIN` no início do `index.html` (só números, com 55 + DDD).

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
