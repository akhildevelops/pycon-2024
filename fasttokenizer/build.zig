const std = @import("std");
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const clib = b.addSharedLibrary(.{ .link_libc = true, .name = "fasttokenizer", .optimize = optimize, .target = target, .root_source_file = b.path("src/asclib.zig") });
    clib.addLibraryPath(b.path("../fancy-regex/target/release"));
    clib.linkSystemLibrary2("fancy_regex", .{});
    b.installArtifact(clib);
}
