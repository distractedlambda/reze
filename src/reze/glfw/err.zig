const std = @import("std");

const c = @import("../c.zig");

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

pub fn check() Error!void {
    var message: ?[*:0]const u8 = undefined;
    const code = c.glfwGetError(&message);
    if (code != c.GLFW_NO_ERROR) return raise(code, message.?);
}

fn raise(code: c_int, message: [*:0]const u8) Error {
    std.log.scoped(.glfw).err("{s}", .{message});
    return switch (code) {
        c.GLFW_NOT_INITIALIZED => error.NotInitialized,
        c.GLFW_NO_CURRENT_CONTEXT => error.NoCurrentContext,
        c.GLFW_INVALID_ENUM => error.InvalidEnum,
        c.GLFW_INVALID_VALUE => error.InvalidValue,
        c.GLFW_OUT_OF_MEMORY => error.OutOfMemory,
        c.GLFW_API_UNAVAILABLE => error.ApiUnavailable,
        c.GLFW_VERSION_UNAVAILABLE => error.VersionUnavailable,
        c.GLFW_PLATFORM_ERROR => error.PlatformError,
        c.GLFW_FORMAT_UNAVAILABLE => error.FormatUnavailable,
        c.GLFW_NO_WINDOW_CONTEXT => error.NoWindowContext,
        else => error.UnknownGlfwError,
    };
}
