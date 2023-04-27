const std = @import("std");
const getopt = @import("./getopt.zig");
const config = @import("./config.zig");

const Opt = getopt.Opt;
const Git = @import("./git.zig").Git;

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    const pass_config = try config.PassConfig.init(gpa);
    defer pass_config.deinit();

    const first_opt: Opt = getopt.parseOpt(args[1]);
    if (first_opt.isLiteral()) {
        if (first_opt.valueEquals("git")) {
            const git = Git.init(pass_config, gpa);

            var result = try git.execute(args[2..]);

            std.debug.print("{s}{s}", .{ result.stderr, result.stdout });
        }
    }
}
