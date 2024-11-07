const std = @import("std");
const utils = @import("./utils.zig");

const PassConfig = @import("./config.zig").PassConfig;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const String = []const u8;
const RunResult = std.process.Child.RunResult;

pub const Gpg = struct {
    config: PassConfig,
    outputToConsole: bool,
    allocator: Allocator,

    pub fn init(allocator: Allocator, config: PassConfig, output_to_console: bool) Gpg {
        return Gpg{
            .allocator = allocator,
            .outputToConsole = output_to_console,
            .config = config,
        };
    }

    pub fn decrypt(self: Gpg, path: String) !std.mem.SplitIterator(u8, .sequence) {
        const path_with_extension = try std.mem.join(self.allocator, ".", &.{
            path,
            "gpg",
        });
        defer self.allocator.free(path_with_extension);

        const absolute_path = try std.fs.path.join(self.allocator, &.{
            self.config.prefix,
            path_with_extension,
        });
        defer self.allocator.free(absolute_path);

        var args = ArrayList([]const u8).init(self.allocator);
        defer args.deinit();

        if (self.config.gpgId) |gpg_id| {
            try args.appendSlice(&.{
                "--default-key",
                gpg_id,
            });
        }

        var gpg_opts = std.mem.split(u8, self.config.gpgOpts, " ");
        while (gpg_opts.next()) |opt| {
            if (opt.len > 0) try args.append(opt);
        }

        try args.appendSlice(&.{
            "--decrypt",
            absolute_path,
        });

        const result = try self.execute(self.allocator, args.items);
        defer self.allocator.free(result.stderr);

        // TODO: handle freeing of result.stdout

        if (result.stdout.len == 0) {
            defer self.allocator.free(result.stdout);

            return error.InvalidOutput;
        }

        return std.mem.split(u8, result.stdout, "\n");
    }

    pub fn encrypt(self: Gpg, data: String, output_file: String, overwrite: bool, recipients: []String) void {
        _ = recipients;
        _ = overwrite;
        _ = output_file;
        _ = data;
        _ = self;
    }

    pub fn getRecipients(self: Gpg, allocator: Allocator, file_name: String) ArrayList(String) {
        _ = allocator;
        _ = file_name;
        _ = self;
    }

    pub fn findShortKeyId(self: Gpg, target: String) ?String {
        _ = target;
        _ = self;
    }

    pub fn sign(self: Gpg, message: String, key_id: String) []String {
        _ = key_id;
        _ = message;
        _ = self;
    }

    pub fn execute(self: Gpg, allocator: Allocator, extra_args: []const String) !RunResult {
        var args = ArrayList(String).init(allocator);
        defer args.deinit();

        try args.append("gpg");
        try args.appendSlice(if (extra_args.len > 0) extra_args else &.{"--help"});

        const result = try std.process.Child.run(.{
            .argv = args.items,
            .allocator = allocator,
        });

        if (self.outputToConsole) {
            std.debug.print("{s}{s}", .{ result.stdout, result.stderr });
        }

        return result;
    }
};
