const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");
const raycaster = @import("raycaster.zig");
const Player = @import("player.zig").Player;
const minimap = @import("minimap.zig");
const Sprite = @import("sprite.zig").Sprite;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 600;
const FOV: f32 = std.math.pi / 3.0; // 60 grados

const GameState = enum {
    welcome,
    playing,
    won,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Raycaster");

    rl.disableCursor(); // oculta el cursor y lo "atrapa" dentro de la ventana

    rl.initAudioDevice();
    defer rl.closeAudioDevice();

    const music = try rl.loadMusicStream("assets/music.ogg");
    defer rl.unloadMusicStream(music);
    rl.playMusicStream(music);
    rl.setMusicVolume(music, 0.4);

    const footstep_sound = try rl.loadSound("assets/footstep.wav");
    defer rl.unloadSound(footstep_sound);

    const victory_sound = try rl.loadSound("assets/victory.ogg");
    defer rl.unloadSound(victory_sound);

    var footstep_timer: f32 = 0.90; // arranca "lista" para sonar de inmediato al primer paso

    defer rl.enableCursor();
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var state: GameState = .welcome;
    var player = Player.init(1.5 * map.CELL_SIZE, 1.5 * map.CELL_SIZE, 0);
    var z_buffer: [SCREEN_WIDTH]f32 = undefined;
    var torch = Sprite{ .x = 17.5 * map.CELL_SIZE, .y = 13.5 * map.CELL_SIZE };

    const dist_to_projection_plane = (SCREEN_WIDTH / 2.0) / @tan(FOV / 2.0);

    const Clock = std.Io.Clock.real;
    var last = Clock.now(io);

    while (!rl.windowShouldClose()) {
        const now = Clock.now(io);
        var dt: f32 = @floatFromInt(last.durationTo(now).toNanoseconds());
        dt /= 1_000_000_000;
        last = now;

        rl.updateMusicStream(music);

        switch (state) {
            .welcome => {
                if (rl.isKeyPressed(.enter)) {
                    state = .playing;
                }

                rl.beginDrawing();
                rl.clearBackground(.black);

                rl.drawText("RAYCASTER", 260, 200, 50, .white);
                rl.drawText("Presiona ENTER para jugar", 240, 300, 20, .light_gray);
                rl.drawText("WASD para moverte -- Mouse para mirar", 220, 340, 18, .gray);

                rl.endDrawing();
            },
            .playing => {
                player.update(dt);
                torch.update(dt);

                const moving = rl.isKeyDown(.w) or rl.isKeyDown(.a) or rl.isKeyDown(.s) or rl.isKeyDown(.d);
                if (moving) {
                    footstep_timer += dt;
                    if (footstep_timer >= 0.35) {
                        footstep_timer = 0;
                        rl.playSound(footstep_sound);
                    }
                } else {
                    footstep_timer = 0.35;
                }

                if (map.isAtGoal(player.x, player.y)) {
                    state = .won;
                    rl.playSound(victory_sound);
                }

                rl.beginDrawing();

                rl.drawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT / 2, .dark_gray);
                rl.drawRectangle(0, SCREEN_HEIGHT / 2, SCREEN_WIDTH, SCREEN_HEIGHT / 2, .gray);

                var col: i32 = 0;
                while (col < SCREEN_WIDTH) : (col += 1) {
                    const t: f32 = @as(f32, @floatFromInt(col)) / @as(f32, SCREEN_WIDTH);
                    const ray_angle = player.angle - FOV / 2.0 + FOV * t;

                    const hit = raycaster.castRay(player.x, player.y, ray_angle);

                    var corrected_dist = hit.distance * @cos(ray_angle - player.angle);
                    z_buffer[@intCast(col)] = corrected_dist;
                    corrected_dist = @max(corrected_dist, 1.0);

                    const wall_height = (map.CELL_SIZE / corrected_dist) * dist_to_projection_plane;

                    var wall_top_f = SCREEN_HEIGHT / 2.0 - wall_height / 2.0;
                    var wall_bottom_f = SCREEN_HEIGHT / 2.0 + wall_height / 2.0;
                    wall_top_f = std.math.clamp(wall_top_f, -10000.0, 10000.0);
                    wall_bottom_f = std.math.clamp(wall_bottom_f, -10000.0, 10000.0);

                    const wall_top: i32 = @intFromFloat(wall_top_f);
                    const wall_bottom: i32 = @intFromFloat(wall_bottom_f);

                    const color = wallColor(hit.wall_type, hit.side);
                    rl.drawLine(col, wall_top, col, wall_bottom, color);
                }

                torch.draw(player.x, player.y, player.angle, FOV, SCREEN_WIDTH, SCREEN_HEIGHT, dist_to_projection_plane, &z_buffer);
                minimap.draw(SCREEN_WIDTH, &player);
                rl.drawFPS(10, 10);

                rl.endDrawing();
            },
            .won => {
                if (rl.isKeyPressed(.enter)) {
                    // Reinicia al jugador de vuelta al spawn y regresa al juego.
                    player.x = 1.5 * map.CELL_SIZE;
                    player.y = 1.5 * map.CELL_SIZE;
                    player.angle = 0;
                    rl.stopSound(victory_sound);
                    state = .playing;
                }

                rl.beginDrawing();
                rl.clearBackground(.{ .r = 10, .g = 40, .b = 10, .a = 255 });

                rl.drawText("¡LO LOGRASTE!", 230, 220, 50, .green);
                rl.drawText("Llegaste a la meta", 270, 300, 22, .light_gray);
                rl.drawText("Presiona ENTER para jugar de nuevo", 200, 340, 18, .gray);

                rl.endDrawing();
            },
        }
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
