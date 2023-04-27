const std = @import("std");

pub const PassConfig = struct {
    home: []const u8,
    prefix: []const u8,
    extensions: []const u8,
    clipTime: []const u8,
    generatedLength: []const u8,
    characterSet: []const u8,
    characterSetNoSymbols: []const u8,
    gpgOpts: []const u8,

    pub fn init(allocator: std.mem.Allocator) !PassConfig {
        const home = getHome();
        const prefix = getPrefix(allocator, home);
        const extensions = getExtensions(allocator, prefix);
        const clip_time = getClipTime();
        const generated_length = getGeneratedLength();
        const character_set = getCharacterSet();
        const character_set_no_symbols = getCharacterSetNoSymbols();
        const gpg_opts = getGpgOpts(allocator);

        return PassConfig{
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

    fn getHome() []const u8 {
        return std.os.getenv("HOME").?;
    }

    fn getPrefix(allocator: std.mem.Allocator, home: []const u8) []const u8 {
        return std.os.getenv("PASSWORD_STORE_DIR") orelse
            std.fmt.allocPrint(allocator, "{s}/.password-store", .{home}) catch unreachable;
    }

    fn getExtensions(allocator: std.mem.Allocator, prefix: []const u8) []const u8 {
        return std.os.getenv("PASSWORD_STORE_EXTENSIONS_DIR") orelse
            std.fmt.allocPrint(allocator, "{s}/.extensions", .{prefix}) catch unreachable;
    }

    fn getClipTime() []const u8 {
        return std.os.getenv("PASSWORD_STORE_CLIP_TIME") orelse "45";
    }

    fn getGeneratedLength() []const u8 {
        return std.os.getenv("PASSWORD_STORE_GENERATED_LENGTH") orelse "25";
    }

    fn getCharacterSet() []const u8 {
        return std.os.getenv("PASSWORD_STORE_CHARACTER_SET") orelse "[:punct:][:alnum:]";
    }

    fn getCharacterSetNoSymbols() []const u8 {
        return std.os.getenv("PASSWORD_STORE_CHARACTER_SET_NO_SYMBOLS") orelse "[:alnum:]";
    }

    fn getGpgOpts(allocator: std.mem.Allocator) []const u8 {
        const customOpts = std.os.getenv("PASSWORD_STORE_GPG_OPTS") orelse "";

        return std.fmt.allocPrint(allocator, "{s} --quiet --yes --compress-algo=none --no-encrypt-to", .{customOpts}) catch unreachable;
    }
};
