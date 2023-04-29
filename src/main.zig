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

    const opts = try getopt.parseOpts(args, gpa);

    const first_opt: Opt = opts.items[0];
    if (first_opt.isLiteral()) {
        if (first_opt.valueEquals("git")) {
            try commandGit(gpa, pass_config, opts.items[1..], args[2..]);
        }
    }
}

fn commandGit(allocator: std.mem.Allocator, pass_config: PassConfig, git_opts: []Opt, git_args: [][]const u8) !void {
    const git = Git.init(allocator, pass_config, true);

    if (git_opts.len > 0) {
        const second_opt: Opt = git_opts[0];

        if (second_opt.valueEquals("init")) {
            _ = try git.initRepository();
        } else {
            _ = try git.execute(git_args);
        }
    } else {
        _ = try git.execute(&.{});
    }
}
