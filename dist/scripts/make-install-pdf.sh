#!/usr/bin/env bash
#
# make-install-pdf.sh — render the end-user install guides to PDF.
#
# Converts dist/templates/common/INSTALL.md and INSTALL.ru.md to
# INSTALL.pdf / INSTALL.ru.pdf next to them. Both PDFs are packaged into every
# distribution archive by make-dist.sh, so re-run this after editing either
# guide.
#
# Requirements (build host only — end users never need these):
#   - python3 with markdown-it-py   (Fedora: python3-markdown-it-py,
#                                    otherwise: pip install markdown-it-py)
#   - Google Chrome / Chromium (headless "print to PDF")
#
# Usage:
#   dist/scripts/make-install-pdf.sh [--chrome <binary>]
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMMON="$REPO_ROOT/dist/templates/common"
CHROME=""

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

while [ $# -gt 0 ]; do
    case "$1" in
        --chrome) CHROME="${2:-}"; shift 2;;
        -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) die "unknown argument: $1";;
    esac
done

if [ -z "$CHROME" ]; then
    for c in google-chrome chromium chromium-browser google-chrome-stable; do
        if command -v "$c" >/dev/null 2>&1; then CHROME="$(command -v "$c")"; break; fi
    done
fi
[ -n "$CHROME" ] || die "no Chrome/Chromium found; pass --chrome <binary>"

command -v python3 >/dev/null 2>&1 || die "python3 not found on PATH"
python3 -c 'import markdown_it' 2>/dev/null || die "python module markdown-it-py not found (pip install markdown-it-py)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

for name in INSTALL INSTALL.ru; do
    src="$COMMON/$name.md"
    [ -f "$src" ] || die "missing $src"
    html="$TMP/$name.html"
    out="$COMMON/$name.pdf"

    log "Rendering $name.md -> HTML"
    python3 "$REPO_ROOT/dist/scripts/md_to_html.py" "$src" "$html"

    log "Printing $name.pdf"
    "$CHROME" --headless --disable-gpu --no-sandbox \
        --user-data-dir="$TMP/chrome" \
        --no-pdf-header-footer \
        --print-to-pdf="$out" "file://$html" >/dev/null 2>&1 \
        || die "chrome failed to print $name.pdf"
    [ -s "$out" ] || die "chrome produced an empty $out"
    log "Done: ${out#"$REPO_ROOT"/} ($(du -h "$out" | cut -f1))"
done
