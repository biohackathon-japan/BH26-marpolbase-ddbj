#!/bin/sh
# Build paper_ja.pdf (Japanese version).
# The BioHackrXiv gen-pdf container has no CJK fonts, so the Japanese version is
# rendered via pandoc -> HTML -> headless Chrome instead.
set -eu
cd "$(dirname "$0")"

docker run --rm -v "$PWD":/data -w /data pandoc/core:latest \
  paper_ja.md -f markdown+implicit_figures -t html5 -s \
  --css ja.css --include-before-body ja-header.html \
  --metadata title="" --metadata pagetitle="paper_ja" \
  -o paper_ja.html

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PWD/paper_ja.pdf" --virtual-time-budget=20000 \
  "file://$PWD/paper_ja.html"

echo "Wrote paper_ja.pdf"
