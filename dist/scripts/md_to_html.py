#!/usr/bin/env python3
"""Render one of the end-user documents to a self-contained, print-styled HTML page.

Used by make-docs-pdf.sh, which then prints the page to PDF with headless
Chrome. Links to a document that ships as a PDF of its own are rewritten to
point at that PDF, and every heading is given the anchor its markdown link
uses, so the table of contents of the user manual works inside the PDF.
"""
import re
import sys
from pathlib import Path

from markdown_it import MarkdownIt

CSS = """
@page { size: A4; margin: 18mm 16mm; }
:root { --fg: #1a1a1a; --muted: #555; --rule: #d8d8d8; --code-bg: #f4f4f5; }
* { box-sizing: border-box; }
body {
  font-family: "Noto Sans", "DejaVu Sans", "Liberation Sans", Arial, sans-serif;
  font-size: 10.5pt; line-height: 1.55; color: var(--fg); margin: 0;
}
h1, h2, h3 { line-height: 1.25; font-weight: 650; margin: 1.4em 0 0.5em; }
h1 { font-size: 20pt; margin-top: 0; }
h2 { font-size: 14pt; border-bottom: 1px solid var(--rule); padding-bottom: 0.2em;
     break-after: avoid; page-break-after: avoid; }
h3 { font-size: 11.5pt; break-after: avoid; page-break-after: avoid; }
p, ul, ol { margin: 0.6em 0; }
li { margin: 0.25em 0; }
li > p { margin: 0.3em 0; }
a { color: #0b5fa5; text-decoration: none; word-break: break-word; }
hr { border: 0; border-top: 1px solid var(--rule); margin: 1.6em 0; }
code {
  font-family: "DejaVu Sans Mono", "Liberation Mono", monospace;
  font-size: 0.88em; background: var(--code-bg); padding: 0.12em 0.32em;
  border-radius: 3px; word-break: break-word;
}
pre {
  background: var(--code-bg); border: 1px solid var(--rule); border-radius: 4px;
  padding: 0.7em 0.9em; overflow: hidden; white-space: pre-wrap; word-break: break-word;
  break-inside: avoid; page-break-inside: avoid; margin: 0.7em 0;
}
pre code { background: none; padding: 0; font-size: 0.85em; }
blockquote {
  margin: 0.9em 0; padding: 0.1em 1em; border-left: 3px solid #b9c6d2;
  background: #f6f9fc; color: var(--muted);
  break-inside: avoid; page-break-inside: avoid;
}
table {
  border-collapse: collapse; width: 100%; margin: 0.9em 0; font-size: 9.2pt;
  break-inside: avoid; page-break-inside: avoid;
}
th, td { border: 1px solid var(--rule); padding: 0.42em 0.6em; text-align: left;
         vertical-align: top; }
th { background: #f1f3f5; font-weight: 650; }
td code { font-size: 0.85em; }
"""

# The documents cross-link by markdown filename; in the PDFs the sibling is a
# PDF. The distribution guide ships in the archive as the install guide, so a
# link to it points at that.
LINK_FIXUPS = {
    "INSTALL.md": "INSTALL.pdf",
    "INSTALL.ru.md": "INSTALL.ru.pdf",
    "DISTRIBUTION.md": "INSTALL.pdf",
    "DISTRIBUTION.ru.md": "INSTALL.ru.pdf",
    "USER_MANUAL.md": "USER_MANUAL.pdf",
    "USER_MANUAL_EN.md": "USER_MANUAL_EN.pdf",
}

_HEADING = re.compile(r"<h([1-6])>(.*?)</h\1>", re.S)
_TAGS = re.compile(r"<[^>]+>")
_DROPPED = re.compile(r"[^\w\- ]", re.U)


def slug(html: str) -> str:
    """Returns the anchor of a heading, the way the markdown links spell it:
    the markup and the punctuation are dropped, the spaces become hyphens."""
    text = _TAGS.sub("", html)
    text = text.replace("&amp;", "").replace("&lt;", "").replace("&gt;", "")
    return _DROPPED.sub("", text.strip().lower()).replace(" ", "-")


def add_anchors(body: str) -> str:
    """Gives every heading the id its table of contents links to."""
    return _HEADING.sub(
        lambda m: f'<h{m.group(1)} id="{slug(m.group(2))}">{m.group(2)}</h{m.group(1)}>',
        body,
    )


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: md_to_html.py <input.md> <output.html>", file=sys.stderr)
        return 2
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    text = src.read_text(encoding="utf-8")

    md = MarkdownIt("commonmark").enable("table").enable("strikethrough")
    body = add_anchors(md.render(text))
    for old, new in LINK_FIXUPS.items():
        body = body.replace(f'href="{old}"', f'href="{new}"')
        body = body.replace(f'>{old}</a>', f'>{new}</a>')

    title = next((m.group(1).strip() for m in [re.search(r"^#\s+(.+)$", text, re.M)] if m),
                 src.stem)
    dst.write_text(
        "<!doctype html>\n<html><head><meta charset=\"utf-8\">\n"
        f"<title>{title}</title>\n<style>{CSS}</style>\n</head><body>\n"
        f"{body}\n</body></html>\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
