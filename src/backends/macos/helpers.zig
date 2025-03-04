//! General helper functions for working with MacOS
const mouse = @import("../../mouse.zig");
const cg = @cImport({
    @cInclude("CoreGraphics/CoreGraphics.h");
});

pub fn pointFromPosition(position: mouse.Position) cg.CGPoint {
    return cg.CGPointMake(
        @floatFromInt(position.x),
        @floatFromInt(position.y),
    );
}

pub fn positionFromPoint(point: cg.CGPoint) mouse.Position {
    return mouse.Position.new(
        @intFromFloat(point.x),
        @intFromFloat(point.y),
    );
}
