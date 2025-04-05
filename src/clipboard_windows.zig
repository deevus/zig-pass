const std = @import("std");
const windows = std.os.windows;
const ffi = @cImport({
    @cInclude("windows.h");
});

const Allocator = std.mem.Allocator;
const LPWSTR = windows.LPWSTR;

pub fn setClipboardData(allocator: Allocator, data: []const u8) !void {
    const g_handle = ffi.GlobalAlloc(ffi.GMEM_MOVEABLE | ffi.GMEM_ZEROINIT, @sizeOf(u16) * data.len);
    {
        defer _ = ffi.GlobalUnlock(g_handle);

        const data_utf16 = try std.unicode.utf8ToUtf16LeAllocZ(allocator, data);
        defer allocator.free(data_utf16);

        const dest: LPWSTR = @alignCast(@ptrCast(ffi.GlobalLock(g_handle)));
        const dest_str = dest[0..data_utf16.len];
        @memcpy(dest_str, data_utf16);
    }

    if (ffi.OpenClipboard(null) == 0) {
        return error.OpenClipboardFailed;
    }
    _ = ffi.EmptyClipboard();
    _ = ffi.SetClipboardData(ffi.CF_UNICODETEXT, g_handle);
    _ = ffi.CloseClipboard();
}
