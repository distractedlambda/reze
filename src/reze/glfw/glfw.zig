const std = @import("std");

const err = @import("err.zig");

pub const Error = err.Error;
pub const Image = @import("Image.zig");
pub const Monitor = @import("monitor.zig").Monitor;
pub const Window = @import("window.zig").Window;

extern fn glfwInitHint(hint: c_int, value: c_int) void;

fn initHint(hint: c_int, value: c_int) Error!void {
    glfwInitHint(hint, value);
    try err.check();
}

pub const InitOptions = struct {
    joystick_hat_buttons: ?bool = null,
    cocoa_chdir_resources: ?bool = null,
    cocoa_menubar: ?bool = null,
};

extern fn glfwInit() c_int;

pub fn init(options: InitOptions) Error!void {
    if (options.joystick_hat_buttons) |v|
        try initHint(0x00050001, @boolToInt(v));

    if (options.cocoa_chdir_resources) |v|
        try initHint(0x00051001, @boolToInt(v));

    if (options.cocoa_menubar) |v|
        try initHint(0x00051002, @boolToInt(v));

    if (glfwInit() == 0) {
        try err.check();
        unreachable;
    }
}

extern fn glfwTerminate() void;

pub const terminate = glfwTerminate;

extern fn glfwPollEvents() void;

pub fn pollEvents() Error!void {
    glfwPollEvents();
    try err.check();
}

extern fn glfwWaitEvents() void;

extern fn glfwWaitEventsTimeout(timeout: f64) void;

pub fn waitEvents(timeout_s: ?f64) Error!void {
    if (timeout_s) |t| glfwWaitEventsTimeout(t) else glfwWaitEvents();
    try err.check();
}

extern fn glfwPostEmptyEvent() void;

pub fn postEmptyEvent() Error!void {
    glfwPostEmptyEvent();
    try err.check();
}

extern fn glfwGetCurrentContext() ?*Window;

pub fn getCurrentContext() Error!?*Window {
    const result = glfwGetCurrentContext();
    try err.check();
    return result;
}

extern fn glfwSwapInterval(interval: c_int) void;

pub fn swapInterval(interval: c_int) Error!void {
    glfwSwapInterval(interval);
    try err.check();
}

extern fn glfwExtensionSupported(extension: [*:0]const u8) c_int;

pub fn extensionSupported(extension: [*:0]const u8) Error!bool {
    const result = glfwExtensionSupported(extension);
    try err.check();
    return result != 0;
}

extern fn glfwGetProcAddress(procname: [*:0]const u8) ?*const anyopaque;

pub fn getProcAddress(procname: [*:0]const u8) Error!?*const anyopaque {
    const result = glfwGetProcAddress(procname);
    try err.check();
    return result;
}

extern fn glfwVulkanSupported() c_int;

pub fn vulkanSupported() Error!bool {
    const result = glfwVulkanSupported();
    try err.check();
    return result != 0;
}

extern fn glfwGetRequiredInstanceExtensions(count: *u32) ?[*]const [*:0]const u8;

pub fn getRequiredInstanceExtensions() Error![]const [*:0]const u8 {
    var count: u32 = undefined;
    const extensions = glfwGetRequiredInstanceExtensions(&count);
    try err.check();
    return extensions.?[0..count];
}

extern fn glfwGetTime() f64;

pub fn getTime() Error!f64 {
    const result = glfwGetTime();
    try err.check();
    return result;
}

extern fn glfwSetTime(time: f64) void;

pub fn setTime(time_s: f64) Error!void {
    glfwSetTime(time_s);
    try err.check();
}

test {
    std.testing.refAllDecls(@This());
}
