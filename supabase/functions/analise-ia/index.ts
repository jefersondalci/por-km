// Edge Function "analise-ia" — analise do dia/ciclo com Claude.
// A chave da Anthropic fica so aqui (secret ANTHROPIC_API_KEY), nunca no navegador.
// Publicar: supabase secrets set ANTHROPIC_API_KEY=...  &&  supabase functions deploy analise-ia
import Anthropic from "npm:@anthropic-ai/sdk";
import { createClient } from "npm:@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const anthropic = new Anthropic(); // le ANTHROPIC_API_KEY do ambiente

function responder(corpo: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

// so numeros finitos entram no pedido — o navegador nao consegue mandar texto livre para a IA
function num(v: unknown): number {
  const n = Number(v);
  return Number.isFinite(n) ? n : 0;
}
const r$ = (v: unknown) => "R$ " + num(v).toFixed(2);

function montarPedido(tipo: string, d: Record<string, unknown>): string | null {
  if (tipo === "dia") {
    return `Dia de trabalho: ${num(d.turnos)} turno(s), ${r$(d.bruto)} bruto, ${num(d.km)} km, ${num(d.viagens)} viagens.
Metas: ${r$(d.meta_km)}/km e ${r$(d.meta_hora)}/hora.
Avalie o dia em 3 a 4 frases e de 1 dica pratica.`;
  }
  if (tipo === "ciclo") {
    return `Ciclo financeiro: bruto ${r$(d.bruto)}, custos ${r$(d.custos)}, lucro ${r$(d.lucro)}, ${num(d.dias)} dias, ${num(d.viagens)} viagens, ${num(d.km)} km.
Resultado: ${r$(d.r_km)}/km (meta ${r$(d.meta_km)}) e ${r$(d.r_hr)}/hora (meta ${r$(d.meta_hora)}).
Avalie o ciclo em 4 a 5 frases e de 2 sugestoes praticas.`;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  // usuario logado e com conta ativa (o Supabase ja valida o token antes de chegar aqui)
  const auth = req.headers.get("Authorization") ?? "";
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: auth } },
  });
  const { data: { user } } = await sb.auth.getUser();
  if (!user) return responder({ erro: "Faca login novamente." }, 401);
  const { data: ctrl } = await sb.from("usuarios_controle").select("ativo").eq("user_id", user.id).maybeSingle();
  if (ctrl && !ctrl.ativo) return responder({ erro: "Conta aguardando ativacao." }, 403);

  let corpo: { tipo?: string; dados?: Record<string, unknown> };
  try {
    corpo = await req.json();
  } catch {
    return responder({ erro: "Pedido invalido." }, 400);
  }
  const pedido = montarPedido(String(corpo.tipo ?? ""), corpo.dados ?? {});
  if (!pedido) return responder({ erro: "Pedido invalido." }, 400);

  try {
    const resp = await anthropic.beta.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 16000,
      output_config: { effort: "low" },
      betas: ["server-side-fallback-2026-07-01"],
      fallbacks: "default",
      system:
        "Voce e um consultor financeiro de motoristas de aplicativo (Uber, 99, particular) no Brasil. " +
        "Responda em portugues, texto corrido, curto e direto, sem titulos nem listas.",
      messages: [{ role: "user", content: pedido }],
    });
    if (resp.stop_reason === "refusal") return responder({ erro: "A IA nao conseguiu analisar agora." });
    const texto = resp.content
      .filter((b) => b.type === "text")
      .map((b) => (b as { text: string }).text)
      .join("\n")
      .trim();
    return responder({ texto: texto || "Sem resposta." });
  } catch (e) {
    if (e instanceof Anthropic.RateLimitError) return responder({ erro: "Muitos pedidos agora, tente em instantes." }, 429);
    if (e instanceof Anthropic.AuthenticationError) return responder({ erro: "IA nao configurada no servidor." }, 500);
    if (e instanceof Anthropic.APIError) return responder({ erro: "IA indisponivel no momento." }, 502);
    return responder({ erro: "Nao foi possivel conectar a IA." }, 500);
  }
});
