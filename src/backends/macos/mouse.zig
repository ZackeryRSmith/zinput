/// -framework ApplicationServices
// TODO:
//   - Fix event timing. Events can and will get skipped at certain speeds under
//     certain loads

// TODO: Avoid relative importing in favor for using the build system properly
const time = @import("std").time;
const mouse = @import("../../mouse.zig");
const helpers = @import("helpers.zig");
const cg = @cImport({
    @cInclude("CoreGraphics/CoreGraphics.h");
});

const MacosMouse = @This();

pub fn init() !MacosMouse {
    return .{};
}
pub fn deinit(_: MacosMouse) void {
    return;
}

///////////////////////////////////////////////////////////////////////////////
// CONTROL
///////////////////////////////////////////////////////////////////////////////

/// Returns the current position of the mouse pointer.
pub fn getPosition(_: MacosMouse) mouse.Position {
    const event: cg.CGEventRef = cg.CGEventCreate(null);
    const point: cg.CGPoint = cg.CGEventGetLocation(event);
    cg.CFRelease(event);

    return helpers.positionFromPoint(point);
}

/// Set the *absolute* mouse position. For relative movement see `moveBy()`.
pub fn moveTo(_: MacosMouse, position: mouse.Position) !void {
    const event: cg.CGEventRef = cg.CGEventCreateMouseEvent(
        null,
        cg.kCGEventMouseMoved,
        helpers.pointFromPosition(position),
        cg.kCGEventNull, // irrelevant for a move event
    );
    if (event == null) return error.EventCreationFailure;

    cg.CGEventPost(cg.kCGSessionEventTap, event);
    cg.CFRelease(event);

    // TODO: Gotta be a better solution than this
    time.sleep(50_000_000);
}

/// Move *relative* to where the mouse currently is. For absolute movement see `moveTo()`.
pub fn moveBy(self: MacosMouse, position: mouse.Position) !void {
    const current_position = self.getPosition();
    try self.moveTo(mouse.Position.new(
        current_position.x + position.x,
        current_position.y + position.y,
    ));
}

/// Send scroll event.
pub fn scroll(_: MacosMouse, dx: f64, dy: f64) !void {
    const event: cg.CGEventRef = cg.CGEventCreateScrollWheelEvent(
        null,
        cg.kCGScrollEventUnitLine,
        2,
        dy,
        dx,
    );
    if (event == null) return error.EventCreationFailure;

    cg.CGEventPost(cg.kCGHIDEventTap, event);
    cg.CFRelease(event);

    // TODO: Gotta be a better solution than this
    time.sleep(50_000_000);
}

pub fn up(self: MacosMouse, button: mouse.Button) !void {
    const drag_event: cg.CGEventRef = cg.CGEventCreateMouseEvent(
        null,
        switch (button) {
            .left => cg.kCGEventLeftMouseDragged,
            .right => cg.kCGEventRightMouseDragged,
            else => cg.kCGEventOtherMouseDragged,
        },
        helpers.pointFromPosition(self.getPosition()),
        cg.kCGEventNull, // oddly irrelevant for an up event
    );
    if (drag_event == null) return error.EventCreationFailure;

    cg.CGEventPost(cg.kCGHIDEventTap, drag_event);
    cg.CFRelease(drag_event);

    const up_event: cg.CGEventRef = cg.CGEventCreateMouseEvent(
        null,
        switch (button) {
            .left => cg.kCGEventLeftMouseUp,
            .right => cg.kCGEventRightMouseUp,
            else => cg.kCGEventOtherMouseUp,
        },
        helpers.pointFromPosition(self.getPosition()),
        cg.kCGEventNull, // oddly irrelevant for an up event
    );
    if (up_event == null) return error.EventCreationFailure;

    cg.CGEventPost(cg.kCGHIDEventTap, up_event);
    cg.CFRelease(up_event);

    // TODO: Gotta be a better solution than this
    time.sleep(50_000_000);
}

pub fn down(self: MacosMouse, button: mouse.Button) !void {
    const event: cg.CGEventRef = cg.CGEventCreateMouseEvent(
        null,
        switch (button) {
            .left => cg.kCGEventLeftMouseDown,
            .right => cg.kCGEventRightMouseDown,
            else => cg.kCGEventOtherMouseDown,
        },
        helpers.pointFromPosition(self.getPosition()),
        cg.kCGEventNull, // oddly irrelevant for a down event
    );
    if (event == null) return error.EventCreationFailure;

    cg.CGEventPost(cg.kCGHIDEventTap, event);
    cg.CFRelease(event);

    // TODO: Gotta be a better solution than this
    time.sleep(50_000_000);
}

/// Emits a button press AND release event at a given position.
pub fn click(self: MacosMouse, button: mouse.Button) !void {
    try self.down(button);
    try self.up(button);
}

///////////////////////////////////////////////////////////////////////////////
// LISTEN
///////////////////////////////////////////////////////////////////////////////
