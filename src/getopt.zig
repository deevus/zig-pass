const std = @import("std");

const OptType = enum {
    ShortOpt,
    LongOpt,
    Literal,
};

const Opt = struct {
    type: OptType,
    name: ?*const []const u8,
    value: ?*const []const u8,

    pub fn init(t: OptType, name: ?*const [] const u8, value: ?*const [] const u8) Opt {
        return Opt {
            .type = t,
            .name = name,
            .value = value,
        };
    }
};

pub fn parseOpts(args: [][] const u8, allocator: std.mem.Allocator) !void {
    var opts = std.ArrayList(Opt).init(allocator);

    for (args[1..]) |arg| {
        std.debug.print("processing arg: {s}\n", .{arg});

        if (std.mem.startsWith(u8, arg, "--")) {
            try opts.append(getLongOpt(arg));
        } else if (std.mem.startsWith(u8, arg, "-")) {
            try opts.append(Opt.init(OptType.ShortOpt, &arg[0..], null));
        } else {
            try opts.append(Opt.init(OptType.Literal, null, &arg[0..]));
        }
    }

    for (opts.items) |opt| {
        std.debug.print("{} ", .{opt.type});
        if (opt.name) |name| std.debug.print("{s} ", .{name.*});
        if (opt.value) |value| std.debug.print("{s} ", .{value.*});
        std.debug.print("\n", .{});
    }

    defer opts.deinit();
}

fn getLongOpt(arg: []const u8) Opt {
    std.debug.print("longopt: {s}", .{arg});
    return Opt.init(OptType.LongOpt, &arg[2..], null);
}