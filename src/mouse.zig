pub const Position = struct {
    x: u16,
    y: u16,

    pub fn new(x: u16, y: u16) Position {
        return .{ .x = x, .y = y };
    }
};

pub const Button = enum { left, middle, right };
