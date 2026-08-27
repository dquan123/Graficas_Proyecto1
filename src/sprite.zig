const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");

const NUM_FRAMES = 4;
const FRAME_DURATION: f32 = 0.15;

const frame_colors = [NUM_FRAMES]rl.Color{
    .{ .r = 255, .g = 140, .b = 0, .a = 255 },
    .{ .r = 255, .g = 180, .b = 40, .a = 255 },
    .{ .r = 255, .g = 100, .b = 0, .a = 255 },
    .{ .r = 255, .g = 200, .b = 60, .a = 255 },
};
const frame_scale = [NUM_FRAMES]f32{ 1.0, 1.15, 0.9, 1.05 };

pub const Sprite = struct {
    x: f32,
    y: f32,
    frame: usize = 0,
    frame_timer: f32 = 0,

    pub fn update(self: *Sprite, dt: f32) void {
        self.frame_timer += dt;
        if (self.frame_timer >= FRAME_DURATION) {
            self.frame_timer = 0;
            self.frame = (self.frame + 1) % NUM_FRAMES;
        }
    }

    pub fn draw(
        self: *const Sprite,
        player_x: f32,
        player_y: f32,
        player_angle: f32,
        fov: f32,
        screen_width: i32,
        screen_height: i32,
        dist_to_projection_plane: f32,
        z_buffer: []const f32,
    ) void {
        const dx = self.x - player_x;
        const dy = self.y - player_y;
        const distance = @sqrt(dx * dx + dy * dy);

        var rel_angle = std.math.atan2(dy, dx) - player_angle;
        while (rel_angle > std.math.pi) rel_angle -= std.math.tau;
        while (rel_angle < -std.math.pi) rel_angle += std.math.tau;

        if (@abs(rel_angle) > fov / 2.0 + 0.3) return;

        const perp_dist = @max(distance * @cos(rel_angle), 1.0);
        const screen_x_f = (0.5 + rel_angle / fov) * @as(f32, @floatFromInt(screen_width));

        const size = (map.CELL_SIZE / perp_dist) * dist_to_projection_plane * 0.7 * frame_scale[self.frame];
        const size_clamped = std.math.clamp(size, 1.0, 2000.0);

        const top: i32 = @intFromFloat(@as(f32, @floatFromInt(screen_height)) / 2.0 - size_clamped / 2.0);
        const bottom: i32 = @intFromFloat(@as(f32, @floatFromInt(screen_height)) / 2.0 + size_clamped / 2.0);

        const half_size = size_clamped / 2.0;
        const draw_start_x: i32 = @intFromFloat(screen_x_f - half_size);
        const draw_end_x: i32 = @intFromFloat(screen_x_f + half_size);

        const start_clamped = std.math.clamp(draw_start_x, 0, screen_width - 1);
        const end_clamped = std.math.clamp(draw_end_x, 0, screen_width - 1);

        var col = start_clamped;
        while (col <= end_clamped) : (col += 1) {
            const idx: usize = @intCast(col);
            if (perp_dist < z_buffer[idx]) {
                rl.drawLine(col, top, col, bottom, frame_colors[self.frame]);
            }
        }
    }
};
