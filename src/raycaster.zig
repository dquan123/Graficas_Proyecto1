const std = @import("std");
const map = @import("map.zig");

pub const RayHit = struct {
    distance: f32, // distancia perpendicular
    map_x: i32,
    map_y: i32,
    side: u8, // 0 = golpeó una pared "vertical" (línea x del grid), 1 = "horizontal"
    wall_type: u8,
    hit_x: f32, // punto de choque, en unidades de mundo
    hit_y: f32,
};

/// Lanza un rayo desde (px, py) en la dirección `angle` (radianes) y
/// devuelve dónde chocó con una pared, usando DDA.
pub fn castRay(px: f32, py: f32, angle: f32) RayHit {
    // Trabajamos en "espacio de grid" (cada celda = 1 unidad), no en píxeles.
    const grid_x = px / map.CELL_SIZE;
    const grid_y = py / map.CELL_SIZE;

    const ray_dir_x = @cos(angle);
    const ray_dir_y = @sin(angle);

    var map_x: i32 = @intFromFloat(@floor(grid_x));
    var map_y: i32 = @intFromFloat(@floor(grid_y));

    // Evitar división entre cero si el rayo va perfectamente horizontal o vertical.
    const delta_dist_x: f32 = if (ray_dir_x == 0) 1e30 else @abs(1.0 / ray_dir_x);
    const delta_dist_y: f32 = if (ray_dir_y == 0) 1e30 else @abs(1.0 / ray_dir_y);

    var step_x: i32 = undefined;
    var step_y: i32 = undefined;
    var side_dist_x: f32 = undefined;
    var side_dist_y: f32 = undefined;

    if (ray_dir_x < 0) {
        step_x = -1;
        side_dist_x = (grid_x - @as(f32, @floatFromInt(map_x))) * delta_dist_x;
    } else {
        step_x = 1;
        side_dist_x = (@as(f32, @floatFromInt(map_x)) + 1.0 - grid_x) * delta_dist_x;
    }

    if (ray_dir_y < 0) {
        step_y = -1;
        side_dist_y = (grid_y - @as(f32, @floatFromInt(map_y))) * delta_dist_y;
    } else {
        step_y = 1;
        side_dist_y = (@as(f32, @floatFromInt(map_y)) + 1.0 - grid_y) * delta_dist_y;
    }

    var side: u8 = 0;
    var hit = false;
    var iterations: u32 = 0;

    // El límite de iteraciones es una red de seguridad: garantiza que NUNCA
    // podamos quedar en un loop infinito (ej. si el mapa tuviera un hueco
    // sin bordes), cumpliendo el requisito de "no debe crashear".
    while (!hit and iterations < 1000) : (iterations += 1) {
        if (side_dist_x < side_dist_y) {
            side_dist_x += delta_dist_x;
            map_x += step_x;
            side = 0;
        } else {
            side_dist_y += delta_dist_y;
            map_y += step_y;
            side = 1;
        }

        if (map.isWall(map_x, map_y)) hit = true;
    }

    const perp_dist: f32 = if (side == 0)
        side_dist_x - delta_dist_x
    else
        side_dist_y - delta_dist_y;

    const world_dist = perp_dist * map.CELL_SIZE;

    return RayHit{
        .distance = world_dist,
        .map_x = map_x,
        .map_y = map_y,
        .side = side,
        .wall_type = map.wallType(map_x, map_y),
        .hit_x = px + ray_dir_x * world_dist,
        .hit_y = py + ray_dir_y * world_dist,
    };
}
