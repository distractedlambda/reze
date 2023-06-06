const c = @import("glfw/c.zig");
const err = @import("glfw/err.zig");
const std = @import("std");

pub const AspectRatio = @import("glfw/AspectRatio.zig");
pub const ContentScale = @import("glfw/ContentScale.zig");
pub const Error = err.Error;
pub const FrameSize = @import("glfw/FrameSize.zig");
pub const Image = @import("glfw/Image.zig");
pub const Monitor = @import("glfw/monitor.zig").Monitor;
pub const PhysicalSize = @import("glfw/PhysicalSize.zig");
pub const Pos = @import("glfw/Pos.zig");
pub const Size = @import("glfw/Size.zig");
pub const SizeLimits = @import("glfw/SizeLimits.zig");
pub const Window = @import("glfw/window.zig").Window;
pub const Workarea = @import("glfw/Workarea.zig");

fn initHint(hint: c_int, value: c_int) Error!void {
    c.glfwInitHint(hint, value);
    try err.check();
}

pub const InitOptions = struct {
    joystick_hat_buttons: ?bool = null,
    cocoa_chdir_resources: ?bool = null,
    cocoa_menubar: ?bool = null,
};

pub fn init(options: InitOptions) Error!void {
    if (options.joystick_hat_buttons) |v|
        try initHint(c.GLFW_JOYSTICK_HAT_BUTTONS, @boolToInt(v));

    if (options.cocoa_chdir_resources) |v|
        try initHint(c.GLFW_COCOA_CHDIR_RESOURCES, @boolToInt(v));

    if (options.cocoa_menubar) |v|
        try initHint(c.GLFW_COCOA_MENUBAR, @boolToInt(v));

    switch (c.glfwInit()) {
        c.GLFW_TRUE => {},

        c.GLFW_FALSE => {
            try err.check();
            unreachable;
        },

        else => unreachable,
    }
}

pub const terminate = c.glfwTerminate;
