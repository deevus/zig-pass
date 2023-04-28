const std = @import("std");

const Allocator = std.mem.Allocator;

pub fn wrapWithDoubleQuotes(allocator: Allocator, str: []const u8) ![]const u8 {
    return std.fmt.allocPrint(allocator, "\"{s}\"", .{str});
}
