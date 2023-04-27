const std = @import("std");

const PassConfig = @import("./config.zig").PassConfig;

pub const Git = struct {
    config: PassConfig,
    allocator: std.mem.Allocator,

    pub fn init(config: PassConfig, allocator: std.mem.Allocator) Git {
        return .{
            .config = config,
            .allocator = allocator,
        };
    }

    pub fn execute(self: Git, args: [][]const u8) !std.ChildProcess.ExecResult {
        var git_args = std.ArrayList([]const u8).init(self.allocator);
        defer git_args.deinit();

        try git_args.appendSlice(&.{ "git", "-C", self.config.prefix });
        try git_args.appendSlice(args);

        return try std.ChildProcess.exec(.{
            .argv = git_args.items,
            .allocator = self.allocator,
            .max_output_bytes = 1_000_000,
        });
    }

    pub fn commit(self: Git, message: []const u8) void {
        const message_with_quotes = std.fmt.allocPrint(self.allocator, "\"{s}\"", .{message});
        defer self.allocator.free(message_with_quotes);

        return self.execute(&.{ "commit", "-m", message_with_quotes });
    }

    pub fn addFile(self: Git, file_name: []const u8) void {
        return self.execute(&.{ "add", file_name });
    }
};
