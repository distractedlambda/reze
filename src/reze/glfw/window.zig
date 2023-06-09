const c = @import("../c.zig");
const Aabb = @import("../aabb.zig").Aabb;
const Ratio = @import("../ratio.zig").Ratio;

const err = @import("err.zig");
const Error = err.Error;
const Image = @import("Image.zig");
const Monitor = @import("monitor.zig").Monitor;

pub const Window = opaque {
    fn glfwWindow(self: *Window) *c.GLFWwindow {
        return @ptrCast(*c.GLFWwindow, self);
    }

    fn defaultWindowHints() Error!void {
        c.glfwDefaultWindowHints();
        try err.check();
    }

    fn windowHint(hint: c_int, value: c_int) Error!void {
        c.glfwWindowHint(hint, value);
        try err.check();
    }

    fn windowHintString(hint: c_int, value: [*:0]const u8) Error!void {
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

    pub fn create(options: CreateOptions) Error!*Window {
        try defaultWindowHints();

        if (options.focused) |v|
            try windowHint(c.GLFW_FOCUSED, @boolToInt(v));

        if (options.auto_iconify) |v|
            try windowHint(c.GLFW_AUTO_ICONIFY, @boolToInt(v));

        if (options.resizable) |v|
            try windowHint(c.GLFW_RESIZABLE, @boolToInt(v));

        if (options.visible) |v|
            try windowHint(c.GLFW_VISIBLE, @boolToInt(v));

        if (options.decorated) |v|
            try windowHint(c.GLFW_DECORATED, @boolToInt(v));

        if (options.auto_iconify) |v|
            try windowHint(c.GLFW_AUTO_ICONIFY, @boolToInt(v));

        if (options.floating) |v|
            try windowHint(c.GLFW_FLOATING, @boolToInt(v));

        if (options.maximized) |v|
            try windowHint(c.GLFW_MAXIMIZED, @boolToInt(v));

        if (options.center_cursor) |v|
            try windowHint(c.GLFW_CENTER_CURSOR, @boolToInt(v));

        if (options.transparent_framebuffer) |v|
            try windowHint(c.GLFW_TRANSPARENT_FRAMEBUFFER, @boolToInt(v));

        if (options.focus_on_show) |v|
            try windowHint(c.GLFW_FOCUS_ON_SHOW, @boolToInt(v));

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
            try windowHint(c.GLFW_STEREO, @boolToInt(v));

        if (options.samples) |v|
            try windowHint(c.GLFW_SAMPLES, v);

        if (options.srgb_capable) |v|
            try windowHint(c.GLFW_SRGB_CAPABLE, @boolToInt(v));

        if (options.refresh_rate) |v|
            try windowHint(c.GLFW_REFRESH_RATE, v);

        if (options.doublebuffer) |v|
            try windowHint(c.GLFW_DOUBLEBUFFER, @boolToInt(v));

        if (options.client_api) |v|
            try windowHint(c.GLFW_CLIENT_API, @enumToInt(v));

        if (options.context_version_major) |v|
            try windowHint(c.GLFW_CONTEXT_VERSION_MAJOR, v);

        if (options.context_version_minor) |v|
            try windowHint(c.GLFW_CONTEXT_VERSION_MINOR, v);

        if (options.context_robustness) |v|
            try windowHint(c.GLFW_CONTEXT_ROBUSTNESS, @enumToInt(v));

        if (options.opengl_forward_compat) |v|
            try windowHint(c.GLFW_OPENGL_FORWARD_COMPAT, @boolToInt(v));

        if (options.opengl_debug_context) |v|
            try windowHint(c.GLFW_OPENGL_DEBUG_CONTEXT, @boolToInt(v));

        if (options.opengl_profile) |v|
            try windowHint(c.GLFW_OPENGL_PROFILE, @enumToInt(v));

        if (options.context_release_behavior) |v|
            try windowHint(c.GLFW_CONTEXT_RELEASE_BEHAVIOR, @enumToInt(v));

        if (options.context_no_error) |v|
            try windowHint(c.GLFW_CONTEXT_NO_ERROR, @boolToInt(v));

        if (options.context_creation_api) |v|
            try windowHint(c.GLFW_CONTEXT_CREATION_API, @enumToInt(v));

        if (options.scale_to_monitor) |v|
            try windowHint(c.GLFW_SCALE_TO_MONITOR, @boolToInt(v));

        if (options.cocoa_retina_framebuffer) |v|
            try windowHint(c.GLFW_COCOA_RETINA_FRAMEBUFFER, @boolToInt(v));

        if (options.cocoa_frame_name) |v|
            try windowHintString(c.GLFW_COCOA_FRAME_NAME, v);

        if (options.cocoa_graphics_switching) |v|
            try windowHint(c.GLFW_COCOA_GRAPHICS_SWITCHING, @boolToInt(v));

        if (options.x11_class_name) |v|
            try windowHintString(c.GLFW_X11_CLASS_NAME, v);

        if (options.x11_instance_name) |v|
            try windowHintString(c.GLFW_X11_INSTANCE_NAME, v);

        const glfw_window = c.glfwCreateWindow(
            options.width,
            options.height,
            options.title,
            @ptrCast(?*c.GLFWmonitor, options.monitor),
            @ptrCast(?*c.GLFWwindow, options.share),
        );

        try err.check();

        return @ptrCast(*Window, glfw_window);
    }

    pub fn destroy(self: *Window) Error!void {
        c.glfwDestroyWindow(self.glfwWindow());
        try err.check();
    }

    pub fn shouldClose(self: *Window) Error!bool {
        const res = c.glfwWindowShouldClose(self.glfwWindow());
        try err.check();
        return res != c.GLFW_FALSE;
    }

    pub fn setShouldClose(self: *Window, value: bool) Error!void {
        c.glfwSetWindowShouldClose(self.glfwWindow(), @boolToInt(value));
        try err.check();
    }

    pub fn setTitle(self: *Window, value: [*:0]const u8) Error!void {
        c.glfwSetWindowTitle(self.glfwWindow(), value);
        try err.check();
    }

    pub fn setIcon(self: *Window, images: []const Image) Error!void {
        c.glfwSetWindowIcon(
            self.glfwWindow(),
            @intCast(c_int, images.len),
            @ptrCast([*]const c.GLFWimage, images.ptr),
        );

        try err.check();
    }

    pub fn getPos(self: *Window) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetWindowPos(self.glfwWindow(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn setPos(self: *Window, pos: [2]c_int) Error!void {
        c.glfwSetWindowPos(self.glfwWindow(), pos[0], pos[1]);
        try err.check();
    }

    pub fn getSize(self: *Window) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetWindowSize(self.glfwWindow(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn setSizeLimits(self: *Window, limits: Aabb(2, ?c_int)) Error!void {
        c.glfwSetWindowSizeLimits(
            self.glfwWindow(),
            limits.min[0] orelse c.GLFW_DONT_CARE,
            limits.min[1] orelse c.GLFW_DONT_CARE,
            limits.max[0] orelse c.GLFW_DONT_CARE,
            limits.max[1] orelse c.GLFW_DONT_CARE,
        );

        try err.check();
    }

    pub fn setAspectRatio(self: *Window, ratio: ?Ratio(c_int)) Error!void {
        c.glfwSetWindowAspectRatio(
            self.glfwWindow(),
            if (ratio) |r| r.numerator else c.GLFW_DONT_CARE,
            if (ratio) |r| r.denominator else c.GLFW_DONT_CARE,
        );

        try err.check();
    }

    pub fn setSize(self: *Window, size: [2]c_int) Error!void {
        c.glfwSetWindowSize(self.glfwWindow(), size[0], size[1]);
        try err.check();
    }

    pub fn getFramebufferSize(self: *Window) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetFramebufferSize(self.glfwWindow(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getContentScale(self: *Window) Error![2]f32 {
        var result: [2]f32 = undefined;
        c.glfwGetWindowContentScale(self.glfwWindow(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getOpacity(self: *Window) Error!f32 {
        const result = c.glfwGetWindowOpacity(self.glfwWindow());
        try err.check();
        return result;
    }

    pub fn setOpacity(self: *Window, opacity: f32) Error!void {
        c.glfwSetWindowOpacity(self.glfwWindow(), opacity);
        try err.check();
    }

    pub fn iconify(self: *Window) Error!void {
        c.glfwIconifyWindow(self.glfwWindow());
        try err.check();
    }

    pub fn restore(self: *Window) Error!void {
        c.glfwRestoreWindow(self.glfwWindow());
        try err.check();
    }

    pub fn maximize(self: *Window) Error!void {
        c.glfwMaximizeWindow(self.glfwWindow());
        try err.check();
    }

    pub fn show(self: *Window) Error!void {
        c.glfwShowWindow(self.glfwWindow());
        try err.check();
    }

    pub fn hide(self: *Window) Error!void {
        c.glfwHideWindow(self.glfwWindow());
        try err.check();
    }

    pub fn focus(self: *Window) Error!void {
        c.glfwFocusWindow(self.glfwWindow());
        try err.check();
    }

    pub fn requestAttention(self: *Window) Error!void {
        c.glfwRequestWindowAttention(self.glfwWindow());
        try err.check();
    }

    pub fn getMonitor(self: *Window) Error!?*Monitor {
        const result = c.glfwGetWindowMonitor(self.glfwWindow());
        try err.check();
        return @ptrCast(?*Monitor, result);
    }

    pub fn setUserPointer(self: *Window, pointer: ?*anyopaque) Error!void {
        c.glfwSetWindowUserPointer(self.glfwWindow(), pointer);
        try err.check();
    }

    pub fn getUserPointer(self: *Window) Error!?*anyopaque {
        const result = c.glfwGetWindowUserPointer(self.glfwWindow());
        try err.check();
        return result;
    }

    pub fn swapBuffers(self: *Window) Error!void {
        c.glfwSwapBuffers(self.glfwWindow());
        try err.check();
    }

    pub fn makeContextCurrent(self: *Window) Error!void {
        c.glfwMakeContextCurrent(self.glfwWindow());
        try err.check();
    }

    pub fn setPosCallback(
        self: *Window,
        comptime callback: ?fn (window: *Window, pos: [2]c_int) void,
    ) Error!void {
        _ = c.glfwSetWindowPosCallback(
            self.glfwWindow(),
            if (callback) |cbk|
                struct {
                    fn f(window: *c.GFLWwindow, xpos: c_int, ypos: c_int) callconv(.C) void {
                        cbk(@ptrCast(*Window, window), .{ xpos, ypos });
                    }
                }.f
            else
                null,
        );

        try err.check();
    }

    test {
        _ = &create;
        _ = &destroy;
        _ = &focus;
        _ = &getContentScale;
        _ = &getFramebufferSize;
        _ = &getMonitor;
        _ = &getOpacity;
        _ = &getPos;
        _ = &getSize;
        _ = &getUserPointer;
        _ = &hide;
        _ = &iconify;
        _ = &makeContextCurrent;
        _ = &maximize;
        _ = &requestAttention;
        _ = &restore;
        _ = &setAspectRatio;
        _ = &setIcon;
        _ = &setOpacity;
        _ = &setPos;
        _ = &setPosCallback;
        _ = &setShouldClose;
        _ = &setSize;
        _ = &setSizeLimits;
        _ = &setTitle;
        _ = &setUserPointer;
        _ = &shouldClose;
        _ = &show;
        _ = &swapBuffers;
    }
};

test {
    _ = Window;
}
