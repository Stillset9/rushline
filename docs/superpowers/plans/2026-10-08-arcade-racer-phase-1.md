# Fase 1 — carrera jugable — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dejar un proyecto Godot 4 jugable con carretera infinita, coche que acelera solo, dirección, freno, cámara, HUD de velocidad y tráfico básico en carriles.

**Architecture:** La simulación es plana (X lateral, Z hacia delante). La presentación es 3D con cámara alta e inclinada. `RaceDirector` es el único bucle: actualiza el techo de velocidad, mueve al jugador, integra la distancia y ordena a la carretera, al tráfico y a la cámara. Tramos y coches salen de reservas creadas al cargar.

**Tech Stack:** Godot 4.5 o superior, GDScript, renderer Forward+, pruebas headless con `godot --headless --script`.

## Global Constraints

- Godot 4.5 o superior, GDScript, renderer Forward+.
- Resolución base 1920×1080, estirado `viewport`, aspecto `expand`.
- Escena principal: `res://scenes/race/race.tscn`.
- Unidades internas: metros y segundos. El HUD muestra km/h con `int(round(m/s * 3.6))`.
- Tres carriles, centros X = -4, 0 y 4. Calzada de 14 m. El jugador no sale de X = [-6, 6].
- El coche arranca a 8 m/s. Techo inicial 30 m/s, sube 0,15 m/s por segundo, máximo 70 m/s.
- Aceleración 8 m/s². Freno 18 m/s², sin bajar de 8 m/s ni marcha atrás.
- Dirección: persigue `steer * 12` m/s a 28 m/s²; sin entrada, vuelve a 0 a 18 m/s².
- Tramos de 40 m, reserva de 8. Se reciclan cuando su borde delantero queda a más de 20 m por detrás del jugador.
- Tráfico: reserva de 12, aparición cada 1,2 s a 90 m, hueco mínimo 18 m, retirada a 30 m atrás, perfil `normal` a 22 m/s.
- No hay colisiones, nitro, puntuación, menús, audio, clima ni obstáculos en esta fase.
- No se copian assets ni nombres de juegos existentes. Los coches son cajas y cilindros originales.
- Durante la carrera no se llama a `instantiate` ni a `queue_free` después de crear las reservas.
- Comentarios en español, solo donde la regla no se lee sola.
- Los commits del plan son locales. No hacer push.

## Estructura de archivos

- `project.godot` — ventana, renderer, escena principal, acciones de entrada.
- `.gitignore` — ignora `.godot/`.
- `tests/run_tests.gd` — descubre `tests/test_*.gd` y termina con código 1 si alguno falla.
- `tests/test_project.gd` — ventana, estirado y renderer.
- `tests/test_ai_profile.gd` — campos de `normal.tres`.
- `tests/test_player_motion.gd` — aceleración, freno y dirección, sin escena.
- `tests/test_player_scene.gd` — malla del jugador y `tick` con entrada inyectada.
- `tests/test_race_director.gd` — techo, distancia y señales.
- `tests/test_road.gd` — orígenes, reciclado y marcas del tramo.
- `tests/test_traffic.gd` — elección de carril, aparición, estilo y retirada.
- `tests/test_camera_hud.gd` — FOV, suavizado y texto del HUD.
- `tests/test_input.gd` — acciones de teclado y gamepad.
- `tests/test_race.gd` — escena completa con `simulate` a delta fijo.
- `scripts/traffic/ai_profile.gd` — recurso de perfil de IA.
- `traffic/profiles/normal.tres` — perfil de la Fase 1.
- `scripts/vehicles/vehicle_visual.gd` — construye la malla compartida. No está en la spec; evita duplicar la caja y las ruedas en jugador y tráfico.
- `scripts/vehicles/player_controller.gd` — integración de movimiento y entrada.
- `scenes/vehicles/player_vehicle.tscn` — coche del jugador.
- `scripts/core/race_director.gd` — techo, distancia, señales y bucle.
- `scripts/world/road_chunk.gd` — genera asfalto y marcas. La spec pide marcas generadas en código; este archivo es el único que las crea.
- `scenes/world/road_chunk.tscn` — raíz del tramo.
- `scripts/world/road_streamer.gd` — reserva y reciclado.
- `scripts/traffic/traffic_vehicle.gd` — un coche de la reserva.
- `scenes/vehicles/traffic_vehicle.tscn` — escena de ese coche.
- `scripts/traffic/traffic_manager.gd` — huecos, carriles, aparición y retirada.
- `scripts/camera/race_camera.gd` — seguimiento y FOV.
- `scripts/ui/speed_hud.gd` — texto de velocidad.
- `scenes/ui/speed_hud.tscn` — panel del HUD.
- `scenes/race/race.tscn` — escena jugable.
- `.gitkeep` en `vehicles/`, `world/`, `ui/`, `effects/`, `audio/`, `data/`, `shaders/`, `resources/`.

## Prerrequisito

`godot --version` debe imprimir una versión 4.3 o superior. Si el comando no existe, instalar Godot 4.3+ y dejar el binario disponible como `godot` antes de la tarea 1. No sustituir el binario por un Godot 3.

Comando de pruebas, siempre desde el directorio del proyecto:

```bash
godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd
```

Salida de éxito: una línea `PASS` por cada archivo `test_*.gd` y código de salida 0. Salida de fallo: una línea `FAIL` con el nombre del archivo y el motivo, código de salida 1.

---

### Task 1: Proyecto y corredor de pruebas

**Files:**
- Create: `.gitignore`
- Create: `project.godot`
- Create: `tests/run_tests.gd`
- Create: `tests/test_project.gd`
- Create: `vehicles/.gitkeep`
- Create: `world/.gitkeep`
- Create: `ui/.gitkeep`
- Create: `effects/.gitkeep`
- Create: `audio/.gitkeep`
- Create: `data/.gitkeep`
- Create: `shaders/.gitkeep`
- Create: `resources/.gitkeep`

**Interfaces:**
- Consumes: nada.
- Produces: `tests/run_tests.gd` carga cada `res://tests/test_*.gd`, llama `run(tree: SceneTree) -> Array` y trata cada string devuelto como un fallo. Un array vacío es un pase.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_project.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var width: int = int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var height: int = int(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var mode: String = str(ProjectSettings.get_setting("display/window/stretch/mode"))
	var aspect: String = str(ProjectSettings.get_setting("display/window/stretch/aspect"))
	var renderer: String = str(ProjectSettings.get_setting("rendering/renderer/rendering_method"))
	if width != 1920:
		failed.append("width %s" % width)
	if height != 1080:
		failed.append("height %s" % height)
	if mode != "viewport":
		failed.append("stretch mode %s" % mode)
	if aspect != "expand":
		failed.append("stretch aspect %s" % aspect)
	if renderer != "forward_plus":
		failed.append("renderer %s" % renderer)
	return failed
```

Crear `tests/run_tests.gd`:

```gdscript
extends SceneTree

func _initialize() -> void:
	# El árbol todavía no está listo dentro de _initialize. Las pruebas que
	# instancian escenas necesitan _ready inmediato, y eso ocurre al diferir.
	call_deferred("_run_all")


func _run_all() -> void:
	var failed := 0
	var dir := DirAccess.open("res://tests")
	if dir == null:
		print("FAIL tests directory missing")
		quit(1)
		return
	var names: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			names.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	for test_name in names:
		var suite: RefCounted = load("res://tests/%s" % test_name).new()
		var errors: Array = suite.run(self)
		if errors.is_empty():
			print("PASS %s" % test_name)
		else:
			failed += 1
			print("FAIL %s %s" % [test_name, ", ".join(errors)])
	quit(1 if failed > 0 else 0)
```

Crear un `project.godot` incompleto a propósito, para que la prueba falle por los ajustes y no porque falte el proyecto:

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Carrera Arcade"
config/features=PackedStringArray("4.3", "Forward Plus")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: código de salida 1 y una línea que empiece por `FAIL test_project.gd`.

- [ ] **Step 3: Write minimal implementation**

Sustituir `project.godot` por:

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Carrera Arcade"
config/features=PackedStringArray("4.3", "Forward Plus")

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="viewport"
window/stretch/aspect="expand"

[rendering]

renderer/rendering_method="forward_plus"
```

Crear `.gitignore`:

```gitignore
.godot/
```

Crear archivos vacíos `vehicles/.gitkeep`, `world/.gitkeep`, `ui/.gitkeep`, `effects/.gitkeep`, `audio/.gitkeep`, `data/.gitkeep`, `shaders/.gitkeep`, `resources/.gitkeep`.

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_project.gd` y código de salida 0.

- [ ] **Step 5: Commit**

```bash
git init
git add .gitignore project.godot tests/run_tests.gd tests/test_project.gd vehicles/.gitkeep world/.gitkeep ui/.gitkeep effects/.gitkeep audio/.gitkeep data/.gitkeep shaders/.gitkeep resources/.gitkeep docs/superpowers/specs/2026-10-08-arcade-racer-design.md docs/superpowers/plans/2026-10-08-arcade-racer-phase-1.md
git commit -m "$(cat <<'EOF'
chore: scaffold Godot 4 project for the arcade race

EOF
)"
```

---

### Task 2: Perfil de IA

**Files:**
- Create: `scripts/traffic/ai_profile.gd`
- Create: `traffic/profiles/normal.tres`
- Create: `tests/test_ai_profile.gd`

**Interfaces:**
- Consumes: el corredor de la tarea 1.
- Produces: `AiProfile` con `id: String`, `speed_mps: float`, `lane_change_interval: float`, `aggression: float`. Recurso `res://traffic/profiles/normal.tres` con id `normal`, 22 m/s, intervalo 0, agresión 0.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_ai_profile.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var profile: Resource = load("res://traffic/profiles/normal.tres")
	if profile == null:
		failed.append("missing normal.tres")
		return failed
	if str(profile.get("id")) != "normal":
		failed.append("id %s" % profile.get("id"))
	if not is_equal_approx(float(profile.get("speed_mps")), 22.0):
		failed.append("speed %s" % profile.get("speed_mps"))
	if not is_equal_approx(float(profile.get("lane_change_interval")), 0.0):
		failed.append("interval %s" % profile.get("lane_change_interval"))
	if not is_equal_approx(float(profile.get("aggression")), 0.0):
		failed.append("aggression %s" % profile.get("aggression"))
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_ai_profile.gd` y código de salida 1. `test_project.gd` sigue en PASS.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/traffic/ai_profile.gd`:

```gdscript
class_name AiProfile
extends Resource

@export var id: String = ""
@export var speed_mps: float = 0.0
@export var lane_change_interval: float = 0.0
@export var aggression: float = 0.0
```

Crear `traffic/profiles/normal.tres`:

```ini
[gd_resource type="Resource" script_class="AiProfile" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/traffic/ai_profile.gd" id="1_profile"]

[resource]
script = ExtResource("1_profile")
id = "normal"
speed_mps = 22.0
lane_change_interval = 0.0
aggression = 0.0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_ai_profile.gd`, `PASS test_project.gd`, código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/traffic/ai_profile.gd traffic/profiles/normal.tres tests/test_ai_profile.gd
git commit -m "$(cat <<'EOF'
feat: add the normal traffic AI profile

EOF
)"
```

---

### Task 3: Integración de movimiento del jugador

**Files:**
- Create: `scripts/vehicles/player_controller.gd`
- Create: `tests/test_player_motion.gd`

**Interfaces:**
- Consumes: nada de escenas.
- Produces:
  - `PlayerController.step_longitudinal(speed: float, max_speed: float, braking: bool, delta: float) -> float`
  - `PlayerController.step_lateral(lateral: float, steer: float, delta: float) -> float`
  - `PlayerController.step_x(x: float, lateral: float, delta: float) -> Vector2` donde `x` es la posición nueva e `y` la velocidad lateral nueva.
  - Constantes: `MIN_SPEED_MPS = 8`, `ACCEL_MPS2 = 8`, `BRAKE_MPS2 = 18`, `LATERAL_SPEED_MPS = 12`, `LATERAL_ACCEL_MPS2 = 28`, `LATERAL_GRIP_MPS2 = 18`, `X_LIMIT = 6`.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_player_motion.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var player: GDScript = load("res://scripts/vehicles/player_controller.gd")
	var accelerated: float = player.step_longitudinal(8.0, 30.0, false, 1.0)
	if not is_equal_approx(accelerated, 16.0):
		failed.append("accel %s" % accelerated)
	var braked: float = player.step_longitudinal(20.0, 30.0, true, 1.0)
	if not is_equal_approx(braked, 8.0):
		failed.append("brake floor %s" % braked)
	var held: float = player.step_longitudinal(8.0, 30.0, true, 1.0)
	if not is_equal_approx(held, 8.0):
		failed.append("brake hold %s" % held)
	var steered: float = player.step_lateral(0.0, 1.0, 0.1)
	if not is_equal_approx(steered, 2.8):
		failed.append("steer %s" % steered)
	var gripped: float = player.step_lateral(12.0, 0.0, 0.5)
	if not is_equal_approx(gripped, 3.0):
		failed.append("grip %s" % gripped)
	var slid: Vector2 = player.step_x(0.0, 2.0, 0.5)
	if not is_equal_approx(slid.x, 1.0) or not is_equal_approx(slid.y, 2.0):
		failed.append("slide %s" % slid)
	var clamped: Vector2 = player.step_x(5.5, 12.0, 0.1)
	if not is_equal_approx(clamped.x, 6.0) or not is_equal_approx(clamped.y, 0.0):
		failed.append("clamp %s" % clamped)
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_player_motion.gd` porque el script no existe. Código 1.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/vehicles/player_controller.gd`:

```gdscript
class_name PlayerController
extends Node3D

const MIN_SPEED_MPS := 8.0
const ACCEL_MPS2 := 8.0
const BRAKE_MPS2 := 18.0
const LATERAL_SPEED_MPS := 12.0
const LATERAL_ACCEL_MPS2 := 28.0
const LATERAL_GRIP_MPS2 := 18.0
const X_LIMIT := 6.0

var speed_mps: float = MIN_SPEED_MPS
var lateral_speed_mps: float = 0.0
var max_speed_mps: float = 30.0
var read_input_devices: bool = true
var steer_input: float = 0.0
var brake_input: bool = false


static func step_longitudinal(speed: float, max_speed: float, braking: bool, delta: float) -> float:
	if braking:
		return maxf(move_toward(speed, MIN_SPEED_MPS, BRAKE_MPS2 * delta), MIN_SPEED_MPS)
	return clampf(move_toward(speed, max_speed, ACCEL_MPS2 * delta), MIN_SPEED_MPS, max_speed)


static func step_lateral(lateral: float, steer: float, delta: float) -> float:
	var target := steer * LATERAL_SPEED_MPS
	var rate := LATERAL_GRIP_MPS2 if is_zero_approx(steer) else LATERAL_ACCEL_MPS2
	return move_toward(lateral, target, rate * delta)


static func step_x(x: float, lateral: float, delta: float) -> Vector2:
	var next_x := x + lateral * delta
	if next_x < -X_LIMIT or next_x > X_LIMIT:
		return Vector2(clampf(next_x, -X_LIMIT, X_LIMIT), 0.0)
	return Vector2(next_x, lateral)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_player_motion.gd` y código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/vehicles/player_controller.gd tests/test_player_motion.gd
git commit -m "$(cat <<'EOF'
feat: add arcade speed and steering integration

EOF
)"
```

---

### Task 4: Coche del jugador en escena

**Files:**
- Create: `scripts/vehicles/vehicle_visual.gd`
- Create: `scenes/vehicles/player_vehicle.tscn`
- Modify: `scripts/vehicles/player_controller.gd`
- Create: `tests/test_player_scene.gd`

**Interfaces:**
- Consumes: `step_longitudinal`, `step_lateral`, `step_x`.
- Produces:
  - `VehicleVisual.build(parent: Node3D) -> MeshInstance3D` crea un hijo `Body` (caja 1,8 × 0,5 × 4,0 m, color `#E8E4DC`) y cuatro hijos `Wheel`.
  - `PlayerController.tick(delta: float) -> void` lee el freno y `Input.get_axis("steer_left", "steer_right")` salvo que `read_input_devices` sea false; en ese caso usa `brake_input` y `steer_input`. Actualiza `speed_mps`, `lateral_speed_mps` y `position`.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_player_scene.gd`:

```gdscript
extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var player: Node3D = load("res://scenes/vehicles/player_vehicle.tscn").instantiate()
	tree.root.add_child(player)
	var body := player.get_node_or_null("Body") as MeshInstance3D
	if body == null or body.mesh == null:
		failed.append("missing body")
		return failed
	var size: Vector3 = (body.mesh as BoxMesh).size
	if not size.is_equal_approx(Vector3(1.8, 0.5, 4.0)):
		failed.append("body size %s" % size)
	var paint: Color = body.material_override.albedo_color
	if paint != Color("e8e4dc"):
		failed.append("body color %s" % paint)
	if player.get_children().filter(func(node: Node) -> bool: return str(node.name).begins_with("Wheel")).size() != 4:
		failed.append("wheel count")
	player.read_input_devices = false
	player.brake_input = false
	player.steer_input = 0.0
	player.max_speed_mps = 30.0
	player.tick(1.0)
	if not is_equal_approx(player.speed_mps, 16.0):
		failed.append("tick speed %s" % player.speed_mps)
	if not is_equal_approx(player.position.z, 16.0):
		failed.append("tick z %s" % player.position.z)
	player.steer_input = -1.0
	player.tick(0.1)
	if player.position.x >= 0.0:
		failed.append("tick x %s" % player.position.x)
	player.queue_free()
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_player_scene.gd` porque la escena no existe. Código 1.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/vehicles/vehicle_visual.gd`:

```gdscript
class_name VehicleVisual
extends RefCounted

const BODY_COLOR := Color("e8e4dc")
const WHEEL_COLOR := Color("1a1a1a")


static func build(parent: Node3D) -> MeshInstance3D:
	var body := _box("Body", Vector3(0.0, 0.55, 0.0), Vector3(1.8, 0.5, 4.0), BODY_COLOR)
	parent.add_child(body)
	var offsets: Array[Vector3] = [
		Vector3(-0.85, 0.33, 1.4),
		Vector3(0.85, 0.33, 1.4),
		Vector3(-0.85, 0.33, -1.4),
		Vector3(0.85, 0.33, -1.4),
	]
	var wheel_names: Array[String] = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	for i in offsets.size():
		parent.add_child(_cylinder(wheel_names[i], offsets[i]))
	return body


static func _box(node_name: String, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.material_override = _material(color)
	return mesh_instance


static func _cylinder(node_name: String, at: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.28
	mesh.bottom_radius = 0.28
	mesh.height = 0.2
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	mesh_instance.rotation.z = PI / 2.0
	mesh_instance.material_override = _material(WHEEL_COLOR)
	return mesh_instance


static func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	return material
```

Añadir `tick` al final de `scripts/vehicles/player_controller.gd`:

```gdscript
func _ready() -> void:
	VehicleVisual.build(self)


func tick(delta: float) -> void:
	speed_mps = step_longitudinal(speed_mps, max_speed_mps, _is_braking(), delta)
	lateral_speed_mps = step_lateral(lateral_speed_mps, _steer_value(), delta)
	var x_step := step_x(position.x, lateral_speed_mps, delta)
	lateral_speed_mps = x_step.y
	position.x = x_step.x
	position.z += speed_mps * delta


func _is_braking() -> bool:
	if not read_input_devices:
		return brake_input
	return Input.is_action_pressed("brake")


func _steer_value() -> float:
	if not read_input_devices:
		return steer_input
	return Input.get_axis("steer_left", "steer_right")
```

Crear `scenes/vehicles/player_vehicle.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/vehicles/player_controller.gd" id="1_player"]

[node name="PlayerVehicle" type="Node3D"]
script = ExtResource("1_player")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_player_scene.gd` y código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/vehicles/vehicle_visual.gd scripts/vehicles/player_controller.gd scenes/vehicles/player_vehicle.tscn tests/test_player_scene.gd
git commit -m "$(cat <<'EOF'
feat: add the player vehicle scene and tick

EOF
)"
```

---

### Task 5: Director de carrera

**Files:**
- Create: `scripts/core/race_director.gd`
- Create: `tests/test_race_director.gd`

**Interfaces:**
- Consumes: `player.speed_mps` y `player.max_speed_mps` cuando existe la escena. Esta tarea no instancia al jugador.
- Produces:
  - `signal speed_changed(speed_mps: float)`
  - `signal distance_changed(distance_m: float)`
  - `RaceDirector.planned_max_speed(elapsed_s: float) -> float`
  - `RaceDirector.begin_frame(delta: float) -> void` suma `delta` a `elapsed_s` y escribe `max_speed_mps`.
  - `RaceDirector.advance_race(delta: float, speed_mps: float) -> void` llama a `begin_frame`, suma `speed_mps * delta` a `distance_m` y emite si cambian los km/h enteros o los metros enteros.
  - Constantes: `INITIAL_MAX_SPEED_MPS = 30`, `SPEED_CAP_MPS = 70`, `MAX_SPEED_RAMP = 0.15`.
  - `simulate` se añade en la tarea 9. No crearlo aquí.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_race_director.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var director_script: GDScript = load("res://scripts/core/race_director.gd")
	if not is_equal_approx(director_script.planned_max_speed(0.0), 30.0):
		failed.append("initial cap")
	if not is_equal_approx(director_script.planned_max_speed(10.0), 31.5):
		failed.append("ramp")
	if not is_equal_approx(director_script.planned_max_speed(1000.0), 70.0):
		failed.append("cap")
	var director: Node = director_script.new()
	var speeds: Array[float] = []
	var distances: Array[float] = []
	director.speed_changed.connect(func(value: float) -> void: speeds.append(value))
	director.distance_changed.connect(func(value: float) -> void: distances.append(value))
	director.advance_race(0.0, 8.0)
	director.advance_race(0.0, 8.05)
	director.advance_race(0.0, 8.2)
	if speeds.size() != 2:
		failed.append("speed signals %s" % speeds.size())
	# Delta 0 deja la distancia en 0, pero el centinela -1 emite ese 0 una vez.
	if distances.size() != 1:
		failed.append("zero distance signals %s" % distances.size())
	director.advance_race(0.1, 10.0)
	director.advance_race(0.05, 10.0)
	director.advance_race(0.05, 10.0)
	# Metros enteros emitidos: 0, 1 y 2. 1.5 no emite.
	if distances.size() != 3:
		failed.append("distance signals %s" % distances.size())
	if not is_equal_approx(director.distance_m, 2.0):
		failed.append("distance %s" % director.distance_m)
	director.free()
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_race_director.gd` porque falta el script. Código 1.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/core/race_director.gd`:

```gdscript
class_name RaceDirector
extends Node3D

signal speed_changed(speed_mps: float)
signal distance_changed(distance_m: float)

const INITIAL_MAX_SPEED_MPS := 30.0
const SPEED_CAP_MPS := 70.0
const MAX_SPEED_RAMP := 0.15

var max_speed_mps: float = INITIAL_MAX_SPEED_MPS
var distance_m: float = 0.0
var elapsed_s: float = 0.0

var _shown_kmh: int = -1
var _shown_distance_m: int = -1


static func planned_max_speed(elapsed_s: float) -> float:
	return minf(SPEED_CAP_MPS, INITIAL_MAX_SPEED_MPS + MAX_SPEED_RAMP * elapsed_s)


static func displayed_kmh(speed_mps: float) -> int:
	return int(round(speed_mps * 3.6))


func begin_frame(delta: float) -> void:
	elapsed_s += delta
	max_speed_mps = planned_max_speed(elapsed_s)


func advance_race(delta: float, speed_mps: float) -> void:
	begin_frame(delta)
	_commit_motion(speed_mps, delta)


func _commit_motion(speed_mps: float, delta: float) -> void:
	distance_m += speed_mps * delta
	_emit_speed_if_changed(speed_mps)
	_emit_distance_if_changed()


func _emit_speed_if_changed(speed_mps: float) -> void:
	var kmh := displayed_kmh(speed_mps)
	if kmh == _shown_kmh:
		return
	_shown_kmh = kmh
	speed_changed.emit(speed_mps)


func _emit_distance_if_changed() -> void:
	var meters := int(distance_m)
	if meters == _shown_distance_m:
		return
	_shown_distance_m = meters
	distance_changed.emit(distance_m)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_race_director.gd` y código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/race_director.gd tests/test_race_director.gd
git commit -m "$(cat <<'EOF'
feat: add the race director speed cap and distance

EOF
)"
```

---

### Task 6: Carretera infinita

**Files:**
- Create: `scripts/world/road_chunk.gd`
- Create: `scenes/world/road_chunk.tscn`
- Create: `scripts/world/road_streamer.gd`
- Create: `tests/test_road.gd`

**Interfaces:**
- Consumes: nada.
- Produces:
  - `RoadStreamer.initial_origins(player_z: float) -> Array[float]` — 8 valores, el primero en `player_z - 40`, paso 40.
  - `RoadStreamer.recycle_origins(origins: Array, player_z: float) -> Array[float]` — mueve al frente cada tramo cuyo borde delantero (`origen + 40`) sea menor que `player_z - 20`.
  - `RoadStreamer.setup(player_z: float) -> void` y `tick(player_z: float) -> void` colocan los hijos.
  - `RoadStreamer.origins() -> Array[float]`.
  - `RoadChunk` genera 23 mallas hijas: 1 asfalto, 2 bordes, 20 trazos (10 en X = -2 y 10 en X = 2).

- [ ] **Step 1: Write the failing test**

Crear `tests/test_road.gd`:

```gdscript
extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var streamer_script: GDScript = load("res://scripts/world/road_streamer.gd")
	var origins: Array = streamer_script.initial_origins(0.0)
	if origins.size() != 8 or not is_equal_approx(float(origins[0]), -40.0) or not is_equal_approx(float(origins[7]), 240.0):
		failed.append("initial %s" % origins)
	var parked: Array = streamer_script.recycle_origins(origins, 0.0)
	if not is_equal_approx(float(parked[0]), -40.0):
		failed.append("recycled too early")
	var moved: Array = streamer_script.recycle_origins(origins, 21.0)
	var sorted: Array[float] = []
	for value in moved:
		sorted.append(float(value))
	sorted.sort()
	if not is_equal_approx(sorted[0], 0.0) or not is_equal_approx(sorted[7], 280.0):
		failed.append("recycle %s" % sorted)
	var chunk: Node3D = load("res://scenes/world/road_chunk.tscn").instantiate()
	tree.root.add_child(chunk)
	if chunk.get_child_count() != 23:
		failed.append("markings %s" % chunk.get_child_count())
	chunk.queue_free()
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_road.gd`. Código 1.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/world/road_chunk.gd`:

```gdscript
class_name RoadChunk
extends Node3D

const LENGTH := 40.0
const ASPHALT := Color(0.16, 0.18, 0.2)
const PAINT := Color(0.9, 0.88, 0.84)


func _ready() -> void:
	_add_box(Vector3(0.0, 0.0, LENGTH * 0.5), Vector3(14.0, 0.1, LENGTH), ASPHALT)
	_add_box(Vector3(-6.0, 0.02, LENGTH * 0.5), Vector3(0.12, 0.04, LENGTH), PAINT)
	_add_box(Vector3(6.0, 0.02, LENGTH * 0.5), Vector3(0.12, 0.04, LENGTH), PAINT)
	var dash_z := 1.0
	while dash_z < LENGTH:
		_add_box(Vector3(-2.0, 0.02, dash_z), Vector3(0.12, 0.04, 2.0), PAINT)
		_add_box(Vector3(2.0, 0.02, dash_z), Vector3(0.12, 0.04, 2.0), PAINT)
		dash_z += 4.0


func _add_box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	add_child(mesh_instance)
```

Crear `scenes/world/road_chunk.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/world/road_chunk.gd" id="1_chunk"]

[node name="RoadChunk" type="Node3D"]
script = ExtResource("1_chunk")
```

Crear `scripts/world/road_streamer.gd`:

```gdscript
class_name RoadStreamer
extends Node3D

const CHUNK_LENGTH := 40.0
const CHUNK_COUNT := 8
const RECYCLE_BEHIND := 20.0

const CHUNK_SCENE := preload("res://scenes/world/road_chunk.tscn")

var _chunks: Array[Node3D] = []


func _ready() -> void:
	for _i in CHUNK_COUNT:
		var chunk: Node3D = CHUNK_SCENE.instantiate()
		add_child(chunk)
		_chunks.append(chunk)


static func initial_origins(player_z: float) -> Array[float]:
	var origins: Array[float] = []
	for i in CHUNK_COUNT:
		origins.append(player_z - CHUNK_LENGTH + float(i) * CHUNK_LENGTH)
	return origins


static func recycle_origins(origins: Array, player_z: float) -> Array[float]:
	var result: Array[float] = []
	for origin in origins:
		result.append(float(origin))
	var guard := 0
	while guard < 64:
		guard += 1
		var behind := -1
		for i in result.size():
			var front := result[i] + CHUNK_LENGTH
			if front < player_z - RECYCLE_BEHIND and (behind == -1 or result[i] < result[behind]):
				behind = i
		if behind == -1:
			break
		var furthest: float = result[0]
		for origin in result:
			furthest = maxf(furthest, origin)
		# Un frame lento puede dejar varios tramos atrás. Cada uno pasa al final.
		result[behind] = furthest + CHUNK_LENGTH
	return result


func setup(player_z: float) -> void:
	_apply(initial_origins(player_z))


func tick(player_z: float) -> void:
	_apply(recycle_origins(origins(), player_z))


func origins() -> Array[float]:
	var values: Array[float] = []
	for chunk in _chunks:
		values.append(chunk.position.z)
	return values


func _apply(origins: Array) -> void:
	for i in _chunks.size():
		_chunks[i].position = Vector3(0.0, 0.0, float(origins[i]))
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_road.gd` y código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/world/road_chunk.gd scenes/world/road_chunk.tscn scripts/world/road_streamer.gd tests/test_road.gd
git commit -m "$(cat <<'EOF'
feat: recycle road chunks ahead of the player

EOF
)"
```

---

### Task 7: Tráfico básico

**Files:**
- Create: `scripts/traffic/traffic_vehicle.gd`
- Create: `scenes/vehicles/traffic_vehicle.tscn`
- Create: `scripts/traffic/traffic_manager.gd`
- Create: `tests/test_traffic.gd`

**Interfaces:**
- Consumes: `AiProfile`, `VehicleVisual.build`, `res://traffic/profiles/normal.tres`, `res://scenes/vehicles/traffic_vehicle.tscn`.
- Produces:
  - `TrafficManager.lane_center(lane: int) -> float` devuelve -4, 0 o 4.
  - `TrafficManager.choose_lane(spawn_z: float, occupants: Array) -> int`. Cada ocupante es un `Dictionary` con `lane: int` y `z: float`. Un carril está libre si ningún ocupante de ese carril está a menos de 18 m. Entre los libres gana la mayor distancia al ocupante más cercano. Empate: índice menor. Sin carril libre: -1. Un carril vacío tiene distancia infinita.
  - `TrafficManager.tick(delta: float, player_z: float) -> void`.
  - `TrafficVehicle.activate(lane_index: int, world_position: Vector3, material: StandardMaterial3D, scale_factor: float) -> void`.
  - `TrafficVehicle.deactivate() -> void`.
  - `TrafficVehicle.tick(delta: float) -> void` avanza `profile.speed_mps` y fija X al centro del carril.
  - Colores en orden `#C4513A`, `#3D6B8C`, `#D4A017`, `#4E7D4F`. Escalas en orden 0,95, 1,0, 1,05, 0,97. Los materiales se crean una vez en `_ready`.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_traffic.gd`:

```gdscript
extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var manager_script: GDScript = load("res://scripts/traffic/traffic_manager.gd")
	if not is_equal_approx(manager_script.lane_center(0), -4.0):
		failed.append("lane 0")
	if manager_script.choose_lane(90.0, []) != 0:
		failed.append("empty lanes")
	var blocked: Array = [
		{"lane": 0, "z": 90.0},
		{"lane": 1, "z": 90.0},
		{"lane": 2, "z": 90.0},
	]
	if manager_script.choose_lane(90.0, blocked) != -1:
		failed.append("all blocked")
	var edge: Array = [
		{"lane": 0, "z": 108.0},
		{"lane": 1, "z": 90.0},
		{"lane": 2, "z": 100.0},
	]
	if manager_script.choose_lane(90.0, edge) != 0:
		failed.append("gap of 18 should be free")
	var inside: Array = [{"lane": 0, "z": 107.9}]
	if manager_script.choose_lane(90.0, inside) != 1:
		failed.append("gap under 18")
	var manager: Node3D = manager_script.new()
	tree.root.add_child(manager)
	if manager.get_child_count() != 12:
		failed.append("pool %s" % manager.get_child_count())
	manager.tick(1.2, 0.0)
	var first := _active(manager)
	if first.size() != 1:
		failed.append("first spawn %s" % first.size())
	elif not is_equal_approx(first[0].global_position.x, -4.0) or not is_equal_approx(first[0].global_position.z, 90.0) or not is_equal_approx(first[0].scale.x, 0.95):
		failed.append("first pose %s %s" % [first[0].global_position, first[0].scale.x])
	elif first[0].get_node("Body").material_override.albedo_color != Color("c4513a"):
		failed.append("first color")
	manager.tick(1.2, 0.0)
	var second := _active(manager)
	if second.size() != 2:
		failed.append("second spawn %s" % second.size())
	manager.tick(0.0, 400.0)
	if not _active(manager).is_empty():
		failed.append("despawn")
	if manager.get_child_count() != 12:
		failed.append("pool changed")
	manager.queue_free()
	return failed


func _active(manager: Node) -> Array[Node]:
	var found: Array[Node] = []
	for child in manager.get_children():
		if child.active:
			found.append(child)
	return found
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_traffic.gd`. Código 1.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/traffic/traffic_vehicle.gd`:

```gdscript
class_name TrafficVehicle
extends Node3D

var active: bool = false
var lane: int = 0
var lane_x: float = 0.0
var profile: AiProfile
var _body: MeshInstance3D


func _ready() -> void:
	_body = VehicleVisual.build(self)
	visible = false


func activate(lane_index: int, world_position: Vector3, material: StandardMaterial3D, scale_factor: float) -> void:
	active = true
	visible = true
	lane = lane_index
	lane_x = world_position.x
	global_position = world_position
	scale = Vector3.ONE * scale_factor
	_body.material_override = material


func deactivate() -> void:
	active = false
	visible = false


func tick(delta: float) -> void:
	if not active or profile == null:
		return
	global_position.x = lane_x
	global_position.z += profile.speed_mps * delta
```

Crear `scenes/vehicles/traffic_vehicle.tscn`:

```ini
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/traffic/traffic_vehicle.gd" id="1_traffic"]

[node name="TrafficVehicle" type="Node3D"]
script = ExtResource("1_traffic")
```

Crear `scripts/traffic/traffic_manager.gd`:

```gdscript
class_name TrafficManager
extends Node3D

const POOL_SIZE := 12
const SPAWN_INTERVAL := 1.2
const SPAWN_AHEAD := 90.0
const DESPAWN_BEHIND := 30.0
const MIN_GAP := 18.0
const LANE_CENTERS: Array[float] = [-4.0, 0.0, 4.0]
const COLORS: Array[Color] = [
	Color("c4513a"),
	Color("3d6b8c"),
	Color("d4a017"),
	Color("4e7d4f"),
]
const SCALES: Array[float] = [0.95, 1.0, 1.05, 0.97]

const VEHICLE_SCENE := preload("res://scenes/vehicles/traffic_vehicle.tscn")
const DEFAULT_PROFILE: AiProfile = preload("res://traffic/profiles/normal.tres")

var profile: AiProfile
var _pool: Array[TrafficVehicle] = []
var _materials: Array[StandardMaterial3D] = []
var _spawn_timer: float = 0.0
var _style_index: int = 0


func _ready() -> void:
	if profile == null:
		profile = DEFAULT_PROFILE
	for color in COLORS:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		_materials.append(material)
	for _i in POOL_SIZE:
		var vehicle: TrafficVehicle = VEHICLE_SCENE.instantiate()
		vehicle.profile = profile
		add_child(vehicle)
		_pool.append(vehicle)


static func lane_center(lane: int) -> float:
	return LANE_CENTERS[lane]


static func choose_lane(spawn_z: float, occupants: Array) -> int:
	var best_lane := -1
	var best_distance := -1.0
	for lane in range(3):
		if not _lane_is_free(spawn_z, lane, occupants):
			continue
		var distance := _nearest_distance(spawn_z, lane, occupants)
		# Mayor estricto: un empate se queda con el índice más bajo.
		if distance > best_distance:
			best_distance = distance
			best_lane = lane
	return best_lane


static func _lane_is_free(spawn_z: float, lane: int, occupants: Array) -> bool:
	for occupant in occupants:
		if int(occupant["lane"]) == lane and absf(float(occupant["z"]) - spawn_z) < MIN_GAP:
			return false
	return true


static func _nearest_distance(spawn_z: float, lane: int, occupants: Array) -> float:
	var best := INF
	for occupant in occupants:
		if int(occupant["lane"]) == lane:
			best = minf(best, absf(float(occupant["z"]) - spawn_z))
	return best


func tick(delta: float, player_z: float) -> void:
	for vehicle in _pool:
		if not vehicle.active:
			continue
		vehicle.tick(delta)
		if vehicle.global_position.z < player_z - DESPAWN_BEHIND:
			vehicle.deactivate()
	_spawn_timer += delta
	while _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer -= SPAWN_INTERVAL
		_try_spawn(player_z)


func _try_spawn(player_z: float) -> void:
	var vehicle := _inactive_vehicle()
	if vehicle == null:
		return
	var spawn_z := player_z + SPAWN_AHEAD
	var occupants: Array = []
	for other in _pool:
		if other.active:
			occupants.append({"lane": other.lane, "z": other.global_position.z})
	var lane := choose_lane(spawn_z, occupants)
	if lane == -1:
		return
	var style := _style_index
	_style_index += 1
	vehicle.activate(
		lane,
		Vector3(lane_center(lane), 0.0, spawn_z),
		_materials[style % COLORS.size()],
		SCALES[style % SCALES.size()]
	)


func _inactive_vehicle() -> TrafficVehicle:
	for vehicle in _pool:
		if not vehicle.active:
			return vehicle
	return null
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_traffic.gd` y código 0.

El segundo `tick(1.2, 0.0)` mueve el primer coche `22 * 1.2` m antes de decidir el nuevo carril. Queda en z = 116,4. El punto nuevo de aparición, con `player_z` todavía 0, es z = 90. La distancia es 26,4 m, así que el carril 0 sigue libre, pero los carriles 1 y 2 están vacíos y ganan. El índice menor es 1. El test solo exige dos activos.

- [ ] **Step 5: Commit**

```bash
git add scripts/traffic/traffic_vehicle.gd scripts/traffic/traffic_manager.gd scenes/vehicles/traffic_vehicle.tscn tests/test_traffic.gd
git commit -m "$(cat <<'EOF'
feat: spawn pooled traffic into the lane with the largest gap

EOF
)"
```

---

### Task 8: Cámara y HUD

**Files:**
- Create: `scripts/camera/race_camera.gd`
- Create: `scripts/ui/speed_hud.gd`
- Create: `scenes/ui/speed_hud.tscn`
- Create: `tests/test_camera_hud.gd`

**Interfaces:**
- Consumes: `RaceDirector.displayed_kmh` no es necesario. El HUD repite la fórmula `int(round(speed_mps * 3.6))`.
- Produces:
  - `RaceCamera.target_position(player_position: Vector3) -> Vector3` = `(x, 18, z - 12)`.
  - `RaceCamera.look_target(player_position: Vector3) -> Vector3` = `(x, 1, z + 4)`.
  - `RaceCamera.smooth_position(current: Vector3, target: Vector3, delta: float) -> Vector3` con peso `1 - exp(-5 * delta)`.
  - `RaceCamera.fov_for_speed(speed_mps: float) -> float` de 60 a 72 entre 0 y 70 m/s, clamped.
  - `RaceCamera.tick(delta: float, player_position: Vector3) -> void`.
  - `RaceCamera.snap_to(player_position: Vector3) -> void`.
  - `RaceCamera.apply_speed(speed_mps: float) -> void` asigna `fov`.
  - `SpeedHud.format_speed(speed_mps: float) -> String` con formato `%03d km/h`.
  - `SpeedHud.show_speed(speed_mps: float) -> void`.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_camera_hud.gd`:

```gdscript
extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var camera_script: GDScript = load("res://scripts/camera/race_camera.gd")
	var hud_script: GDScript = load("res://scripts/ui/speed_hud.gd")
	var target: Vector3 = camera_script.target_position(Vector3(2.0, 0.0, 10.0))
	if not target.is_equal_approx(Vector3(2.0, 18.0, -2.0)):
		failed.append("target %s" % target)
	var look: Vector3 = camera_script.look_target(Vector3(2.0, 0.0, 10.0))
	if not look.is_equal_approx(Vector3(2.0, 1.0, 14.0)):
		failed.append("look %s" % look)
	if not is_equal_approx(camera_script.fov_for_speed(0.0), 60.0):
		failed.append("fov low")
	if not is_equal_approx(camera_script.fov_for_speed(35.0), 66.0):
		failed.append("fov mid")
	if not is_equal_approx(camera_script.fov_for_speed(100.0), 72.0):
		failed.append("fov high")
	var stayed: Vector3 = camera_script.smooth_position(Vector3(1.0, 2.0, 3.0), Vector3(9.0, 9.0, 9.0), 0.0)
	if not stayed.is_equal_approx(Vector3(1.0, 2.0, 3.0)):
		failed.append("smooth zero")
	var moved: Vector3 = camera_script.smooth_position(Vector3.ZERO, Vector3(10.0, 0.0, 0.0), 0.2)
	var expected_x := 10.0 * (1.0 - exp(-1.0))
	if not is_equal_approx(moved.x, expected_x):
		failed.append("smooth step %s" % moved.x)
	if hud_script.format_speed(8.0) != "029 km/h":
		failed.append("format 8")
	if hud_script.format_speed(30.0) != "108 km/h":
		failed.append("format 30")
	var hud: CanvasLayer = load("res://scenes/ui/speed_hud.tscn").instantiate()
	tree.root.add_child(hud)
	hud.show_speed(30.0)
	var label := hud.get_node("%SpeedLabel") as Label
	if label == null or label.text != "108 km/h":
		failed.append("label %s" % (label.text if label != null else "missing"))
	hud.queue_free()
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_camera_hud.gd`. Código 1.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/camera/race_camera.gd`:

```gdscript
class_name RaceCamera
extends Camera3D

const HEIGHT := 18.0
const BEHIND := 12.0
const LOOK_AHEAD := 4.0
const LOOK_HEIGHT := 1.0
const SMOOTH := 5.0
const FOV_BASE := 60.0
const FOV_AT_CAP := 72.0
const SPEED_FOR_FOV := 70.0


static func target_position(player_position: Vector3) -> Vector3:
	return Vector3(player_position.x, HEIGHT, player_position.z - BEHIND)


static func look_target(player_position: Vector3) -> Vector3:
	return Vector3(player_position.x, LOOK_HEIGHT, player_position.z + LOOK_AHEAD)


static func smooth_position(current: Vector3, target: Vector3, delta: float) -> Vector3:
	var weight := 1.0 - exp(-SMOOTH * delta)
	return current.lerp(target, weight)


static func fov_for_speed(speed_mps: float) -> float:
	var weight := clampf(speed_mps / SPEED_FOR_FOV, 0.0, 1.0)
	return lerpf(FOV_BASE, FOV_AT_CAP, weight)


func snap_to(player_position: Vector3) -> void:
	global_position = target_position(player_position)
	look_at(look_target(player_position), Vector3.UP)


func tick(delta: float, player_position: Vector3) -> void:
	global_position = smooth_position(global_position, target_position(player_position), delta)
	look_at(look_target(player_position), Vector3.UP)


func apply_speed(speed_mps: float) -> void:
	fov = fov_for_speed(speed_mps)
```

Crear `scripts/ui/speed_hud.gd`:

```gdscript
class_name SpeedHud
extends CanvasLayer

@onready var _label: Label = %SpeedLabel


static func format_speed(speed_mps: float) -> String:
	return "%03d km/h" % int(round(speed_mps * 3.6))


func show_speed(speed_mps: float) -> void:
	_label.text = format_speed(speed_mps)
```

Crear `scenes/ui/speed_hud.tscn`:

```ini
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/ui/speed_hud.gd" id="1_hud"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel"]
bg_color = Color(0.05, 0.06, 0.08, 0.72)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[node name="SpeedHud" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="Panel" type="Panel" parent="."]
offset_left = 24.0
offset_top = 24.0
offset_right = 280.0
offset_bottom = 108.0
theme_override_styles/panel = SubResource("StyleBoxFlat_panel")

[node name="SpeedLabel" type="Label" parent="Panel"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 16.0
offset_right = 240.0
offset_bottom = 68.0
theme_override_colors/font_color = Color(0.95, 0.94, 0.9, 1)
theme_override_font_sizes/font_size = 40
text = "000 km/h"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS test_camera_hud.gd` y código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/camera/race_camera.gd scripts/ui/speed_hud.gd scenes/ui/speed_hud.tscn tests/test_camera_hud.gd
git commit -m "$(cat <<'EOF'
feat: add the follow camera and speed HUD

EOF
)"
```

---

### Task 9: Escena de carrera

**Files:**
- Modify: `scripts/core/race_director.gd`
- Create: `scenes/race/race.tscn`
- Modify: `project.godot`
- Create: `tests/test_input.gd`
- Create: `tests/test_race.gd`

**Interfaces:**
- Consumes: `PlayerController.tick`, `RoadStreamer.setup` y `tick`, `TrafficManager.tick`, `RaceCamera.snap_to`, `tick` y `apply_speed`, `SpeedHud.show_speed`, `begin_frame`, `_commit_motion`, `displayed_kmh`.
- Produces:
  - `RaceDirector.simulate(delta: float) -> void` en este orden: `begin_frame`, asigna `player.max_speed_mps`, `player.tick`, `_commit_motion` con la velocidad ya actualizada, `road.tick`, `traffic.tick`, `race_camera.tick`.
  - `_process` solo llama a `simulate`.
  - `_ready` coloca la carretera, encuadra la cámara, conecta `speed_changed` a `hud.show_speed` y a `race_camera.apply_speed`, y emite el estado inicial.
  - Nodos hijos directos: `RoadStreamer`, `PlayerVehicle`, `TrafficManager`, `RaceCamera`, `SpeedHud`, `WorldEnvironment`, `Sun`.
  - Acciones `steer_left`, `steer_right` y `brake` como en la spec.
  - `application/run/main_scene` = `res://scenes/race/race.tscn`.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_input.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	if not InputMap.has_action("steer_left") or InputMap.action_get_events("steer_left").size() < 3:
		failed.append("steer_left")
	if not InputMap.has_action("steer_right") or InputMap.action_get_events("steer_right").size() < 3:
		failed.append("steer_right")
	if not InputMap.has_action("brake") or InputMap.action_get_events("brake").size() < 4:
		failed.append("brake")
	var main_scene: String = str(ProjectSettings.get_setting("application/run/main_scene"))
	if main_scene != "res://scenes/race/race.tscn":
		failed.append("main scene %s" % main_scene)
	return failed
```

Crear `tests/test_race.gd`:

```gdscript
extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var race: Node = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	var player: Node3D = race.get_node("PlayerVehicle")
	var hud_label: Label = race.get_node("SpeedHud/Panel/SpeedLabel")
	if hud_label.text != "029 km/h":
		failed.append("initial hud %s" % hud_label.text)
	for _i in 60:
		race.simulate(0.05)
	# 60 pasos de 0,05 s: la velocidad termina en 30,45 m/s y Z en 60,41 m.
	if absf(player.speed_mps - 30.45) > 0.05:
		failed.append("speed %s" % player.speed_mps)
	if absf(player.position.z - 60.41) > 0.5:
		failed.append("distance %s" % player.position.z)
	if hud_label.text != SpeedHud.format_speed(player.speed_mps):
		failed.append("hud %s" % hud_label.text)
	var road: Node = race.get_node("RoadStreamer")
	var origins: Array = road.origins()
	var sorted: Array[float] = []
	for value in origins:
		sorted.append(float(value))
	sorted.sort()
	if sorted.size() != 8 or not is_equal_approx(sorted[1] - sorted[0], 40.0):
		failed.append("chunks %s" % sorted)
	if sorted[0] > player.position.z or sorted[7] + 40.0 < player.position.z:
		failed.append("coverage")
	var active := 0
	for child in race.get_node("TrafficManager").get_children():
		if child.active:
			active += 1
	if active != 2:
		failed.append("traffic %s" % active)
	if race.get_node("TrafficManager").get_child_count() != 12:
		failed.append("pool size")
	if race.get_node("RoadStreamer").get_child_count() != 8:
		failed.append("chunk pool")
	if not race.find_children("", "CollisionShape3D", true, false).is_empty():
		failed.append("unexpected collision")
	var camera: Camera3D = race.get_node("RaceCamera")
	if absf(camera.fov - RaceCamera.fov_for_speed(player.speed_mps)) > 0.5:
		failed.append("fov %s" % camera.fov)
	race.queue_free()
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `FAIL test_input.gd` y `FAIL test_race.gd`. Código 1.

- [ ] **Step 3: Write minimal implementation**

Añadir estas variables y métodos a `scripts/core/race_director.gd`. Las variables van junto al resto de estado. `_ready`, `_process` y `simulate` van después de `advance_race`.

```gdscript
@onready var player: PlayerController = $PlayerVehicle
@onready var road: RoadStreamer = $RoadStreamer
@onready var traffic: TrafficManager = $TrafficManager
@onready var race_camera: RaceCamera = $RaceCamera
@onready var hud: SpeedHud = $SpeedHud


func _ready() -> void:
	player.max_speed_mps = max_speed_mps
	road.setup(player.global_position.z)
	race_camera.snap_to(player.global_position)
	speed_changed.connect(hud.show_speed)
	speed_changed.connect(race_camera.apply_speed)
	_emit_speed_if_changed(player.speed_mps)
	_emit_distance_if_changed()


func _process(delta: float) -> void:
	simulate(delta)


func simulate(delta: float) -> void:
	begin_frame(delta)
	player.max_speed_mps = max_speed_mps
	player.tick(delta)
	_commit_motion(player.speed_mps, delta)
	road.tick(player.global_position.z)
	traffic.tick(delta, player.global_position.z)
	race_camera.tick(delta, player.global_position)
```

Crear `scenes/race/race.tscn`:

```ini
[gd_scene load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/core/race_director.gd" id="1_director"]
[ext_resource type="Script" path="res://scripts/world/road_streamer.gd" id="2_road"]
[ext_resource type="PackedScene" path="res://scenes/vehicles/player_vehicle.tscn" id="3_player"]
[ext_resource type="Script" path="res://scripts/traffic/traffic_manager.gd" id="4_traffic"]
[ext_resource type="Script" path="res://scripts/camera/race_camera.gd" id="5_camera"]
[ext_resource type="PackedScene" path="res://scenes/ui/speed_hud.tscn" id="6_hud"]

[sub_resource type="Environment" id="Environment_race"]
background_mode = 1
background_color = Color(0.55, 0.72, 0.85, 1)
ambient_light_source = 2
ambient_light_energy = 0.4

[node name="Race" type="Node3D"]
script = ExtResource("1_director")

[node name="WorldEnvironment" type="WorldEnvironment" parent="."]
environment = SubResource("Environment_race")

[node name="Sun" type="DirectionalLight3D" parent="."]
transform = Transform3D(0.866025, -0.433013, 0.25, 0, 0.5, 0.866025, -0.5, -0.75, 0.433013, 0, 0, 0)
shadow_enabled = true

[node name="RoadStreamer" type="Node3D" parent="."]
script = ExtResource("2_road")

[node name="PlayerVehicle" parent="." instance=ExtResource("3_player")]

[node name="TrafficManager" type="Node3D" parent="."]
script = ExtResource("4_traffic")

[node name="RaceCamera" type="Camera3D" parent="."]
current = true
fov = 60.0
script = ExtResource("5_camera")

[node name="SpeedHud" parent="." instance=ExtResource("6_hud")]
```

Sustituir `project.godot` completo por:

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Carrera Arcade"
run/main_scene="res://scenes/race/race.tscn"
config/features=PackedStringArray("4.3", "Forward Plus")

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/stretch/mode="viewport"
window/stretch/aspect="expand"

[rendering]

renderer/rendering_method="forward_plus"

[input]

steer_left={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":0,"axis_value":-1.0,"script":null)
]
}
steer_right={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":0,"axis_value":1.0,"script":null)
]
}
brake={
"deadzone": 0.2,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":32,"location":0,"echo":false,"script":null)
, Object(InputEventJoypadMotion,"resource_local_to_scene":false,"resource_name":"","device":-1,"axis":4,"axis_value":1.0,"script":null)
]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: `PASS` en los nueve archivos de prueba y código 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/core/race_director.gd scenes/race/race.tscn project.godot tests/test_input.gd tests/test_race.gd
git commit -m "$(cat <<'EOF'
feat: assemble the playable phase 1 race scene

EOF
)"
```

---

### Task 10: Arranque de la escena

**Files:**
- Modify: ninguno si la tarea 9 pasó. Si el arranque imprime un error de script, parser o input, corregir solo ese error.

**Interfaces:**
- Consumes: la escena principal ya cableada.
- Produces: el juego abre la carrera, el coche avanza y el proceso termina solo.

- [ ] **Step 1: Write the failing test**

No añade un archivo nuevo. La comprobación es el arranque headless de la escena principal, distinto del corredor de pruebas.

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --quit-after 180`

Expected sin corrección pendiente: código 0 y sin líneas `ERROR` ni `SCRIPT ERROR`. Si aparecen, ese es el fallo que hay que corregir antes de seguir.

- [ ] **Step 3: Write minimal implementation**

Corregir el error concreto que imprima Godot. No añadir sistemas de fases posteriores.

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --quit-after 180`

Expected: código 0, sin `ERROR` ni `SCRIPT ERROR`.

Repetir también:

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: nueve líneas `PASS` y código 0.

- [ ] **Step 5: Commit**

Solo si el step 3 cambió archivos:

```bash
git add -u
git commit -m "$(cat <<'EOF'
fix: clear phase 1 startup errors

EOF
)"
```

Si no hubo cambios, no crear un commit vacío.
