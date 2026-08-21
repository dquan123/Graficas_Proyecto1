const std = @import("std");
const rl = @import("raylib");

pub fn main(init: std.process.Init) !void {
    _ = init;

    rl.initWindow(800, 600, "Raycaster");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(.black);
        rl.drawText("Raycaster funcionando", 250, 280, 20, .white);
        rl.endDrawing();
    }
}
