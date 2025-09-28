#!/usr/bin/env bash
# charpick — simple Unicode/special-character picker for rofi
# deps: rofi; one of wl-copy|xclip; optional: wtype|xdotool; optional: notify-send
set -euo pipefail

# --- config ------------------------------------------------------
# Where your character lists live (TSV files). You can keep multiple.
CHAR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/charpick"
# Rofi look & feel (tweak as you like)
ROFI_OPTS=(-dmenu -i -markup-rows -p "Pick char" -no-custom)
# Default behaviour: copy to clipboard. Add -t to also type it, -o to print to stdout.
DO_TYPE=false
DO_PRINT=false
# ----------------------------------------------------------------

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] [initial-filter]
Options:
  -t        also type into active window (wtype or xdotool)
  -o        print to stdout (in addition to copying)
  -h        show help
Notes:
  Put one or more *.tsv files in $CHAR_DIR with lines like:
    ✓\tU+2713\tcheck mark\tcheck tick yes
EOF
}

while getopts ":toh" opt; do
  case $opt in
    t) DO_TYPE=true ;;
    o) DO_PRINT=true ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
  esac
done
shift $((OPTIND-1))
INITIAL_FILTER="${1:-}"

# --- ensure data dir ------------------------------------------------
mkdir -p "$CHAR_DIR"

# If user has no lists yet, drop in a tiny starter list:
STARTER="$CHAR_DIR/starter.tsv"
if [ ! -s "$STARTER" ] && [ -z "$(printf '%s\n' "$CHAR_DIR"/*.tsv 2>/dev/null | grep -v '\*')" ]; then
  cat >"$STARTER" <<'TSV'
✓	U+2713	check mark	check tick yes
✗	U+2717	ballot x	cross multiply no
→	U+2192	right arrow	arrow -> to
←	U+2190	left arrow	arrow <- from
↑	U+2191	up arrow	arrow up
↓	U+2193	down arrow	arrow down
•	U+2022	bullet	point dot
—	U+2014	em dash	dash long
–	U+2013	en dash	dash short
…	U+2026	ellipsis	dots
«	U+00AB	left guillemet	quote
»	U+00BB	right guillemet	quote
§	U+00A7	section sign	legal law
™	U+2122	trade mark	tm
©	U+00A9	copyright	c symbol
®	U+00AE	registered	r symbol
€	U+20AC	euro	currency
£	U+00A3	pound	currency
¥	U+00A5	yen	currency
±	U+00B1	plus-minus	math
≈	U+2248	approximately equal	almost equal
≥	U+2265	greater-or-equal	math
≤	U+2266	less-or-equal	math
∞	U+221E	infinity	math
µ	U+00B5	micro	greek mu
α	U+03B1	alpha	greek
β	U+03B2	beta	greek
π	U+03C0	pi	greek
Ω	U+03A9	ohm	omega
°	U+00B0	degree	temp
TSV
fi

# --- collect all TSVs into menu lines -------------------------------
# fields: char \t code \t name \t tags...
# We’ll render as: "<b>CHAR</b>\tcode\tname\t[tags]"
menu_input() {
  # shellcheck disable=SC2016
  awk -F'\t' '
    BEGIN{ OFS="\t" }
    NF>=1 && $1!~ /^#/ {
      ch=$1; code=(NF>=2 ? $2 : ""); name=(NF>=3 ? $3 : ""); extra="";
      for(i=4;i<=NF;i++){ extra=extra (extra?" ":"") $i }
      # Escape & < > for rofi markup
      gsub(/&/,"&amp;",ch); gsub(/</,"&lt;",ch); gsub(/>/,"&gt;",ch);
      print "<b>" ch "</b>", code, name, extra
    }' "$CHAR_DIR"/*.tsv 2>/dev/null || true
}

# --- run rofi -------------------------------------------------------
SEL="$(menu_input | rofi "${ROFI_OPTS[@]}" ${INITIAL_FILTER:+-filter "$INITIAL_FILTER"})" || exit 1

# Extract the *real* character from the selection:
# It’s inside <b>...</b> at the start of the line
CHAR="$(printf '%s' "$SEL" | sed -n 's/^<b>\(.*\)<\/b>.*/\1/p' | \
       sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g')"

if [ -z "$CHAR" ]; then
  exit 0
fi

# --- copy to clipboard ----------------------------------------------
copy_clip() {
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$CHAR" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$CHAR" | xclip -selection clipboard
  else
    echo "No wl-copy or xclip found for clipboard copy." >&2
    return 1
  fi
}

# --- type into active window (optional) -----------------------------
type_char() {
  if command -v wtype >/dev/null 2>&1; then
    # wtype handles unicode nicely
    wtype "$CHAR"
  elif command -v xdotool >/dev/null 2>&1; then
    # xdotool is X11 only and can be finicky with some codepoints
    xdotool type --clearmodifiers --delay 0 "$CHAR"
  else
    return 1
  fi
}

copy_clip && COPIED=true || COPIED=false

if $DO_TYPE; then
  type_char && TYPED=true || TYPED=false
else
  TYPED=false
fi

$DO_PRINT && printf '%s\n' "$CHAR" || true

if command -v notify-send >/dev/null 2>&1; then
  MSG="Copied ‘$CHAR’"
  $TYPED && MSG="$MSG and typed"
  notify-send "charpick" "$MSG"
fi

