const std = @import("std");

const BuildContext = @import("BuildContext.zig");

pub fn addGlfw(context: *BuildContext) *std.Build.Step.Compile {
    const lib = context.addStaticCLibrary("glfw");

    lib.c_std = .C99;

    lib.addIncludePath("third_party/glfw/include");
    lib.installHeadersDirectory("third_party/glfw/include", "");

    lib.defineCMacro("HAVE_MEMFD_CREATE", null); // TODO make this conditional?

    lib.addCSourceFiles(&.{
        "third_party/glfw/src/context.c",
        "third_party/glfw/src/init.c",
        "third_party/glfw/src/input.c",
        "third_party/glfw/src/monitor.c",
        "third_party/glfw/src/vulkan.c",
        "third_party/glfw/src/window.c",
    }, &.{});

    if (context.target.isWindows()) {
        lib.defineCMacro("_GLFW_WIN32", null);
        lib.defineCMacro("UNICODE", null);
        lib.defineCMacro("_UNICODE", null);
        lib.linkSystemLibrary("gdi32");
        lib.addCSourceFiles(&.{
            "third_party/glfw/src/egl_context.c",
            "third_party/glfw/src/osmesa_context.c",
            "third_party/glfw/src/wgl_context.c",
            "third_party/glfw/src/win32_init.c",
            "third_party/glfw/src/win32_joystick.c",
            "third_party/glfw/src/win32_monitor.c",
            "third_party/glfw/src/win32_thread.c",
            "third_party/glfw/src/win32_time.c",
            "third_party/glfw/src/win32_window.c",
        }, &.{});
    } else if (context.target.isDarwin()) {
        lib.defineCMacro("_GLFW_COCOA", null);
        lib.linkFramework("Cocoa");
        lib.linkFramework("IOKit");
        lib.linkFramework("CoreFoundation");
        lib.addCSourceFiles(&.{
            "third_party/glfw/src/cocoa_init.m",
            "third_party/glfw/src/cocoa_joystick.m",
            "third_party/glfw/src/cocoa_monitor.m",
            "third_party/glfw/src/cocoa_time.c",
            "third_party/glfw/src/cocoa_window.m",
            "third_party/glfw/src/egl_context.c",
            "third_party/glfw/src/nsgl_context.m",
            "third_party/glfw/src/osmesa_context.c",
            "third_party/glfw/src/posix_thread.c",
        }, &.{});
    } else {
        lib.defineCMacro("_GLFW_X11", null);
        lib.linkSystemLibrary("x11");
        lib.addCSourceFiles(&.{
            "third_party/glfw/src/egl_context.c",
            "third_party/glfw/src/glx_context.c",
            "third_party/glfw/src/osmesa_context.c",
            "third_party/glfw/src/posix_thread.c",
            "third_party/glfw/src/posix_time.c",
            "third_party/glfw/src/x11_init.c",
            "third_party/glfw/src/x11_monitor.c",
            "third_party/glfw/src/x11_window.c",
            "third_party/glfw/src/xkb_unicode.c",
            if (context.target.isLinux())
                "third_party/glfw/src/linux_joystick.c"
            else
                "third_party/glfw/src/null_joystick.c",
        }, &.{});
    }

    return lib;
}
