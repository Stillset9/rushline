# Fase 2 — contacto y puntuación — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hacer que chocar con el tráfico baje la velocidad una vez por cruce y que el HUD muestre metros, puntos y un multiplicador que sube cada 200 m limpios.

**Architecture:** `Contact` compara cajas en XZ y no guarda estado. `ScoreKeeper` acumula puntos. `RaceDirector.simulate` mueve al jugador, mueve el tráfico, cuenta golpes nuevos, penaliza la velocidad para el frame siguiente y suma la distancia ya recorrida. No hay cuerpos físicos.

**Tech Stack:** Godot 4.5 o superior, GDScript, renderer Forward+, pruebas headless con `godot --headless --script`.

## Global Constraints

- Godot 4.5 o superior, GDScript, renderer Forward+.
- Resolución base 1920×1080, estirado `viewport`, aspecto `expand`. Escena principal `res://scenes/race/race.tscn`.
- Unidades internas: metros y segundos. El HUD de velocidad sigue siendo `int(round(m/s * 3.6))` con formato `%03d km/h`.
- No se copia código, sprites, audio, nombres, personajes, vehículos, circuitos ni arte de ningún juego existente.
- Durante la carrera no se llama a `instantiate` ni a `queue_free` después de crear las reservas.
- No se añade ningún `CollisionShape3D`.
- Caja de contacto: 1,8 m en X y 4,0 m en Z, centrada en el nodo. Mitades 0,9 y 2,0. Las ruedas no entran. El tráfico multiplica la caja por `scale.x`.
- Hay cruce solo si la distancia entre centros en cada eje es estrictamente menor que la suma de las mitades.
- Cada golpe nuevo resta 15 m/s, con suelo `PlayerController.MIN_SPEED_MPS` (8). Varios golpes del mismo frame se aplican uno tras otro. La velocidad lateral no se asigna en el golpe. El tráfico no se empuja ni se desactiva.
- La distancia del frame usa la velocidad de antes del golpe. La señal `speed_changed` emite la velocidad ya penalizada.
- Multiplicador de 1 a 5. Tramo limpio 200 m. Los puntos mostrados son `int(score)`, truncando hacia cero.
- `advance_race` no resuelve contactos ni puntos.
- Fuera de esta fase: fin de partida, vidas, menús, récords, nitro, derrape, aceite, obstáculos, empujar al otro coche, animación de choque, partículas, audio, sacudida de cámara, bonus por rozar, perfiles distintos de `normal`, dinero, garaje y clima.
- Comentarios en español, solo donde la regla no se lee sola.
- Los commits del plan son locales. No hacer push.
- Si Godot genera un `.uid` junto a un script nuevo, ese archivo entra en el mismo commit. `.godot/` no se commitea.

## Estructura de archivos

- `scripts/race/contact.gd` — cajas, penalización y barrido de golpes nuevos. Sin estado.
- `scripts/race/score_keeper.gd` — puntos, multiplicador y metros limpios. `RefCounted`, no es un nodo.
- `scripts/traffic/traffic_vehicle.gd` — gana `in_contact`.
- `scripts/traffic/traffic_manager.gd` — gana `vehicles()`.
- `scripts/core/race_director.gd` — orden del frame, señales de puntuación.
- `scripts/ui/speed_hud.gd` — formato de metros, puntos y multiplicador.
- `scenes/ui/speed_hud.tscn` — tres etiquetas nuevas y panel más alto.
- `tests/test_contact.gd` — cajas, velocidad y episodios.
- `tests/test_score.gd` — ejemplos del marcador.
- `tests/test_camera_hud.gd` — los formatos nuevos, sin perder los de velocidad.
- `tests/test_race_director.gd` — `advance_race` no suma puntos.
- `tests/test_race.gd` — los 3 s sin choque, más un choque de dos frames.

## Prerrequisito

La Fase 1 está en `master` y sus 10 pruebas pasan. `godot --version` imprime 4.5 o superior.

Comando de pruebas, siempre desde cualquier directorio:

```bash
godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd
```

Éxito: una línea `PASS` por cada `test_*.gd` y código de salida 0. Fallo: una línea `FAIL` y código de salida 1. Al empezar esta fase hay 10 archivos. La tarea 1 deja 11. La tarea 3 deja 12.

---

### Task 1: Cajas y penalización

**Files:**
- Create: `scripts/race/contact.gd`
- Test: `tests/test_contact.gd`

**Interfaces:**
- Consumes: `PlayerController.MIN_SPEED_MPS`.
- Produces: `Contact.BODY_HALF_X` (0.9), `Contact.BODY_HALF_Z` (2.0), `Contact.SPEED_DROP` (15.0), `Contact.half_extents(scale_factor: float) -> Vector2`, `Contact.overlaps(a_center: Vector2, a_half: Vector2, b_center: Vector2, b_half: Vector2) -> bool`, `Contact.speed_after_hits(speed: float, hits: int) -> float`. El `Vector2` usa X del mundo en `x` y Z del mundo en `y`.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_contact.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var body := Contact.half_extents(1.0)
	if not body.is_equal_approx(Vector2(0.9, 2.0)):
		failed.append("body half %s" % body)
	var grown := Contact.half_extents(1.05)
	if not grown.is_equal_approx(Vector2(0.945, 2.1)):
		failed.append("scaled half %s" % grown)
	if Contact.overlaps(Vector2(0, 0), body, Vector2(3, 0), body):
		failed.append("separated x")
	if Contact.overlaps(Vector2(0, 0), body, Vector2(0, 5), body):
		failed.append("separated z")
	if not Contact.overlaps(Vector2(0.5, 0.5), body, Vector2(0, 0), body):
		failed.append("overlap")
	if Contact.overlaps(Vector2(body.x * 2.0, 0), body, Vector2.ZERO, body):
		failed.append("edge touch")
	var high := Vector2(Vector3(0, 10, 0).x, Vector3(0, 10, 0).z)
	var low := Vector2(Vector3(0, -4, 0).x, Vector3(0, -4, 0).z)
	if not Contact.overlaps(high, body, low, body):
		failed.append("height")
	if not is_equal_approx(Contact.speed_after_hits(30.0, 1), 15.0):
		failed.append("drop 30")
	if not is_equal_approx(Contact.speed_after_hits(70.0, 1), 55.0):
		failed.append("drop 70")
	if not is_equal_approx(Contact.speed_after_hits(8.0, 1), 8.0):
		failed.append("floor")
	if not is_equal_approx(Contact.speed_after_hits(20.0, 2), 8.0):
		failed.append("two hits")
	if not is_equal_approx(Contact.speed_after_hits(30.0, 0), 30.0):
		failed.append("zero hits")
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: código de salida 1 y una línea `FAIL test_contact.gd`. Las otras pruebas siguen en `PASS`.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/race/contact.gd`:

```gdscript
class_name Contact
extends RefCounted

const BODY_HALF_X := 0.9
const BODY_HALF_Z := 2.0
const SPEED_DROP := 15.0


static func half_extents(scale_factor: float) -> Vector2:
	return Vector2(BODY_HALF_X, BODY_HALF_Z) * scale_factor


static func overlaps(a_center: Vector2, a_half: Vector2, b_center: Vector2, b_half: Vector2) -> bool:
	var separated_x := absf(a_center.x - b_center.x) >= a_half.x + b_half.x
	var separated_z := absf(a_center.y - b_center.y) >= a_half.y + b_half.y
	return not separated_x and not separated_z


static func speed_after_hits(speed: float, hits: int) -> float:
	var result := speed
	for _i in hits:
		result = maxf(PlayerController.MIN_SPEED_MPS, result - SPEED_DROP)
	return result
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: 11 líneas `PASS`, entre ellas `PASS test_contact.gd`, y código de salida 0. Si Godot creó `scripts/race/contact.gd.uid`, se incluye en el commit del paso 5.

- [ ] **Step 5: Commit**

```bash
git add tests/test_contact.gd scripts/race/contact.gd scripts/race/contact.gd.uid
git commit -m "$(cat <<'EOF'
feat: add planar contact boxes and speed drop

EOF
)"
```

Si el `.uid` todavía no existe, no lo inventes: el `git add` de ese archivo fallará y se commitean solo el script y la prueba.

---

### Task 2: Un golpe por cruce

**Files:**
- Modify: `scripts/race/contact.gd`
- Modify: `scripts/traffic/traffic_vehicle.gd`
- Test: `tests/test_contact.gd`

**Interfaces:**
- Consumes: `Contact.half_extents`, `Contact.overlaps`. `TrafficVehicle.active`, `global_position`, `scale`.
- Produces: `TrafficVehicle.in_contact: bool`, limpiado por `activate` y `deactivate`. `Contact.collect_new_hits(player_position: Vector3, vehicles: Array[TrafficVehicle]) -> int`.

- [ ] **Step 1: Write the failing test**

Reemplazar `tests/test_contact.gd` por el archivo completo. Conserva las comprobaciones de la tarea 1 y añade el barrido:

```gdscript
extends RefCounted

func run(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var body := Contact.half_extents(1.0)
	if not body.is_equal_approx(Vector2(0.9, 2.0)):
		failed.append("body half %s" % body)
	var grown := Contact.half_extents(1.05)
	if not grown.is_equal_approx(Vector2(0.945, 2.1)):
		failed.append("scaled half %s" % grown)
	if Contact.overlaps(Vector2(0, 0), body, Vector2(3, 0), body):
		failed.append("separated x")
	if Contact.overlaps(Vector2(0, 0), body, Vector2(0, 5), body):
		failed.append("separated z")
	if not Contact.overlaps(Vector2(0.5, 0.5), body, Vector2(0, 0), body):
		failed.append("overlap")
	if Contact.overlaps(Vector2(body.x * 2.0, 0), body, Vector2.ZERO, body):
		failed.append("edge touch")
	var high := Vector2(Vector3(0, 10, 0).x, Vector3(0, 10, 0).z)
	var low := Vector2(Vector3(0, -4, 0).x, Vector3(0, -4, 0).z)
	if not Contact.overlaps(high, body, low, body):
		failed.append("height")
	if not is_equal_approx(Contact.speed_after_hits(30.0, 1), 15.0):
		failed.append("drop 30")
	if not is_equal_approx(Contact.speed_after_hits(70.0, 1), 55.0):
		failed.append("drop 70")
	if not is_equal_approx(Contact.speed_after_hits(8.0, 1), 8.0):
		failed.append("floor")
	if not is_equal_approx(Contact.speed_after_hits(20.0, 2), 8.0):
		failed.append("two hits")
	if not is_equal_approx(Contact.speed_after_hits(30.0, 0), 30.0):
		failed.append("zero hits")
	failed.append_array(_episodes(tree))
	return failed


func _episodes(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var first := _vehicle(tree, Vector3(0, 0, 0), 1.0, true)
	var second := _vehicle(tree, Vector3(0, 0, 0), 1.0, true)
	var asleep := _vehicle(tree, Vector3(0, 0, 0), 1.0, false)
	var vehicles: Array[TrafficVehicle] = [first, second, asleep]
	var hits := Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 2 or not first.in_contact or not second.in_contact or asleep.in_contact:
		failed.append("first sweep %s" % hits)
	hits = Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 0:
		failed.append("held %s" % hits)
	first.global_position = Vector3(0, 0, 20)
	hits = Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 0 or first.in_contact:
		failed.append("separate %s" % hits)
	first.global_position = Vector3.ZERO
	hits = Contact.collect_new_hits(Vector3.ZERO, vehicles)
	if hits != 1 or not first.in_contact:
		failed.append("return %s" % hits)
	var grazes := _vehicle(tree, Vector3(1.84, 5, 0), 1.0, true)
	var wide := _vehicle(tree, Vector3(1.84, 5, 0), 1.05, true)
	var miss: Array[TrafficVehicle] = [grazes]
	if Contact.collect_new_hits(Vector3.ZERO, miss) != 0:
		failed.append("scale 1 should miss")
	var hit_scale: Array[TrafficVehicle] = [wide]
	if Contact.collect_new_hits(Vector3.ZERO, hit_scale) != 1:
		failed.append("scale 1.05 should hit")
	first.in_contact = true
	first.deactivate()
	if first.in_contact or first.active:
		failed.append("deactivate flag")
	second.in_contact = true
	second.activate(1, Vector3(4, 0, 9), StandardMaterial3D.new(), 1.0)
	if second.in_contact or not second.active:
		failed.append("activate flag")
	for vehicle in [first, second, asleep, grazes, wide]:
		vehicle.queue_free()
	return failed


func _vehicle(tree: SceneTree, at: Vector3, scale_factor: float, is_active: bool) -> TrafficVehicle:
	var vehicle := TrafficVehicle.new()
	tree.root.add_child(vehicle)
	vehicle.active = is_active
	vehicle.global_position = at
	vehicle.scale = Vector3.ONE * scale_factor
	vehicle.in_contact = false
	return vehicle
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: código de salida 1 y `FAIL test_contact.gd`.

- [ ] **Step 3: Write minimal implementation**

Reemplazar `scripts/race/contact.gd` por:

```gdscript
class_name Contact
extends RefCounted

const BODY_HALF_X := 0.9
const BODY_HALF_Z := 2.0
const SPEED_DROP := 15.0


static func half_extents(scale_factor: float) -> Vector2:
	return Vector2(BODY_HALF_X, BODY_HALF_Z) * scale_factor


static func overlaps(a_center: Vector2, a_half: Vector2, b_center: Vector2, b_half: Vector2) -> bool:
	var separated_x := absf(a_center.x - b_center.x) >= a_half.x + b_half.x
	var separated_z := absf(a_center.y - b_center.y) >= a_half.y + b_half.y
	return not separated_x and not separated_z


static func speed_after_hits(speed: float, hits: int) -> float:
	var result := speed
	for _i in hits:
		result = maxf(PlayerController.MIN_SPEED_MPS, result - SPEED_DROP)
	return result


static func collect_new_hits(player_position: Vector3, vehicles: Array[TrafficVehicle]) -> int:
	var hits := 0
	var player_center := Vector2(player_position.x, player_position.z)
	var player_half := half_extents(1.0)
	for vehicle in vehicles:
		if not vehicle.active:
			continue
		var center := Vector2(vehicle.global_position.x, vehicle.global_position.z)
		var overlapping := overlaps(player_center, player_half, center, half_extents(vehicle.scale.x))
		if overlapping and not vehicle.in_contact:
			hits += 1
		vehicle.in_contact = overlapping
	return hits
```

Reemplazar `scripts/traffic/traffic_vehicle.gd` por:

```gdscript
class_name TrafficVehicle
extends Node3D

var active: bool = false
var lane: int = 0
var lane_x: float = 0.0
var profile: AiProfile
var in_contact: bool = false
var _body: MeshInstance3D


func _ready() -> void:
	_body = VehicleVisual.build(self)
	visible = false


func activate(lane_index: int, world_position: Vector3, material: StandardMaterial3D, scale_factor: float) -> void:
	active = true
	visible = true
	in_contact = false
	lane = lane_index
	lane_x = world_position.x
	global_position = world_position
	scale = Vector3.ONE * scale_factor
	_body.material_override = material


func deactivate() -> void:
	active = false
	visible = false
	in_contact = false


func tick(delta: float) -> void:
	if not active or profile == null:
		return
	global_position.x = lane_x
	global_position.z += profile.speed_mps * delta
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: 11 líneas `PASS` y código de salida 0.

- [ ] **Step 5: Commit**

```bash
git add tests/test_contact.gd scripts/race/contact.gd scripts/traffic/traffic_vehicle.gd
git commit -m "$(cat <<'EOF'
feat: count one hit per traffic overlap

EOF
)"
```

---

### Task 3: Marcador

**Files:**
- Create: `scripts/race/score_keeper.gd`
- Test: `tests/test_score.gd`

**Interfaces:**
- Consumes: nada de las tareas anteriores.
- Produces: `ScoreKeeper` con `score: float`, `multiplier: int`, `clean_m: float`, `add_clean_distance(meters: float) -> void`, `register_hit() -> void`, `add_hit_distance(meters: float) -> void`. Constantes `CLEAN_STEP_M` = 200 y `MULTIPLIER_MAX` = 5.

- [ ] **Step 1: Write the failing test**

Crear `tests/test_score.gd`:

```gdscript
extends RefCounted

func run(_tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var fresh := ScoreKeeper.new()
	fresh.add_clean_distance(199.0)
	if not _is(fresh, 199.0, 1, 199.0):
		failed.append("199 %s" % _dump(fresh))
	var exact := ScoreKeeper.new()
	exact.add_clean_distance(200.0)
	if not _is(exact, 200.0, 2, 0.0):
		failed.append("200 %s" % _dump(exact))
	var run_on := ScoreKeeper.new()
	run_on.add_clean_distance(450.0)
	if not _is(run_on, 750.0, 3, 50.0):
		failed.append("450 %s" % _dump(run_on))
	var crossing := ScoreKeeper.new()
	crossing.multiplier = 4
	crossing.clean_m = 150.0
	crossing.add_clean_distance(100.0)
	if not _is(crossing, 450.0, 5, 0.0):
		failed.append("cross cap %s" % _dump(crossing))
	var capped := ScoreKeeper.new()
	capped.add_clean_distance(800.0)
	if not _is(capped, 2000.0, 5, 0.0):
		failed.append("reach cap %s" % _dump(capped))
	capped.add_clean_distance(10.0)
	if not _is(capped, 2050.0, 5, 0.0):
		failed.append("stay cap %s" % _dump(capped))
	var hit := ScoreKeeper.new()
	hit.score = 750.0
	hit.multiplier = 3
	hit.clean_m = 50.0
	hit.register_hit()
	if not _is(hit, 750.0, 1, 0.0):
		failed.append("reset %s" % _dump(hit))
	hit.add_hit_distance(12.0)
	if not _is(hit, 762.0, 1, 0.0):
		failed.append("hit meters %s" % _dump(hit))
	return failed


func _is(keeper: ScoreKeeper, score: float, multiplier: int, clean_m: float) -> bool:
	return is_equal_approx(keeper.score, score) and keeper.multiplier == multiplier and is_equal_approx(keeper.clean_m, clean_m)


func _dump(keeper: ScoreKeeper) -> String:
	return "%s x%s clean %s" % [keeper.score, keeper.multiplier, keeper.clean_m]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: código de salida 1 y `FAIL test_score.gd`.

- [ ] **Step 3: Write minimal implementation**

Crear `scripts/race/score_keeper.gd`:

```gdscript
class_name ScoreKeeper
extends RefCounted

const CLEAN_STEP_M := 200.0
const MULTIPLIER_MAX := 5

var score: float = 0.0
var multiplier: int = 1
var clean_m: float = 0.0


func add_clean_distance(meters: float) -> void:
	var left := meters
	while left > 0.0:
		if multiplier >= MULTIPLIER_MAX:
			score += left * float(multiplier)
			left = 0.0
			continue
		var room := CLEAN_STEP_M - clean_m
		var step := minf(left, room)
		score += step * float(multiplier)
		clean_m += step
		left -= step
		if clean_m >= CLEAN_STEP_M:
			clean_m -= CLEAN_STEP_M
			multiplier += 1


func register_hit() -> void:
	multiplier = 1
	clean_m = 0.0


func add_hit_distance(meters: float) -> void:
	score += meters * float(multiplier)
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: 12 líneas `PASS`, entre ellas `PASS test_score.gd`, y código de salida 0. Incluir `scripts/race/score_keeper.gd.uid` en el commit si Godot lo generó.

- [ ] **Step 5: Commit**

```bash
git add tests/test_score.gd scripts/race/score_keeper.gd scripts/race/score_keeper.gd.uid
git commit -m "$(cat <<'EOF'
feat: add the clean-distance score multiplier

EOF
)"
```

Si el `.uid` no existe, commitear solo la prueba y el script.

---

### Task 4: HUD de metros, puntos y multiplicador

**Files:**
- Modify: `scripts/ui/speed_hud.gd`
- Modify: `scenes/ui/speed_hud.tscn`
- Test: `tests/test_camera_hud.gd`

**Interfaces:**
- Consumes: nada del marcador. Recibe enteros ya truncados.
- Produces: `SpeedHud.format_distance(distance_m: float) -> String`, `SpeedHud.format_score(score: int) -> String`, `SpeedHud.format_multiplier(multiplier: int) -> String`, `SpeedHud.show_distance(distance_m: float) -> void`, `SpeedHud.show_score(score: int, multiplier: int) -> void`. Nodos `%DistanceLabel`, `%ScoreLabel`, `%MultiplierLabel`.

- [ ] **Step 1: Write the failing test**

Al final de `run` en `tests/test_camera_hud.gd`, antes de `hud.queue_free()` y del `return failed`, insertar estas comprobaciones. El bloque que ya instancia el HUD y llama `show_speed(30.0)` se queda; estas líneas van justo después de comprobar que la etiqueta de velocidad es `108 km/h`:

```gdscript
	if hud_script.format_distance(60.41) != "60 m":
		failed.append("format distance")
	if hud_script.format_score(750) != "750 pts":
		failed.append("format score")
	if hud_script.format_multiplier(3) != "×3":
		failed.append("format multiplier")
	var distance_label := hud.get_node("%DistanceLabel") as Label
	var score_label := hud.get_node("%ScoreLabel") as Label
	var multiplier_label := hud.get_node("%MultiplierLabel") as Label
	if distance_label == null or distance_label.text != "0 m":
		failed.append("distance label")
	if score_label == null or score_label.text != "0 pts":
		failed.append("score label")
	if multiplier_label == null or multiplier_label.text != "×1":
		failed.append("multiplier label")
	hud.show_distance(60.41)
	hud.show_score(750, 3)
	if distance_label.text != "60 m" or score_label.text != "750 pts" or multiplier_label.text != "×3":
		failed.append("shown %s %s %s" % [distance_label.text, score_label.text, multiplier_label.text])
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: código de salida 1 y `FAIL test_camera_hud.gd`.

- [ ] **Step 3: Write minimal implementation**

Reemplazar `scripts/ui/speed_hud.gd` por:

```gdscript
class_name SpeedHud
extends CanvasLayer

@onready var _label: Label = %SpeedLabel
@onready var _distance_label: Label = %DistanceLabel
@onready var _score_label: Label = %ScoreLabel
@onready var _multiplier_label: Label = %MultiplierLabel


static func format_speed(speed_mps: float) -> String:
	return "%03d km/h" % int(round(speed_mps * 3.6))


static func format_distance(distance_m: float) -> String:
	return "%d m" % int(distance_m)


static func format_score(score: int) -> String:
	return "%d pts" % score


static func format_multiplier(multiplier: int) -> String:
	return "×%d" % multiplier


func show_speed(speed_mps: float) -> void:
	_label.text = format_speed(speed_mps)


func show_distance(distance_m: float) -> void:
	_distance_label.text = format_distance(distance_m)


func show_score(score: int, multiplier: int) -> void:
	_score_label.text = format_score(score)
	_multiplier_label.text = format_multiplier(multiplier)
```

Reemplazar `scenes/ui/speed_hud.tscn` por:

```text
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
offset_bottom = 220.0
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

[node name="DistanceLabel" type="Label" parent="Panel"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 80.0
offset_right = 240.0
offset_bottom = 108.0
theme_override_colors/font_color = Color(0.95, 0.94, 0.9, 1)
theme_override_font_sizes/font_size = 22
text = "0 m"

[node name="ScoreLabel" type="Label" parent="Panel"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 112.0
offset_right = 240.0
offset_bottom = 140.0
theme_override_colors/font_color = Color(0.95, 0.94, 0.9, 1)
theme_override_font_sizes/font_size = 22
text = "0 pts"

[node name="MultiplierLabel" type="Label" parent="Panel"]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 144.0
offset_right = 240.0
offset_bottom = 172.0
theme_override_colors/font_color = Color(0.95, 0.94, 0.9, 1)
theme_override_font_sizes/font_size = 22
text = "×1"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: 12 líneas `PASS` y código de salida 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/speed_hud.gd scenes/ui/speed_hud.tscn tests/test_camera_hud.gd
git commit -m "$(cat <<'EOF'
feat: show distance, score, and multiplier on the HUD

EOF
)"
```

---

### Task 5: Choque y puntos dentro de la carrera

**Files:**
- Modify: `scripts/traffic/traffic_manager.gd`
- Modify: `scripts/core/race_director.gd`
- Modify: `tests/test_race_director.gd`
- Modify: `tests/test_race.gd`

**Interfaces:**
- Consumes: `Contact.collect_new_hits`, `Contact.speed_after_hits`, `ScoreKeeper.add_clean_distance`, `ScoreKeeper.register_hit`, `ScoreKeeper.add_hit_distance`, `SpeedHud.show_distance`, `SpeedHud.show_score`, `TrafficVehicle.activate`.
- Produces: `TrafficManager.vehicles() -> Array[TrafficVehicle]`. `RaceDirector.score_keeper`. `RaceDirector.displayed_score(score: float) -> int`. Señal `score_changed(score: int, multiplier: int)`.

- [ ] **Step 1: Write the failing test**

En `tests/test_race_director.gd`, justo antes de `director.free()`, insertar:

```gdscript
	if director_script.displayed_score(750.4) != 750:
		failed.append("truncate")
	var score_before := director.score_keeper.score
	director.advance_race(1.0, 20.0)
	if not is_equal_approx(director.score_keeper.score, score_before) or director.score_keeper.multiplier != 1:
		failed.append("advance scored")
```

Reemplazar `tests/test_race.gd` por:

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
	if race.score_keeper.multiplier != 1:
		failed.append("clean multiplier %s" % race.score_keeper.multiplier)
	if not is_equal_approx(race.score_keeper.score, race.distance_m):
		failed.append("clean score %s vs %s" % [race.score_keeper.score, race.distance_m])
	if int(race.score_keeper.score) != int(race.distance_m):
		failed.append("shown integers")
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
	failed.append_array(_hit_episode(tree))
	return failed


func _hit_episode(tree: SceneTree) -> Array:
	var failed: Array[String] = []
	var race: Node = load("res://scenes/race/race.tscn").instantiate()
	tree.root.add_child(race)
	race.set_process(false)
	var player: PlayerController = race.get_node("PlayerVehicle")
	player.speed_mps = 30.0
	race.score_keeper.score = 750.0
	race.score_keeper.multiplier = 3
	race.score_keeper.clean_m = 50.0
	var traffic: TrafficManager = race.get_node("TrafficManager")
	var vehicle: TrafficVehicle = traffic.vehicles()[0]
	vehicle.activate(1, player.global_position, StandardMaterial3D.new(), 1.0)
	race.simulate(0.05)
	if absf(player.speed_mps - 15.0) > 0.02:
		failed.append("hit speed %s" % player.speed_mps)
	if absf(race.distance_m - 1.5) > 0.02:
		failed.append("hit distance %s" % race.distance_m)
	if absf(race.score_keeper.score - 751.5) > 0.02 or race.score_keeper.multiplier != 1 or not is_zero_approx(race.score_keeper.clean_m):
		failed.append("hit score %s x%s clean %s" % [race.score_keeper.score, race.score_keeper.multiplier, race.score_keeper.clean_m])
	if not vehicle.active or not vehicle.in_contact:
		failed.append("traffic survived")
	var distance_label: Label = race.get_node("SpeedHud/Panel/DistanceLabel")
	var score_label: Label = race.get_node("SpeedHud/Panel/ScoreLabel")
	if distance_label.text != "1 m" or score_label.text != "751 pts":
		failed.append("hit labels %s %s" % [distance_label.text, score_label.text])
	race.simulate(0.05)
	if absf(player.speed_mps - 15.4) > 0.02:
		failed.append("second speed %s" % player.speed_mps)
	race.queue_free()
	return failed
```

- [ ] **Step 2: Run test to verify it fails**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: código de salida 1. `test_race.gd` o `test_race_director.gd` sale en `FAIL`.

- [ ] **Step 3: Write minimal implementation**

En `scripts/traffic/traffic_manager.gd`, añadir este método antes de `tick`:

```gdscript
func vehicles() -> Array[TrafficVehicle]:
	return _pool
```

Reemplazar `scripts/core/race_director.gd` por:

```gdscript
class_name RaceDirector
extends Node3D

signal speed_changed(speed_mps: float)
signal distance_changed(distance_m: float)
signal score_changed(score: int, multiplier: int)

const INITIAL_MAX_SPEED_MPS := 30.0
const SPEED_CAP_MPS := 70.0
const MAX_SPEED_RAMP := 0.15

var max_speed_mps: float = INITIAL_MAX_SPEED_MPS
var distance_m: float = 0.0
var elapsed_s: float = 0.0
var score_keeper := ScoreKeeper.new()

var _shown_kmh: int = -1
var _shown_distance_m: int = -1
var _shown_score: int = -1
var _shown_multiplier: int = 0

@onready var player: PlayerController = $PlayerVehicle
@onready var road: RoadStreamer = $RoadStreamer
@onready var traffic: TrafficManager = $TrafficManager
@onready var race_camera: RaceCamera = $RaceCamera
@onready var hud: SpeedHud = $SpeedHud


static func planned_max_speed(time_s: float) -> float:
	return minf(SPEED_CAP_MPS, INITIAL_MAX_SPEED_MPS + MAX_SPEED_RAMP * time_s)


static func displayed_kmh(speed_mps: float) -> int:
	return int(round(speed_mps * 3.6))


static func displayed_score(score: float) -> int:
	return int(score)


func begin_frame(delta: float) -> void:
	elapsed_s += delta
	max_speed_mps = planned_max_speed(elapsed_s)


# Atajo de tiempo y distancia. No resuelve choques ni puntos.
func advance_race(delta: float, speed_mps: float) -> void:
	begin_frame(delta)
	_commit_motion(speed_mps, delta)


func _ready() -> void:
	player.max_speed_mps = max_speed_mps
	road.setup(player.global_position.z)
	race_camera.snap_to(player.global_position)
	speed_changed.connect(hud.show_speed)
	speed_changed.connect(race_camera.apply_speed)
	distance_changed.connect(hud.show_distance)
	score_changed.connect(hud.show_score)
	_emit_speed_if_changed(player.speed_mps)
	_emit_distance_if_changed()
	_emit_score_if_changed()


func _process(delta: float) -> void:
	simulate(delta)


func simulate(delta: float) -> void:
	begin_frame(delta)
	player.max_speed_mps = max_speed_mps
	player.tick(delta)
	traffic.tick(delta, player.global_position.z)
	var travel_speed := player.speed_mps
	var hits := Contact.collect_new_hits(player.global_position, traffic.vehicles())
	if hits > 0:
		player.speed_mps = Contact.speed_after_hits(travel_speed, hits)
		score_keeper.register_hit()
		score_keeper.add_hit_distance(travel_speed * delta)
	else:
		score_keeper.add_clean_distance(travel_speed * delta)
	# La distancia usa la velocidad de este frame. La señal de velocidad usa
	# la velocidad ya penalizada, que es la que vale a partir de ahora.
	_add_distance(travel_speed, delta)
	_emit_speed_if_changed(player.speed_mps)
	_emit_score_if_changed()
	road.tick(player.global_position.z)
	race_camera.tick(delta, player.global_position)


func _commit_motion(speed_mps: float, delta: float) -> void:
	_add_distance(speed_mps, delta)
	_emit_speed_if_changed(speed_mps)


func _add_distance(speed_mps: float, delta: float) -> void:
	distance_m += speed_mps * delta
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


func _emit_score_if_changed() -> void:
	var shown := displayed_score(score_keeper.score)
	if shown == _shown_score and score_keeper.multiplier == _shown_multiplier:
		return
	_shown_score = shown
	_shown_multiplier = score_keeper.multiplier
	score_changed.emit(shown, score_keeper.multiplier)
```

`simulate` no instancia nodos y no escribe `player.lateral_speed_mps`.

- [ ] **Step 4: Run test to verify it passes**

Run: `godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --script res://tests/run_tests.gd`

Expected: 12 líneas `PASS` y código de salida 0.

Arranque de la escena, para ver que no hay error de script:

```bash
godot --headless --path "/Users/Stillset9/Documents/Juego Nuevo" --quit-after 180
```

Expected: código de salida 0 y ninguna línea `ERROR` ni `SCRIPT ERROR`.

- [ ] **Step 5: Commit**

```bash
git add scripts/traffic/traffic_manager.gd scripts/core/race_director.gd tests/test_race_director.gd tests/test_race.gd
git commit -m "$(cat <<'EOF'
feat: apply traffic hits and score during the race

EOF
)"
```
