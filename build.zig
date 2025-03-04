const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("zinput", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    module.link_libc = true;

    const tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests.linkLibC();

    const tests_step = b.step("test", "Run library tests");
    tests_step.dependOn(&tests.step);

    // NOTE: We're allowed to do this because cross compiling isn't a worry right now.
    //       However it is on the agenda.
    switch (target.result.os.tag) {
        .macos => {
            module.linkFramework("Carbon", .{});
            tests.linkFramework("Carbon");
        },
        .linux => {
            module.linkSystemLibrary("libevdev", .{});
            tests.linkSystemLibrary("libevdev");
        },
        else => {},
    }
}
