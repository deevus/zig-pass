const std = @import("std");
const builtin = @import("builtin");

pub const PassConfig = struct {
    allocator: std.mem.Allocator,
    home: []const u8,
    prefix: []const u8,
    extensions: []const u8,
    clipTime: []const u8,
    generatedLength: []const u8,
    characterSet: []const u8,
    characterSetNoSymbols: []const u8,
    gpgOpts: []const u8,

    pub fn init(allocator: std.mem.Allocator) !PassConfig {
        const home = try getHome(allocator);
        const prefix = try getPrefix(allocator, home);
        const extensions = try getExtensions(allocator, prefix);
        const clip_time = try getClipTime(allocator);
        const generated_length = try getGeneratedLength(allocator);
        const character_set = try getCharacterSet(allocator);
        const character_set_no_symbols = try getCharacterSetNoSymbols(allocator);
        const gpg_opts = try getGpgOpts(allocator);

        return PassConfig{
            .allocator = allocator,
            .home = home,
            .prefix = prefix,
            .extensions = extensions,
            .clipTime = clip_time,
            .generatedLength = generated_length,
            .characterSet = character_set,
            .characterSetNoSymbols = character_set_no_symbols,
            .gpgOpts = gpg_opts,
        };
    }

    pub fn deinit(self: PassConfig) void {
        const allocator = self.allocator;
        allocator.free(self.home);
        allocator.free(self.prefix);
        allocator.free(self.extensions);
        allocator.free(self.clipTime);
        allocator.free(self.generatedLength);
        allocator.free(self.characterSet);
        allocator.free(self.characterSetNoSymbols);
        allocator.free(self.gpgOpts);
    }

    fn getHome(allocator: std.mem.Allocator) ![]const u8 {
        return switch (builtin.os.tag) {
            .windows => std.process.getEnvVarOwned(allocator, "USERPROFILE") catch unreachable,
            else => std.process.getEnvVarOwned(allocator, "HOME") catch unreachable,
        };
    }

    fn getPrefix(allocator: std.mem.Allocator, home: []const u8) ![]const u8 {
        return std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_DIR") catch {
            return try std.fmt.allocPrint(allocator, "{s}/.password-store", .{home});
        };
    }

    fn getExtensions(allocator: std.mem.Allocator, prefix: []const u8) ![]const u8 {
        return std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_EXTENSIONS_DIR") catch {
            return try std.fmt.allocPrint(allocator, "{s}/.extensions", .{prefix});
        };
    }

    fn getClipTime(allocator: std.mem.Allocator) ![]const u8 {
        return std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_CLIP_TIME") catch {
            return try allocator.dupe(u8, "45");
        };
    }

    fn getGeneratedLength(allocator: std.mem.Allocator) ![]const u8 {
        return std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_GENERATED_LENGTH") catch {
            return try allocator.dupe(u8, "25");
        };
    }

    fn getCharacterSet(allocator: std.mem.Allocator) ![]const u8 {
        return std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_CHARACTER_SET") catch {
            return try allocator.dupe(u8, "[:punct:][:alnum:]");
        };
    }

    fn getCharacterSetNoSymbols(allocator: std.mem.Allocator) ![]const u8 {
        return std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_CHARACTER_SET_NO_SYMBOLS") catch {
            return try allocator.dupe(u8, "[:alnum:]");
        };
    }

    fn getGpgOpts(allocator: std.mem.Allocator) ![]const u8 {
        const customOpts = std.process.getEnvVarOwned(allocator, "PASSWORD_STORE_GPG_OPTS") catch "";

        return try std.fmt.allocPrint(allocator, "{s} --quiet --yes --compress-algo=none --no-encrypt-to", .{customOpts});
    }
};