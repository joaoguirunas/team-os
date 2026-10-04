#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""update-pack.py — motor do `/team-os-creator *update` (chamado por update-pack.sh).

Atualiza o pack team-os nesta pasta SEM perder o que o usuário criou ou editou.
Veja o cabeçalho de update-pack.sh para o uso. Regras de ouro:
  * só toca arquivos listados no pack-manifest.json (o resto é do usuário);
  * arquivo do pack editado pelo usuário nunca é sobrescrito (vira <arquivo>.new);
  * tudo que é trocado vai antes para .team-os/backups/<ts>/; nada é apagado (Lixeira);
  * nunca roda git pull/merge/checkout/commit/push nem mexe no índice git do usuário.
"""
import argparse
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
DEFAULT_UPSTREAM = "https://github.com/joaoguirunas/team-os"
DOCS = {"README.md", "CHANGELOG.md", "CLAUDE.md", "CONTRIBUTING.md", "LICENSE",
        "THIRD_PARTY_NOTICES.md", "VERSION"}
CUSTOM_PRESETS = ".claude/skills/team-os-creator/presets/custom/"
SCRIPTS_REL = ".claude/skills/team-os-creator/scripts"
NTP_REL = ".claude/skills/team-os-creator/reference/native-teams-protocol.md"
BACKUP_KEEP = 3
SEMVER = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")


class Fail(Exception):
    """Erro com mensagem para o usuário (vira ERROR=... e exit 1)."""


def out(key, value=""):
    print(f"{key}={value}", flush=True)


# ─────────────────────────────── utilitários ────────────────────────────────

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def file_hash(path):
    """sha256 do arquivo comum (não link); None se não existir."""
    if os.path.islink(path) or not os.path.isfile(path):
        return None
    return sha256(path)


def load_json(path, default=None):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1, sort_keys=False)
        f.write("\n")
    os.replace(tmp, path)


def parse_semver(v):
    m = SEMVER.match((v or "").strip())
    return tuple(int(x) for x in m.groups()) if m else None


def now_iso():
    return datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")


def install_file(src, dest):
    """Copia src → dest de forma atômica (tmp + rename) e copia o modo (bit de execução).
    O rename mantém o arquivo antigo vivo para quem o tem aberto — inclusive este script."""
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = f"{dest}.team-os-tmp.{os.getpid()}"
    shutil.copyfile(src, tmp)
    os.chmod(tmp, os.stat(src).st_mode & 0o777)
    os.replace(tmp, dest)


def allowed_rel(rel):
    """O caminho está dentro do escopo do pack? (protege contra manifest malicioso)"""
    if not rel or rel.startswith("/") or "\\" in rel or "\x00" in rel:
        return False
    parts = rel.split("/")
    if any(p in ("", ".", "..") for p in parts):
        return False
    if rel in DOCS:
        return True
    if rel.startswith(".claude/agents/"):
        return len(parts) == 3 and rel.endswith(".md")
    if rel.startswith(".claude/hooks/"):
        return len(parts) == 3 and rel.endswith(".sh")
    if rel.startswith(".claude/skills/"):
        return len(parts) >= 4 and not rel.startswith(CUSTOM_PRESETS) and not rel.endswith(".new")
    return False


class Trash:
    """Manda para a Lixeira via trash.sh (macOS/Linux). Nunca apaga."""

    def __init__(self, root):
        self.root = root

    def script(self):
        for cand in (os.path.join(self.root, SCRIPTS_REL, "trash.sh"), os.path.join(HERE, "trash.sh")):
            if os.path.isfile(cand):
                return cand
        raise Fail("trash.sh não encontrado — não vou apagar nada sem Lixeira")

    def send(self, *paths):
        paths = [p for p in paths if os.path.lexists(p)]
        if not paths:
            return []
        r = subprocess.run(["bash", self.script(), *paths], capture_output=True, text=True)
        lines = [l for l in r.stdout.splitlines() if l.startswith("TRASH")]
        if r.returncode != 0:
            raise Fail("não consegui mandar para a Lixeira: " + " ; ".join(lines or [r.stderr.strip()]))
        return lines


# ─────────────────────────────── fonte (upstream) ───────────────────────────

def have_git():
    return os.environ.get("TEAM_OS_NO_GIT") != "1" and shutil.which("git") is not None


def git_env():
    env = dict(os.environ)
    env["GIT_TERMINAL_PROMPT"] = "0"
    return env


def github_slug(upstream):
    u = urllib.parse.urlparse(upstream)
    if u.netloc.lower() not in ("github.com", "www.github.com"):
        return None
    parts = [p for p in u.path.split("/") if p]
    if len(parts) < 2:
        return None
    return parts[0], re.sub(r"\.git$", "", parts[1])


def url_read(url, timeout=30):
    req = urllib.request.Request(url, headers={"User-Agent": "team-os-update"})
    with urllib.request.urlopen(req, timeout=timeout) as r:  # noqa: S310 (URL do manifest/flag)
        return r.read()


def list_tags(upstream):
    """Tags semver do upstream, da maior para a menor."""
    tags = []
    if have_git():
        r = subprocess.run(["git", "ls-remote", "--tags", "--refs", upstream],
                           capture_output=True, text=True, env=git_env())
        if r.returncode != 0:
            raise Fail(f"não consegui ler as versões de {upstream} (git ls-remote): {r.stderr.strip()[:200]}")
        for line in r.stdout.splitlines():
            ref = line.split("\t")[-1]
            if ref.startswith("refs/tags/"):
                tags.append(ref[len("refs/tags/"):])
    else:
        url = os.environ.get("TEAM_OS_TAGS_URL")
        if not url:
            slug = github_slug(upstream)
            if not slug:
                raise Fail(f"sem git, só sei consultar versões no GitHub (upstream: {upstream})")
            url = f"https://api.github.com/repos/{slug[0]}/{slug[1]}/tags?per_page=100"
        try:
            data = json.loads(url_read(url).decode("utf-8"))
        except Exception as e:  # rede, JSON
            raise Fail(f"não consegui ler as versões em {url}: {e}")
        tags = [t.get("name", "") for t in data if isinstance(t, dict)]
    tags = [t for t in tags if parse_semver(t)]
    tags.sort(key=parse_semver, reverse=True)
    return tags


def safe_extract(tar_path, dest):
    with tarfile.open(tar_path, "r:*") as tf:
        for m in tf.getmembers():
            name = m.name
            if name.startswith("/") or ".." in name.split("/"):
                raise Fail(f"pacote baixado com caminho perigoso: {name}")
            if m.issym() or m.islnk() or m.isdev():
                continue  # links e devices nunca são extraídos (e o manifest recusa links)
            tf.extract(m, dest)
    tops = [d for d in os.listdir(dest) if not d.startswith(".")]
    if len(tops) == 1 and os.path.isdir(os.path.join(dest, tops[0])):
        return os.path.join(dest, tops[0])
    return dest


def fetch(upstream, tag, workdir):
    """Baixa a versão `tag` para workdir. Devolve (pasta, como)."""
    dest = os.path.join(workdir, "pack")
    if have_git():
        r = subprocess.run(["git", "-c", "advice.detachedHead=false", "clone", "--quiet",
                            "--depth", "1", "--branch", tag, upstream, dest],
                           capture_output=True, text=True, env=git_env())
        if r.returncode != 0:
            raise Fail(f"não consegui baixar {tag} de {upstream}: {r.stderr.strip()[:300]}")
        return dest, "git"
    url = os.environ.get("TEAM_OS_TARBALL_URL", "")
    if url:
        url = url.replace("{tag}", tag)
    else:
        slug = github_slug(upstream)
        if not slug:
            raise Fail(f"sem git, só sei baixar do GitHub (upstream: {upstream})")
        url = f"https://codeload.github.com/{slug[0]}/{slug[1]}/tar.gz/refs/tags/{tag}"
    tgz = os.path.join(workdir, "pack.tar.gz")
    try:
        with open(tgz, "wb") as f:
            f.write(url_read(url, timeout=120))
    except Fail:
        raise
    except Exception as e:
        raise Fail(f"não consegui baixar {url}: {e}")
    os.makedirs(dest)
    return safe_extract(tgz, dest), "tarball"


def verify(src, expect_version=None):
    """Confere o pack baixado: manifest válido, versão certa e sha256 de CADA arquivo."""
    man = load_json(os.path.join(src, "pack-manifest.json"))
    if not isinstance(man, dict) or man.get("name") != "team-os" or not isinstance(man.get("files"), dict):
        raise Fail("o pacote baixado não tem um pack-manifest.json válido do team-os")
    ver = str(man.get("version", ""))
    if not parse_semver(ver) or ver.startswith("v"):
        raise Fail(f"versão inválida no manifest baixado: '{ver}'")
    if expect_version and parse_semver(expect_version) != parse_semver(ver):
        raise Fail(f"o manifest baixado diz versão {ver}, mas a tag pedida é {expect_version}")
    vfile = os.path.join(src, "VERSION")
    if not os.path.isfile(vfile) or open(vfile, encoding="utf-8").read().strip() != ver:
        raise Fail("o arquivo VERSION do pacote não bate com o manifest")
    bad = []
    for rel, h in man["files"].items():
        if not allowed_rel(rel):
            raise Fail(f"o manifest baixado aponta para fora do pack: {rel}")
        p = os.path.join(src, rel)
        if os.path.islink(p):
            raise Fail(f"o pacote baixado tem link simbólico: {rel}")
        if file_hash(p) != h:
            bad.append(rel)
    if bad:
        raise Fail(f"verificação falhou: {len(bad)} arquivo(s) não batem com o sha256 do manifest "
                   f"(ex.: {bad[0]}) — o pacote pode estar adulterado; nada foi aplicado")
    return man


# ─────────────────────────────── estado local ───────────────────────────────

class Local:
    def __init__(self, root):
        self.root = root
        self.state = os.path.join(root, ".team-os")
        self.installed_path = os.path.join(self.state, "installed.json")
        self.backups = os.path.join(self.state, "backups")
        self.removed = os.path.join(self.state, "removed")
        self.report = os.path.join(self.state, "update-report.md")
        self.trash = Trash(root)

    def p(self, rel):
        return os.path.join(self.root, rel)

    def version(self):
        try:
            return open(self.p("VERSION"), encoding="utf-8").read().strip()
        except OSError:
            return ""

    def manifest(self):
        return load_json(self.p("pack-manifest.json"))

    def installed(self):
        return load_json(self.installed_path)

    def baseline(self):
        """Hash de cada arquivo do pack no momento da última instalação/update."""
        inst = self.installed()
        if isinstance(inst, dict) and isinstance(inst.get("files"), dict):
            return dict(inst["files"]), list(inst.get("pending", [])), "installed"
        man = self.manifest()
        if isinstance(man, dict) and isinstance(man.get("files"), dict):
            return dict(man["files"]), [], "manifest"
        return {}, [], "none"

    def upstream(self):
        man = self.manifest() or {}
        return man.get("upstream") or DEFAULT_UPSTREAM

    def new_ts(self, base_dir):
        ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        cand, n = ts, 2
        while os.path.exists(os.path.join(base_dir, cand)):
            cand = f"{ts}-{n:02d}"
            n += 1
        return cand

    def backup_dirs(self):
        if not os.path.isdir(self.backups):
            return []
        return sorted(d for d in os.listdir(self.backups)
                      if os.path.isfile(os.path.join(self.backups, d, "meta.json")))

    def prune_backups(self):
        dirs = self.backup_dirs()
        old = dirs[:-BACKUP_KEEP] if len(dirs) > BACKUP_KEEP else []
        trashed = 0
        for d in old:
            self.trash.send(os.path.join(self.backups, d))
            trashed += 1
        return trashed

    def ensure_gitignore(self):
        gi = self.p(".gitignore")
        if not os.path.isfile(gi):
            return False
        text = open(gi, encoding="utf-8").read()
        if re.search(r"^/?\.team-os/?\s*$", text, re.M):
            return False
        with open(gi, "a", encoding="utf-8") as f:
            if text and not text.endswith("\n"):
                f.write("\n")
            f.write("\n# Estado local do *update (por máquina)\n.team-os/\n")
        return True

    def custom_agents(self):
        adir = self.p(".claude/agents")
        res = []
        if not os.path.isdir(adir):
            return res
        for n in sorted(os.listdir(adir)):
            path = os.path.join(adir, n)
            if not n.endswith(".md") or not os.path.isfile(path):
                continue
            try:
                head = open(path, encoding="utf-8").read(4096)
            except OSError:
                continue
            m = re.match(r"^---\n(.*?)\n---", head, re.S)
            if m and re.search(r"^origin:\s*custom\s*$", m.group(1), re.M):
                res.append(n[:-3])
        return res

    def pending_now(self, files, pending):
        """Conflitos ainda abertos: o .new existe e o arquivo ainda é do pack."""
        return sorted({r for r in pending if r in files and os.path.isfile(self.p(r) + ".new")})


# ─────────────────────────────── classificação ──────────────────────────────

def classify(local, new_files, base):
    """Compara novo manifest × baseline (installed.json) × arquivo no disco."""
    c = {k: [] for k in ("update", "add", "remove", "conflict", "keep_edited", "same", "removed_edited")}
    for rel in sorted(set(new_files) | set(base)):
        cur = file_hash(local.p(rel))
        nh, bh = new_files.get(rel), base.get(rel)
        if nh is not None and bh is not None:
            if nh == bh:  # o pack não mudou este arquivo
                if cur is not None and cur != bh:
                    c["keep_edited"].append(rel)
                else:
                    c["same"].append(rel)
            elif cur == nh:
                c["same"].append(rel)          # já está igual ao novo
            elif cur == bh:
                c["update"].append(rel)        # intocado pelo usuário → substitui
            else:
                c["conflict"].append(rel)      # editado (ou apagado) pelo usuário e mudou no pack
        elif nh is not None:                   # novo no pack
            if cur is None and not os.path.lexists(local.p(rel)):
                c["add"].append(rel)
            elif cur == nh:
                c["same"].append(rel)
            else:
                c["conflict"].append(rel)      # já existe arquivo do usuário com esse nome
        else:                                  # removido do pack
            if os.path.lexists(local.p(rel)):
                c["remove"].append(rel)
                if cur != bh:
                    c["removed_edited"].append(rel)
    return c


def changelog_excerpt(src, cur_ver, new_ver):
    path = os.path.join(src, "CHANGELOG.md")
    if not os.path.isfile(path):
        return "", []
    text = open(path, encoding="utf-8").read()
    lo, hi = parse_semver(cur_ver) or (0, 0, 0), parse_semver(new_ver)
    chunks, versions, keep = [], [], False
    for line in text.splitlines():
        m = re.match(r"^## \[(\d+\.\d+\.\d+)\]", line)
        if m:
            v = parse_semver(m.group(1))
            keep = v is not None and lo < v <= (hi or v)
            if keep:
                versions.append(m.group(1))
        elif line.startswith("## "):
            keep = False
        if keep:
            chunks.append(line)
    return "\n".join(chunks).strip(), versions


# ─────────────────────────────── relatório ──────────────────────────────────

def write_report(local, info, c, ts, audit, ntp, changelog, gitignore):
    L = []
    L.append("# Relatório do update — team-os\n")
    L.append(f"- Data: {now_iso()}")
    L.append(f"- Versão: {info['from']} → {info['to']}")
    L.append(f"- De onde veio: {info['source_desc']} (conferido arquivo por arquivo pelo sha256)")
    L.append(f"- Cópia de segurança dos arquivos trocados: `.team-os/backups/{ts}/`\n")

    def section(title, items, note=""):
        L.append(f"## {title} ({len(items)})\n")
        if note:
            L.append(note + "\n")
        for r in items or ["—"]:
            L.append(f"- `{r}`" if r != "—" else "- nenhum")
        L.append("")

    section("Atualizados", c["update"])
    section("Novos no pack", c["add"])
    section("Saíram do pack", c["remove"],
            f"Não foram apagados: estão guardados em `.team-os/removed/{ts}/`."
            + (" Atenção: você tinha editado " + ", ".join(f"`{r}`" for r in c["removed_edited"]) + "."
               if c["removed_edited"] else ""))
    L.append(f"## Precisa da sua decisão ({len(c['conflict'])})\n")
    if c["conflict"]:
        L.append("Você mudou estes arquivos e o pack também mudou. O seu ficou **intacto**; "
                 "a versão nova está ao lado, com `.new` no fim do nome.\n")
        for r in c["conflict"]:
            L.append(f"- `{r}` → nova versão em `{r}.new`")
        L.append("\nPara decidir, um de cada vez:")
        L.append("- manter o seu: `bash .claude/skills/team-os-creator/scripts/update-pack.sh --resolve <arquivo>=keep`")
        L.append("- usar o novo (o seu vai para a cópia de segurança): `... --resolve <arquivo>=new`\n")
    else:
        L.append("- nada — nenhum arquivo seu bateu de frente com o pack.\n")
    L.append("## O que ficou como estava\n")
    L.append(f"- Arquivos do pack que você editou e o pack não mudou: {len(c['keep_edited'])} (mantidos)")
    L.append(f"- Seus agentes próprios (`origin: custom`): {ntp['total']} — bloco Native Teams Protocol "
             f"atualizado em {ntp['changed']}; o resto de cada arquivo não foi tocado")
    L.append("- Tudo que não é do pack (seus agentes, skills, presets em `presets/custom/`, smart-memory) não foi tocado")
    if gitignore:
        L.append("- `.gitignore` ganhou a linha `.team-os/` (estado local do update)")
    L.append("")
    L.append("## Verificação dos agentes (*audit)\n")
    L.append(f"- {audit['summary']}\n")
    L.append("## Se quiser desfazer\n")
    L.append("`bash .claude/skills/team-os-creator/scripts/update-pack.sh --undo` — volta os arquivos trocados "
             "e manda os novos para a Lixeira.\n")
    if changelog:
        L.append("## Novidades desta versão (CHANGELOG)\n")
        L.append(changelog)
        L.append("")
    os.makedirs(local.state, exist_ok=True)
    with open(local.report, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")


# ─────────────────────────────── modos ──────────────────────────────────────

def resolve_source(local, args, workdir):
    """Descobre e obtém a versão alvo. Devolve dict com src, to, source_desc, kind."""
    if args.from_dir:
        src = os.path.abspath(args.from_dir)
        if not os.path.isdir(src):
            raise Fail(f"--from: pasta não existe: {src}")
        man = load_json(os.path.join(src, "pack-manifest.json")) or {}
        return {"src": src, "to": str(man.get("version", "")), "source_desc": f"pasta local {src}",
                "kind": "dir", "tag": None}
    upstream = args.upstream or local.upstream()
    if args.to:
        tag = args.to if args.to.startswith("v") else "v" + args.to
        if not parse_semver(tag):
            raise Fail(f"--to inválido: {args.to} (use vX.Y.Z)")
    else:
        tags = list_tags(upstream)
        if not tags:
            raise Fail(f"nenhuma versão (tag vX.Y.Z) encontrada em {upstream}")
        tag = tags[0]
    return {"src": None, "to": tag.lstrip("v"), "tag": tag, "upstream": upstream,
            "source_desc": f"{upstream} (tag {tag})", "kind": "remote"}


def materialize(info, workdir):
    if info["src"] is None:
        src, how = fetch(info["upstream"], info["tag"], workdir)
        info["src"], info["kind"] = src, how
        info["source_desc"] += f" via {how}"
    man = verify(info["src"], info.get("tag"))
    info["to"] = man["version"]
    return man


def print_classification(c):
    out("FILES_UPDATE", len(c["update"]))
    out("FILES_ADD", len(c["add"]))
    out("FILES_REMOVE", len(c["remove"]))
    out("FILES_CONFLICT", len(c["conflict"]))
    out("FILES_KEEP_EDITED", len(c["keep_edited"]))
    for r in c["update"]:
        out("UPDATE", r)
    for r in c["add"]:
        out("ADD", r)
    for r in c["remove"]:
        out("REMOVE", r)
    for r in c["removed_edited"]:
        out("REMOVE_EDITED", r)
    for r in c["conflict"]:
        out("CONFLICT", r)
    for r in c["keep_edited"]:
        out("KEEP_EDITED", r)


def mode_check_or_apply(local, args):
    cur_ver = local.version()
    base, pending, base_src = local.baseline()
    out("CURRENT_VERSION", cur_ver or "?")
    out("BASELINE", base_src)
    workdir = tempfile.mkdtemp(prefix="team-os-update.")
    try:
        info = resolve_source(local, args, workdir)
        info["from"] = cur_ver or "?"
        out("SOURCE", info["source_desc"])
        target = info["to"]
        if info["kind"] == "remote" and not args.to and parse_semver(target) and parse_semver(cur_ver) \
                and parse_semver(target) <= parse_semver(cur_ver):
            out("LATEST_VERSION", target)
            out("UPDATE_AVAILABLE", 0)
            out("STATUS", "em dia")
            return finish_pending(local, base, pending)
        man = materialize(info, workdir)
        new_files = man["files"]
        out("SOURCE_KIND", info["kind"])
        out("LATEST_VERSION", info["to"])
        out("VERIFY", "ok")
        cv, tv = parse_semver(cur_ver), parse_semver(info["to"])
        out("UPDATE_AVAILABLE", 1 if (cv is None or tv > cv) else 0)
        if cv and tv < cv:
            out("DOWNGRADE", 1)
        c = classify(local, new_files, base)
        print_classification(c)
        excerpt, versions = changelog_excerpt(info["src"], cur_ver, info["to"])
        out("CHANGELOG_VERSIONS", ",".join(versions))
        if excerpt:
            cl = os.path.join(tempfile.gettempdir(), f"team-os-update-changelog-{info['to']}.md")
            with open(cl, "w", encoding="utf-8") as f:
                f.write(excerpt + "\n")
            out("CHANGELOG_FILE", cl)
        nothing = not (c["update"] or c["add"] or c["remove"] or c["conflict"])
        if args.mode != "apply":
            out("MODE", "check")
            return finish_pending(local, base, pending)
        if nothing and cur_ver == info["to"] and base_src == "installed":
            out("APPLIED", 0)
            out("STATUS", "nada a aplicar")
            return finish_pending(local, base, pending)
        confirm(args, cur_ver, info["to"], c)
        return apply(local, info, man, c, base, pending, excerpt)
    finally:
        shutil.rmtree(workdir, ignore_errors=True)  # só a pasta temporária criada aqui


def confirm(args, cur, to, c):
    if args.yes:
        return
    if not sys.stdin.isatty():
        raise Fail("--apply precisa de confirmação: rode de novo com --yes")
    msg = (f"Atualizar team-os {cur} → {to}: {len(c['update'])} atualizado(s), {len(c['add'])} novo(s), "
           f"{len(c['remove'])} removido(s), {len(c['conflict'])} para você decidir. Aplicar? [s/N] ")
    if input(msg).strip().lower() not in ("s", "sim", "y", "yes"):
        raise Fail("cancelado pelo usuário — nada foi alterado")


def apply(local, info, man, c, base, pending, excerpt):
    src, new_files = info["src"], man["files"]
    os.makedirs(local.backups, exist_ok=True)
    ts = local.new_ts(local.backups)
    bdir = os.path.join(local.backups, ts)
    bfiles = os.path.join(bdir, "files")
    os.makedirs(bfiles)
    meta = {"kind": "update", "ts": ts, "from_version": info["from"], "to_version": info["to"],
            "replaced": [], "added": [], "removed": [], "new_files": [], "renew": [],
            "installed_before": local.installed(), "manifest_before": False}
    # cópia do manifest e do installed.json de antes
    if os.path.isfile(local.p("pack-manifest.json")):
        shutil.copy2(local.p("pack-manifest.json"), os.path.join(bdir, "pack-manifest.json"))
        meta["manifest_before"] = True
    write_json(os.path.join(bdir, "meta.json"), meta)  # grava cedo: um --undo funciona mesmo após falha
    changed = []
    try:
        for rel in c["update"]:
            dst = os.path.join(bfiles, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(local.p(rel), dst)
            meta["replaced"].append(rel)
            install_file(os.path.join(src, rel), local.p(rel))
            changed.append(rel)
        for rel in c["add"]:
            install_file(os.path.join(src, rel), local.p(rel))
            meta["added"].append(rel)
            changed.append(rel)
        for rel in c["conflict"]:
            install_file(os.path.join(src, rel), local.p(rel) + ".new")
            meta["new_files"].append(rel + ".new")
            changed.append(rel + ".new")
        for rel in c["remove"]:
            dst = os.path.join(local.removed, ts, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(local.p(rel), dst)
            meta["removed"].append(rel)
            changed.append(rel)
        install_file(os.path.join(src, "pack-manifest.json"), local.p("pack-manifest.json"))

        # installed.json: conflito mantém o hash INSTALADO antigo (continua "editado")
        files = {}
        conflicts = set(c["conflict"])
        for rel, h in new_files.items():
            if rel in conflicts:
                if rel in base:
                    files[rel] = base[rel]
            else:
                files[rel] = h
        still = local.pending_now(new_files, set(pending) | conflicts)
        write_json(local.installed_path, {"name": "team-os", "version": info["to"], "updated": now_iso(),
                                          "files": dict(sorted(files.items())), "pending": still})
    finally:
        write_json(os.path.join(bdir, "meta.json"), meta)

    # agentes próprios: reinjeta SÓ o bloco Native Teams Protocol canônico (com cópia antes)
    ntp = {"total": 0, "changed": 0}
    customs = local.custom_agents()
    ntp["total"] = len(customs)
    migrate = local.p(os.path.join(SCRIPTS_REL, "migrate-ntp.sh"))
    if customs and os.path.isfile(migrate) and os.path.isfile(local.p(NTP_REL)):
        before = {}
        for n in customs:
            rel = f".claude/agents/{n}.md"
            before[rel] = file_hash(local.p(rel))
            dst = os.path.join(bfiles, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(local.p(rel), dst)
        r = subprocess.run(["bash", migrate, "--dir", local.p(".claude/agents"),
                            "--canonical", local.p(NTP_REL), *customs],
                           capture_output=True, text=True, cwd=local.root)
        for rel, h in before.items():
            if file_hash(local.p(rel)) != h:
                meta["replaced"].append(rel)
                changed.append(rel)
                ntp["changed"] += 1
            else:
                os.remove(os.path.join(bfiles, rel))  # cópia temporária desnecessária (nossa, dentro do backup)
        if r.returncode != 0:
            last = (r.stdout.strip().splitlines() or [r.stderr.strip()])[-1]
            out("WARNING", f"migrate-ntp.sh falhou em algum agente próprio: {last}")
        write_json(os.path.join(bdir, "meta.json"), meta)
    out("CUSTOM_AGENTS", ntp["total"])
    out("NTP_REINJECTED", ntp["changed"])

    gitignore = local.ensure_gitignore()
    if gitignore:
        out("GITIGNORE_UPDATED", 1)
    trashed = local.prune_backups()
    if trashed:
        out("BACKUPS_TRASHED", trashed)

    audit = run_audit(local)
    out("AUDIT", audit["status"])
    out("AUDIT_SUMMARY", audit["summary"])
    write_report(local, info, c, ts, audit, ntp, excerpt, gitignore)

    out("APPLIED", 1)
    out("NEW_VERSION", info["to"])
    out("BACKUP", f".team-os/backups/{ts}")
    out("REPORT", ".team-os/update-report.md")
    out("CHANGED_FILES", len(changed))
    for rel in changed:
        out("CHANGED", rel)
    inst = local.installed() or {}
    pend = inst.get("pending", [])
    out("PENDING", len(pend))
    return 2 if pend else 0


def run_audit(local):
    va = local.p(os.path.join(SCRIPTS_REL, "validate-agent.sh"))
    if not os.path.isfile(va):
        return {"status": "skipped", "summary": "validate-agent.sh não encontrado"}
    r = subprocess.run(["bash", va], capture_output=True, text=True, cwd=local.root)
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    summary = lines[-1] if lines else "(sem saída)"
    return {"status": "ok" if r.returncode == 0 else "fail", "summary": summary}


def finish_pending(local, base, pending):
    still = local.pending_now(base, pending)
    out("PENDING", len(still))
    for r in still:
        out("PENDING_FILE", r)
    return 2 if still else 0


def mode_status(local):
    inst = local.installed()
    base, pending, src = local.baseline()
    out("VERSION", local.version() or "?")
    out("INSTALLED_VERSION", (inst or {}).get("version", "") if inst else "")
    out("BASELINE", src)
    out("UPSTREAM", local.upstream())
    edited = sorted(r for r, h in base.items() if os.path.lexists(local.p(r)) and file_hash(local.p(r)) != h)
    out("EDITED", len(edited))
    for r in edited:
        out("EDITED_FILE", r)
    out("CUSTOM_AGENTS", len(local.custom_agents()))
    b = local.backup_dirs()
    out("BACKUPS", len(b))
    if b:
        out("LAST_BACKUP", f".team-os/backups/{b[-1]}")
    return finish_pending(local, base, pending)


def mode_resolve(local, items):
    inst = local.installed()
    if not isinstance(inst, dict) or not isinstance(inst.get("files"), dict):
        base, pending, _ = local.baseline()
        inst = {"name": "team-os", "version": local.version(), "files": base, "pending": pending}
    man = local.manifest() or {}
    pack_files = man.get("files", {})
    rc = 0
    for item in items:
        if "=" not in item:
            raise Fail(f"--resolve espera <arquivo>=keep|new (recebi: {item})")
        rel, choice = item.rsplit("=", 1)
        rel = rel.strip()
        if rel.startswith("./"):
            rel = rel[2:]
        if rel.endswith(".new"):
            rel = rel[:-4]
        choice = choice.strip().lower()
        if choice not in ("keep", "new"):
            raise Fail(f"--resolve: escolha '{choice}' inválida (use keep ou new)")
        if not allowed_rel(rel):
            raise Fail(f"--resolve: {rel} não é um arquivo do pack")
        newp = local.p(rel) + ".new"
        if not os.path.isfile(newp):
            raise Fail(f"--resolve: não há versão nova pendente para {rel} ({rel}.new não existe)")
        if choice == "keep":
            h = file_hash(newp)
            local.trash.send(newp)
            inst["files"][rel] = pack_files.get(rel, h)
            out("RESOLVED", f"{rel}|keep")
        else:
            os.makedirs(local.backups, exist_ok=True)
            ts = local.new_ts(local.backups)
            bdir = os.path.join(local.backups, ts)
            os.makedirs(os.path.join(bdir, "files"))
            meta = {"kind": "resolve", "ts": ts, "from_version": local.version(), "to_version": local.version(),
                    "replaced": [], "added": [], "removed": [], "new_files": [], "renew": [rel],
                    "installed_before": local.installed(), "manifest_before": False}
            if os.path.isfile(local.p(rel)):
                dst = os.path.join(bdir, "files", rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy2(local.p(rel), dst)
                meta["replaced"].append(rel)
            else:
                meta["added"].append(rel)
            write_json(os.path.join(bdir, "meta.json"), meta)
            os.replace(newp, local.p(rel))
            inst["files"][rel] = file_hash(local.p(rel))
            out("RESOLVED", f"{rel}|new")
            out("BACKUP", f".team-os/backups/{ts}")
        inst["pending"] = [r for r in inst.get("pending", []) if r != rel]
        inst["files"] = dict(sorted(inst["files"].items()))
        write_json(local.installed_path, inst)
    trashed = local.prune_backups()
    if trashed:
        out("BACKUPS_TRASHED", trashed)
    still = local.pending_now(inst["files"] if inst.get("files") else {}, inst.get("pending", []))
    out("PENDING", len(still))
    for r in still:
        out("PENDING_FILE", r)
    return 2 if still else rc


def mode_undo(local):
    dirs = local.backup_dirs()
    if not dirs:
        raise Fail("não há cópia de segurança para desfazer (.team-os/backups/ vazio)")
    ts = dirs[-1]
    bdir = os.path.join(local.backups, ts)
    meta = load_json(os.path.join(bdir, "meta.json"))
    if not isinstance(meta, dict):
        raise Fail(f"cópia de segurança {ts} sem meta.json legível")
    restored, trashed, back = 0, 0, 0
    warnings = []
    for rel in meta.get("renew", []):  # desfazer um --resolve new: o novo volta a ser .new
        if os.path.isfile(local.p(rel)):
            install_file(local.p(rel), local.p(rel) + ".new")
    for rel in meta.get("replaced", []):
        b = os.path.join(bdir, "files", rel)
        if os.path.isfile(b):
            install_file(b, local.p(rel))
            restored += 1
    for rel in meta.get("added", []) + meta.get("new_files", []):
        if os.path.lexists(local.p(rel)):
            local.trash.send(local.p(rel))
            trashed += 1
    rdir = os.path.join(local.removed, ts)
    for rel in meta.get("removed", []):
        src = os.path.join(rdir, rel)
        if not os.path.exists(src):
            continue
        if os.path.lexists(local.p(rel)):
            warnings.append(f"{rel} já existe — a cópia removida ficou em .team-os/removed/{ts}/")
            continue
        os.makedirs(os.path.dirname(local.p(rel)), exist_ok=True)
        shutil.move(src, local.p(rel))
        back += 1
    if meta.get("kind") == "update":
        bman = os.path.join(bdir, "pack-manifest.json")
        if meta.get("manifest_before") and os.path.isfile(bman):
            install_file(bman, local.p("pack-manifest.json"))
        elif os.path.isfile(local.p("pack-manifest.json")):
            local.trash.send(local.p("pack-manifest.json"))
    before = meta.get("installed_before")
    if isinstance(before, dict):
        write_json(local.installed_path, before)
    elif os.path.isfile(local.installed_path):
        local.trash.send(local.installed_path)
    local.trash.send(bdir)
    if os.path.isdir(rdir):
        local.trash.send(rdir)
    out("UNDONE", ts)
    out("UNDO_KIND", meta.get("kind", "?"))
    out("VERSION", local.version() or "?")
    out("RESTORED", restored)
    out("TRASHED", trashed)
    out("RESTORED_REMOVED", back)
    for w in warnings:
        out("WARNING", w)
    return 0


# ─────────────────────────────── main ───────────────────────────────────────

def main(argv):
    ap = argparse.ArgumentParser(prog="update-pack.sh", add_help=True,
                                 description="Atualiza o pack team-os sem perder o que você criou ou editou.")
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--check", dest="mode", action="store_const", const="check")
    g.add_argument("--apply", dest="mode", action="store_const", const="apply")
    g.add_argument("--undo", dest="mode", action="store_const", const="undo")
    g.add_argument("--status", dest="mode", action="store_const", const="status")
    ap.add_argument("--resolve", action="append", default=[], metavar="ARQUIVO=keep|new")
    ap.add_argument("--yes", action="store_true")
    ap.add_argument("--from", dest="from_dir")
    ap.add_argument("--to")
    ap.add_argument("--upstream")
    ap.add_argument("--root", default=os.environ.get("TEAM_OS_ROOT", DEFAULT_ROOT))
    ap.add_argument("--allow-maintainer", action="store_true")
    args = ap.parse_args(argv)
    if args.resolve:
        if args.mode not in (None,):
            raise Fail("--resolve não combina com --check/--apply/--undo/--status")
        args.mode = "resolve"
    args.mode = args.mode or "check"

    root = os.path.abspath(args.root)
    if not os.path.isdir(os.path.join(root, ".claude", "skills", "team-os-creator")):
        raise Fail(f"{root} não parece a pasta do team-os (falta .claude/skills/team-os-creator)")
    local = Local(root)
    out("ROOT", root)
    if args.mode in ("apply", "undo", "resolve") and os.path.isfile(local.p(".team-os-maintainer")) \
            and not args.allow_maintainer:
        raise Fail("esta é a pasta do mantenedor (.team-os-maintainer): o *update é para quem usa o pack. "
                   "Use --allow-maintainer se for mesmo intencional")
    if args.mode == "status":
        return mode_status(local)
    if args.mode == "undo":
        return mode_undo(local)
    if args.mode == "resolve":
        return mode_resolve(local, args.resolve)
    return mode_check_or_apply(local, args)


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Fail as e:
        out("ERROR", str(e))
        sys.exit(1)
    except KeyboardInterrupt:
        out("ERROR", "interrompido")
        sys.exit(1)
