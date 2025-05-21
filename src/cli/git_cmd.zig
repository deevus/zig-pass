const std = @import("std");
const config = @import("../config.zig");
const getopt = @import("../getopt.zig");

const Git = @import("../git.zig").Git;
const Opt = getopt.Opt;
const PassConfig = config.PassConfig;

pub fn execute(allocator: std.mem.Allocator, pass_config: PassConfig, git_opts: []Opt, git_args: [][:0]u8) !void {
    const git = Git.init(allocator, pass_config, true);

    if (git_opts.len > 0) {
        const second_opt: Opt = git_opts[0];

        if (second_opt == .literal and std.mem.eql(u8, second_opt.literal, "init")) {
            _ = try git.initRepository();
        } else {
            _ = try git.execute(git_args);
        }
    } else {
        _ = try git.execute(&.{});
    }
}
