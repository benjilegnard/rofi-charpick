# rofi-charpick

A tiny, no-dependency* way to get a Unicode/special-characters picker in **rofi**.

(* uses common tools you likely already have: `bash`, `rofi`, plus clipboard + optional “type” tools.)

---

## 1) install the picker script

Save [charpick.sh](./charpick.sh) as `/usr/local/bin/charpick` (or anywhere on your `$PATH`) and make it executable.

```bash
curl https://github.com/benjilegnard/rofi-charpick/charpick.sh -o /usr/local/bin/charpick
```

Make it executable:

```bash
chmod +x /usr/local/bin/charpick
```

If you don’t have `/usr/local/bin` on your PATH, add it (e.g., in `~/.bashrc` / `~/.zshrc`):

```bash
export PATH="/usr/local/bin:$PATH"
```

---

## 2) setup your character lists (TSV)

Put one or more `*.tsv` files in `~/.config/charpick/`.
Each line is:
`CHAR<TAB>U+CODE<TAB>Name<TAB>optional tags...`

Example `~/.config/charpick/math.tsv`:

```
∑	U+2211	n-ary summation	sum sigma math
√	U+221A	square root	root math
∫	U+222B	integral	integral calculus
≈	U+2248	approximately equal	almost equal
≠	U+2260	not equal	not equals
→	U+2192	right arrow	arrow -> to
↔	U+2194	left right arrow	arrow <-> both
```

Search in rofi matches anywhere on the line (names, codes, or tags).

---

## 3) usage

* Launch: `charpick`
  Start typing to fuzzy-filter (e.g., “arrow”, “degree”, “U+2192”).
* Also type into the active window: `charpick -t`
* Also print to stdout for scripts: `charpick -o`
* Seed the query (e.g., bind in your WM/DE): `charpick "arrow"`

A nice i3/sway binding example:

```
# sway
bindsym $mod+u exec --no-startup-id charpick
bindsym $mod+Shift+u exec --no-startup-id charpick -t
```

---

## 4) (optional) auto-generate a big list from Unicode data

If your distro ships `/usr/share/unicode/UnicodeData.txt`, you can create a broad list:

```bash
awk -F';' '
  # skip controls and unassigned
  $3 != "Cn" && $3 != "Cc" && $1 != "" {
    code=$1
    # hex -> decimal and to char via printf in awk (GNU awk required)
    # limit to sane displayables: from U+0020 to U+2FFF here; tweak as you like
    n=strtonum("0x" code)
    if (n>=0x20 && n<=0x2FFF) {
      # build the actual character
      ch = sprintf("%c", n)
      printf "%s\tU+%s\t%s\n", ch, code, $2
    }
  }' /usr/share/unicode/UnicodeData.txt > ~/.config/charpick/unicode-basic.tsv
```

You can maintain multiple TSVs (math, arrows, quotes, currency, Greek…), and the script will merge them at runtime.

---

## 5) tips / tweaks

* Wayland: install `wl-clipboard` (`wl-copy`). X11: install `xclip`.
* To **paste automatically** after copy on X11 apps that accept Ctrl+V, you can extend the script to call `xdotool key ctrl+v` (but that’s app-dependent).
* If a character doesn’t “type” correctly via `xdotool`, rely on clipboard only (`charpick`) and paste manually; or use Wayland’s `wtype`.


