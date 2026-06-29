# hooks/lib/witness_overlay.py
# Overlay binding (A5/A6) + deterministic model resolution for the
# gate-as-signer dispatch witness (PR #15, task-009).
#
# Two responsibilities, used IDENTICALLY by the PreToolUse gate
# (hooks/validate-dispatch-pre.sh) and read-consistently by the orchestrator
# ritual / PostToolUse audit:
#
#   1. recompute_overlay_digest(override_path, short)  -- REQ-031 (A5)
#        overlay_digest is the sha256 of the RAW, LF-normalized `.toml` file
#        bytes (NOT the rendered Markdown block — no renderer coupling). The
#        file is read ONCE and the held bytes are hashed (no second read, so
#        the gate has no read-vs-hash TOCTOU). The lookup directory is the
#        persisted `override_path` (REQ-032/A6) confined to a configured
#        allowlist (default `customization/`) within the project root, and the
#        `<short>` name carries the path-traversal guard (REQ-038: reject
#        `/`, `\`, `..`). A path escaping the allowlist -> DENY (a forged
#        override_path cannot redirect the hash target outside the repo).
#        Boundary cases (REQ-031 step 3):
#          * overlay_source == "toml" but the `.toml` is ABSENT at intercept
#            -> OVERLAY_MISMATCH (NOT a crash / GATE_ERROR);
#          * a `.toml` legitimately edited between claim-write and intercept
#            -> recomputed digest != claimed -> OVERLAY_MISMATCH (real
#            detection; AGENT_FLOW_STRICT_DISPATCH=0 is the rollout mitigation).
#
#   2. resolve_model(override_path, short, frontmatter_model, claim_model) -- REQ-048
#        Deterministic precedence, IDENTICAL on orchestrator and gate so the
#        `model` field can never false-DENY a correctly-behaving dispatch:
#          (1) the overlay TOML top-level `model =` scalar at
#              override_path/<short>.toml, parsed by REUSING the SAME TOML
#              parser the SINGLE injector parser uses
#              (skills/setup-agents/lib/toml-merge.sh resolve_overlay ->
#              parse_toml_overlay -> tomllib/tomli) -- NEVER a naive
#              `grep '^model ='` line-scan (which diverges from a real TOML
#              parse on `model = "x"  # comment` or `[table]`-scoped keys,
#              re-introducing the very orchestrator-vs-gate divergence this
#              function exists to kill);
#          (2) else the dispatched agent definition's frontmatter `model:`
#              (resolved by the caller at the agent's REAL definition path;
#              the gate passes it in, or None when it cannot resolve it);
#          (3) else the CLAIM's `model` value (model_source="claim").
#        The TOML parser is gated identically on both sides: when no parser is
#        importable, the overlay step is SKIPPED identically (the injector has
#        already dropped the overlay, so frontmatter/claim is the effective AND
#        bound model -- consistent). The keyed CORE stays stdlib-only; `tomli`
#        (Py 3.10.7) / `tomllib` (Py >= 3.11) is the ONE documented overlay
#        parse dependency, gated by /check-setup.
#
# Stdlib only except the ONE allowed overlay-parse dependency (tomllib/tomli,
# used identically on both sides).

import os
import hashlib

# recompute_overlay_digest status sentinels (the gate dispatches on these).
OVERLAY_OK = "OK"              # digest recomputed; value is the 64-hex digest
OVERLAY_MISMATCH = "MISMATCH"  # toml absent/unreadable at intercept -> DENY MISMATCH
OVERLAY_DENY = "DENY"          # traversal guard / allowlist escape -> DENY

# Default configured allowlist root (REQ-031). The persisted override_path may
# be any directory WITHIN the project root; `customization/` is the conventional
# default location used when no override_path is persisted. The load-bearing
# security boundary is "the resolved .toml stays inside the project root" so a
# forged claim cannot redirect the hash target outside the repo.
DEFAULT_OVERRIDE_PATH = "customization/"


def _toml_parser():
    """Return the SAME TOML module the injector uses (tomllib >= 3.11 else tomli).

    None when no parser is importable -> the overlay step is skipped identically
    on both sides (REQ-048 dependency reconciliation).
    """
    try:
        import tomllib
        return tomllib
    except ImportError:
        try:
            import tomli
            return tomli
        except ImportError:
            return None


def _short_is_safe(short):
    """Path-traversal guard on the overlay short name (REQ-038).

    The short name forms `<override_path>/<short>.toml`; reject any separator or
    parent-dir token so a forged short name cannot escape the lookup directory.
    """
    return bool(short) and ("/" not in short) and ("\\" not in short) and (".." not in short)


def _within(root, target):
    """True iff realpath(target) is inside realpath(root) (allowlist confinement).

    Fail-closed: any resolution error (incl. cross-drive ValueError on Windows)
    -> False -> the caller DENYs.
    """
    try:
        root_r = os.path.realpath(root)
        tgt_r = os.path.realpath(target)
        return os.path.commonpath([root_r, tgt_r]) == root_r
    except (ValueError, OSError):
        return False


def _toml_path(override_path, short, project_root):
    """Build the candidate <override_path>/<short>.toml path under project_root."""
    ovp = override_path or DEFAULT_OVERRIDE_PATH
    if os.path.isabs(ovp):
        return os.path.join(ovp, short + ".toml")
    return os.path.join(project_root, ovp, short + ".toml")


def recompute_overlay_digest(override_path, short, project_root=None):
    """sha256 of the RAW LF-normalized `.toml` bytes (REQ-031).

    Returns (status, value):
      (OVERLAY_OK, "<64-hex>")       digest recomputed from the held bytes
      (OVERLAY_MISMATCH, "<reason>") overlay_source=toml but .toml absent/unreadable
      (OVERLAY_DENY, "<reason>")     traversal guard / allowlist escape (forged path)
    Reads the file ONCE and hashes the held bytes (no second read; no renderer
    coupling) -> no gate-side read-vs-hash TOCTOU.
    """
    root = project_root or os.getcwd()
    if not _short_is_safe(short):
        return (OVERLAY_DENY, "overlay short name failed the path-traversal guard")
    toml_path = _toml_path(override_path, short, root)
    if not _within(root, toml_path):
        return (OVERLAY_DENY, "override_path escapes the configured allowlist (project root)")
    try:
        with open(toml_path, "rb") as f:
            raw = f.read()
    except (FileNotFoundError, NotADirectoryError, IsADirectoryError, PermissionError, OSError):
        return (OVERLAY_MISMATCH,
                "overlay_source=toml but the .toml is absent/unreadable at intercept")
    # LF-normalize the RAW bytes (CRLF/CR -> LF) so MSYS2<->Linux byte-identity
    # holds, then hash the SAME held bytes.
    norm = raw.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    return (OVERLAY_OK, hashlib.sha256(norm).hexdigest())


def resolve_model(override_path, short, frontmatter_model=None, claim_model="",
                  project_root=None):
    """Deterministic model resolution via the SHARED TOML parser (REQ-048).

    Returns (model, model_source) where model_source in
    {"overlay", "frontmatter", "claim"}. Precedence: overlay TOML scalar ->
    agent-def frontmatter (caller-supplied) -> CLAIM model. Never a naive
    `grep '^model ='` -- the overlay scalar comes from a real TOML parse.
    """
    root = project_root or os.getcwd()
    parser = _toml_parser()
    if parser is not None and _short_is_safe(short):
        toml_path = _toml_path(override_path, short, root)
        if _within(root, toml_path) and os.path.isfile(toml_path):
            try:
                with open(toml_path, "rb") as f:
                    data = parser.load(f)
                m = data.get("model") if isinstance(data, dict) else None
                if isinstance(m, str) and m:
                    return (m, "overlay")
            except Exception:
                # A parse error here is non-fatal for model resolution: fall
                # through to frontmatter/claim (the digest path detects a
                # mutated/dropped overlay; model never false-DENYs on it).
                pass
    if isinstance(frontmatter_model, str) and frontmatter_model:
        return (frontmatter_model, "frontmatter")
    return (claim_model or "", "claim")


if __name__ == "__main__":
    # Non-authoritative CLI / self-check helper (no keyed material here).
    #   witness_overlay.py digest OVERRIDE_PATH SHORT [PROJECT_ROOT]
    #   witness_overlay.py model  OVERRIDE_PATH SHORT FRONTMATTER CLAIM [PROJECT_ROOT]
    #   witness_overlay.py --self-test
    import sys

    args = sys.argv[1:]
    cmd = args[0] if args else ""
    if cmd == "digest" and len(args) >= 3:
        pr = args[3] if len(args) > 3 else None
        st, val = recompute_overlay_digest(args[1], args[2], project_root=pr)
        sys.stdout.write("%s %s" % (st, val))
    elif cmd == "model" and len(args) >= 5:
        pr = args[5] if len(args) > 5 else None
        m, src = resolve_model(args[1], args[2], frontmatter_model=args[3] or None,
                               claim_model=args[4], project_root=pr)
        sys.stdout.write("%s %s" % (m, src))
    elif cmd == "--self-test":
        import tempfile
        ok = True
        work = tempfile.mkdtemp(prefix="wo_")
        os.makedirs(os.path.join(work, "customization"), exist_ok=True)
        with open(os.path.join(work, "customization", "fixer.toml"), "wb") as f:
            f.write(b'model = "sonnet"\nstyle = "Terse"\n')
        st, dig = recompute_overlay_digest("customization/", "fixer", project_root=work)
        ok = ok and (st == OVERLAY_OK) and len(dig) == 64
        st2, _ = recompute_overlay_digest("customization/", "nope", project_root=work)
        ok = ok and (st2 == OVERLAY_MISMATCH)
        st3, _ = recompute_overlay_digest("../../../../etc/", "fixer", project_root=work)
        ok = ok and (st3 == OVERLAY_DENY)
        st4, _ = recompute_overlay_digest("customization/", "../escape", project_root=work)
        ok = ok and (st4 == OVERLAY_DENY)
        m, src = resolve_model("customization/", "fixer", claim_model="opus",
                               project_root=work)
        # tomli/tomllib present on this runtime -> overlay scalar wins.
        if _toml_parser() is not None:
            ok = ok and (m == "sonnet") and (src == "overlay")
        else:
            ok = ok and (m == "opus") and (src == "claim")
        m2, src2 = resolve_model("customization/", "absent", frontmatter_model="haiku",
                                 claim_model="opus", project_root=work)
        ok = ok and (m2 == "haiku") and (src2 == "frontmatter")
        try:
            import shutil
            shutil.rmtree(work, ignore_errors=True)
        except Exception:
            pass
        sys.stdout.write("self-test: PASS\n" if ok else "self-test: FAIL\n")
        sys.exit(0 if ok else 1)
    else:
        sys.stderr.write(
            "usage: witness_overlay.py {digest OVERRIDE_PATH SHORT [ROOT] | "
            "model OVERRIDE_PATH SHORT FRONTMATTER CLAIM [ROOT] | --self-test}\n")
        sys.exit(2)
