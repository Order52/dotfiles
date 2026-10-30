#!/usr/bin/env bash
# Usage: ./ocr.sh [lang]
# Example: ./ocr.sh eng   or   ./ocr.sh ara

# Default to English if no argument is provided
LANG_OPT="${1:-eng}"

# 1. Select the area
geometry="$(hyprctl clients -j | jq -r '.[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp)"
[[ -z "$geometry" ]] && exit 0

# 2. Notify User
notify_id=$(notify-send -p -h string:x-canonical-private-synchronous:ocr "OCR" "Scanning ($LANG_OPT)...")

# 3. Process (using pipefail to catch errors in the pipeline)
set -o pipefail
content="$(grim -g "$geometry" - | \
  magick - -modulate 100,0 -sigmoidal-contrast 10,50% -resize 200% - | \
  tesseract stdin stdout -l "$LANG_OPT" \
    --oem 1 \
    --psm 6 \
    -c load_system_dawg=1 \
    -c load_freq_dawg=1 \
    -c tessedit_char_blacklist="¦" \
    2>/dev/null)" || {
  notify-send -r "$notify_id" -u low "OCR Failed" "Processing error."
  exit 1
}

# 4. Handle Result
if [[ -z "$content" ]]; then
    notify-send -r "$notify_id" -u low "OCR Failed" "No text detected."
    exit 1
fi

# 5. Clean, Copy & Escape in one pass
cleaned="${content//[$'\f']}"  # Remove form feeds
cleaned="${cleaned#"${cleaned%%[![:space:]]*}"}"  # Trim leading whitespace
cleaned="${cleaned%"${cleaned##*[![:space:]]}"}"  # Trim trailing whitespace

# Copy to clipboard
wl-copy <<< "$cleaned"

# 6. Create preview and escape
preview="${cleaned:0:200}"
preview="${preview//&/&amp;}"
preview="${preview//</&lt;}"
preview="${preview//>/&gt;}"

notify-send \
  -r "$notify_id" \
  -h string:x-canonical-private-synchronous:ocr \
  "OCR Copied ($LANG_OPT)" \
  "<tt>${preview}...</tt>"
