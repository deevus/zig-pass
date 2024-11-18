const std = @import("std");
const ffi = @import("gpgme_ffi.zig");

const GpgErrorContext = @This();

pub const ErrorSource = enum(c_int) {
    unknown = ffi.GPG_ERR_SOURCE_UNKNOWN,
    gpgme = ffi.GPG_ERR_SOURCE_GPGME,
    gpg = ffi.GPG_ERR_SOURCE_GPG,
    gpgsm = ffi.GPG_ERR_SOURCE_GPGSM,
    gcrypt = ffi.GPG_ERR_SOURCE_GCRYPT,
    gpgAgent = ffi.GPG_ERR_SOURCE_GPGAGENT,
    pinEntry = ffi.GPG_ERR_SOURCE_PINENTRY,
    scd = ffi.GPG_ERR_SOURCE_SCD,
    keyBox = ffi.GPG_ERR_SOURCE_KEYBOX,
    user1 = ffi.GPG_ERR_SOURCE_USER_1,
    user2 = ffi.GPG_ERR_SOURCE_USER_2,
    user3 = ffi.GPG_ERR_SOURCE_USER_3,
    user4 = ffi.GPG_ERR_SOURCE_USER_4,
};

pub const ErrorCode = enum(c_int) {
    noError = ffi.GPG_ERR_NO_ERROR,
    eof = ffi.GPG_ERR_EOF,
    general = ffi.GPG_ERR_GENERAL,
    outOfMemory = ffi.GPG_ERR_ENOMEM,
    invalidValue = ffi.GPG_ERR_INV_VALUE,
    unusablePublicKey = ffi.GPG_ERR_UNUSABLE_PUBKEY,
    unusableSecretKey = ffi.GPG_ERR_UNUSABLE_SECKEY,
    noData = ffi.GPG_ERR_NO_DATA,
    conflict = ffi.GPG_ERR_CONFLICT,
    notImplemented = ffi.GPG_ERR_NOT_IMPLEMENTED,
    decryptFailed = ffi.GPG_ERR_DECRYPT_FAILED,
    badPassphrase = ffi.GPG_ERR_BAD_PASSPHRASE,
    canceled = ffi.GPG_ERR_CANCELED,
    fullyCanceled = ffi.GPG_ERR_FULLY_CANCELED,
    invalidEngine = ffi.GPG_ERR_INV_ENGINE,
    ambiguousName = ffi.GPG_ERR_AMBIGUOUS_NAME,
    wrongKeyUsage = ffi.GPG_ERR_WRONG_KEY_USAGE,
    certificateRevoked = ffi.GPG_ERR_CERT_REVOKED,
    certificateExpired = ffi.GPG_ERR_CERT_EXPIRED,
    noCertificateRevocationList = ffi.GPG_ERR_NO_CRL_KNOWN,
    noPolicyMatch = ffi.GPG_ERR_NO_POLICY_MATCH,
    noSecretKey = ffi.GPG_ERR_NO_SECKEY,
    missingCertificate = ffi.GPG_ERR_MISSING_CERT,
    badCertificateChain = ffi.GPG_ERR_BAD_CERT_CHAIN,
    unsupportedAlgorithm = ffi.GPG_ERR_UNSUPPORTED_ALGORITHM,
    badSignature = ffi.GPG_ERR_BAD_SIGNATURE,
    noPublicKey = ffi.GPG_ERR_NO_PUBKEY,
    user1 = ffi.GPG_ERR_USER_1,
    user2 = ffi.GPG_ERR_USER_2,
    user3 = ffi.GPG_ERR_USER_3,
    user4 = ffi.GPG_ERR_USER_4,
    user5 = ffi.GPG_ERR_USER_5,
    user6 = ffi.GPG_ERR_USER_6,
    user7 = ffi.GPG_ERR_USER_7,
    user8 = ffi.GPG_ERR_USER_8,
    user9 = ffi.GPG_ERR_USER_9,
    user10 = ffi.GPG_ERR_USER_10,
    user11 = ffi.GPG_ERR_USER_11,
    user12 = ffi.GPG_ERR_USER_12,
    user13 = ffi.GPG_ERR_USER_13,
    user14 = ffi.GPG_ERR_USER_14,
    user15 = ffi.GPG_ERR_USER_15,
    user16 = ffi.GPG_ERR_USER_16,
    userIdExists = ffi.GPG_ERR_USER_ID_EXISTS,
    _,
};

handle: ffi.gpgme_error_t,

pub fn init(from: c_uint) GpgErrorContext {
    return .{
        .handle = from,
    };
}

pub fn check(from: c_uint, throw: anytype) !void {
    const err = init(from);

    if (err.isError()) {
        err.dumpDebug();
        return throw;
    }
}

pub fn code(self: GpgErrorContext) ErrorCode {
    return @enumFromInt(ffi.gpgme_err_code(self.handle));
}

pub fn source(self: GpgErrorContext) ErrorSource {
    return @enumFromInt(ffi.gpgme_err_source(self.handle));
}

pub fn message(self: GpgErrorContext) []const u8 {
    const str = ffi.gpgme_strerror(self.handle);

    return str[0..std.mem.len(str)];
}

pub fn isError(self: GpgErrorContext) bool {
    return self.code() != .noError;
}

pub fn isSuccess(self: GpgErrorContext) bool {
    return self.code() == .noError;
}

pub fn dumpDebug(self: GpgErrorContext) void {
    const err_code = self.code();
    const err_source = self.source();
    const err_message = self.message();

    std.debug.print("GPG Error: {d} ({}) - {s}\n", .{ err_code, err_source, err_message });
}
