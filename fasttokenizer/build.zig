const std = @import("std");
pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // fasttokenizer module
    const fasttokenizer_module = b.addModule("fasttokenizer", .{ .root_source_file = b.path("src/lib.zig") });

    // // Temp executable
    // var temp_exe = b.addExecutable(.{ .name = "temp_exe", .root_source_file = b.path("scratchpad/temp.zig"), .target = target, .optimize = optimize });
    // // temp_exe.linkSystemLibrary("pcre2-8");
    // temp_exe.linkLibC();
    // // temp_exe.addLibraryPath(.{ .path = "/home/akhil/practice/fancy-regex/target/release" });
    // // temp_exe.rp
    // temp_exe.linkSystemLibrary("fancy_regex");
    // temp_exe.root_module.addImport("fasttokenizer", fasttokenizer_module);
    // b.installArtifact(temp_exe);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib_unit_tests.linkLibC();

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const lib_test_step = b.step("libtest", "Run unit tests");
    lib_test_step.dependOn(&run_lib_unit_tests.step);

    // CLib
    const clib = b.addSharedLibrary(.{ .link_libc = true, .name = "fasttokenizer", .optimize = optimize, .target = target, .root_source_file = b.path("src/asclib.zig") });
    clib.addLibraryPath(b.path("../fancy-regex/target/release"));
    clib.linkSystemLibrary2("fancy_regex", .{});
    b.installArtifact(clib);

    //Create test for all test files
    ////////////////////////////////////////////////////////////
    //// Unit Testing
    // Creates a test binary.
    // Test step is created to be run from commandline i.e, zig build test

    test_blk: {
        const test_file = std.fs.cwd().openFile("build.zig.zon", .{}) catch {
            break :test_blk;
        };
        defer test_file.close();

        const test_file_contents = try test_file.readToEndAlloc(b.allocator, std.math.maxInt(usize));
        defer b.allocator.free(test_file_contents);

        // Hack for identifying if the current root is cudaz project, if not don't register tests.
        if (std.mem.indexOf(u8, test_file_contents, ".name = \"fasttokenizer\"") == null) {
            break :test_blk;
        }

        const test_step = b.step("test", "Run library tests");
        const lib_test = b.addTest(.{ .name = "libtests", .root_source_file = b.path("src/lib.zig"), .target = target, .optimize = optimize });
        lib_test.addLibraryPath(b.path("../fancy-regex/target/release"));
        lib_test.linkSystemLibrary2("fancy_regex", .{});
        lib_test.linkLibC();
        const run_lib_test = b.addRunArtifact(lib_test);
        test_step.dependOn(&run_lib_test.step);

        const test_dir = try std.fs.cwd().openDir("test", .{ .iterate = true });
        var dir_iterator = try test_dir.walk(b.allocator);
        while (try dir_iterator.next()) |item| {
            if (item.kind == .file) {
                if (!std.mem.endsWith(u8, item.path, ".zig")) {
                    continue;
                }
                const test_path = try std.fmt.allocPrint(b.allocator, "{s}/{s}", .{ "test", item.path });
                const sub_test = b.addTest(.{ .name = item.path, .root_source_file = b.path(test_path), .target = target, .optimize = optimize });
                // Add Module
                sub_test.root_module.addImport("fasttokenizer", fasttokenizer_module);
                sub_test.addLibraryPath(b.path("../fancy-regex/target/debug"));
                sub_test.linkSystemLibrary2("fancy_regex", .{});

                // Link libc, cuda and nvrtc libraries
                sub_test.linkLibC();

                // Creates a run step for test binary
                const run_sub_tests = b.addRunArtifact(sub_test);

                const test_name = try std.fmt.allocPrint(b.allocator, "test-{s}", .{item.path[0 .. item.path.len - 4]});
                // Create a test_step name
                const ind_test_step = b.step(test_name, "Individual Test");
                ind_test_step.dependOn(&run_sub_tests.step);
                test_step.dependOn(&run_sub_tests.step);
            }
        }
    }
}
