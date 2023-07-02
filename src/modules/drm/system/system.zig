const builtin = @import("builtin");
const std = @import("std");

comptime {
    if (builtin.os.tag != .linux) {
        @compileError("TODO add support for non-Linux targets");
    }
}

pub usingnamespace @import("types.zig");

pub const ioctls = @import("ioctls.zig");

pub fn ioctl(fd: std.os.fd_t, request: u32, arg: ?*anyopaque) !void {
    while (true) {
        // FIXME: is the ioctl signature wrong in std.c?
        // FIXME: `request` type differs between musl and glibc
        const rc = std.os.linux.ioctl(fd, request, @intFromPtr(arg));
        return switch (std.os.errno(rc)) {
            .SUCCESS => {},
            .INTR, .AGAIN => continue,
            .BADF => unreachable,
            .FAULT => unreachable,
            .ACCES => error.PermissionDenied,
            .INVAL => error.InvalidArgument,
            .NOTTY => error.InappropriateRequest,
            .OPNOTSUPP => error.NotSupported,
            else => |e| std.os.unexpectedErrno(e),
        };
    }
}
