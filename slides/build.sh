#!/bin/sh
# Render the one-slide wrap-up deck to a 16:9 PDF (20in x 11.25in = 1920x1080 px at 96dpi).
set -eu
cd "$(dirname "$0")"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$PWD/wrapup.pdf" --virtual-time-budget=20000 \
  "file://$PWD/wrapup.html"
echo "Wrote wrapup.pdf"
