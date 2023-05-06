const std = @import("std");
const builtin = @import("builtin");
const getopt = @import("./getopt.zig");
const config = @import("./config.zig");
const utils = @import("./utils.zig");

const PassConfig = config.PassConfig;
const Opt = getopt.Opt;
const Git = @import("./git.zig").Git;
const Gpg = @import("./gpg.zig").Gpg;

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const pass_config = try config.PassConfig.init(gpa);
    defer pass_config.deinit();

    const opts = try getopt.parseOpts(args, gpa);

    if (opts.items.len > 0) {
        const first_opt: Opt = opts.items[0];
        if (first_opt.isLiteral() and first_opt.valueEquals("git")) {
            try commandGit(gpa, pass_config, opts.items[1..], args[2..]);
            return;
        }
    }

    try commandShow(gpa, pass_config, opts);
}

fn commandGit(allocator: std.mem.Allocator, pass_config: PassConfig, git_opts: []Opt, git_args: [][]const u8) !void {
    const git = Git.init(allocator, pass_config, true);

    if (git_opts.len > 0) {
        const second_opt: Opt = git_opts[0];

        if (second_opt.valueEquals("init")) {
            _ = try git.initRepository();
        } else {
            _ = try git.execute(git_args);
        }
    } else {
        _ = try git.execute(&.{});
    }
}

const ShowOptions = struct {
    selectedLine: u8,
    clip: bool,
    qrcode: bool,
    name: ?[]const u8,
};

fn parseShowOpts(opts: std.ArrayList(Opt)) !ShowOptions {
    const all_opts: []Opt = opts.items;

    var show_options = ShowOptions{
        .selectedLine = 0,
        .clip = false,
        .qrcode = false,
        .name = null,
    };

    var clip_option: ?Opt = null;
    for (all_opts) |opt| {
        if (opt.isLiteral()) {
            show_options.name = opt.value;
        } else if (opt.isShortOpt()) {
            if (opt.nameEquals("c")) {
                clip_option = opt;
            }
        } else if (opt.isLongOpt()) {
            if (opt.nameEquals("clip")) {
                clip_option = opt;
            }
        }
    }

    if (clip_option) |clip| {
        show_options.clip = true;
        show_options.selectedLine = if (clip.value) |value| try std.fmt.parseInt(u8, value, 10) else 0;
    }

    return show_options;
}

fn commandShow(allocator: std.mem.Allocator, pass_config: PassConfig, opts: std.ArrayList(Opt)) !void {
    const gpg = Gpg.init(allocator, pass_config, false);

    const show_options = try parseShowOpts(opts);

    if (show_options.name) |name| {
        var output = try gpg.decrypt(name);

        const line: ?[]const u8 = blk: {
            var i: u8 = 0;
            while (output.next()) |line| {
                if (show_options.selectedLine == i) {
                    break :blk line;
                }

                i += 1;
            }

            break :blk null;
        };

        if (line) |l| {
            const quoted = try utils.wrapWithDoubleQuotes(allocator, l);
            defer allocator.free(quoted);

            const clip_script = try utils.getScriptPath(allocator, switch (builtin.os.tag) {
                .windows => "Clip.ps1",
                else => "Clip.sh",
            });
            defer allocator.free(clip_script);

            const clip_args = switch (builtin.os.tag) {
                .windows => .{
                    "powershell",
                    "-NoProfile",
                    clip_script,
                    "-Value",
                    quoted,
                    "-ClipTime",
                    pass_config.clipTime,
                    "-Name",
                    name,
                },
                else => .{},
            };

            const clip_result = try std.ChildProcess.exec(.{
                .allocator = allocator,
                .argv = &clip_args,
            });
            defer allocator.free(clip_result.stderr);
            defer allocator.free(clip_result.stdout);

            std.debug.print("{s}{s}\n", .{ clip_result.stderr, clip_result.stdout });
        }
    }
}
