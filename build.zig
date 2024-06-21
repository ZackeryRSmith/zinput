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
    //       Soon however this will be really important to me. For right now though it
    //       isn't a huge problem...
    switch (target.result.os.tag) {
        .macos => {
            module.linkFramework("Carbon", .{});
            tests.linkFramework("Carbon");
        },
        .linux, .freebsd => {
            // NOTE: To have support for both X11 and Wayland in the same binary
            //       you must have both X11 and Wayland installed on your system.
            //       Alternativly you may use either:
            //       `` or ``
            //       Disable compiling with one or the other

            module.linkSystemLibrary("wayland-client", .{});
            tests.linkSystemLibrary("wayland-client");

            module.linkSystemLibrary("xdo", .{});
            tests.linkSystemLibrary("xdo");
        },
        else => {},
    }
}
