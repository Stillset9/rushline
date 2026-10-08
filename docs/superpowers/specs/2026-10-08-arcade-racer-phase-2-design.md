# Carrera arcade — Fase 2: contacto y puntuación

Fecha: 2026-10-08

Este documento fija el alcance de la Fase 2. La arquitectura, las unidades y las reglas de la Fase 1 siguen en `docs/superpowers/specs/2026-10-08-arcade-racer-design.md`. Aquí solo se añade el choque con el tráfico y el marcador.

No se copia código, sprites, audio, nombres, personajes, vehículos, circuitos ni arte de ningún juego existente.

## Reglas de contacto

El cuerpo del jugador es una caja de 1,8 m en X y 4,0 m en Z, centrada en el nodo del coche. Las ruedas no entran en la caja. Cada coche de tráfico usa esa misma caja multiplicada por su escala uniforme (`scale.x`). La altura no cuenta.

Hay contacto cuando las dos cajas se cruzan en X y en Z con área real. El borde exacto no cuenta: la distancia entre centros en cada eje tiene que ser estrictamente menor que la suma de las mitades.

La comprobación ocurre después de mover al jugador y al tráfico en ese frame. El primer frame en que un coche activo pasa a estar cruzado cuenta un golpe. Mientras siga cruzado, ese coche no vuelve a golpear. Al separarse, el flag `in_contact` vuelve a falso y un cruce nuevo vuelve a contar. `activate` y `deactivate` dejan `in_contact` en falso, así que un coche que vuelve a la reserva puede golpear en una aparición posterior.

Cada golpe resta 15 m/s a la velocidad longitudinal del jugador. El resultado no baja de `PlayerController.MIN_SPEED_MPS` (8 m/s). Varios golpes nuevos en el mismo frame se aplican uno tras otro, cada uno con ese suelo. La velocidad lateral no cambia. El coche de tráfico no se empuja, no se desactiva y sigue su perfil.

La resta vale para los frames siguientes. Los metros de este frame son los que el jugador ya recorrió, con la velocidad de antes del golpe.

Ejemplos de velocidad:

- 30 m/s y un golpe quedan en 15 m/s.
- 70 m/s y un golpe quedan en 55 m/s.
- 8 m/s y un golpe siguen en 8 m/s.
- 20 m/s y dos golpes: el primero baja a 8 m/s y el segundo se queda en 8 m/s.
- Cero golpes no cambian la velocidad.

## Reglas de puntuación

`ScoreKeeper` guarda tres valores. Los puntos empiezan en 0. El multiplicador empieza en 1 y llega como máximo a 5. Los metros limpios empiezan en 0. El tramo limpio es 200 m.

En un frame sin golpe nuevo, `add_clean_distance(metros)` reparte esos metros:

- Mientras el multiplicador sea menor que 5, solo avanza hasta completar el tramo de 200 m. Esos metros suman `metros * multiplicador` a los puntos y suman los metros, sin multiplicar, al contador limpio.
- Al llegar a 200, los metros limpios vuelven a 0 y el multiplicador sube 1. El resto del frame se reparte con el multiplicador nuevo.
- En ×5, los metros suman `metros * 5` y los metros limpios no crecen.

En un frame con al menos un golpe nuevo, el director llama primero a `register_hit` y después a `add_hit_distance(metros)`. `register_hit` pone el multiplicador en 1 y los metros limpios en 0, y no toca los puntos. `add_hit_distance` suma `metros * multiplicador` (ya ×1) y no modifica el multiplicador ni los metros limpios.

Los puntos solo crecen. El valor mostrado es la parte entera, truncando hacia cero.

Ejemplos, partiendo de 0 puntos, ×1 y 0 m limpios:

- 199 m limpios: 199 puntos, ×1, 199 m limpios.
- 200 m limpios: 200 puntos, ×2, 0 m limpios.
- 450 m limpios de una vez: 200×1 + 200×2 + 50×3 = 750 puntos, ×3, 50 m limpios.
- Desde ×4 y 150 m limpios, 100 m más: 50 m a ×4 y 50 m a ×5, o sea 450 puntos más. El multiplicador queda en 5 y los metros limpios en 0.
- Ya en ×5, 10 m más suman 50 puntos y los metros limpios siguen en 0.
- `register_hit` con 750 puntos, ×3 y 50 m limpios deja 750 puntos, ×1 y 0 m limpios. `add_hit_distance(12)` deja 762 puntos, ×1 y 0 m limpios.

## Piezas

Tres piezas nuevas. Ninguna instancia nodos durante la carrera.

**Contact** (`scripts/race/contact.gd`), sin estado:

- Mitades del cuerpo: 0,9 m en X y 2,0 m en Z.
- `half_extents(scale)` devuelve esas mitades por la escala.
- `overlaps` compara dos cajas en el plano. El `Vector2` usa X del mundo en `x` y Z del mundo en `y`.
- `speed_after_hits(speed, hits)` aplica la resta de 15 m/s, `hits` veces, con suelo de 8 m/s.
- `collect_new_hits(player_position, vehicles)` recorre la reserva. Ignora los coches inactivos. Usa `global_position` del jugador y de cada coche, y `scale.x` del tráfico. Si hay cruce y `in_contact` era falso, suma un golpe. Después escribe `in_contact` con el cruce de este frame. Devuelve cuántos golpes nuevos hubo.

**TrafficVehicle** gana `in_contact: bool`. `activate` y `deactivate` lo ponen en falso.

**ScoreKeeper** (`scripts/race/score_keeper.gd`), `RefCounted`, creado por el director. No es un nodo de la escena. Campos: `score: float`, `multiplier: int`, `clean_m: float`. Métodos: `add_clean_distance`, `register_hit`, `add_hit_distance`.

**TrafficManager** expone `vehicles()` con la reserva completa de 12 coches. El director no lee el array privado.

El HUD sigue siendo `SpeedHud`. El panel de la esquina superior izquierda pasa de `(24, 24)–(280, 108)` a `(24, 24)–(280, 220)`. La velocidad se queda como está: `%SpeedLabel`, 40 px, `000 km/h`. Debajo, tres etiquetas a 22 px, el mismo color de fuente:

- `%DistanceLabel`, de (16, 80) a (240, 108), texto inicial `0 m`. Muestra los metros enteros que ya publica `distance_changed`, como `%d m`.
- `%ScoreLabel`, de (16, 112) a (240, 140), texto inicial `0 pts`.
- `%MultiplierLabel`, de (16, 144) a (240, 172), texto inicial `×1`.

`score_changed(score: int, multiplier: int)` sale del director cuando cambia la parte entera de los puntos o cambia el multiplicador. Esa parte entera es `int(score)`, que trunca hacia cero: 750,4 se emite como 750. El HUD no vuelve a redondear. La distancia sigue escuchando `distance_changed`.

## Orden de cada frame

`RaceDirector.simulate` queda así:

1. `begin_frame`.
2. Asignar `player.max_speed_mps` y llamar a `player.tick`.
3. `traffic.tick`.
4. Guardar `travel_speed = player.speed_mps`. Esa es la velocidad con la que este frame ya se movió.
5. `hits = Contact.collect_new_hits(...)`.
6. Si `hits > 0`, asignar `player.speed_mps = Contact.speed_after_hits(travel_speed, hits)`, llamar a `register_hit` y a `add_hit_distance(travel_speed * delta)`. Si no, llamar a `add_clean_distance(travel_speed * delta)`.
7. Sumar la distancia con `travel_speed` y emitir `speed_changed` con `player.speed_mps` ya penalizada. La distancia del director usa la velocidad de antes del golpe, la misma que movió al coche.
8. Emitir `score_changed` si la parte entera o el multiplicador cambiaron respecto a lo último emitido.
9. `road.tick` y `race_camera.tick`, como en la Fase 1.

`_ready` conecta el HUD y emite el marcador inicial: 0 puntos y ×1. Los centinelas empiezan en puntuación mostrada `-1` y multiplicador mostrado `0`, así esa primera emisión ocurre.

`advance_race` no cambia. Sigue siendo solo el atajo de tiempo y distancia. No resuelve contactos ni puntos.

## Casos límite

- Un coche inactivo no se compara. Si se desactiva en `traffic.tick`, eso ocurre antes del barrido, así que ese frame no golpea.
- Rozar el borde con área cero no es golpe.
- Dos coches que empiezan el cruce en el mismo frame restan 15 m/s cada uno.
- Seguir encima del mismo coche no resta otra vez. El frame siguiente acelera con normalidad desde la velocidad ya penalizada y el barrido añade cero golpes.
- La carrera no termina. No hay vidas ni pantalla de fin.

## Pruebas

Funciones puras, más un frame de la escena de carrera. La salida vacía sigue siendo PASS.

`tests/test_contact.gd`:

- Cajas separadas en X, o solo en Z, no se cruzan. Cruzadas en los dos ejes, sí. El borde exacto, no. Una diferencia de altura, no. La escala 1,05 agranda la caja del tráfico.
- Las velocidades de la tabla de arriba, incluido cero golpes y dos golpes desde 20 m/s.
- Primer cruce: un golpe y `in_contact` verdadero. Segundo barrido todavía cruzado: cero golpes. Tras separarse, `in_contact` es falso y otro cruce cuenta de nuevo. `deactivate` limpia el flag.

`tests/test_score.gd`: los ejemplos de puntuación de arriba, uno por caso.

`tests/test_race.gd` mantiene sus comprobaciones de la Fase 1. En esos 3 s no hay contacto: la velocidad sigue en 30,45 m/s, el multiplicador en 1 y los puntos enteros coinciden con los metros enteros de la distancia. Sigue sin haber ningún `CollisionShape3D`.

Un caso nuevo en esa escena: un coche de tráfico activo colocado sobre el jugador, velocidad del jugador 30 m/s, marcador en 750 puntos, multiplicador 3 y 50 m limpios, `delta` 0,05 s y el reloj de carrera en 0. El techo de ese primer frame sube un poco por la rampa de 0,15 m/s², así que la velocidad de viaje queda un pelo por encima de 30. Tras ese `simulate`, la velocidad queda en la velocidad de viaje menos 15 m/s, a no más de 0,02 m/s de 15. La distancia sube esa velocidad de viaje por 0,05, a no más de 0,02 de 1,5. Los puntos quedan a no más de 0,02 de 751,5, el multiplicador en 1 y los metros limpios en 0. Las etiquetas muestran `1 m` y `751 pts`, porque solo enseñan enteros. El tráfico sigue activo. Un segundo `simulate`, todavía cruzados, no resta otros 15 m/s: el jugador acelera 0,4 m/s y termina a no más de 0,02 m/s de 15,4.

`tests/test_camera_hud.gd` conserva el formato de velocidad y comprueba `0 m`, `0 pts` y `×1`. Al recibir la señal 750 y ×3, las etiquetas quedan `750 pts` y `×3`.

## Qué queda fuera

Fin de partida, vidas, menús, récords, nitro, derrape, aceite, obstáculos, empujar al otro coche, animación de choque, partículas, audio, sacudida de cámara, bonus por rozar, perfiles de tráfico distintos de `normal`, dinero, garaje y clima.

## Criterio de hecho

- Chocar con un coche baja la velocidad 15 m/s una vez por episodio de contacto, con suelo de 8 m/s, y la carrera sigue.
- Cada 200 m limpios el multiplicador sube 1, hasta ×5. Un choque lo devuelve a ×1 y los puntos no bajan.
- El HUD muestra velocidad, metros, puntos y multiplicador.
- La carretera, el tráfico y la cámara de la Fase 1 se comportan igual cuando no hay choque.
- Las pruebas pasan y la escena arranca sin errores de script.
