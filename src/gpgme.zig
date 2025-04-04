const std = @import("std");
const ffi = @import("gpgme_ffi.zig");

const Allocator = std.mem.Allocator;
const GpgError = @import("GpgError.zig");

pub const GpgMe = @This();

context: *ffi.gpgme_ctx_t,
arena: std.heap.ArenaAllocator,

pub fn init(allocator: Allocator) GpgMe {
    _ = ffi.gpgme_check_version(null);

    const context = allocator.create(ffi.gpgme_ctx_t) catch @panic("OOM");
    _ = ffi.gpgme_new(context);

    return .{
        .context = context,
        .arena = std.heap.ArenaAllocator.init(allocator),
    };
}

pub fn deinit(self: GpgMe) void {
    _ = ffi.gpgme_release(self.context.*);
    const allocator = self.arena.child_allocator;
    allocator.destroy(self.context);
    self.arena.deinit();
}

pub fn decrypt(self: *GpgMe, file_path: []const u8) ![]const u8 {
    const arena_allocator = self.arena.allocator();
    const allocator = self.arena.child_allocator;

    const file_path_z = try allocator.dupeZ(u8, file_path);
    defer allocator.free(file_path_z);

    var input: ffi.gpgme_data_t = undefined;
    try GpgError.check(ffi.gpgme_data_new(&input), error.InputDataCreation);
    try GpgError.check(ffi.gpgme_data_set_file_name(input, file_path_z.ptr), error.InputSetFile);
    defer _ = ffi.gpgme_data_release(input);

    var output: ffi.gpgme_data_t = undefined;

    try GpgError.check(ffi.gpgme_data_new(&output), error.OutputDataCreation);
    defer ffi.gpgme_data_release(output);

    try GpgError.check(ffi.gpgme_op_decrypt(self.context.*, input, output), error.DecryptionFailed);

    var result = arena_allocator.alloc(u8, 1024) catch @panic("OOM");

    var result_len: i64 = 0;
    _ = ffi.gpgme_data_seek(output, 0, 0);

    result_len = ffi.gpgme_data_read(output, result.ptr, result.len);

    return result[0..@intCast(result_len)];
}
