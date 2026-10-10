# Intro HJGAMES

Presentación original del estudio. No usa logotipos, animaciones ni sonidos de PlayStation, Capcom ni de otros juegos.

## Secuencia

Dura 8 segundos y después abre el menú. No vuelve a reproducirse al regresar desde la pausa: esa salida entra directo a la pantalla de título.

1. 0–1 s: negro, ambiente grave y partículas.
2. 1–2,5 s: un haz azul cruza la pantalla y la cámara se acerca.
3. 2,5–4,5 s: las letras HJGAMES entran una a una, en metal.
4. 4,5–6 s: destello e impacto, con el nombre ya completo.
5. 6–8 s: aparece PRESENTA y la imagen cierra a negro hacia el menú.

Esc, Start o A la omiten. M alterna el silencio guardado en las opciones. En la web, si el navegador bloquea el audio hasta el primer gesto, el sting arranca con esa pulsación.

## Recursos

| Archivo | Origen | Licencia |
| --- | --- | --- |
| `Orbitron-Variable.ttf` | [Google Fonts / Orbitron](https://fonts.google.com/specimen/Orbitron), proyecto [theleagueof/orbitron](https://github.com/theleagueof/orbitron) | SIL OFL 1.1, texto completo en `OFL.txt`. Uso comercial y en videojuegos permitido. |
| `NotoSans-Regular.ttf` | [Google Noto Sans](https://fonts.google.com/noto/specimen/Noto+Sans) | SIL OFL 1.1, aviso en `NotoSans-OFL.txt`. Respaldo de la interfaz para signos que Orbitron no dibuja. |
| Sonido | Generado en `scripts/branding/hj_intro.gd` | Original. No se descargó audio de Freesound ni de Mixkit. |

La escena es `scenes/branding/HJGamesIntro.tscn`. El escenario 3D está en `scripts/branding/intro_stage.gd` y el polvo en `scripts/branding/intro_dust.gd`.
