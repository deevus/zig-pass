const std = @import("std");

const OptType = enum {
    ShortOpt,
    LongOpt,
    Literal,
};

const Opt = struct {
    type: OptType,
    name: ?[]const u8,
    value: ?[]const u8,

    pub fn init(t: OptType, name: ?[]const u8, value: ?[]const u8) Opt {
        return Opt{
            .type = t,
            .name = name,
            .value = value,
        };
    }
};

pub fn parseOpts(args: [][]const u8, allocator: std.mem.Allocator) !void {
    var opts = std.ArrayList(Opt).init(allocator);
    defer opts.deinit();

    for (args[1..args.len]) |arg| {
        if (std.mem.startsWith(u8, arg, "--")) {
            try opts.append(getLongOpt(arg));
        } else if (std.mem.startsWith(u8, arg, "-")) {
            try opts.append(getShortOpt(arg));
        } else {
            try opts.append(getLiteral(arg));
        }
    }

    for (opts.items) |opt| {
        std.debug.print("{} ", .{opt.type});
        if (opt.name) |name| std.debug.print("{s} ", .{name});
        if (opt.value) |value| std.debug.print("{s} ", .{value});
        std.debug.print("\n", .{});
    }
}

fn getOptSegments(opt_type: OptType, data: []const u8) Opt {
    const indexOfEqualsSign = std.mem.indexOf(u8, data, "=");
    const name = data[0 .. indexOfEqualsSign orelse data.len];
    const value: ?[]const u8 = if (indexOfEqualsSign) |i| data[(i + 1)..data.len] else null;

    return Opt.init(opt_type, name, value);
}

fn getLongOpt(arg: []const u8) Opt {
    return getOptSegments(OptType.LongOpt, arg[2..]);
}

fn getShortOpt(arg: []const u8) Opt {
    return getOptSegments(OptType.ShortOpt, arg[1..]);
}

fn getLiteral(arg: []const u8) Opt {
    return Opt.init(OptType.Literal, null, arg);
}
