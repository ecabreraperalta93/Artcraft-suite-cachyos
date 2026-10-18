#!/usr/bin/env bash
# Instalador de la Craft App Suite (ArtCraft Launcher + 12 apps) para Arch/CachyOS x86_64.
# Uso:
#   ./instalar.sh                      menu interactivo
#   ./instalar.sh --all                lanzador + las 12 apps (craft-suite-all)
#   ./instalar.sh --launcher           solo el lanzador
#   ./instalar.sh photocraft vectorcraft   apps concretas
#   ./instalar.sh --dry-run [...]      muestra lo que haria, sin instalar
#   ./instalar.sh --yes [...]          no pregunta "Continuar?" (lo usa el instalador grafico)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPS=(photocraft vectorcraft filmcraft lightcraft pdfcraft effectcraft designcraft wordcraft deckcraft gridcraft cadcraft soundcraft)
ALL_NAMES=(artcraft-launcher "${APPS[@]}" craft-suite-all)
DRY=0
YES=()

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -r /etc/arch-release || "$(. /etc/os-release 2>/dev/null; echo "${ID_LIKE:-} ${ID:-}")" == *arch* ]] \
  || die "Este instalador es para Arch/CachyOS."
[[ "$(uname -m)" == x86_64 ]] || die "Solo x86_64 (este equipo es $(uname -m))."
command -v pacman >/dev/null || die "No se encontro pacman."

SUDO=""
[[ $EUID -eq 0 ]] || { command -v sudo >/dev/null || die "Hace falta sudo."; SUDO="sudo"; }

# ---- argumentos ----
SEL=()
INTERACTIVE=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --yes) YES=(--noconfirm) ;;
    --all) SEL+=(craft-suite-all); INTERACTIVE=0 ;;
    --launcher) SEL+=(artcraft-launcher); INTERACTIVE=0 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    -*) die "Opcion desconocida: $1" ;;
    *) ok=0; for n in "${ALL_NAMES[@]}"; do [[ $n == "$1" ]] && ok=1; done
       [[ $ok -eq 1 ]] || die "Paquete desconocido: $1 (validos: ${ALL_NAMES[*]})"
       SEL+=("$1"); INTERACTIVE=0 ;;
  esac
  shift
done

pkgfile() { # ultimo .pkg.tar.zst de un paquete, en el mismo directorio
  local f
  f=$(ls -1 "$DIR/$1"-[0-9]*.pkg.tar.zst 2>/dev/null | sort -V | tail -1)
  [[ -n "$f" ]] || die "Falta el archivo de $1 en $DIR"
  echo "$f"
}

# ---- menu ----
menu() {
  local items=(artcraft-launcher "ArtCraft Launcher" on)
  for a in "${APPS[@]}"; do items+=("$a" "$a" off); done
  items+=(craft-suite-all "Todo (lanzador + 12 apps)" off)
  local out
  if command -v dialog >/dev/null; then
    out=$(dialog --stdout --separate-output --title "Craft App Suite" \
      --checklist "Espacio = marcar, Enter = aceptar" 24 62 15 "${items[@]}") || die "Cancelado."
    clear
    mapfile -t SEL <<<"$out"
  else
    echo "(dialog no esta instalado: menu simple)"
    local i=1 names=()
    for n in artcraft-launcher "${APPS[@]}" craft-suite-all; do echo "  $i) $n"; names+=("$n"); i=$((i+1)); done
    read -rp "Numeros separados por espacio (ej: 1 2 3): " nums
    SEL=(); for k in $nums; do [[ $k =~ ^[0-9]+$ ]] && (( k>=1 && k<=${#names[@]} )) && SEL+=("${names[k-1]}"); done
  fi
  [[ ${#SEL[@]} -gt 0 && -n "${SEL[0]}" ]] || die "No se selecciono nada."
}
[[ $INTERACTIVE -eq 1 ]] && menu

# craft-suite-all ya incluye todo; hay que pasar los .pkg de todo para que pacman -U los resuelva
declare -A seen; PKGS=()
add() { [[ -n ${seen[$1]:-} ]] || { seen[$1]=1; PKGS+=("$(pkgfile "$1")"); }; }
[[ ${#SEL[@]} -gt 0 ]] && add craft-suite-updater
for s in "${SEL[@]}"; do
  if [[ $s == craft-suite-all ]]; then
    for n in artcraft-launcher "${APPS[@]}" craft-suite-all; do add "$n"; done
  else add "$s"; fi
done

# ---- verificar checksums ----
echo "Verificando SHA256SUMS..."
[[ -r "$DIR/SHA256SUMS" ]] || die "Falta SHA256SUMS"
for f in "${PKGS[@]}"; do
  b=$(basename "$f")
  grep -F "  $b" "$DIR/SHA256SUMS" > /tmp/.craft_sum.$$ || die "$b no esta en SHA256SUMS"
  (cd "$DIR" && sha256sum -c --quiet /tmp/.craft_sum.$$) || { rm -f /tmp/.craft_sum.$$; die "Checksum invalido: $b"; }
done
rm -f /tmp/.craft_sum.$$
echo "OK. A instalar:"; printf '  %s\n' "${PKGS[@]##*/}"

if [[ $DRY -eq 1 ]]; then
  echo "[dry-run] $SUDO pacman -U --needed ${PKGS[*]##*/}"; exit 0
fi
$SUDO pacman -U --needed "${YES[@]}" "${PKGS[@]}"
echo "Listo."
