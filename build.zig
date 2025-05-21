const std = @import("std");
const Query = std.Target.Query;

pub fn build(b: *std.Build) void {
    const default_target: std.Target.Query = switch (b.graph.host.result.os.tag) {
        // Gpg4Win is only built for x86
        .windows => .{
            .cpu_arch = .x86,
        },
        else => .{},
    };

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{
        .default_target = default_target,
    });

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "zig-pass",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    switch (target.result.os.tag) {
        .windows => {
            const env = std.process.getEnvMap(b.allocator) catch @panic("OOM");
            const gpg4win_path = env.get("GPG4WIN_PATH") orelse @panic("GPG4WIN_PATH not set");
            const gpg4win_include_path = b.fmt("{s}/include", .{gpg4win_path});
            const gpg4win_lib_path = b.fmt("{s}/lib", .{gpg4win_path});
            const gpg4win_bin_path = b.fmt("{s}/bin", .{gpg4win_path});

            exe.addIncludePath(.{
                .cwd_relative = gpg4win_include_path,
            });
            exe.addLibraryPath(.{
                .cwd_relative = gpg4win_lib_path,
            });
            exe.addLibraryPath(.{
                .cwd_relative = gpg4win_bin_path,
            });
            exe.addObjectFile(.{
                .cwd_relative = b.fmt("{s}/bin/libgpgme-11.dll", .{gpg4win_path}),
            });
        },
        else => {
            exe.linkSystemLibrary("gpgme");
        },
    }

    exe.linkLibC();

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    const dep_clipboard = b.dependency("clipboard", .{});
    const mod_clipboard = dep_clipboard.module("clipboard");

    exe_mod.addImport("clipboard", mod_clipboard);
}
