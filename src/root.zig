const std = @import("std");
const builtin = @import("builtin");

const backend = switch (builtin.os.tag) {
    .windows => @import("backends/win32/backend.zig"),
    .macos => @import("backends/macos/backend.zig"),
    .linux, .freebsd => @import("backends/linux/backend.zig"),
    else => @compileError(std.fmt.comptimePrint("Unsupported OS: {}", .{builtin.os.tag})),
};
const Mouse = backend.Mouse;

test "zinput: refAllDecls" {
    std.testing.refAllDecls(backend);

    std.debug.print("PASSED\n", .{});
}

pub fn main() !void {
    var mouse = try Mouse.init();
    defer mouse.deinit();

    try mouse.down(.left);
    try mouse.moveBy(.{ .x = 50, .y = 50 });
    try mouse.up(.left);
}
