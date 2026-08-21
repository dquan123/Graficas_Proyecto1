const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");
const raycaster = @import("raycaster.zig");
const Player = @import("player.zig").Player;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const FOV: f32 = std.math.pi / 3.0; // 60 grados

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raycaster");

    rl.disableCursor(); // oculta el cursor y lo "atrapa" dentro de la ventana

    defer rl.enableCursor();
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var player = Player.init(3 * map.CELL_SIZE, 3 * map.CELL_SIZE, 0);

    const dist_to_projection_plane = (SCREEN_WIDTH / 2.0) / @tan(FOV / 2.0);

    const Clock = std.Io.Clock.real;
    var last = Clock.now(io);

    while (!rl.windowShouldClose()) {
        const now = Clock.now(io);
        var dt: f32 = @floatFromInt(last.durationTo(now).toNanoseconds());
        dt /= 1_000_000_000;
        last = now;

        player.update(dt);

        rl.beginDrawing();

        // Techo y piso: dos rectángulos simples por ahora (los mejoramos
        // luego con texturas si da tiempo). Esto también reemplaza el
        // "clearBackground" -- ya estamos pintando toda la pantalla.
        rl.drawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT / 2, .dark_gray);
        rl.drawRectangle(0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT / 2, .gray);

        var col: i32 = 0;
        while (col < SCREEN_WIDTH) : (col += 1) {
            const t: f32 = @as(f32, @floatFromInt(col)) / @as(f32, SCREEN_WIDTH);
            const ray_angle = player.angle - FOV / 2.0 + FOV * t;

            const hit = raycaster.castRay(player.x, player.y, ray_angle);

            var corrected_dist = hit.distance * @cos(ray_angle - player.angle);
            // Evita división entre cero / distancias absurdamente chicas
            // cuando el jugador está pegado a una pared.
            corrected_dist = @max(corrected_dist, 1.0);

            const wall_height = (map.CELL_SIZE / corrected_dist) * dist_to_projection_plane;

            var wall_top_f = SCREEN_HEIGHT / 2.0 - wall_height / 2.0;
            var wall_bottom_f = SCREEN_HEIGHT / 2.0 + wall_height / 2.0;

            // Clamp para que nunca se salga del rango seguro de un i32,
            // sin importar qué tan extrema sea wall_height.
            wall_top_f = std.math.clamp(wall_top_f, -10000.0, 10000.0);
            wall_bottom_f = std.math.clamp(wall_bottom_f, -10000.0, 10000.0);

            const wall_top: i32 = @intFromFloat(wall_top_f);
            const wall_bottom: i32 = @intFromFloat(wall_bottom_f);

            const color = wallColor(hit.wall_type, hit.side);

            rl.drawLine(col, wall_top, col, wall_bottom, color);
        }

        rl.drawFPS(10, 10);

        rl.endDrawing();
    }
}

/// Un color distinto por tipo de pared (número del mapa), y un poco más
/// oscuro en los lados "horizontales" (side == 1) para dar sensación de
/// profundidad -- es un truco barato pero muy efectivo visualmente.
fn wallColor(wall_type: u8, side: u8) rl.Color {
    var base: rl.Color = switch (wall_type) {
        1 => .{ .r = 180, .g = 60, .b = 60, .a = 255 },
        2 => .{ .r = 60, .g = 180, .b = 60, .a = 255 },
        3 => .{ .r = 60, .g = 60, .b = 180, .a = 255 },
        4 => .{ .r = 180, .g = 180, .b = 60, .a = 255 },
        5 => .{ .r = 180, .g = 60, .b = 180, .a = 255 },
        else => .{ .r = 200, .g = 200, .b = 200, .a = 255 },
    };

    if (side == 1) {
        base.r = @intFromFloat(@as(f32, @floatFromInt(base.r)) * 0.7);
        base.g = @intFromFloat(@as(f32, @floatFromInt(base.g)) * 0.7);
        base.b = @intFromFloat(@as(f32, @floatFromInt(base.b)) * 0.7);
    }

    return base;
}
