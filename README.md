# Proyecto 1: Raycaster

Diego Quan (24336)

Motor de raycasting en tiempo real (estilo Wolfenstein 3D) hecho en Zig 0.16 + raylib, sin usar geometría 3D — todo el renderizado es DDA + proyección de columnas verticales.

## Cómo correrlo

```bash
zig build run
```

Controles: **W/A/S/D** para moverte, **mouse** para rotar la cámara.

## Objetivos implementados

- Motor de raycasting con algoritmo DDA, corrección de fisheye y sombreado por lado de pared
- Colores distintos por tipo de pared, un laberinto real (sin atajos ni ciclos)
- Cámara con movimiento + rotación con mouse
- FPS mostrados en pantalla (estables en 60)
- Minimapa en la esquina superior derecha, con posición del jugador y meta marcada
- Sprite animado (antorcha parpadeante) con visualización correcta detrás de paredes (z-buffer)
- Música de fondo en loop
- Efectos de sonido (pasos al caminar, sonido de victoria)
- Pantalla de bienvenida y pantalla de éxito al llegar a la meta

## Estructura

- `src/main.zig`: loop principal, máquina de estados (bienvenida / jugando / victoria), render de las 800 columnas.
- `src/map.zig`: grid del laberinto, tipos de pared y celda de meta.
- `src/player.zig`: posición, movimiento con colisión, rotación con mouse.
- `src/raycaster.zig`: algoritmo DDA (`castRay`).
- `src/sprite.zig`: renderizado de billboards con z-buffer.
- `src/minimap.zig`: minimapa en esquina.
- `assets/`: música y efectos de sonido.

## Video

[link al video de demostración]
