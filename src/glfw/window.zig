const common = @import("common");

const Aabb = common.Aabb;

const err = @import("err.zig");
const Error = err.Error;
const Image = @import("Image.zig");
const Monitor = @import("monitor.zig").Monitor;

pub const Window = opaque {
    extern fn glfwDefaultWindowHints() void;

    fn defaultWindowHints() Error!void {
        glfwDefaultWindowHints();
        try err.check();
    }

    extern fn glfwWindowHint(hint: c_int, value: c_int) void;

    fn windowHint(hint: c_int, value: c_int) Error!void {
        glfwWindowHint(hint, value);
        try err.check();
    }

    extern fn glfwWindowHintString(hint: c_int, value: [*:0]const u8) void;

    fn windowHintString(hint: c_int, value: [*:0]const u8) Error!void {
        glfwWindowHintString(hint, value);
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
            none = 0,
            opengl = 0x00030001,
            opengl_es = 0x00030002,
        };

        pub const ContextCreationApi = enum(c_int) {
            native = 0x00036001,
            egl = 0x00036002,
            osmesa = 0x00036003,
        };

        pub const OpenGLProfile = enum(c_int) {
            any = 0,
            core = 0x00032001,
            compat = 0x00032002,
        };

        pub const ContextRobustness = enum(c_int) {
            none = 0,
            no_reset_notification = 0x00031001,
            lose_context_on_reset = 0x00031002,
        };

        pub const ContextReleaseBehavior = enum(c_int) {
            any = 0,
            flush = 0x00035001,
            none = 0x00035002,
        };
    };

    extern fn glfwCreateWindow(
        width: c_int,
        height: c_int,
        title: [*:0]const u8,
        monitor: ?*Monitor,
        share: ?*Window,
    ) ?*Window;

    pub fn create(options: CreateOptions) Error!*Window {
        try defaultWindowHints();

        if (options.focused) |v|
            try windowHint(0x00020001, @boolToInt(v));

        if (options.auto_iconify) |v|
            try windowHint(0x00020006, @boolToInt(v));

        if (options.resizable) |v|
            try windowHint(0x00020003, @boolToInt(v));

        if (options.visible) |v|
            try windowHint(0x00020004, @boolToInt(v));

        if (options.decorated) |v|
            try windowHint(0x00020005, @boolToInt(v));

        if (options.auto_iconify) |v|
            try windowHint(0x00020006, @boolToInt(v));

        if (options.floating) |v|
            try windowHint(0x00020007, @boolToInt(v));

        if (options.maximized) |v|
            try windowHint(0x00020008, @boolToInt(v));

        if (options.center_cursor) |v|
            try windowHint(0x00020009, @boolToInt(v));

        if (options.transparent_framebuffer) |v|
            try windowHint(0x0002000A, @boolToInt(v));

        if (options.focus_on_show) |v|
            try windowHint(0x0002000C, @boolToInt(v));

        if (options.red_bits) |v|
            try windowHint(0x00021001, v);

        if (options.green_bits) |v|
            try windowHint(0x00021002, v);

        if (options.blue_bits) |v|
            try windowHint(0x00021003, v);

        if (options.alpha_bits) |v|
            try windowHint(0x00021004, v);

        if (options.depth_bits) |v|
            try windowHint(0x00021005, v);

        if (options.stencil_bits) |v|
            try windowHint(0x00021006, v);

        if (options.accum_red_bits) |v|
            try windowHint(0x00021007, v);

        if (options.accum_green_bits) |v|
            try windowHint(0x00021008, v);

        if (options.accum_blue_bits) |v|
            try windowHint(0x00021009, v);

        if (options.accum_alpha_bits) |v|
            try windowHint(0x0002100A, v);

        if (options.aux_buffers) |v|
            try windowHint(0x0002100B, v);

        if (options.stereo) |v|
            try windowHint(0x0002100C, @boolToInt(v));

        if (options.samples) |v|
            try windowHint(0x0002100D, v);

        if (options.srgb_capable) |v|
            try windowHint(0x0002100E, @boolToInt(v));

        if (options.refresh_rate) |v|
            try windowHint(0x0002100F, v);

        if (options.doublebuffer) |v|
            try windowHint(0x00021010, @boolToInt(v));

        if (options.client_api) |v|
            try windowHint(0x00022001, @enumToInt(v));

        if (options.context_version_major) |v|
            try windowHint(0x00022002, v);

        if (options.context_version_minor) |v|
            try windowHint(0x00022003, v);

        if (options.context_robustness) |v|
            try windowHint(0x00022005, @enumToInt(v));

        if (options.opengl_forward_compat) |v|
            try windowHint(0x00022006, @boolToInt(v));

        if (options.opengl_debug_context) |v|
            try windowHint(0x00022007, @boolToInt(v));

        if (options.opengl_profile) |v|
            try windowHint(0x00022008, @enumToInt(v));

        if (options.context_release_behavior) |v|
            try windowHint(0x00022009, @enumToInt(v));

        if (options.context_no_error) |v|
            try windowHint(0x0002200A, @boolToInt(v));

        if (options.context_creation_api) |v|
            try windowHint(0x0002200B, @enumToInt(v));

        if (options.scale_to_monitor) |v|
            try windowHint(0x0002200C, @boolToInt(v));

        if (options.cocoa_retina_framebuffer) |v|
            try windowHint(0x00023001, @boolToInt(v));

        if (options.cocoa_frame_name) |v|
            try windowHintString(0x00023002, v);

        if (options.cocoa_graphics_switching) |v|
            try windowHint(0x00023003, @boolToInt(v));

        if (options.x11_class_name) |v|
            try windowHintString(0x00024001, v);

        if (options.x11_instance_name) |v|
            try windowHintString(0x00024002, v);

        const glfw_window = glfwCreateWindow(
            options.width,
            options.height,
            options.title,
            options.monitor,
            options.share,
        );

        try err.check();

        return @ptrCast(*Window, glfw_window);
    }

    extern fn glfwDestroyWindow(window: *Window) void;

    pub fn destroy(self: *Window) Error!void {
        glfwDestroyWindow(self);
        try err.check();
    }

    extern fn glfwWindowShouldClose(window: *Window) c_int;

    pub fn shouldClose(self: *Window) Error!bool {
        const result = glfwWindowShouldClose(self);
        try err.check();
        return result != 0;
    }

    extern fn glfwSetWindowShouldClose(window: *Window, value: c_int) void;

    pub fn setShouldClose(self: *Window, value: bool) Error!void {
        glfwSetWindowShouldClose(self, @boolToInt(value));
        try err.check();
    }

    extern fn glfwSetWindowTitle(window: *Window, title: [*:0]const u8) void;

    pub fn setTitle(self: *Window, value: [*:0]const u8) Error!void {
        glfwSetWindowTitle(self, value);
        try err.check();
    }

    extern fn glfwSetWindowIcon(window: *Window, count: c_int, images: [*]const Image) void;

    pub fn setIcon(self: *Window, images: []const Image) Error!void {
        glfwSetWindowIcon(self, @intCast(c_int, images.len), images.ptr);
        try err.check();
    }

    extern fn glfwGetWindowPos(window: *Window, xpos: *c_int, ypos: *c_int) void;

    pub fn getPos(self: *Window) Error![2]c_int {
        var result: [2]c_int = undefined;
        glfwGetWindowPos(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwSetWindowPos(window: *Window, xpos: c_int, ypos: c_int) void;

    pub fn setPos(self: *Window, pos: [2]c_int) Error!void {
        glfwSetWindowPos(self, pos[0], pos[1]);
        try err.check();
    }

    extern fn glfwGetWindowSize(window: *Window, width: *c_int, height: *c_int) void;

    pub fn getSize(self: *Window) Error![2]c_int {
        var result: [2]c_int = undefined;
        glfwGetWindowSize(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwSetWindowSizeLimits(
        window: *Window,
        minwidth: c_int,
        minheight: c_int,
        maxwidth: c_int,
        maxheight: c_int,
    ) void;

    pub fn setSizeLimits(self: *Window, limits: Aabb(2, ?c_int)) Error!void {
        glfwSetWindowSizeLimits(
            self,
            limits.min[0] orelse -1,
            limits.min[1] orelse -1,
            limits.max[0] orelse -1,
            limits.max[1] orelse -1,
        );

        try err.check();
    }

    extern fn glfwSetWindowAspectRatio(window: *Window, numer: c_int, denom: c_int) void;

    pub fn setAspectRatio(self: *Window, ratio: ?[2]c_int) Error!void {
        glfwSetWindowAspectRatio(
            self,
            if (ratio) |r| r[0] else -1,
            if (ratio) |r| r[1] else -1,
        );

        try err.check();
    }

    extern fn glfwSetWindowSize(window: *Window, width: c_int, height: c_int) void;

    pub fn setSize(self: *Window, size: [2]c_int) Error!void {
        glfwSetWindowSize(self, size[0], size[1]);
        try err.check();
    }

    extern fn glfwGetFramebufferSize(window: *Window, width: *c_int, height: *c_int) void;

    pub fn getFramebufferSize(self: *Window) Error![2]c_int {
        var result: [2]c_int = undefined;
        glfwGetFramebufferSize(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwGetWindowContentScale(window: *Window, xscale: *f32, yscale: *f32) void;

    pub fn getContentScale(self: *Window) Error![2]f32 {
        var result: [2]f32 = undefined;
        glfwGetWindowContentScale(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwGetWindowOpacity(window: *Window) f32;

    pub fn getOpacity(self: *Window) Error!f32 {
        const result = glfwGetWindowOpacity(self);
        try err.check();
        return result;
    }

    extern fn glfwSetWindowOpacity(window: *Window, opacity: f32) void;

    pub fn setOpacity(self: *Window, opacity: f32) Error!void {
        glfwSetWindowOpacity(self, opacity);
        try err.check();
    }

    extern fn glfwIconifyWindow(window: *Window) void;

    pub fn iconify(self: *Window) Error!void {
        glfwIconifyWindow(self);
        try err.check();
    }

    extern fn glfwRestoreWindow(window: *Window) void;

    pub fn restore(self: *Window) Error!void {
        glfwRestoreWindow(self);
        try err.check();
    }

    extern fn glfwMaximizeWindow(window: *Window) void;

    pub fn maximize(self: *Window) Error!void {
        glfwMaximizeWindow(self);
        try err.check();
    }

    extern fn glfwShowWindow(window: *Window) void;

    pub fn show(self: *Window) Error!void {
        glfwShowWindow(self);
        try err.check();
    }

    extern fn glfwHideWindow(window: *Window) void;

    pub fn hide(self: *Window) Error!void {
        glfwHideWindow(self);
        try err.check();
    }

    extern fn glfwFocusWindow(window: *Window) void;

    pub fn focus(self: *Window) Error!void {
        glfwFocusWindow(self);
        try err.check();
    }

    extern fn glfwRequestWindowAttention(window: *Window) void;

    pub fn requestAttention(self: *Window) Error!void {
        glfwRequestWindowAttention(self);
        try err.check();
    }

    extern fn glfwGetWindowMonitor(window: *Window) ?*Monitor;

    pub fn getMonitor(self: *Window) Error!?*Monitor {
        const result = glfwGetWindowMonitor(self);
        try err.check();
        return result;
    }

    extern fn glfwSetWindowUserPointer(window: *Window, pointer: ?*anyopaque) void;

    pub fn setUserPointer(self: *Window, pointer: ?*anyopaque) Error!void {
        glfwSetWindowUserPointer(self, pointer);
        try err.check();
    }

    extern fn glfwGetWindowUserPointer(window: *Window) ?*anyopaque;

    pub fn getUserPointer(self: *Window) Error!?*anyopaque {
        const result = glfwGetWindowUserPointer(self);
        try err.check();
        return result;
    }

    extern fn glfwSwapBuffers(window: *Window) void;

    pub fn swapBuffers(self: *Window) Error!void {
        glfwSwapBuffers(self);
        try err.check();
    }

    extern fn glfwMakeContextCurrent(window: *Window) void;

    pub fn makeContextCurrent(self: *Window) Error!void {
        glfwMakeContextCurrent(self);
        try err.check();
    }

    pub const WindowPosFun = *const fn (
        window: *Window,
        xpos: c_int,
        ypos: c_int,
    ) callconv(.C) void;

    extern fn glfwSetWindowPosCallback(window: *Window, callback: ?WindowPosFun) ?WindowPosFun;

    pub fn setPosCallback(self: *Window, callback: ?WindowPosFun) Error!?WindowPosFun {
        const result = glfwSetWindowPosCallback(self, callback);
        try err.check();
        return result;
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
