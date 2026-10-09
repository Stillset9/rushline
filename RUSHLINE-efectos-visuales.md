# RUSHLINE — brief para recomendar efectos visuales

Usa este documento para proponer efectos visuales futuros. No escribas código todavía. No copies juegos, marcas, logotipos, autos, pistas ni música comerciales. Las ideas tienen que encajar en el juego que ya existe.

## Qué es

RUSHLINE es un arcade de carreras original, en español, de HJgames. Se juega en PC con Godot 4.7.2 y también en el navegador: https://stillset9.github.io/rushline/

La sensación buscada es la de un arcade callejero de los años 2000: velocidad, tráfico, nitro y choques, con identidad propia. No es un simulador. No es un juego 2D de ninjas. No usa Canvas ni JavaScript.

## Cómo está hecho

- Motor: Godot 4.7, GDScript.
- Escritorio: renderer Forward+.
- Navegador: Compatibility (WebGL). GitHub Pages no permite hilos.
- Resolución de diseño: 1920×1080, estirado en modo viewport con aspecto expand. No se deforman los gráficos.
- La simulación es plana: X es el lateral, Z es la distancia. No usa física de Godot para la carrera. Las cajas de contacto son planas.
- La imagen es 3D, con cámara de persecución detrás del auto.
- La carretera y el tráfico son grupos reutilizados, no objetos nuevos en cada fotograma.
- El tiempo ya depende de delta. No debe acelerarse con los hercios del monitor.
- Máquina real de referencia: Intel UHD Graphics 617. Hay que cuidar luces, sombras, glow y partículas.
- Ajuste actual de fluidez: la escena 3D se dibuja al 80 % y se escala (FSR en escritorio; bilineal en la web). Sombras del sol a 2048. El glow de la carrera se apaga en la web porque volvía el cielo blanco.

## Identidad

- Nombre del juego: RUSHLINE. Es el protagonista visual.
- Firma del estudio: HJgames. Debe verse, sin competir con el título.
- Color del sello: cian `rgb(0.74, 0.96, 1)` sobre fondo casi negro `rgb(0.02, 0.03, 0.05)`.
- Tipografía: Kenney Future Narrow. Es libre (CC0) y ya tiene acentos.
- Autos: Grab3D, licencia CC0, en `assets/vehicles/`. Ciudad, naturaleza y fuente: Kenney, CC0. No sustituirlos por modelos de marcas reales.
- Música de carrera: Pure Raceway, de MintoDog, dominio público CC0. Efectos de motor, choque y subida de multiplicador: originales, generados en el proyecto.

## Qué ya se ve

Intro, unos 4 segundos, se salta con Escape, Start o A:

- Fondo con resplandor radial frío.
- Monograma HJ dibujado en pantalla: trazo cian, gancho de la J, arco que se cierra y esquinas discretas.
- Línea, texto «HJgames presents» y título RUSHLINE grande.
- Destello corto en el impacto del logo.
- Sting original.

Menú:

- Jugar, Garaje, Récords, Opciones, Créditos, Salir.
- Fondo oscuro, opción elegida en cian.

Carrera:

- Cámara detrás del auto. Altura 7,5 m, 10,5 m por detrás, mira 12 m por delante. Solo se suaviza el eje X. El campo de visión pasa de 60 a 72 según la velocidad.
- Un sol cálido con sombra y una luz de relleno sin sombra. Materiales de los faroles son emisivos: no hay una luz por lámpara.
- Siete lugares, en este orden según las carreras jugadas: Ciudad, Costa, Desierto, Bosque, Nieve, Atardecer, Industrial. Cambian cielo, asfalto, pintura del suelo y decorado (edificios, palmeras, cactus, árboles o pinos).
- Tres climas, emparejados con el lugar: Despejado, Lluvia, Niebla. La lluvia usa unas 80 partículas de CPU pegadas a la cámara. La niebla es un valor bajo en el entorno, no un volumen denso.
- Auto del jugador: sedán deportivo claro. El tráfico alterna sedán, hatchback, furgoneta y taxi, con tintes.
- Nitro: dos cajas emisivas naranjas detrás del auto mientras se acelera con Shift.
- Choque: una esfera naranja semitransparente durante 0,22 s. El golpe frena y, al tercero, termina la carrera.
- Aceite en el suelo: resbala, no es un choque.
- Derrape: menos agarre si se gira fuerte a alta velocidad. Todavía no deja marcas ni humo.
- HUD: velocidad en km/h, nitro, lugar, puntos, multiplicador, pausa y un aviso de controles solo en la primera carrera. Tiene que seguir leyéndose. Los efectos no pueden taparlo.

## Qué no existe y no hay que dar por hecho

No hay humo de neumáticos, marcas de derrape, chispas, cristales, deformación del auto, motion blur, shake de cámara, líneas de velocidad, luces de freno, estela de nitro larga, reflejos de charcos, relámpagos, polvo, nieve cayendo, hojas, ni transición cinematográfica entre lugares. El mundo no se recentra al origen. No hay un nivel tutorial aparte.

## Límites para las ideas

- Proponer efectos originales, realizables en Godot 4.7 sin plugins de pago ni assets con copyright.
- Servir tanto a Forward+ como a la web en Compatibility. Si un efecto solo sirve en escritorio, decirlo.
- Preferir partículas reutilizadas, mallas simples, materiales sin luz o emisivos, y animación con el tiempo de la carrera. Evitar crear nodos cada fotograma.
- Como mucho una sombra direccional. No añadir muchas OmniLight.
- El HUD y el auto tienen que seguir claros a 140–250 km/h de lectura (la unidad interna es m/s; el HUD muestra km/h).
- No cambiar las reglas: tres golpes terminan, el puntaje no baja, el nitro y el derrape ya existen.
- HJgames sigue siendo la firma. RUSHLINE sigue siendo el nombre grande.

## Qué quiero que respondas

Dame una lista priorizada de 8 a 12 efectos visuales para el futuro. Para cada uno incluye:

1. Nombre corto.
2. Dónde se ve: intro, menú, carrera, choque, nitro, derrape, lluvia, niebla o cambio de lugar.
3. Qué debe sentir el jugador en un segundo.
4. Cómo hacerlo en Godot sin depender de un asset comercial. Técnica concreta: partícula, malla, shader simple, luz o animación de cámara.
5. Costo aproximado en una gráfica integrada y en el navegador: bajo, medio o alto.
6. Qué no hacer para no copiar otro juego ni ensuciar el HUD.

Ordena por impacto visual dividido por costo. Al final, separa tres efectos que convienen dejar para más adelante porque pesarían demasiado en la web.
