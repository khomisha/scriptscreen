#!/usr/bin/env bash
#
# make-docs-pdf.sh — render the end-user documents to PDF.
#
# Converts to PDF, next to the source file:
#   dist/templates/common/INSTALL.md     -> INSTALL.pdf       the install guide
#   dist/templates/common/INSTALL.ru.md  -> INSTALL.ru.pdf
#   USER_MANUAL_EN.md                    -> USER_MANUAL_EN.pdf  the user manual
#   USER_MANUAL.md                       -> USER_MANUAL.pdf
#
# All four PDFs are packaged into every distribution archive by make-dist.sh,
# so re-run this after editing any of the sources.
#
# Requirements (build host only — end users never need these):
#   - python3 with markdown-it-py   (Fedora: python3-markdown-it-py,
#                                    otherwise: pip install markdown-it-py)
#   - Google Chrome / Chromium (headless "print to PDF")
#
# Usage:
#   dist/scripts/make-docs-pdf.sh [--chrome <binary>] [<name> ...]
#
#   <name>  render only the named documents: install | install.ru |
#           manual | manual.en   (default: all of them)
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMMON="$REPO_ROOT/dist/templates/common"
CHROME=""
WANTED=( )

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

# document name -> source file, relative to the repository root
doc_source( ) {
    case "$1" in
        install)    echo "dist/templates/common/INSTALL.md";;
        install.ru) echo "dist/templates/common/INSTALL.ru.md";;
        manual.en)  echo "USER_MANUAL_EN.md";;
        manual)     echo "USER_MANUAL.md";;
        *)          die "unknown document: $1 (install|install.ru|manual|manual.en)";;
    esac
}

while [ $# -gt 0 ]; do
    case "$1" in
        --chrome) CHROME="${2:-}"; shift 2;;
        -h|--help) sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        -*) die "unknown argument: $1";;
        *) WANTED+=( "$1" ); shift;;
    esac
done
[ ${#WANTED[@]} -gt 0 ] || WANTED=( install install.ru manual.en manual )

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

for name in "${WANTED[@]}"; do
    src="$REPO_ROOT/$(doc_source "$name")"
    [ -f "$src" ] || die "missing $src"
    stem="$(basename "$src" .md)"
    html="$TMP/$stem.html"
    out="$(dirname "$src")/$stem.pdf"

    log "Rendering $stem.md -> HTML"
    python3 "$REPO_ROOT/dist/scripts/md_to_html.py" "$src" "$html"

    log "Printing $stem.pdf"
    "$CHROME" --headless --disable-gpu --no-sandbox \
        --user-data-dir="$TMP/chrome" \
        --no-pdf-header-footer \
        --print-to-pdf="$out" "file://$html" >/dev/null 2>&1 \
        || die "chrome failed to print $stem.pdf"
    [ -s "$out" ] || die "chrome produced an empty $out"
    log "Done: ${out#"$REPO_ROOT"/} ($(du -h "$out" | cut -f1))"
done
