const std = @import("std");

pub const OptType = enum {
    short,
    long,
    literal,
};

pub const OptValue = struct {
    name: []const u8,
    value: ?[]const u8 = null,
};

pub const Opt = union(OptType) {
    short: OptValue,
    long: OptValue,
    literal: []const u8,

    pub fn isLiteral(self: Opt) bool {
        return self == .literal;
    }

    pub fn isLongOpt(self: Opt) bool {
        return self == .long;
    }

    pub fn isShortOpt(self: Opt) bool {
        return self == .short;
    }

    pub fn nameToEnum(self: Opt, comptime E: type) ?E {
        return switch (self) {
            .short, .long => |v| std.meta.stringToEnum(E, v.name),
            else => null,
        };
    }

    pub fn value(self: Opt) ?[]const u8 {
        return switch (self) {
            .short, .long => |v| v.value,
            else => null,
        };
    }
};

pub fn parseOpts(args: [][:0]u8, allocator: std.mem.Allocator) !std.ArrayList(Opt) {
    var opts = std.ArrayList(Opt).init(allocator);

    for (args[1..args.len]) |arg| {
        try opts.append(parseOpt(arg));
    }

    return opts;
}

pub fn parseOpt(arg: []const u8) Opt {
    if (std.mem.startsWith(u8, arg, "--")) {
        return getLongOpt(arg);
    } else if (std.mem.startsWith(u8, arg, "-")) {
        return getShortOpt(arg);
    } else {
        return getLiteral(arg);
    }
}

fn getOptSegments(opt_type: OptType, data: []const u8) Opt {
    const indexOfEqualsSign = std.mem.indexOf(u8, data, "=");
    const name = data[0 .. indexOfEqualsSign orelse data.len];
    const value: ?[]const u8 = if (indexOfEqualsSign) |i| data[(i + 1)..data.len] else null;

    return switch (opt_type) {
        .long => Opt{ .long = .{
            .name = name,
            .value = value,
        } },
        .short => Opt{ .short = .{
            .name = name,
            .value = value,
        } },
        else => @panic("getOptSegments called with invalid OptType"),
    };
}

fn getLongOpt(arg: []const u8) Opt {
    return getOptSegments(OptType.long, arg[2..]);
}

fn getShortOpt(arg: []const u8) Opt {
    return getOptSegments(OptType.short, arg[1..]);
}

fn getLiteral(arg: []const u8) Opt {
    return Opt{
        .literal = arg,
    };
}
