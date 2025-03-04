/// -lc $(pkg-config --cflags --libs libevdev)
// TODO:
//   - write a small libevdev wrapper, or even a evdev wrapper
//   - Fix event timing. Events can and will get skipped at certain speeds under
//     certain loads.
const Thread = @import("std").Thread;
const mouse = @import("../../mouse.zig");
pub const c = @cImport({
    @cInclude("libevdev/libevdev.h");
    @cInclude("libevdev/libevdev-uinput.h");
});

const LinuxMouse = @This();

/// uinput device
device: ?*c.libevdev_uinput,

pub fn init() !LinuxMouse {
    var device: *c.libevdev = undefined;
    var uidevice: ?*c.libevdev_uinput = undefined;

    device = c.libevdev_new().?;
    _ = c.libevdev_set_name(device, "ZinputMouse");
    // TODO: This code shouldn't be hardcoded...
    // absolute movement
    const abs_info_x = c.input_absinfo{
        .minimum = 0,
        .maximum = 1920, // Example screen width
        .fuzz = 0,
        .flat = 0,
    };
    const abs_info_y = c.input_absinfo{
        .minimum = 0,
        .maximum = 1080,
        .fuzz = 0,
        .flat = 0,
    };
    _ = c.libevdev_enable_event_type(device, c.EV_ABS);
    _ = c.libevdev_enable_event_code(device, c.EV_ABS, c.ABS_X, &abs_info_x);
    _ = c.libevdev_enable_event_code(device, c.EV_ABS, c.ABS_Y, &abs_info_y);
    // relative movement
    _ = c.libevdev_enable_event_type(device, c.EV_REL);
    _ = c.libevdev_enable_event_code(device, c.EV_REL, c.REL_X, null);
    _ = c.libevdev_enable_event_code(device, c.EV_REL, c.REL_Y, null);
    // key presses
    _ = c.libevdev_enable_event_type(device, c.EV_KEY);
    _ = c.libevdev_enable_event_code(device, c.EV_KEY, c.BTN_LEFT, null);
    _ = c.libevdev_enable_event_code(device, c.EV_KEY, c.BTN_MIDDLE, null);
    _ = c.libevdev_enable_event_code(device, c.EV_KEY, c.BTN_RIGHT, null);
    // reporting
    _ = c.libevdev_enable_event_type(device, c.EV_SYN);
    _ = c.libevdev_enable_event_code(device, c.EV_SYN, c.SYN_REPORT, null);

    if (c.libevdev_uinput_create_from_device(device, c.LIBEVDEV_UINPUT_OPEN_MANAGED, &uidevice) != 0)
        return error.CannotCreateUinput;
    c.libevdev_free(device);

    // TODO: Give time for the Xserver / Compositor to register the new device
    Thread.sleep(50_000_000);

    return .{ .device = uidevice };
}

pub fn deinit(self: *LinuxMouse) void {
    c.libevdev_uinput_destroy(self.device);
}

/// Set the *absolute* mouse position. For relative movement see `moveBy()`.
pub fn moveTo(self: *LinuxMouse, position: mouse.Position) !void {
    _ = c.libevdev_uinput_write_event(self.device, c.EV_ABS, c.ABS_Y, position.x);
    _ = c.libevdev_uinput_write_event(self.device, c.EV_ABS, c.ABS_X, position.y);
    _ = c.libevdev_uinput_write_event(self.device, c.EV_SYN, c.SYN_REPORT, 0);

    // TODO: Gotta be a better solution than this
    Thread.sleep(50_000_000);
}

/// Move *relative* to where the mouse currently is. For absolute movement see `moveTo()`.
pub fn moveBy(self: *LinuxMouse, position: mouse.Position) !void {
    _ = c.libevdev_uinput_write_event(self.device, c.EV_REL, c.REL_X, position.x);
    _ = c.libevdev_uinput_write_event(self.device, c.EV_REL, c.REL_Y, position.y);
    _ = c.libevdev_uinput_write_event(self.device, c.EV_SYN, c.SYN_REPORT, 0);

    // TODO: Gotta be a better solution than this
    Thread.sleep(50_000_000);
}

pub fn up(self: LinuxMouse, button: mouse.Button) !void {
    const btn: c_uint = switch (button) {
        .left => c.BTN_LEFT,
        .middle => c.BTN_MIDDLE,
        .right => c.BTN_RIGHT,
    };

    _ = c.libevdev_uinput_write_event(self.device, c.EV_KEY, btn, 0);
    _ = c.libevdev_uinput_write_event(self.device, c.EV_SYN, c.SYN_REPORT, 0);

    // TODO: Gotta be a better solution than this
    Thread.sleep(50_000_000);
}

pub fn down(self: LinuxMouse, button: mouse.Button) !void {
    const btn: c_uint = switch (button) {
        .left => c.BTN_LEFT,
        .middle => c.BTN_MIDDLE,
        .right => c.BTN_RIGHT,
    };

    _ = c.libevdev_uinput_write_event(self.device, c.EV_KEY, btn, 1);
    _ = c.libevdev_uinput_write_event(self.device, c.EV_SYN, c.SYN_REPORT, 0);

    // TODO: Gotta be a better solution than this
    Thread.sleep(50_000_000);
}

pub fn click(self: LinuxMouse, button: mouse.Button) !void {
    try self.down(button);
    try self.up(button);
}
