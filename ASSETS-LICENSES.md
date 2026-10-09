# Licencias de los recursos de RUSHLINE

Solo figuran recursos cuya licencia se pudo comprobar. Atribución no obligatoria en CC0; se nombra al autor igual.

## Superficies

| Recurso | Autor | Fuente | Licencia | Uso |
| --- | --- | --- | --- | --- |
| Asphalt 02, JPG 1K | Rob Tuytel | https://polyhaven.com/a/asphalt_02 | CC0. Poly Haven publica su biblioteca como CC0. | `assets/world/asphalt_diff.jpg`, asfalto de la pista. El mapa cubre 3 m. Se subió el contraste para que se note bajo el color del tema. |
| Concrete Floor Worn 001, JPG 1K | Dimitrios Savva, procesado por Rico Cilliers | https://polyhaven.com/a/concrete_floor_worn_001 | CC0, la misma política de Poly Haven. | `assets/world/concrete_diff.jpg`, aceras. |

## Ciudad

City Kit Commercial 2.1, Kenney. Licencia CC0 en `assets/kenney/city-kit-commercial-license.txt`. Fuente: https://kenney.nl/assets/city-kit-commercial

En la carrera se usan las fachadas con textura de ventanas: `building-a`, `building-c`, `building-e`, `building-g`, `building-j`, `building-n`, `building-skyscraper-a` a `d`. Las mallas no se editaron. Los edificios low-detail de unos 150 triángulos ya no se colocan.

City Kit Roads, Kenney. Licencia CC0 en `assets/kenney/city-kit-roads-license.txt`. Fuente: https://kenney.nl/assets/city-kit-roads

Además del cruce y la farola, la calle usa `road-straight-barrier`, `road-sign-warning`, `sign-highway`, `traffic-light`, `dumpster` y `road-bridge` (puente lateral, fuera de la pista). Las mallas no se editaron.

## Naturaleza

Nature Kit, Kenney. Licencia CC0 en `assets/kenney/nature-kit-license.txt`. Fuente: https://kenney.nl/assets/nature-kit

Se usan `tree_detailed`, `tree_oak`, `tree_pineRoundA`, `tree_pineDefaultB`, `tree_palmDetailedTall`, `plant_bushDetailed`, además de cactus y rocas que ya estaban. Las mallas no se editaron.

## Vehículos

Ver `VEHICLE_ASSET_CREDITS.md`. Grab3D, CC0 1.0, nota embebida en cada GLB.

## Intro de HJGAMES

| Recurso | Autor | Fuente | Licencia | Uso |
| --- | --- | --- | --- | --- |
| Orbitron, variable | The Orbitron Project Authors, Matt McInerney. Nombre reservado: Orbitron. | https://fonts.google.com/specimen/Orbitron y https://github.com/theleagueof/orbitron | SIL Open Font License 1.1. Permite uso comercial e incrustar la fuente en un videojuego. No se puede vender la fuente sola ni relicenciarla. El texto de la licencia está en `assets/branding/OFL.txt`. | `assets/branding/Orbitron-Variable.ttf`, wordmark HJGAMES y la línea PRESENTA. Peso 700. |
| Sting de la intro | Original del proyecto | Síntesis en `scripts/branding/hj_intro.gd` | Obra original. No hay samples de terceros. | Ambiente, subida, ticks metálicos, impacto y cola. El silencio del menú Opciones también lo apaga. |

Si la fuente no carga, el nombre se dibuja con Kenney Future Narrow, CC0, que ya usa la interfaz.

## Qué no se integró

Downtown City MegaKit de Quaternius es CC0 (https://quaternius.com/packs/downtowncitymegakit.html), pero son más de 300 módulos y la descarga libre pasa por itch.io. No se metió el paquete entero: el juego se publica en GitHub Pages y ese volumen no cabe en una carga web fluida.
