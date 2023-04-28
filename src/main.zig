const std = @import("std");
const getopt = @import("./getopt.zig");
const config = @import("./config.zig");
const utils = @import("./utils.zig");

const PassConfig = config.PassConfig;
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
            try commandGit(gpa, pass_config, args[2..]);
        }
    }
}

fn commandGit(allocator: std.mem.Allocator, pass_config: PassConfig, git_args: [][]const u8) !void {
    const git = Git.init(pass_config, allocator);

    if (git_args.len > 0) {
        const second_opt: Opt = getopt.parseOpt(git_args[0]);
        if (second_opt.valueEquals("init")) {
            _ = try git.initRepository();
        } else {
            const result = try git.execute(git_args);
            std.debug.print("{s}{s}", .{ result.stderr, result.stdout });
        }
    }
}
