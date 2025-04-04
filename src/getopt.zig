const std = @import("std");

pub const OptType = enum {
    ShortOpt,
    LongOpt,
    Literal,
};

pub const Opt = struct {
    type: OptType,
    name: ?[]const u8,
    value: ?[]const u8,
    raw: []const u8,

    pub fn init(t: OptType, name: ?[]const u8, value: ?[]const u8, raw: []const u8) Opt {
        return Opt{
            .type = t,
            .name = name,
            .value = value,
            .raw = raw,
        };
    }

    pub fn isLiteral(self: Opt) bool {
        return self.type == OptType.Literal;
    }

    pub fn isLongOpt(self: Opt) bool {
        return self.type == OptType.LongOpt;
    }

    pub fn isShortOpt(self: Opt) bool {
        return self.type == OptType.ShortOpt;
    }

    pub fn valueEquals(self: Opt, value: []const u8) bool {
        return std.mem.eql(u8, value, self.value.?);
    }

    pub fn nameEquals(self: Opt, name: []const u8) bool {
        return std.mem.eql(u8, name, self.name.?);
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

    return Opt.init(opt_type, name, value, data);
}

fn getLongOpt(arg: []const u8) Opt {
    return getOptSegments(OptType.LongOpt, arg[2..]);
}

fn getShortOpt(arg: []const u8) Opt {
    return getOptSegments(OptType.ShortOpt, arg[1..]);
}

fn getLiteral(arg: []const u8) Opt {
    return Opt.init(OptType.Literal, null, arg, arg);
}
