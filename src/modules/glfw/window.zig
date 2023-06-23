const std = @import("std");

const common = @import("common");
const Aabb = common.Aabb;
const pointeeCast = common.pointeeCast;

const c = @import("c.zig");
const err = @import("err.zig");
const Monitor = @import("monitor.zig").Monitor;

pub const Window = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.GLFWwindow, self)) {
        return pointeeCast(c.GLFWwindow, self);
    }

    fn defaultWindowHints() !void {
        c.glfwDefaultWindowHints();
        try err.check();
    }

    fn windowHint(hint: c_int, value: c_int) !void {
        c.glfwWindowHint(hint, value);
        try err.check();
    }

    fn windowHintString(hint: c_int, value: [*:0]const u8) !void {
        c.glfwWindowHintString(hint, value);
        try err.check();
    }

    pub const CreateOptions = struct {
        width: c_int,
        height: c_int,
        title: [*:0]const u8,
        monitor: ?*Monitor = null,
        share: ?*Window = null,
        resizable: ?bool = null,
        visible: ?bool = null,
        decorated: ?bool = null,
        focused: ?bool = null,
        auto_iconify: ?bool = null,
        floating: ?bool = null,
        maximized: ?bool = null,
        center_cursor: ?bool = null,
        transparent_framebuffer: ?bool = null,
        focus_on_show: ?bool = null,
        scale_to_monitor: ?bool = null,
        red_bits: ?c_int = null,
        green_bits: ?c_int = null,
        blue_bits: ?c_int = null,
        alpha_bits: ?c_int = null,
        depth_bits: ?c_int = null,
        stencil_bits: ?c_int = null,
        accum_red_bits: ?c_int = null,
        accum_green_bits: ?c_int = null,
        accum_blue_bits: ?c_int = null,
        accum_alpha_bits: ?c_int = null,
        aux_buffers: ?c_int = null,
        stereo: ?bool = null,
        samples: ?c_int = null,
        srgb_capable: ?bool = null,
        doublebuffer: ?bool = null,
        refresh_rate: ?c_int = null,
        client_api: ?ClientApi = null,
        context_creation_api: ?ContextCreationApi = null,
        context_version_major: ?c_int = null,
        context_version_minor: ?c_int = null,
        opengl_forward_compat: ?bool = null,
        opengl_debug_context: ?bool = null,
        opengl_profile: ?OpenGLProfile = null,
        context_robustness: ?ContextRobustness = null,
        context_release_behavior: ?ContextReleaseBehavior = null,
        context_no_error: ?bool = null,
        cocoa_retina_framebuffer: ?bool = null,
        cocoa_frame_name: ?[*:0]const u8 = null,
        cocoa_graphics_switching: ?bool = null,
        x11_class_name: ?[*:0]const u8 = null,
        x11_instance_name: ?[*:0]const u8 = null,

        pub const ClientApi = enum(c_int) {
            none = c.GLFW_NO_API,
            opengl = c.GLFW_OPENGL_API,
            opengl_es = c.GLFW_OPENGL_ES_API,
        };

        pub const ContextCreationApi = enum(c_int) {
            native = c.GLFW_NATIVE_CONTEXT_API,
            egl = c.GLFW_EGL_CONTEXT_API,
            osmesa = c.GLFW_OSMESA_CONTEXT_API,
        };

        pub const OpenGLProfile = enum(c_int) {
            any = c.GLFW_OPENGL_ANY_PROFILE,
            core = c.GLFW_OPENGL_CORE_PROFILE,
            compat = c.GLFW_OPENGL_COMPAT_PROFILE,
        };

        pub const ContextRobustness = enum(c_int) {
            none = c.GLFW_NO_ROBUSTNESS,
            no_reset_notification = c.GLFW_NO_RESET_NOTIFICATION,
            lose_context_on_reset = c.GLFW_LOSE_CONTEXT_ON_RESET,
        };

        pub const ContextReleaseBehavior = enum(c_int) {
            any = c.GLFW_ANY_RELEASE_BEHAVIOR,
            flush = c.GLFW_RELEASE_BEHAVIOR_FLUSH,
            none = c.GLFW_RELEASE_BEHAVIOR_NONE,
        };
    };

    pub fn create(options: CreateOptions) !*Window {
        try defaultWindowHints();

        if (options.focused) |v|
            try windowHint(c.GLFW_FOCUSED, @intFromBool(v));

        if (options.auto_iconify) |v|
            try windowHint(c.GLFW_AUTO_ICONIFY, @intFromBool(v));

        if (options.resizable) |v|
            try windowHint(c.GLFW_RESIZABLE, @intFromBool(v));

        if (options.visible) |v|
            try windowHint(c.GLFW_VISIBLE, @intFromBool(v));

        if (options.decorated) |v|
            try windowHint(c.GLFW_DECORATED, @intFromBool(v));

        if (options.auto_iconify) |v|
            try windowHint(c.GLFW_AUTO_ICONIFY, @intFromBool(v));

        if (options.floating) |v|
            try windowHint(c.GLFW_FLOATING, @intFromBool(v));

        if (options.maximized) |v|
            try windowHint(c.GLFW_MAXIMIZED, @intFromBool(v));

        if (options.center_cursor) |v|
            try windowHint(c.GLFW_CENTER_CURSOR, @intFromBool(v));

        if (options.transparent_framebuffer) |v|
            try windowHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, @intFromBool(v));

        if (options.focus_on_show) |v|
            try windowHint(c.GLFW_FOCUS_ON_SHOW, @intFromBool(v));

        if (options.red_bits) |v|
            try windowHint(c.GLFW_RED_BITS, v);

        if (options.green_bits) |v|
            try windowHint(c.GLFW_GREEN_BITS, v);

        if (options.blue_bits) |v|
            try windowHint(c.GLFW_BLUE_BITS, v);

        if (options.alpha_bits) |v|
            try windowHint(c.GLFW_ALPHA_BITS, v);

        if (options.depth_bits) |v|
            try windowHint(c.GLFW_DEPTH_BITS, v);

        if (options.stencil_bits) |v|
            try windowHint(c.GLFW_STENCIL_BITS, v);

        if (options.accum_red_bits) |v|
            try windowHint(c.GLFW_ACCUM_RED_BITS, v);

        if (options.accum_green_bits) |v|
            try windowHint(c.GLFW_ACCUM_GREEN_BITS, v);

        if (options.accum_blue_bits) |v|
            try windowHint(c.GLFW_ACCUM_BLUE_BITS, v);

        if (options.accum_alpha_bits) |v|
            try windowHint(c.GLFW_ACCUM_ALPHA_BITS, v);

        if (options.aux_buffers) |v|
            try windowHint(c.GLFW_AUX_BUFFERS, v);

        if (options.stereo) |v|
            try windowHint(c.GLFW_STEREO, @intFromBool(v));

        if (options.samples) |v|
            try windowHint(c.GLFW_SAMPLES, v);

        if (options.srgb_capable) |v|
            try windowHint(c.GLFW_SRGB_CAPABLE, @intFromBool(v));

        if (options.refresh_rate) |v|
            try windowHint(c.GLFW_REFRESH_RATE, v);

        if (options.doublebuffer) |v|
            try windowHint(c.GLFW_DOUBLEBUFFER, @intFromBool(v));

        if (options.client_api) |v|
            try windowHint(c.GLFW_CLIENT_API, @intFromEnum(v));

        if (options.context_version_major) |v|
            try windowHint(c.GLFW_CONTEXT_VERSION_MAJOR, v);

        if (options.context_version_minor) |v|
            try windowHint(c.GLFW_CONTEXT_VERSION_MINOR, v);

        if (options.context_robustness) |v|
            try windowHint(c.GLFW_CONTEXT_ROBUSTNESS, @intFromEnum(v));

        if (options.opengl_forward_compat) |v|
            try windowHint(c.GLFW_OPENGL_FORWARD_COMPAT, @intFromBool(v));

        if (options.opengl_debug_context) |v|
            try windowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, @intFromBool(v));

        if (options.opengl_profile) |v|
            try windowHint(c.GLFW_OPENGL_PROFILE, @intFromEnum(v));

        if (options.context_release_behavior) |v|
            try windowHint(c.GLFW_CONTEXT_RELEASE_BEHAVIOR, @intFromEnum(v));

        if (options.context_no_error) |v|
            try windowHint(c.GLFW_CONTEXT_NO_ERROR, @intFromBool(v));

        if (options.context_creation_api) |v|
            try windowHint(c.GLFW_CONTEXT_CREATION_API, @intFromEnum(v));

        if (options.scale_to_monitor) |v|
            try windowHint(c.GLFW_SCALE_TO_MONITOR, @intFromBool(v));

        if (options.cocoa_retina_framebuffer) |v|
            try windowHint(c.GLFW_COCOA_RETINA_FRAMEBUFFER, @intFromBool(v));

        if (options.cocoa_frame_name) |v|
            try windowHintString(c.GLFW_COCOA_FRAME_NAME, v);

        if (options.cocoa_graphics_switching) |v|
            try windowHint(c.GLFW_COCOA_GRAPHICS_SWITCHING, @intFromBool(v));

        if (options.x11_class_name) |v|
            try windowHintString(c.GLFW_X11_CLASS_NAME, v);

        if (options.x11_instance_name) |v|
            try windowHintString(c.GLFW_X11_INSTANCE_NAME, v);

        const window = c.glfwCreateWindow(
            options.width,
            options.height,
            options.title,
            @ptrCast(?*c.GLFWmonitor, options.monitor),
            @ptrCast(?*c.GLFWwindow, options.share),
        );

        try err.check();

        return pointeeCast(Window, window.?);
    }

    pub fn destroy(self: *Window) !void {
        c.glfwDestroyWindow(self.toC());
        try err.check();
    }

    pub fn shouldClose(self: *Window) !bool {
        const result = c.glfwWindowShouldClose(self.toC());
        try err.check();
        return result != c.GLFW_FALSE;
    }

    pub fn setShouldClose(self: *Window, value: bool) !void {
        c.glfwSetWindowShouldClose(self.toC(), @intFromBool(value));
        try err.check();
    }

    pub fn setTitle(self: *Window, value: [*:0]const u8) !void {
        c.glfwSetWindowTitle(self.toC(), value);
        try err.check();
    }

    pub fn setIcon(self: *Window, images: []const c.GLFWimage) !void {
        c.glfwSetWindowIcon(self.toC(), @intCast(c_int, images.len), images.ptr);
        try err.check();
    }

    pub fn getPos(self: *Window) ![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetWindowPos(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn setPos(self: *Window, pos: [2]c_int) !void {
        c.glfwSetWindowPos(self.toC(), pos[0], pos[1]);
        try err.check();
    }

    pub fn getSize(self: *Window) ![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetWindowSize(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn setSizeLimits(self: *Window, limits: Aabb(2, ?c_int)) !void {
        c.glfwSetWindowSizeLimits(
            self.toC(),
            limits.min[0] orelse -1,
            limits.min[1] orelse -1,
            limits.max[0] orelse -1,
            limits.max[1] orelse -1,
        );

        try err.check();
    }

    pub fn setAspectRatio(self: *Window, ratio: ?[2]c_int) !void {
        c.glfwSetWindowAspectRatio(
            self.toC(),
            if (ratio) |r| r[0] else -1,
            if (ratio) |r| r[1] else -1,
        );

        try err.check();
    }

    pub fn setSize(self: *Window, size: [2]c_int) !void {
        c.glfwSetWindowSize(self.toC(), size[0], size[1]);
        try err.check();
    }

    pub fn getFramebufferSize(self: *Window) ![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetFramebufferSize(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getContentScale(self: *Window) ![2]f32 {
        var result: [2]f32 = undefined;
        c.glfwGetWindowContentScale(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getOpacity(self: *Window) !f32 {
        const result = c.glfwGetWindowOpacity(self.toC());
        try err.check();
        return result;
    }

    pub fn setOpacity(self: *Window, opacity: f32) !void {
        c.glfwSetWindowOpacity(self.toC(), opacity);
        try err.check();
    }

    pub fn iconify(self: *Window) !void {
        c.glfwIconifyWindow(self.toC());
        try err.check();
    }

    pub fn restore(self: *Window) !void {
        c.glfwRestoreWindow(self.toC());
        try err.check();
    }

    pub fn maximize(self: *Window) !void {
        c.glfwMaximizeWindow(self.toC());
        try err.check();
    }

    pub fn show(self: *Window) !void {
        c.glfwShowWindow(self.toC());
        try err.check();
    }

    pub fn hide(self: *Window) !void {
        c.glfwHideWindow(self.toC());
        try err.check();
    }

    pub fn focus(self: *Window) !void {
        c.glfwFocusWindow(self.toC());
        try err.check();
    }

    pub fn requestAttention(self: *Window) !void {
        c.glfwRequestWindowAttention(self.toC());
        try err.check();
    }

    pub fn getMonitor(self: *Window) !?*Monitor {
        const result = c.glfwGetWindowMonitor(self.toC());
        try err.check();
        return @ptrCast(?*Monitor, result);
    }

    pub fn setUserPointer(self: *Window, pointer: ?*anyopaque) !void {
        c.glfwSetWindowUserPointer(self.toC(), pointer);
        try err.check();
    }

    pub fn getUserPointer(self: *Window) !?*anyopaque {
        const result = c.glfwGetWindowUserPointer(self.toC());
        try err.check();
        return result;
    }

    pub fn swapBuffers(self: *Window) !void {
        c.glfwSwapBuffers(self.toC());
        try err.check();
    }

    pub fn makeContextCurrent(self: *Window) !void {
        c.glfwMakeContextCurrent(self.toC());
        try err.check();
    }
};

test {
    std.testing.refAllDecls(Window);
}
