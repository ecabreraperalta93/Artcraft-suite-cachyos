#!/usr/bin/env bash
# Instalador grafico de la Craft App Suite (doble clic en "Instalar Craft Suite").
# Usa kdialog (KDE) o zenity/yad (GNOME, XFCE...) y pkexec para pedir la contrasena.
# Sin entorno grafico o sin esas herramientas, cae al instalador de terminal.
set -uo pipefail
DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
APPS=(photocraft vectorcraft filmcraft lightcraft pdfcraft effectcraft designcraft wordcraft deckcraft gridcraft cadcraft soundcraft)
TITLE="Craft App Suite - Instalador"

descr() { case $1 in
  artcraft-launcher) echo "ArtCraft Launcher (lanzador de la suite)";;
  photocraft) echo "PhotoCraft - editor de fotos";;
  vectorcraft) echo "VectorCraft - graficos vectoriales";;
  filmcraft) echo "FilmCraft - edicion de video";;
  lightcraft) echo "LightCraft - revelado RAW";;
  pdfcraft) echo "PDFCraft - PDF";;
  effectcraft) echo "EffectCraft - efectos y composicion";;
  designcraft) echo "DesignCraft - diseno y maquetacion";;
  wordcraft) echo "WordCraft - procesador de textos";;
  deckcraft) echo "DeckCraft - presentaciones";;
  gridcraft) echo "GridCraft - hojas de calculo";;
  cadcraft) echo "CADCraft - diseno CAD";;
  soundcraft) echo "SoundCraft - edicion de audio";;
  craft-suite-all) echo "TODO: lanzador + las 12 apps";;
esac; }

# ---- sin GUI: terminal ----
if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then exec "$DIR/instalar.sh" "$@"; fi
GUI=""
for g in kdialog zenity yad; do command -v $g >/dev/null && { GUI=$g; break; }; done
if [[ -z "$GUI" || ! -x "$(command -v pkexec || true)" ]]; then
  for t in konsole gnome-terminal xfce4-terminal kitty alacritty xterm; do
    command -v $t >/dev/null || continue
    case $t in gnome-terminal) exec $t -- "$DIR/instalar.sh";; *) exec $t -e "$DIR/instalar.sh";; esac
  done
  exec "$DIR/instalar.sh"
fi

msg()  { case $GUI in kdialog) kdialog --title "$TITLE" --msgbox "$1";; zenity) zenity --info --title "$TITLE" --no-markup --text "$1" --width 420;; yad) yad --title "$TITLE" --text "$1" --button=OK:0 --width 420;; esac; }
err()  { case $GUI in kdialog) kdialog --title "$TITLE" --error "$1";; zenity) zenity --error --title "$TITLE" --no-markup --text "$1" --width 420;; yad) yad --title "$TITLE" --image=dialog-error --text "$1" --button=OK:0 --width 420;; esac; }

# ---- comprobaciones ----
[[ "$(uname -m)" == x86_64 ]] || { err "Solo x86_64 (este equipo es $(uname -m))."; exit 1; }
command -v pacman >/dev/null || { err "Este instalador es para Arch/CachyOS (no se encontro pacman)."; exit 1; }

# ---- seleccion ----
SEL=()
if [[ $# -gt 0 ]]; then SEL=("$@"); else
  ALL=(artcraft-launcher "${APPS[@]}" craft-suite-all)
  case $GUI in
    kdialog)
      args=(); for n in "${ALL[@]}"; do st=off; [[ $n == artcraft-launcher ]] && st=on; args+=("$n" "$(descr $n)" $st); done
      out=$(kdialog --title "$TITLE" --separate-output --checklist "Elige que instalar:" "${args[@]}") || exit 0 ;;
    zenity)
      args=(); for n in "${ALL[@]}"; do st=FALSE; [[ $n == artcraft-launcher ]] && st=TRUE; args+=("$st" "$n" "$(descr $n)"); done
      out=$(zenity --list --checklist --title "$TITLE" --text "Elige que instalar:" --column "" --column "Paquete" --column "Descripcion" --separator=$'\n' --print-column=2 --width 560 --height 480 "${args[@]}") || exit 0 ;;
    yad)
      args=(); for n in "${ALL[@]}"; do st=FALSE; [[ $n == artcraft-launcher ]] && st=TRUE; args+=("$st" "$n" "$(descr $n)"); done
      out=$(yad --list --checklist --title "$TITLE" --text "Elige que instalar:" --column "" --column "Paquete" --column "Descripcion" --separator=$'\n' --print-column=2 --width 560 --height 480 "${args[@]}" | sed '/^$/d') || exit 0 ;;
  esac
  mapfile -t SEL <<<"$out"
fi
[[ ${#SEL[@]} -gt 0 && -n "${SEL[0]}" ]] || { msg "No elegiste nada."; exit 0; }

# ---- instalar (pkexec pide la contrasena en ventana grafica) ----
LOG="$(mktemp /tmp/craft-install.XXXXXX.log)"
case $GUI in
  kdialog) ref=$(kdialog --title "$TITLE" --progressbar "Instalando..." 0); qdbus_ok=1 ;;
esac
# Si hay un agente polkit en la sesion, pkexec muestra la ventana de contrasena del sistema.
# Si no lo hay (p.ej. sesion XRDP/VNC o escritorios minimos), pedimos la contrasena nosotros y usamos sudo.
askpass() { case $GUI in
  kdialog) kdialog --title "$TITLE" --password "$1";;
  zenity)  zenity --password --title "$TITLE";;
  yad)     yad --entry --hide-text --title "$TITLE" --text "$1";;
esac; }
PW=""; USE_PKEXEC=0
for a in $(pgrep -a -u "$(id -u)" . 2>/dev/null | awk '{print $2}' | sed 's|.*/||'); do
  case $a in
    polkit-kde-authentication-agent-1|polkit-gnome-authentication-agent-1|polkit-mate-authentication-agent-1|lxqt-policykit-agent|xfce-polkit|gnome-shell|cinnamon|budgie-wm) USE_PKEXEC=1;;
  esac
done
[[ $EUID -eq 0 ]] && USE_PKEXEC=2
if [[ $USE_PKEXEC -eq 0 ]]; then
  command -v sudo >/dev/null || { err "No se encontro sudo ni un agente de autenticacion."; exit 1; }
  ok=0
  for try in 1 2; do
    PW=$(askpass "Escribe tu contrasena de $USER para instalar:") || exit 0
    if printf '%s\n' "$PW" | sudo -S -p '' -k true 2>/dev/null; then ok=1; break; fi
    [[ $try -eq 1 ]] && err "Contrasena incorrecta. Intentalo de nuevo."
  done
  [[ $ok -eq 1 ]] || { err "Contrasena incorrecta. Se cancelo la instalacion."; exit 1; }
fi
(
  case $USE_PKEXEC in
    1) SHELL=/bin/bash pkexec "$DIR/instalar.sh" --yes "${SEL[@]}" ;;
    2) "$DIR/instalar.sh" --yes "${SEL[@]}" ;;
    0) printf '%s\n' "$PW" | sudo -S -p '' "$DIR/instalar.sh" --yes "${SEL[@]}" ;;
  esac >"$LOG" 2>&1; echo $? > "$LOG.rc"
) &
pid=$!
case $GUI in
  zenity) ( while kill -0 $pid 2>/dev/null; do echo "# Instalando (pide tu contrasena si aparece la ventana)..."; sleep 1; done ) | zenity --progress --pulsate --auto-close --no-cancel --title "$TITLE" --width 420 ;;
  yad) ( while kill -0 $pid 2>/dev/null; do echo "# Instalando..."; sleep 1; done ) | yad --progress --pulsate --auto-close --no-buttons --title "$TITLE" --width 420 ;;
  kdialog) while kill -0 $pid 2>/dev/null; do sleep 1; done; [[ -n "${ref:-}" ]] && qdbus6 ${ref% *} ${ref#* } close 2>/dev/null || true ;;
esac
wait $pid 2>/dev/null
rc=$(cat "$LOG.rc" 2>/dev/null || echo 1)
if [[ $rc -eq 0 ]]; then
  msg "Instalacion completada.\n\nBusca \"ArtCraft Launcher\" y las apps en el menu de aplicaciones."
else
  case $rc in 126|127) why="Cancelaste la autenticacion o no se pudo obtener permisos.";; *) why="$(tail -n 12 "$LOG")";; esac
  err "La instalacion fallo (codigo $rc).\n\n$why\n\nRegistro: $LOG"
  exit $rc
fi
rm -f "$LOG" "$LOG.rc"
