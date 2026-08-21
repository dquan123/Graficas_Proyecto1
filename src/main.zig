const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");
const Player = @import("player.zig").Player;
const raycaster = @import("raycaster.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    rl.initWindow(800, 600, "Raycaster - debug vista de arriba");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var player = Player.init(3 * map.CELL_SIZE, 3 * map.CELL_SIZE, 0);

    const Clock = std.Io.Clock.real;
    var last = Clock.now(io);

    while (!rl.windowShouldClose()) {
        const now = Clock.now(io);
        var dt: f32 = @floatFromInt(last.durationTo(now).toNanoseconds());
        dt /= 1_000_000_000;
        last = now;

        player.update(dt);

        const hit = raycaster.castRay(player.x, player.y, player.angle);

        rl.beginDrawing();
        rl.clearBackground(.black);

        // Dibuja el grid completo, celda por celda.
        for (0..map.MAP_HEIGHT) |gy| {
            for (0..map.MAP_WIDTH) |gx| {
                if (map.grid[gy][gx] != 0) {
                    const px: i32 = @intFromFloat(@as(f32, @floatFromInt(gx)) * map.CELL_SIZE);
                    const py: i32 = @intFromFloat(@as(f32, @floatFromInt(gy)) * map.CELL_SIZE);
                    rl.drawRectangle(px, py, @intFromFloat(map.CELL_SIZE), @intFromFloat(map.CELL_SIZE), .gray);
                }
            }
        }

        // Jugador: un punto rojo + una línea amarilla mostrando hacia dónde mira.
        rl.drawCircle(@intFromFloat(player.x), @intFromFloat(player.y), 5, .red);
        rl.drawLine(
            @intFromFloat(player.x),
            @intFromFloat(player.y),
            @intFromFloat(player.x + @cos(player.angle) * 20),
            @intFromFloat(player.y + @sin(player.angle) * 20),
            .yellow,
        );

        // Dibuja el rayo desde el jugador hasta donde chocó con la pared.
        rl.drawLine(
            @intFromFloat(player.x),
            @intFromFloat(player.y),
            @intFromFloat(hit.hit_x),
            @intFromFloat(hit.hit_y),
            .green,
        );
        rl.drawCircle(@intFromFloat(hit.hit_x), @intFromFloat(hit.hit_y), 4, .lime);

        var buf: [64]u8 = undefined;
        const text = try std.fmt.bufPrintZ(&buf, "dist: {d:.1} tipo: {} lado: {}", .{ hit.distance, hit.wall_type, hit.side });
        rl.drawText(text, 10, 10, 20, .white);

        rl.endDrawing();
    }
}
