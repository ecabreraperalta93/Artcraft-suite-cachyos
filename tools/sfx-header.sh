#!/usr/bin/env bash
# Craft App Suite - instalador autoextraible para CachyOS / Arch Linux x86_64
# Contiene el ArtCraft Launcher y las 12 apps (paquetes pacman). Un solo archivo.
#
#   Doble clic (o ./Instalar-Craft-Suite.run)   abre el instalador grafico
#   ./Instalar-Craft-Suite.run --cli [opciones]  instalador de terminal (--all, --launcher, nombres, --dry-run)
#   ./Instalar-Craft-Suite.run --check           solo verifica que el archivo no esta danado
#   ./Instalar-Craft-Suite.run --extract DIR     extrae los paquetes en DIR sin instalar
#
# Si no tiene permiso de ejecucion (p.ej. copiado por USB):  bash Instalar-Craft-Suite.run
set -euo pipefail
PAYLOAD_OFFSET=@@OFFSET@@
PAYLOAD_SHA256=@@SHA256@@
SELF="$(readlink -f "${BASH_SOURCE[0]}")"
msg() { echo "[craft-suite] $*" >&2; }
die() { msg "ERROR: $*"; if [[ "${QUIET:-0}" != 1 && -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    if command -v kdialog >/dev/null; then kdialog --error "$*" 2>/dev/null || true
    elif command -v zenity >/dev/null; then zenity --error --no-markup --text "$*" 2>/dev/null || true; fi; fi; exit 1; }
payload() { tail -c +$((10#$PAYLOAD_OFFSET + 1)) "$SELF"; }

[[ "$(uname -m)" == x86_64 ]] || die "Solo x86_64 (este equipo es $(uname -m))."
command -v pacman >/dev/null || die "Este instalador es para CachyOS/Arch Linux (no se encontro pacman)."
command -v tar >/dev/null && command -v sha256sum >/dev/null && command -v zstd >/dev/null || die "Faltan tar, sha256sum o zstd."

verify() {
  msg "Verificando integridad del archivo..."
  [[ "$(payload | sha256sum | cut -d' ' -f1)" == "$PAYLOAD_SHA256" ]] || die "El archivo esta danado o incompleto (checksum no coincide). Vuelve a copiarlo."
}

MODE=gui; ARGS=(); DEST=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) QUIET=1; verify; msg "OK: archivo integro."; exit 0 ;;
    --extract) QUIET=1; DEST="${2:?falta DIR}"; shift 2; verify; mkdir -p "$DEST"; payload | tar -xf - -C "$DEST"; msg "Extraido en $DEST/craft-suite"; exit 0 ;;
    --cli) QUIET=1; MODE=cli; shift; ARGS=("$@"); break ;;
    -h|--help) sed -n '2,10p' "$SELF"; exit 0 ;;
    *) QUIET=1; MODE=cli; ARGS=("$@"); break ;;
  esac
done

# Espacio libre necesario: ~1,6 GB (archivo extraido + margen)
BASE="${XDG_CACHE_HOME:-$HOME/.cache}"; mkdir -p "$BASE"
avail=$(df -Pk "$BASE" | awk 'NR==2{print $4}')
(( avail > 1700000 )) || die "Poco espacio libre en $BASE ($((avail/1024)) MB). Hacen falta ~1,7 GB."
WORK="$(mktemp -d -p "$BASE" craft-suite-installer.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

if [[ "$MODE" == gui && -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && command -v kdialog >/dev/null; then
  kdialog --passivepopup "Preparando el instalador de Craft App Suite..." 8 2>/dev/null &
fi
verify
msg "Extrayendo paquetes..."
payload | tar -xf - -C "$WORK"
cd "$WORK/craft-suite"
rc=0
if [[ "$MODE" == cli ]]; then
  ./instalar.sh "${ARGS[@]}" || rc=$?
else
  ./instalar-gui.sh || rc=$?
fi
exit $rc
# ---- fin del script: lo que sigue es el archivo de datos (binario), no se ejecuta ----
