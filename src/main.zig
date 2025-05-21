const std = @import("std");
const builtin = @import("builtin");
const getopt = @import("./getopt.zig");
const config = @import("./config.zig");
const utils = @import("./utils.zig");
const clipboard = @import("clipboard");

const PassConfig = config.PassConfig;
const Opt = getopt.Opt;
const Git = @import("./git.zig").Git;
const Gpg = @import("./gpg.zig").Gpg;

const Command = enum(u32) {
    show,
    git,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    const pass_config = try config.PassConfig.init(allocator);
    const opts = try getopt.parseOpts(args, allocator);

    if (opts.items.len > 0) {
        const first_opt: Opt = opts.items[0];
        if (first_opt == .literal) {
            if (std.meta.stringToEnum(Command, first_opt.literal)) |command| switch (command) {
                .git => try commandGit(allocator, pass_config, opts.items[1..], args[2..]),
                .show => try commandShow(allocator, pass_config, opts),
            } else {
                try commandShow(allocator, pass_config, opts);
            }
            return;
        }
    } else {
        try printUsage();
        std.process.exit(1);
    }
}

fn printUsage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print(
        \\Usage: pass [command] [options]
        \\
        \\Commands:
        \\  show [name]       Show password content
        \\  git [command]     Execute git commands
        \\
        \\Options:
        \\  -c, --clip [line] Copy password line to clipboard
        \\
    , .{});
}

fn commandGit(allocator: std.mem.Allocator, pass_config: PassConfig, git_opts: []Opt, git_args: [][:0]u8) !void {
    const git = Git.init(allocator, pass_config, true);

    if (git_opts.len > 0) {
        const second_opt: Opt = git_opts[0];

        if (second_opt == .literal and std.mem.eql(u8, second_opt.literal, "init")) {
            _ = try git.initRepository();
        } else {
            _ = try git.execute(git_args);
        }
    } else {
        _ = try git.execute(&.{});
    }
}

const ShowOption = enum {
    clip,
    c,
};

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

    for (all_opts) |opt| {
        switch (opt) {
            .literal => |name| show_options.name = name,
            .long, .short => if (opt.nameToEnum(ShowOption)) |show_option| switch (show_option) {
                .c, .clip => {
                    show_options.clip = true;
                    show_options.selectedLine = if (opt.value()) |value| try std.fmt.parseInt(u8, value, 10) else 0;
                },
            },
        }
    }

    return show_options;
}

fn commandShow(allocator: std.mem.Allocator, pass_config: PassConfig, opts: std.ArrayList(Opt)) !void {
    var gpg = Gpg.init(allocator, pass_config, false);
    defer gpg.deinit();

    const show_options = try parseShowOpts(opts);

    if (show_options.name) |name| {
        var output = try gpg.decrypt(name);

        if (show_options.clip) {
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

                try clipboard.write(l);
            }
        } else {
            while (output.next()) |l| {
                std.debug.print("{s}\n", .{l});
            }
        }
    }
}
