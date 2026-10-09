# HANDOFF — RUSHLINE / HJGAMES

Documento para retomar el trabajo sin el historial de chats. Fecha de corte: **9 de octubre de 2026**. HEAD local y remoto: `a8eebc5` en `master`.

Si un dato no se pudo confirmar en disco o en git, está marcado **(a verificar)**.

---

## 1. Resumen

**RUSHLINE** es un arcade de carreras original en 3D, en español, de la marca **HJGAMES** (también escrito HJgames en créditos). Inspiración conceptual: racers verticales de NES de los 80 y racers callejeros de mediados de los 2000. **No es un simulador.** No usa física de Godot para el auto: la simulación es plana en XZ.

**Para qué sirve:** jugar una etapa de 2000 m entre tráfico, con nitro, clima, temas de ciudad y una meta o tres choques. Hay menú, garaje con mejoras, récords y opciones de audio.

**Quién lo usa:** Hector Juani (cuenta GitHub `Stillset9`). El juego se publica en GitHub Pages para jugarlo en el navegador y también corre en escritorio con Godot. No hay backend, cuentas de usuario ni base de datos.

**Prohibición legal permanente:** no copiar assets, código, sprites, audio, nombres, personajes, vehículos, pistas, logos ni música de NFS, EA, Rockstar, Disturbed, Sony PlayStation, Capcom ni de ningún juego comercial. Solo recursos libres cuya licencia permita uso **personal y comercial**. Atribución se documenta aunque CC0 no la exija.

Repositorio público: https://github.com/Stillset9/rushline  
Juego en el navegador: https://stillset9.github.io/rushline/  
Carpeta local: `/Users/Stillset9/Documents/Juego Nuevo`

No hay `README.md` en la raíz (solo este handoff y créditos de assets). No hay `package.json` ni `.env`.

---

## 2. Stack y versiones

| Pieza | Valor | Notas |
| --- | --- | --- |
| Motor | Godot **4.7.2.stable.official** (`ed1daf0bf`) | Binario: `$HOME/.local/bin/godot` → `$HOME/.local/share/Godot.app` |
| Lenguaje | GDScript | `config_version=5`, features `4.7` + Forward Plus |
| Desktop renderer | `forward_plus` | Obligatorio: `tests/test_project.gd` falla si cambia |
| Web renderer | `gl_compatibility` | Override en `project.godot`. GitHub Pages no tiene COOP/COEP |
| Resolución | 1920×1080 | Stretch `viewport`, aspect `expand` (letterbox, no deforma) |
| Fluidez 3D | `scaling_3d/mode=1`, scale `0.8`, FSR sharpness `0.5` | En Compatibility/web cae a bilineal. Sombras direccionales 2048 |
| Export web | preset `"Web"`, `docs/index.html` | `variant/thread_support=false`, `canvas_resize_policy=2` |
| Plantillas de export | `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` | Solo web, no hay preset desktop |
| Tests | 20 scripts `tests/test_*.gd` + `tests/run_tests.gd` | Headless, necesitan permisos de `user://` |
| Node / Python / npm | **no se usan** | No hay `package.json`, ni venv, ni CI en el repo **(a verificar si hay Actions en GitHub)** |
| Firebase / APIs / DB | **ninguno** | Persistencia solo `user://progress.cfg` y `user://settings.cfg` |

Tipografías: Kenney Future Narrow (UI, CC0) y Orbitron variable peso 700 (intro HJGAMES, SIL OFL 1.1).

Audio de carrera: MP3 CC0. Sting de intro y SFX de motor/choque: síntesis en GDScript, no samples de terceros.

---

## 3. Estructura

```
Juego Nuevo/
├── project.godot              # nombre RUSHLINE, escena principal = intro
├── export_presets.cfg         # un solo preset: Web → docs/index.html
├── ASSETS-LICENSES.md         # superficies, ciudad, naturaleza, intro
├── VEHICLE_ASSET_CREDITS.md   # flota Grab3D
├── RUSHLINE-efectos-visuales.md  # brief para efectos futuros (intro desactualizada)
├── HANDOFF.md                 # este archivo
├── assets/
│   ├── branding/              # Orbitron + OFL.txt + README de la intro
│   ├── kenney/                # ciudad, naturaleza, roads, cars unused, fuente
│   ├── vehicles/              # Grab3D GLB (jugador + 4 tráfico)
│   ├── world/                 # asfalto y concreto Polyhaven CC0
│   └── music/                 # pure_raceway.mp3
├── scenes/                    # intro, title, garage, race, HUD, vehículos, chunk
├── scripts/                   # todo el gameplay (ver abajo)
├── tests/                     # 20 pruebas + run_tests.gd
├── traffic/profiles/          # normal, rapido, pesado, agresivo
├── ui/rushline_theme.tres
├── docs/                      # export web para GitHub Pages
│   ├── .nojekyll              # no borrar
│   ├── .gdignore              # Godot no reimporta el export
│   ├── index.html / .pck / .wasm / .js
│   └── superpowers/           # specs y planes de fase 1–2 (históricos)
├── backups/                   # COPIAS VIEJAS. Sin trackear. Tiene .gdignore
└── audio/, data/, effects/, resources/, shaders/, vehicles/, world/
                               # carpetas vacías de andamiaje. No las uses.
```

### Scripts importantes

| Archivo | Rol |
| --- | --- |
| `scripts/branding/hj_intro.gd` | Timeline 8 s, skip, mute M, audio sintético, salto al título |
| `scripts/branding/intro_stage.gd` | Logo 3D (Label3D extruido), haz, partículas, cámara |
| `scripts/branding/intro_dust.gd` | Polvo 2D sobre el viewport |
| `scripts/branding/hj_mark.gd` | Monograma 2D **ya no está en la escena**. `test_intro` aún llama `HJMark.origin_for` |
| `scripts/ui/title_screen.gd` | Menú: jugar, garaje, récords, opciones, créditos, salir |
| `scripts/ui/garage_screen.gd` | Compra motor / tope / nitro |
| `scripts/core/race_director.gd` | Loop de carrera, pausa, fin, cielo, glow/SSAO web |
| `scripts/vehicles/player_controller.gd` | Movimiento XZ, nitro, drift, steer invertido para la cámara |
| `scripts/vehicles/vehicle_visual.gd` | Import Grab3D, ruedas, faros, tinte PBR |
| `scripts/camera/race_camera.gd` | Chase: HEIGHT 7.5, BEHIND 10.5, LOOK_AHEAD 12 |
| `scripts/world/course.gd` | `STAGE_M = 2000`, 8 temas, 3 climas |
| `scripts/world/course_path.gd` | **Recta identidad** `(lateral, 0, along)`, yaw 0 |
| `scripts/world/road_streamer.gd` | 8 chunks de 40 m, recycle 20 m atrás |
| `scripts/world/road_chunk.gd` | 23 hijos (1 asfalto + 2 bordes + 20 dashes). Asfalto `LENGTH+8` |
| `scripts/world/street_dressing.gd` | Ciudad/naturaleza, `ROAD_CLEAR = 17` |
| `scripts/world/sky_dressing.gd` | Sol + nubes de día; luna + estrellas de noche |
| `scripts/race/contact.gd` | Cajas 1.8×4 m, drop 15 m/s, un golpe por cruce |
| `scripts/race/score_keeper.gd` | Metros × multiplicador, +1 cada 200 m limpios, cap ×5 |
| `scripts/traffic/traffic_manager.gd` | Pool 12, spawn 90 m adelante, 3 carriles −4/0/4 |
| `scripts/meta/progress.gd` | Save `user://progress.cfg` |
| `scripts/meta/game_settings.gd` | Música, SFX, silencio → `user://settings.cfg` |
| `scripts/ui/track_map.gd` | Mapa izquierdo + «Faltan N m» / «Meta» |
| `scripts/ui/control_card.gd` | Tarjeta de teclas arriba a la derecha |

Escena principal: `res://scenes/branding/HJGamesIntro.tscn`.

---

## 4. Cómo correrlo

Godot tiene que estar en `$PATH` (en esta máquina: `export PATH="$HOME/.local/bin:$PATH"`).

### Jugar en el editor / escritorio

```bash
godot --path "/Users/Stillset9/Documents/Juego Nuevo"
```

O abrir la carpeta en el editor de Godot 4.7.2. La intro arranca sola. Esc / Start / A la omiten.

### Importar assets nuevos (clase `class_name` o fuente nueva)

Hasta que corre `--import`, Godot no ve clases nuevas y falla con «Identifier not declared».

```bash
godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --import --quit
```

### Tests (20). Salida 0 = PASS. Hace falta acceso real a `user://` (sandbox de Cursor cuelga).

```bash
godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd
```

### Export web (actualiza Pages)

```bash
godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --export-release "Web" "/Users/Stillset9/Documents/Juego Nuevo/docs/index.html"
```

Luego commit de `docs/index.html` + `docs/index.pck` (y wasm/js si cambiaron) y `git push origin master`.

### Preview local del export (opcional)

Servir `docs/` con cualquier HTTP estático. Las rutas del export de Godot son relativas; no romper eso.

### Deploy

1. Commit convencional en `master` (nunca force-push).
2. Push a `origin` (`https://github.com/Stillset9/rushline.git`).
3. GitHub Pages: source **master** / carpeta **`/docs`**.
4. Estado: `gh api repos/Stillset9/rushline/pages/builds/latest`.
5. URL: https://stillset9.github.io/rushline/

No hay script de CI en el repo. No hay preview de Vercel/Netlify. **(a verificar)** si existe algún workflow de GitHub Actions fuera del árbol local.

Cuando el usuario dice «publicalo / subelo al git / PUBLICA EN EL GIT»: exportar web + commit + push. No commitear `backups/`.

---

## 5. Configuración y servicios

### Variables de entorno

**Ninguna.** No hay `.env` ni `.env.example`.

Persistencia de Godot (no son secretos de servidor):

| Archivo | Para qué |
| --- | --- |
| `user://progress.cfg` | dinero, récord, carreras, niveles de motor/tope/nitro |
| `user://settings.cfg` | `music`, `sfx`, `muted` |

En tests: `Progress.isolated = true` y `GameSettings.isolated = true` para no tocar el disco del usuario.

### Servicios externos

| Servicio | Uso |
| --- | --- |
| GitHub `Stillset9/rushline` | código público |
| GitHub Pages | hosting del juego |
| Godot / plantillas 4.7.2 | build local |

No hay Firebase, Stripe, Auth, analytics ni API keys en el código (búsqueda de `api_key` / `token` / `password` sin hallazgos reales; `docs/index.js` es el runtime de Godot).

### URLs

- Producción: https://stillset9.github.io/rushline/
- Repo: https://github.com/Stillset9/rushline
- Preview: no hay entorno aparte. Lo que está en `master`/`docs` es lo que se ve. **(a verificar)** el estado del último build de Pages tras `a8eebc5` (al pushear quedó `building`).

### Identidad git (solo de ESTE repo, ya está en `.git/config` local)

- `user.name=Hector Juani`
- `user.email=hectorjuani78@gmail.com`

**Nunca** `git config --global`. Nunca `--no-verify`. Nunca force-push a `master`.

---

## 6. Estado actual

### Qué funciona (publicado en `a8eebc5`)

- Intro cinematográfica HJGAMES ~8 s (Orbitron, metal 3D, haz, PRESENTA). Skip Esc/Start/A. Mute con M (usa `GameSettings.muted`). En web el audio espera el primer gesto.
- Menú título, garaje, récords, opciones, créditos. Pausa en carrera: Seguir o Inicio (vuelve al **título**, no a la intro).
- Carrera **recta** 2000 m. Mapa izquierdo en línea vertical. «Faltan N m» / «Meta».
- Tráfico, aceite, lluvia/niebla, 8 temas (el 8.º es **noche**), sol+nubes de día, luna+estrellas de noche.
- Edificios/árboles empujados a `|x| ≥ 17`.
- Contacto planar, 3 golpes = fin, score que nunca baja, multiplicador ×1–×5.
- Flota Grab3D, asfalto/concreto Polyhaven, ciudad Kenney, música Pure Raceway.
- 20 tests en verde tras el último cambio.
- Export web en `docs/` incluido en el commit.

### A medias / diferido a propósito

- **Recentering del origen del mundo** (Z crece sin reset): pedido nunca hecho; no empezarlo solo.
- **Toggle de ajustes “saltar intro”**: diferido. Hoy se salta con input, no hay checkbox.
- **Glow/SSAO en web**: apagados a propósito (bloom Compatibility volvía el cielo blanco).
- `RUSHLINE-efectos-visuales.md` describe la intro **vieja** (4 s, monograma HJ, texto «HJgames presents»). La intro real es la de `a8eebc5`.
- `scripts/branding/hj_mark.gd` sigue en el repo pero la escena de intro ya no lo instancia.
- Carpetas raíz vacías (`audio/`, `data/`, etc.).
- `backups/` sin commitear (a propósito).

### Bugs / rarezas conocidas

- Torres altas a `|x|=17` **se sienten** encima de la pista aunque el AABB no cruza el asfalto. El usuario aceptó el publish con clearance.
- Primera noche jugable (`races % 8 == 7`) cae con lluvia porque clima = `races % 3`. Noche despejada: `races == 15`. No forzar noche siempre clara salvo que lo pidan.
- Primeros frames del viewport a veces son color de cielo vacío; hay que simular y esperar frames antes de screenshots.
- `Input.action_press` **no** enciende `is_action_just_pressed` en el mismo frame de un test. Por eso existe `confirm_pause()`.
- Headless usa renderer dummy: `get_viewport().get_texture()` es null. Capturas reales: **sin** `--headless`.
- `street.free()` en tests logueaba `Parameter material is null`. Usar `queue_free()`.
- En zsh, `status` es read-only; en bucles de Pages usar otro nombre de variable.
- Orbitron no sirve como `TextMesh` (contornos que se cruzan). El logo 3D es un stack de `Label3D`.
- `CPUParticles3D.amount_ratio` **no existe** en 4.7.2; se usa `visible` + alpha.

### Git status al corte

```
On branch master
Your branch is up to date with 'origin/master'.
Untracked: backups/
```

No hay cambios staged ni modificados. Solo `backups/` sin trackear. **No commitearlo.**

---

## 7. Historial de decisiones

### Gameplay cerrado (no cambiar sin motivo técnico)

- Choque: −15 m/s, piso 8 m/s, la carrera sigue. Tres choques = fin. También fin al llegar a 2000 m.
- Score = metros acumulados × multiplicador. **Nunca baja.** +1 al multi cada 200 m limpios, cap ×5, hit vuelve a ×1 (el resto de metros de ese frame se guarda). Distancia/score del frame del hit usan la velocidad **previa**.
- Cajas 1.8×4 m (mitades 0.9 y 2.0). Overlap solo si el hueco en **cada** eje es **estrictamente** menor que la suma de mitades. Un golpe por cruce (`in_contact`).
- HUD km/h = `int(round(m/s * 3.6))` como `%03d km/h`.
- 3 carriles X = −4, 0, 4. Ancho de asfalto 14 m. Clamp jugador X ∈ [−6, 6].
- Start 8 m/s. Máx inicial 30, rampa +0.15/s, cap 70. Garaje tope: +3 inicial y +3 cap por nivel. Motor: +1.5 accel. Nitro: +2 boost y drain × 0.82^nivel.
- Aceleración 8, freno 18, sin marcha atrás. Steer lateral target `steer*12` a 28 m/s²; al soltar, grip 18. Drift si `|steer|≥0.65`, speed>18, no freno, no aceite: grip ×0.42 y bleed 3. Aceite grip 0.18 / 0.85 s. Clima: despejado 1, lluvia 0.72, niebla 0.88.
- Cámara hermana del auto, no hija. Solo X suavizado peso `1-exp(-5*delta)`. FOV 60→72 a 70 m/s. Nitro +6 FOV, tope 78. Shake 0.16 s al choque.
- **Steer:** `_steer_value` = `-Input.get_axis("steer_left", "steer_right")`. La cámara mira +Z, la derecha de pantalla es mundo −X. D mueve a la derecha de pantalla. Los tests asignan `steer_input` directo y esperan que −1 mueva x&lt;0. **No invertir** las acciones del menú de opciones (ahí `steer_left/right` bajan/suben volumen).

### Arte e identidad

- Intro actual: protagonista **HJGAMES**, no RUSHLINE. RUSHLINE aparece en el menú.
- Autos: Grab3D CC0, frente +Z, escala a 4 m de largo. Kenney Car Kit **queda en disco pero no se instancia**. Quaternius rechazado (low poly / zip de itch). Sketchfab no: marcas o licencia dudosa.
- Ciudad: Kenney City Kit Commercial texturizado. Puentes laterales en x=±24, nunca sobre la calzada.
- Asfalto: Polyhaven Asphalt 02, contraste subido. `apply_palette` debe dejar albedo **exacto** del tema (el test pone rojo/verde).
- Road chunk: exactamente **23** hijos. No agregar hijos sin actualizar `test_road`. Pintura no asfalto con Y &gt; 0.05.
- Pista curva (commit `a5ed7bd`): 360 m rectos + arcos 90° radio 90. El usuario pidió **sacarla**. `a8eebc5` deja `CoursePath` como identidad. `present` / `place_span` / `samples` se quedaron para no romper callers. El mapa dibuja lo que `samples` devuelve, así que sale una franja recta sola.
- Fórmula de arco (por si alguien la revive): yaw positivo de Godot, `x += (-cos(yaw1)+cos(yaw))/curv`, `z += (sin(yaw1)-sin(yaw))/curv`. La primera versión plegaba la pista (Z negativo). **No copiar logos de circuitos reales.**

### Rendering / web

- Glow de **carrera** off en web. Glow de **intro** solo desktop. SSAO de carrera off en web.
- Fog mínimo 0.0009 + aerial 0.18 siempre; el clima hace `max()` con ese piso.
- Día: sol energy 2.2, ambient 0.48, pitch ~0.2. Noche: 0.28 / 0.2 / pitch 0.22. Cuerpos celestes en el cono de la chase cam (FOV vertical 60, mira ~15° abajo: el sol alto queda fuera de cuadro).
- `docs/.nojekyll` y `docs/.gdignore` no se borran.

### Descartado

| Intento | Por qué no |
| --- | --- |
| Física de Godot para el auto | El diseño es cajas planas y tests deterministas |
| Hilos en export web | Pages sin COOP/COEP |
| Glow web | Cielo blanco en Compatibility |
| TextMesh para Orbitron | Convex decompose fail |
| `amount_ratio` en CPUParticles | No existe en esta versión |
| Pack Quaternius Downtown | Volumen / itch gate / no cabe en Pages |
| Modelos Sketchfab de marcas | Licencia / IP |
| Extra stripe cian en el sports-car | El GLB ya trae raya blanca |
| Tint lerp del asfalto | Rompía `test_course` (albedo exacto) |
| Pista curva “realista” | El usuario volvió a pedir recta |
| Copiar Sony/Capcom en la intro | IP. Identidad propia HJGAMES |
| Commitear `backups/` | Tienen `class_name` y Godot cargaba el VehicleVisual viejo hasta poner `.gdignore` |

### Commits recientes (estilo `feat:` / `fix:` / `docs:` en inglés)

`a8eebc5` intro + recta → `00d664d` cielo día/noche + clearance → `a5ed7bd` curva (revertida en gameplay) → `68ab953` autos Grab3D + ciudad.

---

## 8. Pendientes (prioridad)

1. **Nada bloqueante.** El build de Pages de `a8eebc5` hay que **confirmar** que quedó `built` y no error.
2. No empezar recentering de origen ni toggle “saltar intro” salvo pedido explícito.
3. Si piden más espacio visual en la calle: subir `ROAD_CLEAR` o bajar altura de rascacielos; no deshacer el clamp a 17.
4. Si piden curvas otra vez: reactivar layout en `course_path.gd` **y** actualizar `test_course` (hoy exige recta y span X ≈ 0).
5. Limpieza opcional no pedida: borrar o dejar de testear `hj_mark.gd`; actualizar `RUSHLINE-efectos-visuales.md`; ignorar `backups/` en `.gitignore`.
6. No reactivar glow web, no meter Quaternius, no copiar circuitos con nombre.

Cuando el usuario pida publicar: export Web + commit (sin `backups/`) + push + chequear Pages.

---

## 9. Convenciones

No hay `.cursor/rules`, `.cursorrules` ni `AGENTS.md` **en este repo**. Hay un plugin de GitLab en Cursor (no se usa GitLab aquí) y reglas del usuario/agente:

### Git

- Conventional commits: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`.
- Commits **solo si el usuario lo pide**. «Publicalo» cuenta como pedido de commit **y** push **y** export.
- Mensaje en inglés, 1–2 frases, el **porqué**. HEREDOC, sin `--no-verify`, sin amend salvo las reglas estrictas del usuario.
- Identidad local ya puesta. Nunca global. Nunca force-push a master.

### Código

- No inventar features ni sacar sistemas que andan sin razón técnica.
- No marcar “listo” sin tests (o sin captura si es visual). Suite = 20 tests, todos verdes.
- No dejar scripts `tests/snap_*.gd` en el repo.
- `class_name` nueva → `--import` antes de referenciarla.
- UI 1920×1080; no tocar renderer desktop ni stretch. Web override se queda.
- Rutas de Pages relativas.
- Recursos: licencia comercial comprobada, archivo de créditos, nada de procedencia dudosa.
- Español en UI del juego. Código y mensajes de commit en inglés.

### Controles (producto)

- Conducir: A izquierda, D derecha; S / abajo / espacio freno; Shift o gatillo derecho nitro.
- Intro: Esc / Start / A omiten; M silencio.
- Menús: arriba/abajo o W/S, Enter/A/Start confirman, Esc atrás/salir.
- Pausa: Esc abre, arriba Seguir, abajo Inicio, Enter confirma, Esc reanuda.

### Preferencias del usuario en este proyecto

- Hablarle en español, directo.
- No copiar juegos AAA.
- No publicar hasta que lo pida.
- Máquina de referencia: Intel UHD Graphics 617; cuidar luces, sombras, glow y partículas.

---

## 10. Gotchas

1. **`backups/.gdignore` es obligatorio.** Sin él Godot ejecuta `backups/vehicles/vehicle_visual.gd` y `test_variety` falla. No borrar el ignore. No commitear backups.
2. **`docs/.gdignore` y `docs/.nojekyll`:** el export no debe reimportarse; Jekyll no debe tragar `_` de Godot.
3. Tests headless: en Cursor usar permisos `all`. El sandbox bloquea `user://`.
4. Primer spawn de tráfico: X −4, Z 90, scale 0.95 (`test_traffic`).
5. `RoadStreamer.origins()` devuelve arco almacenado, no `position.z`. En recta coinciden.
6. `PlayerController.tick` copia `position` a `road_*` mientras `on_straight` (hoy siempre). Tests que asignan `position.x` entre ticks siguen valiendo.
7. `test_camera` llama `tick()`, no `follow()`. Con path identidad da igual; si vuelven las curvas, `follow()` deja de usar `tick()` cuando `along + LOOK_AHEAD ≥ STRAIGHT_M`. Por eso `STRAIGHT_M` está en 100000.
8. Overlap de asfalto `LENGTH+8` era para juntas de curva; en recta es inocuo, no lo saques sin mirar grietas.
9. Fill 900×900 bajo StreetDressing se recentra al chunk del medio para no mostrar el vacío.
10. `Basis.looking_at` apunta **−Z** al target. En cielo se pasa `-toward_sky` para que `basis.z` mire al sol/luna.
11. `draw_polyline` necesita ≥2 puntos. `PackedVector2Array` se copia al asignar: `TrackMap._fit` arma el array y después asigna.
12. No reparentar un `AudioStreamPlayer` que está sonando (intro mueve el sting a `root`).
13. Clearcoat es Forward+; en web se simplifica. No dependas de él en Pages.
14. Godot Image `get_pixel` en headless es más lineal; PNG vía PIL es sRGB. Y=0 es arriba, igual que `unproject`.
15. Auto-review de Cursor a veces bloquea `git push` a `rushline` o descargas de grab3d.com. Reintentar con aprobación si el usuario lo pidió.
16. `test_course` instancia `StreetDressing` y llama `blocks_road()` / `blocks_path()`; liberar con `queue_free()`.
17. Primeras noches + lluvia: no es bug de cielo, es `races % 3`.
18. Brief `RUSHLINE-efectos-visuales.md` miente sobre la intro actual: no lo uses como spec de branding sin leer `hj_intro.gd`.

### Comandos que fallan y arreglo

| Fallo | Qué hacer |
| --- | --- |
| `Identifier not declared` (CoursePath, IntroStage, SkyDressing…) | `godot --import --quit` |
| Tests cuelgan en Cursor | permisos `all` |
| `test_variety` carga VehicleVisual viejo | `backups/.gdignore` |
| Export web boom / cielo blanco | no reactivar glow; Compatibility |
| Screenshot headless negro/null | quitar `--headless` |
| Pages 404 en `/rushline/` | comprobar `docs/.nojekyll` y que el export esté commiteado |
| `status: read-only variable` en zsh | no usar `status` como nombre |

---

## 11. Prompt para retomar

Pegá esto a un agente nuevo:

> Leé `HANDOFF.md` en la raíz de este repo (RUSHLINE / HJGAMES, Godot 4.7.2) y continuá desde la sección Pendientes. El código está en `/Users/Stillset9/Documents/Juego Nuevo`, remoto `https://github.com/Stillset9/rushline`, Pages `https://stillset9.github.io/rushline/`. HEAD esperado: `a8eebc5`. No copies juegos comerciales. No inventes features. No commitees ni pushees salvo que yo lo pida (si digo “publicalo”, exportá Web a `docs/`, commit convencional sin `backups/`, y push a `master`). Corré los 20 tests con `godot --headless --path "…" --script res://tests/run_tests.gd` y permisos completos. La carrera es recta; la intro es HJGAMES 8 s; el origen del mundo y el toggle de skip-intro siguen diferidos. Confirmá primero que el build de GitHub Pages de `a8eebc5` terminó bien, y después preguntame qué sigue.

---

## Apéndice A — Flujo de pantallas

Intro (`HJGamesIntro`) → Título → Jugar (`race.tscn`) o Garaje. Pausa → Inicio vuelve al **título**. Fin de carrera: Enter reinicia la escena de carrera (no la intro). Progreso y audio viven en `user://` y sobreviven.

## Apéndice B — Temas y clima

Temas (`progress.races % 8`): ciudad, costa, desierto, bosque, nieve, atardecer, industrial, noche.  
Climas (`progress.races % 3`): despejado, lluvia, niebla.  
Ciudad visual (edificios) también en atardecer, industrial y noche.

## Apéndice C — Licencias en uso

- Grab3D vehículos: CC0-1.0  
- Kenney city / roads / nature / font: CC0  
- Polyhaven asphalt + concrete: CC0  
- Orbitron: SIL OFL 1.1 (nombre reservado “Orbitron”; no relicenciar ni vender la fuente sola)  
- Pure Raceway, MintoDog, OpenGameArt: CC0  
- Sting intro y SFX: originales del proyecto  

Textos de licencia en `ASSETS-LICENSES.md`, `VEHICLE_ASSET_CREDITS.md`, `assets/branding/OFL.txt`, `assets/music/pure_raceway-license.txt`.
