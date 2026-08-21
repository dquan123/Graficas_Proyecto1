const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");

pub const Player = struct {
    x: f32,
    y: f32,
    angle: f32,

    move_speed: f32 = 100.0, // unidades de mundo por segundo
    rot_speed: f32 = 2.5, // radianes por segundo
    mouse_sensitivity: f32 = 0.003,

    pub fn init(x: f32, y: f32, angle: f32) Player {
        return Player{ .x = x, .y = y, .angle = angle };
    }

    pub fn update(self: *Player, dt: f32) void {
        const forward_x = @cos(self.angle);
        const forward_y = @sin(self.angle);

        // El vector perpendicular (para moverte de lado, "strafe" con A/D)
        // es simplemente el vector de dirección rotado 90 grados.
        // Rotar 90° en 2D es: (x, y) -> (-y, x).
        const strafe_x = -forward_y;
        const strafe_y = forward_x;

        var move_x: f32 = 0;
        var move_y: f32 = 0;

        if (rl.isKeyDown(.w)) {
            move_x += forward_x;
            move_y += forward_y;
        }
        if (rl.isKeyDown(.s)) {
            move_x -= forward_x;
            move_y -= forward_y;
        }
        if (rl.isKeyDown(.d)) {
            move_x += strafe_x;
            move_y += strafe_y;
        }
        if (rl.isKeyDown(.a)) {
            move_x -= strafe_x;
            move_y -= strafe_y;
        }

        const new_x = self.x + move_x * self.move_speed * dt;
        const new_y = self.y + move_y * self.move_speed * dt;

        // Colisión: probamos cada eje POR SEPARADO. Esto permite "deslizarte"
        // contra una pared en vez de quedarte pegado si te mueves en diagonal
        // hacia ella (si chocas en X, igual te dejamos mover en Y, y viceversa).
        if (!map.isWall(@intFromFloat(new_x / map.CELL_SIZE), @intFromFloat(self.y / map.CELL_SIZE))) {
            self.x = new_x;
        }
        if (!map.isWall(@intFromFloat(self.x / map.CELL_SIZE), @intFromFloat(new_y / map.CELL_SIZE))) {
            self.y = new_y;
        }

        // Rotación con mouse (solo horizontal, como pide el enunciado).
        const mouse_delta = rl.getMouseDelta();
        self.angle += mouse_delta.x * self.mouse_sensitivity;

        // Dejamos las flechas como respaldo/alternativa, no estorban.
        if (rl.isKeyDown(.right)) self.angle += self.rot_speed * dt;
        if (rl.isKeyDown(.left)) self.angle -= self.rot_speed * dt;
    }
};
