const std = @import("std");

const common = @import("common");
const pointeeCast = common.pointeeCast;

const c = @import("c.zig");
const err = @import("err.zig");

pub const Error = err.Error;
pub const Monitor = @import("monitor.zig").Monitor;
pub const Window = @import("window.zig").Window;

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

    if (c.glfwInit() == c.GLFW_FALSE) {
        try err.check();
        unreachable;
    }
}

pub const terminate = c.glfwTerminate;

pub fn pollEvents() Error!void {
    c.glfwPollEvents();
    try err.check();
}

pub fn waitEvents(timeout_s: ?f64) Error!void {
    if (timeout_s) |t| c.glfwWaitEventsTimeout(t) else c.glfwWaitEvents();
    try err.check();
}

pub fn postEmptyEvent() Error!void {
    c.glfwPostEmptyEvent();
    try err.check();
}

pub fn getCurrentContext() Error!?*Window {
    const window = c.glfwGetCurrentContext();
    try err.check();
    return pointeeCast(Window, window);
}

pub fn swapInterval(interval: c_int) Error!void {
    c.glfwSwapInterval(interval);
    try err.check();
}

pub fn extensionSupported(extension: [*:0]const u8) Error!bool {
    const result = c.glfwExtensionSupported(extension);
    try err.check();
    return result != c.GLFW_FALSE;
}

pub fn getProcAddress(procname: [*:0]const u8) Error!?*const anyopaque {
    const result = c.glfwGetProcAddress(procname);
    try err.check();
    return result;
}

pub fn vulkanSupported() Error!bool {
    const result = c.glfwVulkanSupported();
    try err.check();
    return result != c.GLFW_FALSE;
}

pub fn getRequiredInstanceExtensions() Error![]const [*:0]const u8 {
    var count: u32 = undefined;
    const extensions = c.glfwGetRequiredInstanceExtensions(&count);
    try err.check();
    return @ptrCast([*]const [*:0]const u8, extensions)[0..count];
}

pub fn getTime() Error!f64 {
    const result = c.glfwGetTime();
    try err.check();
    return result;
}

pub fn setTime(time_s: f64) Error!void {
    c.glfwSetTime(time_s);
    try err.check();
}

test {
    std.testing.refAllDecls(@This());
}
