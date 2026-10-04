#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""propagate-sync.py — grava agentes, skills e hooks num projeto destino SEM perder o que o
usuário editou lá. Chamado pelo install-to-project.sh (*install / *propagate); o modo `drift`
é usado pelo scan-ct-projects.sh.

Estado do destino: <destino>/.team-os/installed.json — mesmo formato do *update do CT:
  {"name": "team-os", "version": "X.Y.Z", "updated": "<iso>",
   "files": {"<caminho relativo>": "<sha256 do que o CT gravou>"}, "pending": [...]}

Decisão por arquivo (fonte = CT · registrado = installed.json · atual = disco do destino):
  não existe no destino ............................ copia
  atual == fonte ................................... nada a fazer
  sem installed.json (instalação antiga) ........... sobrescreve (como antes) e grava a base
  atual == registrado (usuário não mexeu) .......... atualiza
  usuário mexeu, fonte == registrado (CT não mudou)  mantém o do usuário (CUSTOMIZED)
  usuário mexeu E o CT mudou ....................... CONFLITO:
      --on-conflict keep (padrão, sem decisão) ... mantém o do usuário, grava <arquivo>.new ao lado
      --on-conflict keep --decided ............... decisão "manter o meu": .new vai à Lixeira e a
                                                   versão atual do CT fica registrada como vista
      --on-conflict new .......................... usa o novo; o do usuário vai para
                                                   .team-os/backups/<data>/ (guarda os 3 últimos)
Arquivo de skill que saiu do CT: se o usuário não mexeu, vai para .team-os/removed/<data>/;
se mexeu, fica e deixa de ser do pack. Arquivo que o usuário criou no destino nunca é tocado.
Nada é apagado: o que sai vai para a Lixeira (trash.sh).

Uso (sync):  propagate-sync.py sync --target <dir> --plan <tsv> --results <arquivo>
                 --version <X.Y.Z> [--dry-run] [--on-conflict keep|new] [--decided]
                 [--only a,b] [--trash <trash.sh>]
   plano: uma linha por item, TAB: <agent|skill|hook>\t<nome>\t<caminho na fonte>
Uso (drift): propagate-sync.py drift --source <CT> --target <dir>
"""
import argparse
import datetime
import hashlib
import json
import os
import shutil
import subprocess
import sys

STATE = ".team-os"
BACKUP_KEEP = 3
# Lixo que nunca viaja (mesma lista do SYNC_EXCLUDES do install-to-project.sh)
SKIP_DIRS = {".venv", "ms-playwright", "__pycache__"}
SKIP_FILES = {".DS_Store", "runtime-state.json"}
HERE = os.path.dirname(os.path.abspath(__file__))


def out(key, value=""):
    print(f"{key}={value}", flush=True)


def sha256(path):
    if os.path.islink(path) or not os.path.isfile(path):
        return None
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def junk(name):
    return (name in SKIP_FILES or name.endswith(".pyc") or name.endswith(".new")
            or ".team-os-tmp." in name or name == "Icon\r")


def skill_files(src):
    """Arquivos de uma skill na fonte → lista de caminhos relativos à pasta da skill."""
    res = []
    for d, dirs, files in os.walk(src):
        dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS and not os.path.islink(os.path.join(d, x)))
        for n in sorted(files):
            p = os.path.join(d, n)
            if junk(n) or os.path.islink(p) or not os.path.isfile(p):
                continue
            res.append(os.path.relpath(p, src).replace(os.sep, "/"))
    return res


def load_json(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


def write_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f"{path}.tmp.{os.getpid()}"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
        f.write("\n")
    os.replace(tmp, path)


def install_file(src, dest, exe=False):
    """Cópia atômica (tmp + rename) preservando o modo; exe=True garante o bit de execução."""
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    tmp = f"{dest}.team-os-tmp.{os.getpid()}"
    shutil.copyfile(src, tmp)
    mode = os.stat(src).st_mode & 0o777
    if exe:
        mode |= 0o111
    os.chmod(tmp, mode)
    os.replace(tmp, dest)


def now_iso():
    return datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")


class Trash:
    def __init__(self, script):
        self.script = script

    def send(self, *paths):
        paths = [p for p in paths if os.path.lexists(p)]
        if not paths:
            return
        if not self.script or not os.path.isfile(self.script):
            raise SystemExit("ERROR=trash.sh não encontrado — não vou apagar nada sem Lixeira")
        r = subprocess.run(["bash", self.script, *paths], capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit("ERROR=não consegui mandar para a Lixeira: " + (r.stdout + r.stderr).strip()[:300])


# ─────────────────────────────────── sync ───────────────────────────────────

class Sync:
    def __init__(self, a):
        self.a = a
        self.target = os.path.abspath(a.target)
        self.state = os.path.join(self.target, STATE)
        self.inst_path = os.path.join(self.state, "installed.json")
        self.dry = a.dry_run
        self.trash = Trash(a.trash or os.path.join(HERE, "trash.sh"))
        inst = load_json(self.inst_path)
        self.has_base = isinstance(inst, dict) and isinstance(inst.get("files"), dict)
        self.base = dict(inst["files"]) if self.has_base else {}
        self.old_pending = list(inst.get("pending", [])) if self.has_base else []
        self.files = dict(self.base)
        self.only = {x.strip() for x in (a.only or "").split(",") if x.strip()}
        self.ts = None
        self.c = {k: [] for k in ("added", "updated", "conflict", "customized", "replaced", "kept",
                                  "removed", "orphaned", "newfile")}
        self.touched = set()   # caminhos tratados nesta execução (para limpar pendências)

    def p(self, rel):
        return os.path.join(self.target, rel)

    def stamp(self):
        if self.ts is None:
            self.ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
            n = 2
            while (os.path.exists(os.path.join(self.state, "backups", self.ts))
                   or os.path.exists(os.path.join(self.state, "removed", self.ts))):
                self.ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S") + f"-{n:02d}"
                n += 1
        return self.ts

    def trash_new(self, rel):
        nf = self.p(rel) + ".new"
        if os.path.lexists(nf) and not self.dry:
            self.trash.send(nf)

    def handle(self, src, rel, exe=False):
        """Decide e (fora do dry-run) grava um arquivo. Devolve True se o destino mudou."""
        self.touched.add(rel)
        sh, dst = sha256(src), self.p(rel)
        th = sha256(dst)
        if th is None and not os.path.lexists(dst):
            if not self.dry:
                install_file(src, dst, exe)
            self.files[rel] = sh
            self.c["added"].append(rel)
            return True
        if th == sh:
            self.files[rel] = sh
            nf = dst + ".new"
            if not self.dry and os.path.isfile(nf) and sha256(nf) == sh:
                self.trash.send(nf)   # .new antigo idêntico ao que já está no lugar: sobra
            if exe and not self.dry and not os.access(dst, os.X_OK):
                os.chmod(dst, os.stat(dst).st_mode | 0o111)
            return False
        bh = self.base.get(rel)
        if not self.has_base or (bh is not None and th == bh):
            # instalação antiga (sem base) ou o usuário não mexeu: atualiza
            if not self.dry:
                install_file(src, dst, exe)
            self.files[rel] = sh
            self.c["updated"].append(rel)
            return True
        if bh is not None and sh == bh:
            self.c["customized"].append(rel)   # editado lá; o CT não mudou → mantém, sem barulho
            return False
        # conflito: usuário mexeu (ou o arquivo é dele com o mesmo nome) e o CT mudou
        mode = self.a.on_conflict
        if mode == "new":
            if not self.dry:
                bk = os.path.join(self.state, "backups", self.stamp(), rel)
                os.makedirs(os.path.dirname(bk), exist_ok=True)
                shutil.copy2(dst, bk)
                install_file(src, dst, exe)
                self.trash_new(rel)
            self.files[rel] = sh
            self.c["replaced"].append(rel)
            return True
        if self.a.decided:
            # "manter o meu" decidido: a versão atual do CT fica registrada como vista
            self.trash_new(rel)
            self.files[rel] = sh
            self.c["kept"].append(rel)
            return False
        nf = dst + ".new"
        if not self.dry and sha256(nf) != sh:
            install_file(src, nf, False)
            self.c["newfile"].append(rel + ".new")
        if bh is None:
            self.files.pop(rel, None)
        self.c["conflict"].append(rel)
        return False

    def removed_skill_files(self, name, src_rels):
        """Arquivos que o CT gravou nesta skill e que saíram da fonte."""
        prefix = f".claude/skills/{name}/"
        changed = False
        for rel in sorted(k for k in self.base if k.startswith(prefix)):
            if rel in src_rels:
                continue
            self.touched.add(rel)
            dst = self.p(rel)
            th = sha256(dst)
            if th is not None and th == self.base[rel]:
                if not self.dry:
                    mv = os.path.join(self.state, "removed", self.stamp(), rel)
                    os.makedirs(os.path.dirname(mv), exist_ok=True)
                    shutil.move(dst, mv)
                self.c["removed"].append(rel)
                changed = True
            elif th is not None:
                self.c["orphaned"].append(rel)   # editado pelo usuário: fica, agora é dele
            self.files.pop(rel, None)
        return changed

    def run(self):
        items = []
        with open(self.a.plan, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if not line:
                    continue
                kind, name, src = line.split("\t", 2)
                items.append((kind, name, src))
        results = []
        for kind, name, src in items:
            if self.only and name not in self.only and name.rsplit(".sh", 1)[0] not in self.only:
                results.append((kind, name, "only-skipped"))
                continue
            if kind == "agent":
                rel = f".claude/agents/{name}.md"
                existed = os.path.lexists(self.p(rel))
                changed = self.handle(src, rel)
            elif kind == "hook":
                rel = f".claude/hooks/{name}"
                existed = os.path.lexists(self.p(rel))
                changed = self.handle(src, rel, exe=True)
            else:
                droot = self.p(f".claude/skills/{name}")
                existed = os.path.isdir(droot)
                rels = skill_files(src)
                full = {f".claude/skills/{name}/{r}" for r in rels}
                changed = False
                for r in rels:
                    if self.handle(os.path.join(src, r), f".claude/skills/{name}/{r}"):
                        changed = True
                if self.removed_skill_files(name, full):
                    changed = True
            status = "copied" if not existed else ("updated" if changed else "skipped")
            results.append((kind, name, status))

        with open(self.a.results, "w", encoding="utf-8") as f:
            for kind, name, status in results:
                f.write(f"{kind}\t{name}\t{status}\n")

        c = self.c
        pending = set(p for p in self.old_pending if p not in self.touched) | set(c["conflict"])
        if not self.dry:
            pending = {p for p in pending if os.path.isfile(self.p(p) + ".new")}
        out("PACK_VERSION", self.a.version)
        out("CHANGED_FILES", len(c["added"]) + len(c["updated"]) + len(c["replaced"]) + len(c["removed"]))
        out("CONFLICT_FILES", len(c["conflict"]))
        for rel in c["conflict"]:
            out("CONFLICT", rel)
        for key, label in (("customized", "CUSTOMIZED"), ("replaced", "REPLACED"), ("kept", "KEPT"),
                           ("removed", "REMOVED"), ("orphaned", "ORPHANED")):
            if c[key]:
                out(f"{label}_FILES", len(c[key]))
                for rel in c[key]:
                    out(label, rel)
        if self.ts and c["replaced"] and not self.dry:
            out("CONFLICT_BACKUP", f"{STATE}/backups/{self.ts}")
        if self.dry:
            out("BASELINE", "found" if self.has_base else "missing (será criada)")
            out("INSTALLED_JSON", "dry-run (nada gravado)")
            return 0
        write_json(self.inst_path, {"name": "team-os", "version": self.a.version, "updated": now_iso(),
                                    "files": dict(sorted(self.files.items())),
                                    "pending": sorted(pending)})
        if not self.has_base:
            out("BASELINE_CREATED", 1)
        out("INSTALLED_JSON", f"{STATE}/installed.json")
        out("PENDING", len(pending))
        self.prune_backups()
        return 0

    def prune_backups(self):
        bdir = os.path.join(self.state, "backups")
        if not os.path.isdir(bdir):
            return
        dirs = sorted(d for d in os.listdir(bdir) if os.path.isdir(os.path.join(bdir, d)))
        old = dirs[:-BACKUP_KEEP] if len(dirs) > BACKUP_KEEP else []
        for d in old:
            self.trash.send(os.path.join(bdir, d))
        if old:
            out("CONFLICT_BACKUPS_TRASHED", len(old))


# ─────────────────────────────────── drift ──────────────────────────────────

def drift(a):
    """Drift do destino vs CT levando em conta o que o usuário editou (installed.json)."""
    src, tgt = os.path.abspath(a.source), os.path.abspath(a.target)
    inst = load_json(os.path.join(tgt, STATE, "installed.json"))
    base = inst.get("files", {}) if isinstance(inst, dict) and isinstance(inst.get("files"), dict) else None

    def classify(srcf, rel):
        sh, th = sha256(srcf), sha256(os.path.join(tgt, rel))
        if th is None:
            return "missing"
        if th == sh:
            return "ok"
        if base is None:
            return "outdated"
        bh = base.get(rel)
        if bh is not None and th == bh:
            return "outdated"
        if bh is not None and sh == bh:
            return "customized"
        return "conflict"

    ag = {"ok": 0, "outdated": 0, "customized": 0, "conflict": 0}
    adir = os.path.join(tgt, ".claude", "agents")
    for n in sorted(os.listdir(adir)) if os.path.isdir(adir) else []:
        sf = os.path.join(src, ".claude", "agents", n)
        if not n.endswith(".md") or not os.path.isfile(sf):
            continue
        ag[classify(sf, f".claude/agents/{n}")] += 1
    sk_out = sk_conf = 0
    sdir = os.path.join(tgt, ".claude", "skills")
    for n in sorted(os.listdir(sdir)) if os.path.isdir(sdir) else []:
        ss = os.path.join(src, ".claude", "skills", n)
        if n == "team-os-creator" or not os.path.isdir(ss) or not os.path.isdir(os.path.join(sdir, n)):
            continue
        states = {classify(os.path.join(ss, r), f".claude/skills/{n}/{r}") for r in skill_files(ss)}
        if base is not None:   # arquivo que o CT gravou, o usuário não mexeu e saiu da fonte
            srcset = {f".claude/skills/{n}/{r}" for r in skill_files(ss)}
            for rel, bh in base.items():
                if rel.startswith(f".claude/skills/{n}/") and rel not in srcset \
                        and sha256(os.path.join(tgt, rel)) == bh:
                    states.add("outdated")
        if states & {"outdated", "missing"}:
            sk_out += 1
        elif "conflict" in states:
            sk_conf += 1
    print(f"DRIFT_OK={ag['ok'] + ag['customized']}\tDRIFT_OUTDATED={ag['outdated']}\t"
          f"DRIFT_CUSTOMIZED={ag['customized']}\tDRIFT_CONFLICT={ag['conflict']}\t"
          f"SKILLS_OUTDATED={sk_out}\tSKILLS_CONFLICT={sk_conf}")
    return 0


def main(argv):
    ap = argparse.ArgumentParser(prog="propagate-sync.py")
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sync")
    s.add_argument("--target", required=True)
    s.add_argument("--plan", required=True)
    s.add_argument("--results", required=True)
    s.add_argument("--version", default="")
    s.add_argument("--dry-run", action="store_true")
    s.add_argument("--on-conflict", choices=("keep", "new"), default="keep")
    s.add_argument("--decided", action="store_true")
    s.add_argument("--only", default="")
    s.add_argument("--trash", default="")
    d = sub.add_parser("drift")
    d.add_argument("--source", required=True)
    d.add_argument("--target", required=True)
    a = ap.parse_args(argv)
    if a.cmd == "drift":
        return drift(a)
    return Sync(a).run()


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
