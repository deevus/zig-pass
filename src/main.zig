const std = @import("std");
const builtin = @import("builtin");
const getopt = @import("./getopt.zig");
const config = @import("./config.zig");
const utils = @import("./utils.zig");
const clipboard = @import("clipboard");

const show_cmd = @import("cli/show_cmd.zig");
const git_cmd = @import("cli/git_cmd.zig");

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
                .git => try git_cmd.execute(allocator, pass_config, opts.items[1..], args[2..]),
                .show => try show_cmd.execute(allocator, pass_config, opts),
            } else {
                try show_cmd.execute(allocator, pass_config, opts);
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
