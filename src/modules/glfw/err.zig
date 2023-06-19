const common = @import("common");
const std = @import("std");

const c = @import("c.zig");

const translateCError = common.translateCError;

const known_errors = .{
    .{ "GLFW_NOT_INITIALIZED", error.NotInitialized },
    .{ "GLFW_NO_CURRENT_CONTEXT", error.NoCurrentContext },
    .{ "GLFW_INVALID_ENUM", error.InvalidEnum },
    .{ "GLFW_INVALID_VALUE", error.InvalidValue },
    .{ "GLFW_OUT_OF_MEMORY", error.OutOfMemory },
    .{ "GLFW_API_UNAVAILABLE", error.ApiUnavailable },
    .{ "GLFW_VERSION_UNAVAILABLE", error.VersionUnavailable },
    .{ "GLFW_PLATFORM_ERROR", error.PlatformError },
    .{ "GLFW_FORMAT_UNAVAILABLE", error.FormatUnavailable },
    .{ "GLFW_NO_WINDOW_CONTEXT", error.NoWindowContext },
};

pub fn check() !void {
    var message: ?[*:0]const u8 = undefined;
    const code = c.glfwGetError(&message);
    if (code != 0) try raise(code, message.?);
}

fn raise(code: c_int, message: [*:0]const u8) !noreturn {
    std.log.scoped(.glfw).err("{s}", .{message});
    try translateCError(code, c, known_errors);
    return error.UnknownGlfwError;
}
