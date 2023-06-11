const std = @import("std");

pub const Error = error{
    NotInitialized,
    NoCurrentContext,
    InvalidEnum,
    InvalidValue,
    OutOfMemory,
    ApiUnavailable,
    VersionUnavailable,
    PlatformError,
    FormatUnavailable,
    NoWindowContext,
    UnknownGlfwError,
};

extern fn glfwGetError(description: ?*?[*:0]const u8) c_int;

pub fn check() Error!void {
    var message: ?[*:0]const u8 = undefined;
    const code = glfwGetError(&message);
    if (code != 0) return raise(code, message.?);
}

fn raise(code: c_int, message: [*:0]const u8) Error {
    std.log.scoped(.glfw).err("{s}", .{message});
    return switch (code) {
        0x00010001 => error.NotInitialized,
        0x00010002 => error.NoCurrentContext,
        0x00010003 => error.InvalidEnum,
        0x00010004 => error.InvalidValue,
        0x00010005 => error.OutOfMemory,
        0x00010006 => error.ApiUnavailable,
        0x00010007 => error.VersionUnavailable,
        0x00010008 => error.PlatformError,
        0x00010009 => error.FormatUnavailable,
        0x0001000A => error.NoWindowContext,
        else => error.UnknownGlfwError,
    };
}
