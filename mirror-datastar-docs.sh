#!/usr/bin/env bash
# Mirrors data-star.dev's guide/reference/examples/how_tos docs (via its
# sitemap.xml) to local Markdown files using trafilatura for
# readability-quality content extraction (drops nav/sidebar/footer chrome
# that a raw pandoc-on-HTML conversion would keep). Skips top-level marketing
# pages (/, /pro, /shop, /videos, ...) and essays -- not needed for reference.
#
# data-star.dev also publishes an aggregated /docs.md export, but it only
# covers guide/ fully plus 2 of 6 reference/ pages (verified: no "Rocket",
# "SSE Events", "SDKs", or "Security" sections) -- everything below is
# scraped directly instead, so the mirror is complete and not dependent on
# that export staying in sync with the full site.
#
# Usage: ./mirror-datastar-docs.sh [output-dir]
# Requires: curl, python3 with the trafilatura package importable
#
# Uses trafilatura's Python API (not its CLI) to do the extraction: the CLI
# silently produces an empty file when its stdout is redirected (`trafilatura
# -i file > out.md` reliably gives a 0-byte out.md here, exit code 0, no
# error -- some batch-mode/tty-detection quirk in the CLI itself), while
# printing to a terminal works fine. Calling extract() directly and writing
# the file ourselves from Python sidesteps that entirely.

set -euo pipefail

SITE="https://data-star.dev"
OUT_DIR="${1:-./data-star-docs}"

python3 -c "import trafilatura" 2>/dev/null || {
    echo "error: trafilatura not importable from python3 (pip install trafilatura)" >&2
    exit 1
}

mkdir -p "$OUT_DIR"

echo "Fetching sitemap..."
urls="$(curl -sf "$SITE/sitemap.xml" | grep -oP '(?<=<loc>)[^<]+' | grep -E "^$SITE/(guide|reference|examples|how_tos)/")"

if [ -z "$urls" ]; then
    echo "error: no URLs found in sitemap" >&2
    exit 1
fi

count="$(printf '%s\n' "$urls" | wc -l)"
echo "Found $count URLs. Converting to Markdown in $OUT_DIR ..."

i=0
failed=0
while IFS= read -r url; do
    i=$((i + 1))

    # URL path relative to site root -> mirrored file path, e.g.
    # https://data-star.dev/guide/getting_started -> guide/getting_started.md
    rel="${url#"$SITE"}"
    rel="${rel#/}"
    rel="${rel%/}"
    [ -z "$rel" ] && rel="index"

    dest="$OUT_DIR/$rel.md"
    mkdir -p "$(dirname "$dest")"

    printf '[%d/%d] %s\n' "$i" "$count" "$url"

    # Fetch with curl, not trafilatura's own downloader -- trafilatura -u
    # gets an empty/unparseable response from this site (likely Cloudflare
    # treating its fetcher's UA/TLS fingerprint as a bot), while plain curl
    # gets the real page every time. Feed the saved HTML to trafilatura's
    # extract() below instead, which never touches the network itself.
    html="$dest.html"
    if ! curl -sfL "$url" -o "$html"; then
        echo "  warn: curl fetch failed" >&2
        rm -f "$html"
        failed=$((failed + 1))
        continue
    fi

    if ! python3 - "$html" "$dest.tmp" <<'PY' 2>/dev/null
import sys
import trafilatura

with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
    html = f.read()

md = trafilatura.extract(html, output_format="markdown", favor_recall=True)
if not md:
    sys.exit(1)

with open(sys.argv[2], "w", encoding="utf-8") as f:
    f.write(md)
PY
    then
        echo "  warn: failed to convert" >&2
        rm -f "$html" "$dest.tmp"
        failed=$((failed + 1))
        continue
    fi
    rm -f "$html"

    if [ ! -s "$dest.tmp" ]; then
        echo "  warn: empty output" >&2
        rm -f "$dest.tmp"
        failed=$((failed + 1))
        continue
    fi

    mv "$dest.tmp" "$dest"
    sleep 0.3
done <<< "$urls"

written="$(find "$OUT_DIR" -name '*.md' | wc -l)"
echo "Done. $written markdown files written to $OUT_DIR ($failed failed)"
