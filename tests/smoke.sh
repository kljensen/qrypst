#!/bin/sh
# Compile tests/smoke.typ, rasterise every page, and check that zbar decodes
# each code to the payload printed under it. Exits non-zero on the first
# mismatch. Needs typst, pdftoppm (poppler) and zbarimg (zbar).
set -eu

cd "$(dirname "$0")/.."
out=tests/out
rm -rf "$out"
mkdir -p "$out"

for tool in typst pdftoppm zbarimg; do
    command -v "$tool" >/dev/null 2>&1 || { echo "missing: $tool" >&2; exit 2; }
done

typst compile --root . tests/smoke.typ "$out/smoke.pdf"
pdftoppm -r 300 -png "$out/smoke.pdf" "$out/page"

# The payloads, in page order, straight from the source: the test file is
# the single place they are written down.
sed -n 's/^  ("\([^"]*\)", "[LMQH]"),$/\1/p' tests/smoke.typ > "$out/expected.txt"

pages=$(ls "$out"/page-*.png | wc -l | tr -d ' ')
expected=$(wc -l < "$out/expected.txt" | tr -d ' ')
if [ "$pages" -ne "$expected" ]; then
    echo "expected $expected pages, rendered $pages" >&2
    exit 1
fi

i=0
status=0
for png in $(ls "$out"/page-*.png | sort); do
    i=$((i + 1))
    want=$(sed -n "${i}p" "$out/expected.txt")
    got=$(zbarimg -q --raw "$png" | head -n 1 || true)
    if [ "$got" = "$want" ]; then
        echo "ok   page $i"
    else
        echo "FAIL page $i" >&2
        echo "  want: $want" >&2
        echo "  got:  $got" >&2
        status=1
    fi
done
exit "$status"
