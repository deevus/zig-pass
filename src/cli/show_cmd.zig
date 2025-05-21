const std = @import("std");
const clipboard = @import("clipboard");

const config = @import("../config.zig");
const getopt = @import("../getopt.zig");
const utils = @import("../utils.zig");

const Gpg = @import("../gpg.zig").Gpg;
const Opt = getopt.Opt;
const PassConfig = config.PassConfig;

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

pub fn execute(allocator: std.mem.Allocator, pass_config: PassConfig, opts: std.ArrayList(Opt)) !void {
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
