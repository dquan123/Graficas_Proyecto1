const std = @import("std");
const rl = @import("raylib");
const map = @import("map.zig");
const Player = @import("player.zig").Player;
const raycaster = @import("raycaster.zig");

const MINIMAP_SCALE: f32 = 6.0;
const MARGIN: i32 = 10;

pub fn draw(screen_width: i32, player: *const Player) void {
    const minimap_width: i32 = @intFromFloat(@as(f32, map.MAP_WIDTH) * MINIMAP_SCALE);
    const minimap_height: i32 = @intFromFloat(@as(f32, map.MAP_HEIGHT) * MINIMAP_SCALE);

    const origin_x = screen_width - minimap_width - MARGIN;
    const origin_y = MARGIN;

    rl.drawRectangle(origin_x - 4, origin_y - 4, minimap_width + 8, minimap_height + 8, .{ .r = 0, .g = 0, .b = 0, .a = 160 });

    for (0..map.MAP_HEIGHT) |gy| {
        for (0..map.MAP_WIDTH) |gx| {
            if (map.grid[gy][gx] != 0) {
                const px = origin_x + @as(i32, @intFromFloat(@as(f32, @floatFromInt(gx)) * MINIMAP_SCALE));
                const py = origin_y + @as(i32, @intFromFloat(@as(f32, @floatFromInt(gy)) * MINIMAP_SCALE));
                rl.drawRectangle(px, py, @intFromFloat(MINIMAP_SCALE), @intFromFloat(MINIMAP_SCALE), .light_gray);
            }
        }
    }

    const player_grid_x = player.x / map.CELL_SIZE;
    const player_grid_y = player.y / map.CELL_SIZE;
    const player_px = origin_x + @as(i32, @intFromFloat(player_grid_x * MINIMAP_SCALE));
    const player_py = origin_y + @as(i32, @intFromFloat(player_grid_y * MINIMAP_SCALE));

    rl.drawCircle(player_px, player_py, 3, .red);

    const hit = raycaster.castRay(player.x, player.y, player.angle);
    const hit_grid_x = hit.hit_x / map.CELL_SIZE;
    const hit_grid_y = hit.hit_y / map.CELL_SIZE;
    const hit_px = origin_x + @as(i32, @intFromFloat(hit_grid_x * MINIMAP_SCALE));
    const hit_py = origin_y + @as(i32, @intFromFloat(hit_grid_y * MINIMAP_SCALE));

    rl.drawLine(player_px, player_py, hit_px, hit_py, .yellow);
}
