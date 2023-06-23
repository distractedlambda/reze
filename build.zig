const std = @import("std");

const Build = std.Build;

const BuildContext = @import("buildsrc/BuildContext.zig");

pub fn build(b: *Build) void {
    const context = BuildContext.create(b);

    const pm_common = context.projectModule("common");

    const zlib = @import("buildsrc/zlib.zig").addZlib(b, .{
        .target = context.target,
        .optimize = context.optimize,
    });

    const libpng = @import("buildsrc/libpng.zig").addLibpng(b, .{
        .target = context.target,
        .optimize = context.optimize,
        .zlib = zlib,
    });

    const pm_freetype = context.projectModule("freetype");
    pm_freetype.addMixedModule("common", pm_common);
    pm_freetype.linkLibrary(@import("buildsrc/freetype.zig").addFreetype(b, .{
        .target = context.target,
        .optimize = context.optimize,
        .zlib = zlib,
        .png = libpng,
    }));

    const pm_fontconfig = context.projectModule("fontconfig");
    pm_fontconfig.linkSystemLibrary("fontconfig");
    pm_fontconfig.linkLibC();

    const pm_glfw = context.projectModule("glfw");
    pm_glfw.addMixedModule("common", pm_common);
    pm_glfw.linkLibrary(@import("buildsrc/glfw.zig").addGlfw(b, .{
        .target = context.target,
        .optimize = context.optimize,
        .vulkan_loader = null,
    }));

    const pm_harfbuzz = context.projectModule("harfbuzz");
    pm_harfbuzz.addMixedModule("common", pm_common);
    pm_harfbuzz.linkSystemLibrary("harfbuzz");
    pm_harfbuzz.linkLibC();

    const pm_wasm = context.projectModule("wasm");
    _ = pm_wasm;

    const pm_wasmrt = context.projectModule("wasmrt");
    _ = pm_wasmrt;

    const app_hello_glfw = context.addApp("hello_glfw");
    pm_glfw.addTo(app_hello_glfw, "glfw");

    if (context.target.isDarwin()) {
        const pm_objc = context.projectModule("objc");
        pm_objc.linkSystemLibrary("objc");
    }

    context.addProjectModuleUnitTests();
}
