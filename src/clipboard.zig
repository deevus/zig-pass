const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;

pub fn setClipboardData(allocator: Allocator, data: []const u8) !void {
    switch (builtin.os.tag) {
        .windows => try @import("clipboard_windows.zig").setClipboardData(allocator, data),
        else => return error.UnsupportedPlatform,
    }
}
