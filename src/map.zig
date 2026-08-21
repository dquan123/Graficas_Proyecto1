const std = @import("std");

pub const MAP_WIDTH = 10;
pub const MAP_HEIGHT = 10;
pub const CELL_SIZE: f32 = 64.0; // cuántas "unidades de mundo" mide cada celda del grid

// 0 = espacio vacío. Cualquier otro número = pared, y el número indica
// el tipo de pared
pub const grid = [MAP_HEIGHT][MAP_WIDTH]u8{
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 0, 2, 2, 0, 0, 3, 3, 0, 1 },
    .{ 1, 0, 2, 0, 0, 0, 0, 3, 0, 1 },
    .{ 1, 0, 0, 0, 1, 1, 0, 0, 0, 1 },
    .{ 1, 0, 0, 0, 1, 1, 0, 0, 0, 1 },
    .{ 1, 0, 4, 0, 0, 0, 0, 5, 0, 1 },
    .{ 1, 0, 4, 4, 0, 0, 5, 5, 0, 1 },
    .{ 1, 0, 0, 0, 0, 0, 0, 0, 0, 1 },
    .{ 1, 1, 1, 1, 1, 1, 1, 1, 1, 1 },
};

pub fn isWall(x: i32, y: i32) bool {
    if (x < 0 or y < 0 or x >= MAP_WIDTH or y >= MAP_HEIGHT) return true;
    return grid[@intCast(y)][@intCast(x)] != 0;
}

pub fn wallType(x: i32, y: i32) u8 {
    if (x < 0 or y < 0 or x >= MAP_WIDTH or y >= MAP_HEIGHT) return 1;
    return grid[@intCast(y)][@intCast(x)];
}
