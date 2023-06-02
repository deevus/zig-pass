const std = @import("std");
const utils = @import("./utils.zig");

const PassConfig = @import("./config.zig").PassConfig;
const ExecResult = std.ChildProcess.ExecResult;

pub const Git = struct {
    config: PassConfig,
    allocator: std.mem.Allocator,
    outputToConsole: bool,

    pub fn init(allocator: std.mem.Allocator, config: PassConfig, output_to_console: bool) Git {
        return .{
            .config = config,
            .allocator = allocator,
            .outputToConsole = output_to_console,
        };
    }

    pub fn execute(self: Git, args: []const []const u8) !ExecResult {
        var git_args = std.ArrayList([]const u8).init(self.allocator);
        defer git_args.deinit();

        try git_args.appendSlice(&.{ "git", "-C", self.config.prefix });
        try git_args.appendSlice(args);

        const result = try std.ChildProcess.exec(.{
            .argv = git_args.items,
            .allocator = self.allocator,
            .max_output_bytes = 1_000_000,
        });

        if (self.outputToConsole) {
            std.debug.print("{s}{s}", .{ result.stdout, result.stderr });
        }

        return result;
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

        const dot_git_dir_path = try std.fmt.allocPrint(self.allocator, "{s}/.git", .{self.config.prefix});
        defer self.allocator.free(dot_git_dir_path);

        const dot_git_dir: std.fs.Dir = try std.fs.openDirAbsolute(dot_git_dir_path, .{});
        const dir_stat = try dot_git_dir.stat();
        if (dir_stat.kind == .directory) {
            std.log.err("Password store is already a git repository", .{});
            return;
        }

        // TODO: echo '*.gpg diff=gpg' > .gitattributes
        _ = try self.execute(&.{"init"});
        _ = try self.addFile(self.config.prefix);
        _ = try self.commit("Add current contents of password store.");
        _ = try self.setLocalConfig("diff.gpg.binary", "true");
        _ = try self.setLocalConfig("diff.gpg.textconv", textconv);
    }
};
