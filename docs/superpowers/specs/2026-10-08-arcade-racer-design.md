# Carrera arcade cenital — diseño

Fecha: 2026-10-08

Juego original de carreras arcade para PC. Vista cenital con profundidad, carretera que avanza sin fin y velocidad que crece durante la carrera. Este documento fija la arquitectura de todo el juego y el alcance exacto de la Fase 1. Las fases posteriores no se implementan hasta que la Fase 1 esté aprobada.

No se copia código, sprites, audio, nombres, personajes, vehículos, circuitos ni arte de ningún juego existente. Los coches de la Fase 1 son mallas geométricas originales.

## Decisión de presentación

La simulación es plana: carril lateral y distancia a lo largo de la pista. La presentación es una escena 3D de Godot 4 con cámara alta y poco inclinada hacia el suelo.

Esa separación permite luces, sombras, reflejos, clima y ciclo de día y noche más adelante, sin cambiar las reglas de conducción. Un scroll 2D puro dejaría esos efectos como trucos de shader que habría que rehacer. Una cámara de persecución con punto de fuga dejaría de ser la vista cenital pedida.

## Motor y proyecto

- Godot 4.3 o superior.
- GDScript.
- Renderer Forward+.
- Resolución base 1920×1080.
- Estirado: modo `viewport`, aspecto `expand`.
- Escena principal de la Fase 1: `res://scenes/race/race.tscn`.
- Entrada: teclado y gamepad, definidos en el mapa de entrada del proyecto.

Acciones de la Fase 1:

| Acción | Teclado | Gamepad |
|---|---|---|
| `steer_left` | A, flecha izquierda | Stick izquierdo, eje X negativo |
| `steer_right` | D, flecha derecha | Stick izquierdo, eje X positivo |
| `brake` | S, flecha abajo, espacio | Gatillo izquierdo |

El código lee la dirección con `Input.get_axis("steer_left", "steer_right")`, que devuelve de -1 a 1. El stick aporta valores intermedios. El teclado aporta -1, 0 o 1. No hay una acción `steer` aparte.

No hay acción de nitro en la Fase 1.

## Unidades y pista

Unidades internas: metros y segundos. El HUD muestra km/h (`m/s * 3.6`).

- Tres carriles.
- Ancho de carril: 4 m.
- Centros de carril en X: -4, 0 y 4.
- Ancho total de calzada: 14 m (tres carriles y arcenes).
- El jugador no puede salir de X = -6 a X = 6. Al llegar al borde, la velocidad lateral se anula.

Eje Z: distancia recorrida. Crece hacia delante. La cámara mira en +Z.

## Escena de carrera

`scenes/race/race.tscn` contiene un solo dueño del bucle y componentes con una responsabilidad cada uno.

- **RaceDirector** — tiempo de carrera, velocidad máxima actual, distancia, señales hacia el resto.
- **RoadStreamer** — reserva de tramos de carretera y su recolocación.
- **PlayerVehicle** — entrada, aceleración, freno y dirección.
- **TrafficManager** — reserva de tráfico, huecos, carriles y retirada fuera de cámara.
- **RaceCamera** — seguimiento y reacción leve a la velocidad.
- **SpeedHud** — velocidad en km/h.

Ningún script mueve a la vez la carretera, el tráfico y el HUD. El director no teletransporta mallas: publica estado. Los componentes leen ese estado o escuchan sus señales.

Señales del director:

- `speed_changed(speed_mps: float)`
- `distance_changed(distance_m: float)`

La cámara escucha `speed_changed`. El HUD escucha `speed_changed`. La distancia se acumula en el director para fases posteriores; el HUD de la Fase 1 no la muestra.

## Conducción del jugador

El coche acelera solo hacia la velocidad máxima actual. Arranca ya a 8 m/s.

- Velocidad máxima inicial: 30 m/s (108 km/h).
- Techo de velocidad máxima: 70 m/s (252 km/h).
- La velocidad máxima sube 0,15 m/s por cada segundo de carrera, hasta el techo.
- Aceleración hacia la velocidad máxima: 8 m/s².
- Freno: 18 m/s². La velocidad longitudinal no baja de 8 m/s y no hay marcha atrás.
- Dirección: la velocidad lateral persigue `Input.get_axis(...) * 12 m/s`. Si hay entrada, la persigue a 28 m/s². Si la entrada es 0, vuelve a 0 a 18 m/s².
- La posición X se integra con la velocidad lateral y se recorta a [-6, 6]. Al recortar, la velocidad lateral pasa a 0.

La posición Z del jugador aumenta con su velocidad longitudinal. El coche no se queda clavado en el origen: el mundo lo acompaña reciclando tramos.

El director posee el techo de velocidad (`max_speed_mps`) y la distancia. Cada frame lee `speed_mps` del jugador, integra la distancia y sube el techo. El jugador solo lee ese techo para acelerar. Emite `speed_changed` cuando la velocidad mostrada en km/h enteros cambia, y `distance_changed` cuando la distancia entera en metros cambia.

Nitro, derrape, pérdida de control, aceite y daño quedan fuera de la Fase 1. `PlayerVehicle` expone `speed_mps` y su posición global para que esos sistemas se enganchen después sin reescribir el controlador.

## Carretera infinita

Cada tramo mide 40 m de largo. Hay 8 tramos en una reserva (320 m visibles en conjunto).

Al empezar, el primer tramo cubre desde `player_z - 40` hasta `player_z`. Los siete siguientes se colocan hacia +Z, de 40 en 40 m. La cobertura inicial es `[player_z - 40, player_z + 280]`. En cada frame, si el borde delantero de un tramo quedó más de 20 m por detrás del jugador, ese tramo pasa al final de la fila, pegado al tramo que ahora es el más adelantado.

Los tramos son planos de asfalto. Las marcas se generan en código, sin texturas externas: líneas continuas en los bordes (X = -6 y X = 6) y líneas discontinuas en los límites entre carriles (X = -2 y X = 2).

## Tráfico básico

Reserva de 12 vehículos. Si un vehículo queda más de 30 m por detrás del jugador, vuelve a la reserva.

El gestor intenta poner un vehículo en juego cada 1,2 s. El punto de aparición es fijo: 90 m por delante del jugador, en el centro de uno de los tres carriles. Un carril está libre si ningún vehículo activo de ese carril tiene su Z a menos de 18 m del punto de aparición. Entre los carriles libres se elige el de mayor distancia al vehículo activo más cercano de ese carril. Si hay empate, se elige el índice más bajo. Si ninguno está libre, ese intento no genera nada.

No se usa una posición lateral aleatoria.

Perfil de la Fase 1, recurso `AiProfile`:

Campos del recurso: `id: String`, `speed_mps: float`, `lane_change_interval: float`, `aggression: float`.

Valores de `normal`: id `normal`, 22 m/s, intervalo 0, agresión 0. El vehículo de tráfico solo lee el perfil: mantiene su carril y su velocidad. No esquiva al jugador en la Fase 1.

El jugador atraviesa el tráfico sin empuje ni penalización. La respuesta al contacto entra en una fase posterior; dejarlo explícito evita un comportamiento fantasma interpretado como fallo.

El jugador es una caja de 1,8 × 0,5 × 4,0 m más cuatro ruedas cilíndricas. Color de carrocería `#E8E4DC`. Los coches de tráfico reutilizan esa forma. Su color recorre, en orden y sin azar, `#C4513A`, `#3D6B8C`, `#D4A017` y `#4E7D4F`. Su escala recorre, en el mismo orden, 0,95, 1,0, 1,05 y 0,97. Color y escala se asignan al salir de la reserva.

## Cámara

La cámara es hija lógica del seguimiento, no del nodo del coche, para poder suavizar sin heredar cada corrección lateral al instante.

- Objetivo de posición: X del jugador, Y = 18 m, Z del jugador − 12 m.
- Mira a un punto 4 m por delante del jugador, a 1 m de altura.
- La posición de la cámara se suaviza con `lerp(actual, objetivo, 1 - exp(-5 * delta))`.
- FOV base: 60°. A 70 m/s llega a 72°, en proporción lineal con `speed_mps` entre 0 y 70.

## HUD

`CanvasLayer` con una etiqueta en la esquina superior izquierda: `000 km/h`, tres dígitos, fuente por defecto del motor. Fondo semitransparente propio, sin imitar la interfaz de otro juego. Solo muestra velocidad.

## Carpetas

```text
res://
  scenes/
    race/race.tscn
    vehicles/player_vehicle.tscn
    vehicles/traffic_vehicle.tscn
    world/road_chunk.tscn
    ui/speed_hud.tscn
  scripts/
    core/race_director.gd
    vehicles/player_controller.gd
    traffic/traffic_manager.gd
    traffic/traffic_vehicle.gd
    traffic/ai_profile.gd
    world/road_streamer.gd
    camera/race_camera.gd
    ui/speed_hud.gd
  traffic/profiles/normal.tres
  vehicles/
  world/
  ui/
  effects/
  audio/
  data/
  shaders/
  resources/
```

`scenes/` contiene escenas. `scripts/` contiene lógica, separada por sistema. `traffic/profiles/` contiene datos. Las demás carpetas de dominio quedan creadas con `.gitkeep` para el resto del juego y no reciben código en la Fase 1.

## Rendimiento

La Fase 1 ya recicla tramos y vehículos. No se llama a `instantiate` ni a `queue_free` durante la carrera después de crear las reservas al cargar la escena. Con 8 tramos y 12 coches, el coste de la IA es un recorrido fijo de la reserva activa: posición, carril y retirada.

## Qué queda fuera de la Fase 1

Nitro, puntuación, multiplicador, dinero, mejoras, garaje, menús, récords, créditos, obstáculos, aceite, eventos, persecuciones, rampas, varios ambientes, clima, día y noche, audio, partículas, motion blur, reflejos, sombras dinámicas elaboradas, derrape y contacto entre vehículos.

La iluminación de la Fase 1 es la luz direccional y el entorno por defecto de una escena 3D, suficientes para leer la profundidad de la cámara inclinada.

## Criterio de hecho de la Fase 1

- El proyecto abre en la escena de carrera.
- El coche acelera solo, se dirige con teclado y gamepad, y frena sin ir marcha atrás.
- La velocidad máxima crece con el tiempo hasta 70 m/s.
- La carretera no se acaba: los tramos reaparecen por delante.
- Circulan varios coches en carriles, separados, y desaparecen al quedar atrás.
- El HUD muestra la velocidad en km/h.
- La cámara sigue al coche y abre un poco el FOV al ir más rápido.
- No hay errores en la salida del editor ni al ejecutar la escena.
