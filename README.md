# Craft Suite para CachyOS / Arch Linux

Instalador y actualizador **no oficial** de la *Craft App Suite* de [storytold](https://github.com/storytold)
(ArtCraft Launcher + PhotoCraft, VectorCraft, FilmCraft, LightCraft, PDFCraft, EffectCraft, DesignCraft,
WordCraft, DeckCraft, GridCraft, CADCraft, SoundCraft) para CachyOS / Arch x86_64.

La suite es un conjunto de alternativas a las herramientas habituales de ofimatia, diseno y CAD, para poder
trabajar en CachyOS sin depender de Windows/macOS:

| Categoria | Referencia habitual | Apps de la suite |
|---|---|---|
| Ofimatia | Microsoft Office | WordCraft (Word), GridCraft (Excel), DeckCraft (PowerPoint) |
| Diseno y foto/video | Adobe | PhotoCraft (Photoshop), VectorCraft (Illustrator), LightCraft (Lightroom), FilmCraft (Premiere), EffectCraft (After Effects), DesignCraft (InDesign), PDFCraft (Acrobat), SoundCraft (Audition) |
| CAD | AutoCAD | CADCraft |

Son proyectos independientes (no oficiales, sin relacion con Microsoft, Adobe ni Autodesk; esas marcas son de sus
duenos y se nombran solo como referencia). Cubren los flujos principales, pero no son clones identicos: pueden faltar
funciones avanzadas o haber diferencias de formato; revisa el repositorio de cada app para ver su alcance.

No se compila nada: se toman los binarios oficiales de storytold (SHA256 verificado) y se empaquetan como
paquetes `pacman`, de modo que se instalan, actualizan y desinstalan limpiamente (`pacman -Rns`).

## Instalar (un clic)
1. Descarga `Instalar-Craft-Suite.run` desde [Releases](../../releases/latest).
2. Dale permisos y ejecuta (o doble clic en el gestor de archivos):
   ```
   chmod +x Instalar-Craft-Suite.run && ./Instalar-Craft-Suite.run
   ```
   Abre una ventana (kdialog / zenity / yad) para elegir que apps instalar. Modo texto: `--cli --all`.
   Integridad: `./Instalar-Craft-Suite.run --check`.

Alternativa: descarga los `.pkg.tar.zst` + `SHA256SUMS` del Release y usa `sudo pacman -U ...`.

## Actualizar sin romper nada
Se instala `craft-suite-update`:
```
craft-suite-update --check                       # que hay nuevo
craft-suite-update                               # actualizar lo instalado
craft-suite-update --rollback wordcraft 0.6.1    # volver a una version anterior
systemctl --user enable --now craft-suite-update.timer   # opcional: solo AVISA cada dia
```
Descarga el release oficial, verifica SHA256, comprueba que sigan `bin/<app>` y `share/` y que no falten
librerias (`ldd`); si algo no valida, **no toca** la version instalada. No modifica `~/.config` ni tus datos.

## Construir los paquetes tu mismo
```
./build-all.sh            # todas, ultima version oficial -> ./out/
./build-all.sh wordcraft  # solo una
```
Requiere `base-devel`, `curl`, `python`, `libarchive`, `binutils`.

## Maquinas sin GPU (VM)
Las apps usan egui/wgpu y fallan sin EGL. Solo en VMs sin GPU real:
`export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json LIBGL_ALWAYS_SOFTWARE=1 WGPU_BACKEND=gl`

## Estado de pruebas
Las 13 piezas (launcher + 12 apps) fueron probadas por el autor y funcionan. Ademas se verifico en una VM CachyOS
(KDE, sin GPU) la instalacion, el arranque y la desinstalacion limpia, y la actualizacion y vuelta atras de
WordCraft y CADCraft con `craft-suite-update`. Los Releases contienen las versiones empaquetadas el 2026-10-13
(launcher 0.3.2, etc.); usa `craft-suite-update` para las mas nuevas. Si encuentras un problema, abre un issue.

## Contenido
`installer/` scripts del instalador · `updater/` actualizador + timer · `tools/` generacion del `.run` ·
`docs/` documentacion (incluye instrucciones para asistentes de IA) · `NOTICE.md` licencias y origen.
