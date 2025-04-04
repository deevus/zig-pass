const std = @import("std");
const utils = @import("./utils.zig");
const GpgMe = @import("gpgme.zig");

const PassConfig = @import("./config.zig").PassConfig;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const String = []const u8;
const RunResult = std.process.Child.RunResult;

pub const Gpg = struct {
    config: PassConfig,
    outputToConsole: bool,
    allocator: Allocator,
    gpgme: GpgMe,

    pub fn init(allocator: Allocator, config: PassConfig, output_to_console: bool) Gpg {
        return Gpg{
            .allocator = allocator,
            .outputToConsole = output_to_console,
            .config = config,
            .gpgme = GpgMe.init(allocator),
        };
    }

    pub fn deinit(self: Gpg) void {
        self.gpgme.deinit();
    }

    pub fn decrypt(self: Gpg, path: String) !std.mem.SplitIterator(u8, .sequence) {
        const absolute_path = try std.fmt.allocPrint(self.allocator, "{s}/{s}.gpg", .{
            self.config.prefix,
            path,
        });
        defer self.allocator.free(absolute_path);

        const result = try self.gpgme.decrypt(absolute_path);

        return std.mem.splitSequence(u8, result, "\n");
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
};
