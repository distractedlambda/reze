const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;

pub const Config = struct {
    target: CrossTarget,
    optimize: OptimizeMode,
    vulkan_loader: ?*Step.Compile,
};

pub fn addGlfw(b: *Build, config: Config) *Step.Compile {
    const use_osmesa = !config.target.isWindows() and b.option(
        bool,
        "glfw_use_osmesa",
        "Use OSMesa for offscreen context creation",
    ) orelse false;

    const use_hybrid_hpg = config.target.isWindows() and b.option(
        bool,
        "glfw_use_hybrid_hpg",
        "Force use of high-performance GPU on hybrid systems",
    ) orelse false;

    const lib = b.addStaticLibrary(.{
        .name = "glfw",
        .target = config.target,
        .optimize = config.optimize,
        .link_libc = true,
    });

    lib.c_std = .C99;

    lib.addIncludePath("third_party/glfw/include");
    lib.installHeadersDirectory("third_party/glfw/include", "");

    lib.defineCMacro("HAVE_MEMFD_CREATE", null); // TODO make this conditional?

    if (config.vulkan_loader) |l| {
        lib.defineCMacro("_GLFW_VULKAN_STATIC", null);
        lib.linkLibrary(l);
    }

    lib.addCSourceFiles(&.{
        "third_party/glfw/src/context.c",
        "third_party/glfw/src/init.c",
        "third_party/glfw/src/input.c",
        "third_party/glfw/src/monitor.c",
        "third_party/glfw/src/vulkan.c",
        "third_party/glfw/src/window.c",
    }, &.{});

    if (use_osmesa) {
        lib.defineCMacro("_GLFW_OSMESA", null);
        lib.linkSystemLibraryPkgConfigOnly("osmesa");
        lib.addCSourceFiles(&.{
            "third_party/glfw/src/null_init.c",
            "third_party/glfw/src/null_joystick.c",
            "third_party/glfw/src/null_monitor.c",
            "third_party/glfw/src/null_window.c",
            "third_party/glfw/src/osmesa_context.c",
            "third_party/glfw/src/posix_thread.c",
            "third_party/glfw/src/posix_time.c",
        }, &.{});
    } else if (config.target.isWindows()) {
        lib.defineCMacro("_GLFW_WIN32", null);
        lib.defineCMacro("UNICODE", null);
        lib.defineCMacro("_UNICODE", null);
        if (use_hybrid_hpg) lib.defineCMacro("_GLFW_USE_HYBRID_HPG", null);
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
    } else if (config.target.isDarwin()) {
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
        lib.linkSystemLibraryPkgConfigOnly("x11");
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
            if (config.target.isLinux())
                "third_party/glfw/src/linux_joystick.c"
            else
                "third_party/glfw/src/null_joystick.c",
        }, &.{});
    }

    return lib;
}
