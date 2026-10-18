#!/bin/bash
# Construye los .pkg.tar.zst de la Craft App Suite a partir de los releases OFICIALES de storytold (sin compilar).
# Uso: ./build-all.sh [app ...]    Resultado en ./out/
# Requiere: curl, python3, bsdtar (libarchive), makepkg (base-devel), binutils.
set -uo pipefail
cd "$(dirname "$0")"; OUT=$PWD/out; mkdir -p "$OUT"
APPS="photocraft vectorcraft filmcraft lightcraft pdfcraft effectcraft designcraft wordcraft deckcraft gridcraft cadcraft soundcraft artcraft-launcher"
SEL=("$@"); [ ${#SEL[@]} -eq 0 ] && SEL=($APPS)
# El actualizador ya sabe descargar, verificar, validar y empaquetar: reutilizamos su funcion build_pkg.
for app in "${SEL[@]}"; do
  echo "== $app"
  XDG_DATA_HOME="$PWD/.data" ./updater/craft-suite-update --fetch "$app" || echo "  FALLO $app"

done
cp .data/craft-suite/pkgs/*.pkg.tar.zst "$OUT"/ 2>/dev/null
# Actualizador y metapaquete
(cd updater && makepkg -f --nodeps --skipchecksums && cp craft-suite-updater-*.pkg.tar.zst "$OUT"/)
(cd metapackage && makepkg -f --nodeps && cp craft-suite-all-*.pkg.tar.zst "$OUT"/)
(cd "$OUT" && sha256sum *.pkg.tar.zst > SHA256SUMS)
echo "Listo: $OUT"
