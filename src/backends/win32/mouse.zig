// TODO: Convert i32 to i32 somehow. Every other system uses i3 to represent
//       mouse position, other than MacOS which uses i32.

const winapi = @cImport(@cInclude("windows.h"));

///////////////////////////////////////////////////////////////////////////////
// ENUMS
///////////////////////////////////////////////////////////////////////////////
pub const Win32MouseButton = enum {
    /// An unknown button
    unknown,
    /// Left click, also known as LMB
    left,
    /// Right click, also know as RMB
    right,
    /// Middle click, also known as MMB
    middle,
};
pub const Win32MouseButtonState = enum { pressed, released, moved };
pub const Win32MousePosition = struct {
    x: i32,
    y: i32,

    pub fn new(x: i32, y: i32) Win32MousePosition {
        return .{ .x = x, .y = y };
    }
};

pub const Win32Mouse = struct {
    /// A helper function useful for batching SendInput calls
    fn gen_input(_: *Win32Mouse, kind: u32, dwflags: u32) winapi.INPUT {
        return winapi.INPUT{
            .type = kind,
            .unnamed_0 = .{
                .mi = .{
                    .dwFlags = dwflags,
                    .time = 0,
                    .mouseData = 0,
                    .dwExtraInfo = 0,
                },
            },
        };
    }

    /// A helper function useful for batching SendInput press calls
    fn gen_press(self: *Win32Mouse, button: Win32MouseButton) !winapi.INPUT {
        return self.gen_input(
            winapi.INPUT_MOUSE,
            switch (button) {
                .left => winapi.MOUSEEVENTF_LEFTDOWN,
                .right => winapi.MOUSEEVENTF_RIGHTDOWN,
                .middle => winapi.MOUSEEVENTF_MIDDLEDOWN,
                else => return error.InvalidButton,
            },
        );
    }

    /// A helper function useful for batching SendInput release calls
    fn gen_release(self: *Win32Mouse, button: Win32MouseButton) !winapi.INPUT {
        return self.gen_input(
            winapi.INPUT_MOUSE,
            switch (button) {
                .left => winapi.MOUSEEVENTF_LEFTUP,
                .right => winapi.MOUSEEVENTF_RIGHTUP,
                .middle => winapi.MOUSEEVENTF_MIDDLEUP,
                else => return error.InvalidButton,
            },
        );
    }

    pub fn init() Win32Mouse {
        return .{};
    }

    pub fn deinit(_: *Win32Mouse) void {
        // nothing to deinit
        return;
    }

    ///////////////////////////////////////////////////////////////////////////
    // CONTROL
    ///////////////////////////////////////////////////////////////////////////
    /// Returns the current position of the mouse pointer.
    pub fn getPosition(_: *Win32Mouse) [2]i32 {
        var pos: winapi.POINT = undefined;
        _ = winapi.GetCursorPos(&pos);

        return [2]i32{ pos.x, pos.y };
    }

    /// Moves the mouse pointer to a given position
    pub fn moveTo(_: *Win32Mouse, x: i32, y: i32) !void {
        _ = winapi.SetCursorPos(x, y);
    }

    /// Moves the mouse pointer a number of pixels from its current position.
    /// This function is not to be confused with `moveTo`!
    pub fn moveBy(self: *Win32Mouse, dx: i32, dy: i32) !void {
        const pos = self.getPosition();
        try self.moveTo(pos[0] + dx, pos[1] + dy);
    }

    /// Send scroll event.
    pub fn scroll(self: *Win32Mouse, dx: i32, dy: i32) !void {
        var input: [2]winapi.INPUT = undefined;

        if (dx != 0) {
            input[0] = try self._gen_input(winapi.INPUT_MOUSE, winapi.MOUSEEVENTF_HWHEEL);
            input[0].unnamed_0.mi.mouseData = dx; // maybe do * WHEEL_DELTA?

        }

        if (dy != 0) {
            input[0] = try self._gen_input(winapi.INPUT_MOUSE, winapi.MOUSEEVENTF_WHEEL);
            input.unnamed_0.mi.mouseData = dy; // maybe do * WHEEL_DELTA?
        }

        _ = winapi.SendInput(input.len, &input, @sizeOf(winapi.INPUT));
    }

    /// Emits a button press event at the current position.
    pub fn press(self: *Win32Mouse, button: Win32MouseButton) !void {
        var input = try self._gen_press(button);
        _ = winapi.SendInput(1, &input, @sizeOf(winapi.INPUT));
    }

    /// Emits a button press event at a given position
    pub fn pressAt(self: *Win32Mouse, button: Win32MouseButton, x: i32, y: i32) !void {
        try self.moveTo(x, y);
        try self.press(button);
    }

    /// Emits a button release event at the current position.
    pub fn release(self: *Win32Mouse, button: Win32MouseButton) !void {
        var input = try self._gen_release(button);
        _ = winapi.SendInput(1, &input, @sizeOf(winapi.INPUT));
    }

    /// Emits a button press event at a given position
    pub fn releaseAt(self: *Win32Mouse, button: Win32MouseButton, x: i32, y: i32) !void {
        try self.moveTo(x, y);
        try self.release(button);
    }

    /// Emits a button press AND release event at the current position.
    pub fn click(_: *Win32Mouse, _: Win32MouseButton) !void {
        // var input = [2]winapi.INPUT{
        //     try self._gen_press(button),
        //     try self._gen_release(button),
        // };
        // _ = winapi.SendInput(2, &input, @sizeOf(winapi.INPUT));
        _ = winapi.mouse_event(winapi.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
        _ = winapi.mouse_event(winapi.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
    }

    /// Emits a button press AND release event at a given position
    pub fn clickAt(self: *Win32Mouse, button: Win32MouseButton, x: i32, y: i32) !void {
        try self.moveTo(x, y);
        try self.click(button);
    }
};

///////////////////////////////////////////////////////////////////////////////
// LISTENER
///////////////////////////////////////////////////////////////////////////////
