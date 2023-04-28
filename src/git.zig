const std = @import("std");
const utils = @import("./utils.zig");

const PassConfig = @import("./config.zig").PassConfig;
const ExecResult = std.ChildProcess.ExecResult;

pub const Git = struct {
    config: PassConfig,
    allocator: std.mem.Allocator,

    pub fn init(config: PassConfig, allocator: std.mem.Allocator) Git {
        return .{
            .config = config,
            .allocator = allocator,
        };
    }

    pub fn execute(self: Git, args: []const []const u8) !ExecResult {
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

    pub fn commit(self: Git, message: []const u8) !ExecResult {
        const message_with_quotes = try utils.wrapWithDoubleQuotes(self.allocator, message);
        defer self.allocator.free(message_with_quotes);

        return try self.execute(&.{ "commit", "-m", message_with_quotes });
    }

    pub fn addFile(self: Git, file_name: []const u8) !ExecResult {
        return try self.execute(&.{ "add", file_name });
    }

    pub fn setLocalConfig(self: Git, key: []const u8, value: []const u8) !ExecResult {
        return try self.execute(&.{
            "config",
            "--local",
            key,
            value,
        });
    }

    pub fn initRepository(self: Git) !void {
        const textconv = try std.fmt.allocPrint(self.allocator, "\"gpg -d {s}\"", .{self.config.gpgOpts});
        defer self.allocator.free(textconv);

        // TODO: echo '*.gpg diff=gpg' > .gitattributes
        _ = try self.execute(&.{"init"});
        _ = try self.addFile(self.config.prefix);
        _ = try self.commit("Add current contents of password store.");
        _ = try self.setLocalConfig("diff.gpg.binary", "true");
        _ = try self.setLocalConfig("diff.gpg.textconv", textconv);
    }
};
