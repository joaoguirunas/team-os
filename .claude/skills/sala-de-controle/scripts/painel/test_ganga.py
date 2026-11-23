#!/usr/bin/env python3
"""Testes da Ganga (sem rede, sem microfone): níveis de pedido, filtro de segredos, fila, Copiloto, arquivos.

  python3 .claude/skills/sala-de-controle/scripts/painel/test_ganga.py     → sai 0 se tudo passar
"""
import json
import os
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = tempfile.mkdtemp(prefix="ganga-test-")
os.environ["GANGA_QDIR"] = os.path.join(TMP, "fila")
sys.path.insert(0, HERE)
import copilot  # noqa: E402
import ganga  # noqa: E402

ganga.MEM_DIR, ganga.MEM_FILE = TMP, os.path.join(TMP, "memoria.json")
ganga.PREFS_FILE = os.path.join(TMP, "prefs.json")
FAIL = []


def check(name, cond, extra=""):
    if not cond:
        FAIL.append(name)
    print(("PASS " if cond else "FAIL ") + name + (f" — {extra}" if extra and not cond else ""))


# ---- níveis: piso duro (sem classificador) ----
for t in ["paga o boleto da Vercel", "faz um pix de 200", "roda rm -rf na pasta", "git push --force", "cola o .env no relatório",
          "troca a senha do admin"]:
    check(f"piso sensível: {t}", copilot.level(t) == "sensivel")
# ---- níveis: reserva por regex (sem classificador) ----
for t, exp in [("faz o deploy", "sensivel"), ("sobe para produção", "sensivel"), ("apaga o rascunho antigo", "sensivel"),
               ("manda o PDF no WhatsApp do Carlos", "externo"), ("manda pro Carlos o PDF", "externo"),
               ("envia o relatório por e-mail", "externo"),
               ("incluir a página exclusiva no site", "normal"), ("acelerar a produção das três páginas", "normal"),
               ("manda o Comercial revisar a proposta", "normal"), ("continua o capítulo 4", "normal")]:
    check(f"regex {exp}: {t}", copilot.level(t, "Scalify | Comercial") == exp, copilot.level(t, "Scalify | Comercial"))
# ---- classificador decide, piso não rebaixa ----
check("classificador decide", copilot.level("sobe o site", "", lambda t: "sensivel") == "sensivel")
check("classificador libera falso positivo", copilot.level("revisa o token de design", "", lambda t: "normal") == "normal")
check("piso vence o classificador", copilot.level("paga o boleto", "", lambda t: "normal") == "sensivel")
check("classificador fora do ar cai na regex", copilot.level("faz o deploy", "", lambda t: None) == "sensivel")

# ---- filtro de segredos ----
for t in ["postgres://user:minhasenha123@db.host/x", "STRIPE_SECRET_KEY=sk_live_abcdefghij1234", '"api_key": "abcd1234efgh5678"',
          "Authorization: Bearer abcdefghijklmnop123", "ANON_KEY=abc123def456ghi", "senha: Xy12345678",
          "sk-ant-abcdefghijklmnopqrstuv", "AIzaSyA1234567890abcdefghijklmn", "ghp_abcdefghijklmnopqrstuvwxyz0123"]:
    check(f"oculta: {t[:28]}", "[segredo oculto]" in ganga.redact(t) and "minhasenha123" not in ganga.redact(t))
for t in ["Senha: definida pelo cliente", "Token: aproximadamente 2 mil por resposta", "tokens: 1.108.751",
          "o token de design é azul-500", "a chave do sucesso é constância"]:
    check(f"não mutila: {t[:30]}", ganga.redact(t) == t, ganga.redact(t))
for f, exp in [(".env", 1), (".env.local", 1), ("env.sh", 1), ("secrets/prod.yaml", 1), ("senhas.txt", 1), ("server.pem", 1),
               ("credentials.json", 1), ("firebase-adminsdk-x.json", 1), ("design-tokens.md", 0), ("politica-de-senhas.pdf", 0),
               ("secretaria-contatos.md", 0), ("deck.key", 0), ("config.json", 0), ("proposta.pdf", 0)]:
    check(f"arquivo {'protegido' if exp else 'liberado'}: {f}", ganga.is_secret_path(f) == bool(exp))

# ---- fila: confirmações e ciclo de vida ----
P = {"name": "X | Site", "path": "/x", "sessions": []}
n = copilot.draft(P, "revisa o texto", {"sessions": []}, lambda t: "normal")
check("normal: 1 chamada envia", copilot.confirm(n["id"]).get("enviado") is True)
e = copilot.draft(P, "manda o PDF pro Carlos", {"sessions": []}, lambda t: "externo")
check("externo: 1 sim envia", copilot.confirm(e["id"]).get("enviado") is True)
s = copilot.draft(P, "publica a página nova", {"sessions": []}, lambda t: "sensivel")
r1 = copilot.confirm(s["id"])
check("sensível: 1º sim não envia", r1.get("precisa_segunda") is True and not r1.get("enviado"))
check("sensível: 2º sim envia", copilot.confirm(s["id"]).get("enviado") is True)
q = {r["id"]: r for r in copilot.read_queue(50)}
check("sensível chega aprovado, sem OK no chat", q[s["id"]].get("aprovado_pelo_usuario") is True and not q[s["id"]].get("ok_no_chat"))
d2 = copilot.draft(P, "revisa o texto", {"sessions": []}, lambda t: "normal")
check("mesmo pedido em 2 min não duplica", copilot.confirm(d2["id"]).get("duplicado") is True)
check("aprovar o que não espera OK é recusado", "error" in copilot.set_status(n["id"], "aprovado"))
copilot.append_status(e["id"], "aguardando_ok")
check("aprovar aguardando_ok", copilot.set_status(e["id"], "aprovado").get("ok") is True)
with open(copilot.QUEUE, "a", encoding="utf-8") as f:
    f.write("{quebrado\n" + json.dumps({"sem": "id"}) + "\n[1,2]\n")
check("linha estragada não derruba a fila", len(copilot.read_queue(50)) == 3)

# ---- ganga-fila --wait: anuncia uma vez só, avisa cancelamento ----
def run_wait(secs=5):
    p = subprocess.Popen([sys.executable, "-u", os.path.join(HERE, "ganga-fila.py"), "--wait"], stdout=subprocess.PIPE, text=True,
                         env=dict(os.environ))
    time.sleep(secs)
    p.terminate()
    return p.communicate()[0]

out1 = run_wait()
check("anuncia os pendentes", out1.count("PEDIDO_GANGA") == 3, out1)
out2 = run_wait(4)
check("reinício não anuncia de novo", out2.count("PEDIDO_GANGA") == 0, out2)
check("sala_listening depois do batimento", copilot.sala_listening())

# ---- Copiloto: pergunta x conclusão x erro ----
for t, exp in [("Revisei o capítulo 3. Quer que eu siga para o 4?", True), ("Fiz as 3 versões. Qual você prefere: A, B ou C?", True),
               ("Terminei o deploy do site.", False), ("Pronto, tudo certo por aqui.", False)]:
    check(f"pergunta={exp}: {t[:36]}", copilot.needs_reply(t) == exp)

# ---- arquivos: achar, ler, recusar ----
proj = os.path.join(TMP, "proj")
os.makedirs(os.path.join(proj, "docs", "_lixo"))
os.makedirs(os.path.join(proj, "secrets"))
for rel, txt in [("docs/proposta-acme-v2.md", "Proposta ACME\napi_key = abcd1234efgh5678\nfim"), ("docs/_lixo/proposta-acme-v1.md", "velha"),
                 (".env", "KEY=1"), ("secrets/prod.yaml", "x: 1"), ("docs/roda.command", "echo oi")]:
    with open(os.path.join(proj, rel), "w", encoding="utf-8") as f:
        f.write(txt)
os.symlink(os.path.join(proj, "docs", "roda.command"), os.path.join(proj, "docs", "falso.pdf"))
hits = ganga.find_files(proj, "proposta acme", exts=ganga.READ_EXT)
check("acha o arquivo e ignora o lixo", [h["nome"] for h in hits] == ["proposta-acme-v2.md"], str(hits))
txt = ganga.read_file_text(proj, "docs/proposta-acme-v2.md") or ""
check("lê o texto sem o segredo", "Proposta ACME" in txt and "abcd1234" not in txt, txt)
check("não lê .env", ganga.read_file_text(proj, ".env") is None)
check("não lê pasta secrets", ganga.read_file_text(proj, "secrets/prod.yaml") is None)
check("não lê fora do projeto", ganga.read_file_text(proj, "../x.md") is None)
_popen, ganga.subprocess.Popen = ganga.subprocess.Popen, lambda *a, **k: None
check("não abre programa", ganga.open_file(proj, "docs/roda.command") is None)
check("não abre link disfarçado de PDF", ganga.open_file(proj, "docs/falso.pdf") is None)
check("abre documento", ganga.open_file(proj, "docs/proposta-acme-v2.md") is not None)
ganga.subprocess.Popen = _popen

# ---- Copiloto ativo: age sozinha no que já foi decidido, chama o usuário para decidir ----
def sess(st, tail, sid="s1", state=""):
    return {"projects": [{"path": "/p", "name": "X | Livro"}],
            "sessions": [{"id": sid, "name": "X | Livro", "project": "/p", "status": st, "state": state, "tail": tail, "goal": "escrever os capítulos"}]}

def cop(decide, **prefs):
    c = copilot.Copilot(lambda: {"on": True, "mode": "copiloto", "notify": {"wait": True, "error": True}, **prefs})
    c.decide_fn = decide
    c.said = []
    c._say = lambda text, voice, seq: c.said.append(text)
    return c

def settle(c, secs=1.5):
    time.sleep(secs)
    c.last_spoken = 0
    c._pump(c.prefs_fn())
    time.sleep(0.4)

n0 = len([r for r in copilot.read_queue(200) if r.get("auto")])
c1 = cop(lambda s, g, t: {"tipo": "continuar", "resposta": "Pode seguir para o capítulo 4.", "pergunta": ""})
c1.feed(sess("busy", "x")); c1.feed(sess("idle", "Revisei o capítulo 3. Posso seguir para o capítulo 4?")); settle(c1)
autos = [r for r in copilot.read_queue(200) if r.get("auto")]
check("continuação: responde sozinha", len(autos) == n0 + 1 and "resposta automática" in autos[0]["text"] and "Não publique" in autos[0]["text"])
check("continuação: não chama o usuário", not c1.said and any(n["kind"] == "auto" for n in c1.notices))
c2 = cop(lambda s, g, t: {"tipo": "decisao", "resposta": "", "pergunta": "Prefere o título A ou B?"})
c2.feed(sess("busy", "x", "s2")); c2.feed(sess("idle", "Fiz dois títulos. Qual você prefere, A ou B?", "s2")); settle(c2)
check("decisão: chama o usuário", len(c2.said) == 1 and len([r for r in copilot.read_queue(200) if r.get("auto")]) == n0 + 1)
c3 = cop(lambda s, g, t: {"tipo": "continuar", "resposta": "Pode publicar.", "pergunta": ""})
c3.feed(sess("busy", "x", "s3")); c3.feed(sess("idle", "Página pronta. Posso publicar no ar e fazer o deploy?", "s3")); settle(c3)
check("publicar nunca é continuação automática", len(c3.said) == 1 and not any(n["kind"] == "auto" for n in c3.notices))
c4 = cop(lambda s, g, t: {"tipo": "decisao", "resposta": "", "pergunta": "Quer revisar?"})
c4.feed(sess("busy", "x", "s4")); c4.feed(sess("idle", "Pronto: o PDF está em docs/builds e passou no QA.", "s4")); settle(c4)
check("terminou sem perguntar: silêncio", not c4.said and not c4.notices)
c5 = cop(lambda s, g, t: None)
c5.feed(sess("busy", "x", "s5")); c5.feed(sess("idle", "Terminei, tudo passou sem erro.", "s5")); settle(c5)
check("sem Gemini: 'sem erro' não é erro", not c5.said and not c5.notices)
c6 = cop(lambda s, g, t: {"tipo": "continuar", "resposta": "Siga.", "pergunta": ""})
for i in range(5):
    c6.feed(sess("busy", "x", "s6")); c6.feed(sess("idle", f"Passo {i} pronto. Sigo com o próximo?", "s6")); time.sleep(0.5)
settle(c6)
check("limite de 3 ações automáticas por sessão por hora", len(c6.autos.get("s6", [])) <= 3 and len(c6.said) >= 1)
c7 = cop(lambda s, g, t: {"tipo": "decisao", "resposta": "", "pergunta": "A ou B?"})
c7.live, c7.live_at = True, time.time()
c7.feed(sess("busy", "x", "s7")); c7.feed(sess("idle", "Qual você prefere, A ou B?", "s7")); settle(c7)
held = not c7.said and len(c7.todo) == 1
c7.live = False; settle(c7, 0.2)
check("aviso durante conversa espera e depois é falado", held and len(c7.said) == 1)
c8 = cop(lambda s, g, t: {"tipo": "decisao", "resposta": "", "pergunta": "?"})
c8.feed({"sessions": [{"id": "a", "name": "A", "status": "busy", "state": "", "tail": ""}, {"id": "b", "name": "B", "status": "busy", "state": "", "tail": ""}]})
c8.feed({"sessions": [{"id": "a", "name": "A", "status": "idle", "state": "", "tail": "Qual você prefere, A ou B?"}, {"id": "b", "name": "B", "status": "idle", "state": "", "tail": "Posso mudar o preço para 99?"}]})
settle(c8); settle(c8, 0.3)
check("duas sessões ao mesmo tempo: as duas são faladas, uma por vez", len(c8.said) == 2, str(c8.said))
c9 = cop(lambda s, g, t: {"tipo": "continuar", "resposta": "Siga.", "pergunta": ""}, auto=False)
c9.feed(sess("busy", "x", "s9")); c9.feed(sess("idle", "Sigo com a página 2?", "s9")); settle(c9)
check("com 'age sozinha' desligado, pergunta ao usuário", len(c9.said) == 1 and not c9.autos)

# ---- memória ----
ganga.save_memory({"name": "Ana"})
ganga.save_memory({"fact": "prefere resumo curto"})
check("memória guarda nome e fato", ganga.user_name() == "Ana" and "prefere resumo curto" in ganga.name_rule())
ganga.save_memory({"fact": "o projeto do livro chama Atlas"})
ganga.save_memory({"forget": "a"})
check("'esquece a' não apaga tudo", len(ganga.load_memory()["facts"]) == 2)
ganga.save_memory({"forget": "livro atlas"})
check("esquece só o fato pedido", ganga.load_memory()["facts"] == ["prefere resumo curto"])
ganga.save_memory({"conversation": [{"who": "eu", "text": "como está o site?"}, {"who": "ganga", "text": "token=abc12345xyz está pronto"}]})
check("memória guarda a conversa, sem segredo", "como está o site?" in ganga.name_rule() and "abc12345xyz" not in ganga.name_rule())

print(f"\n{'OK' if not FAIL else 'FALHOU'}: {len(FAIL)} falha(s)")
sys.exit(1 if FAIL else 0)
