#!/usr/bin/env bash
# recolor-icon.sh — generate a tinted Claude Desktop icon for a side profile.
#
# Two modes:
#
#   modulate — rotate the whole image's hue (and optionally brightness /
#              saturation). Affects every pixel including the white logo,
#              so for muted/dark variants the logo gets dimmed too.
#
#   fill     — replace only the coral background pixels with a solid color.
#              The white Claude logo and the rounded-square shape are kept
#              intact. Best choice for "muted/dark/chill" tints.
#
# Usage:
#   ./recolor-icon.sh <profile-N> modulate <brightness> <saturation> <hue>
#   ./recolor-icon.sh <profile-N> fill <hex-color> [fuzz-percent]
#
# Examples:
#   ./recolor-icon.sh 2 modulate 100 100 47      # purple/lavender (hue -95°)
#   ./recolor-icon.sh 3 fill '#3F6B47'           # dark forest matte
#   ./recolor-icon.sh 3 modulate 100 100 167     # bright green (hue +120°)
#   ./recolor-icon.sh 4 modulate 110 160 30      # boosted indigo
#
# Output: 6 PNGs at standard hicolor sizes under
# ~/.local/share/icons/hicolor/<size>/apps/claude-desktop-<N>.png
#
# After running, refresh the icon cache:
#   gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor

usage() {
	sed -n '2,29p' "$0"
	exit "${1:-0}"
}

profile="${1:-}"
mode="${2:-}"
[[ -z "$profile" || -z "$mode" ]] && usage 1

# Coral approx — the upstream icon's background hue.
coral_color='#D97757'

case "$mode" in
	modulate)
		brightness="${3:-100}"
		saturation="${4:-100}"
		hue="${5:-100}"
		modulate_arg="${brightness},${saturation},${hue}"
		;;
	fill)
		fill_color="${3:?hex color required (e.g. #3F6B47)}"
		fuzz_pct="${4:-30}"
		;;
	-h | --help | help)
		usage 0
		;;
	*)
		echo "Unknown mode: $mode" >&2
		usage 1
		;;
esac

src_base='/usr/share/icons/hicolor'
dst_base="${HOME}/.local/share/icons/hicolor"
sizes=(16 24 32 48 64 256)

magick_cmd='magick'
if ! command -v magick >/dev/null; then
	if command -v convert >/dev/null; then
		magick_cmd='convert'
	else
		echo 'ImageMagick not found. Install it (e.g. `apt install imagemagick`).' >&2
		exit 1
	fi
fi

for size in "${sizes[@]}"; do
	src="${src_base}/${size}x${size}/apps/claude-desktop.png"
	dst_dir="${dst_base}/${size}x${size}/apps"
	dst="${dst_dir}/claude-desktop-${profile}.png"

	if [[ ! -f "$src" ]]; then
		echo "  [skip] ${size}x${size}: source not found ($src)"
		continue
	fi

	mkdir -p "$dst_dir"
	if [[ "$mode" == 'modulate' ]]; then
		"$magick_cmd" "$src" \
			-modulate "$modulate_arg" \
			"$dst"
	else
		"$magick_cmd" "$src" \
			-fuzz "${fuzz_pct}%" \
			-fill "$fill_color" \
			-opaque "$coral_color" \
			"$dst"
	fi
	echo "  [ok] ${size}x${size} -> ${dst}"
done

echo
echo 'Done. Refresh icon cache:'
echo "  gtk-update-icon-cache -f -t ${dst_base}"
