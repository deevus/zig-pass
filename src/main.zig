const std = @import("std");
const getopt = @import("./getopt.zig");
const config = @import("./config.zig");
const Opt = getopt.Opt;

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const pass_config = try config.PassConfig.init(gpa);

    var first_opt: Opt = getopt.parseOpt(args[1]);
    if (first_opt.isLiteral()) {
        if (first_opt.valueEquals("git")) {
            var git_args = std.ArrayList([]const u8).init(gpa);
            defer git_args.deinit();

            try git_args.append("git");
            try git_args.append("-C");
            try git_args.append(pass_config.prefix);

            for (args[2..]) |arg| {
                try git_args.append(arg);
            }

            var result = try std.ChildProcess.exec(.{
                .argv = git_args.items,
                .allocator = gpa,
            });

            std.debug.print("{s}{s}", .{ result.stdout, result.stderr });
        }
    }
}
