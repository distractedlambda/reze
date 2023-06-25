const std = @import("std");

const Build = std.Build;

const BuildContext = @import("buildsrc/BuildContext.zig");

pub fn build(b: *Build) void {
    const context = BuildContext.create(b);

    const lib_freetype = @import("buildsrc/freetype.zig").addFreetype(context);
    const lib_harfbuzz = @import("buildsrc/harfbuzz.zig").addHarfbuzz(context, lib_freetype);
    const lib_glfw = @import("buildsrc/glfw.zig").addGlfw(context);
    const lib_drm = @import("buildsrc/libdrm.zig").addLibdrm(context);

    const pm_common = context.projectModule("common");

    const pm_freetype = context.projectModule("freetype");
    pm_freetype.addMixedModule("common", pm_common);
    pm_freetype.linkLibrary(lib_freetype);

    const pm_glfw = context.projectModule("glfw");
    pm_glfw.addMixedModule("common", pm_common);
    pm_glfw.linkLibrary(lib_glfw);

    const pm_harfbuzz = context.projectModule("harfbuzz");
    pm_harfbuzz.addMixedModule("common", pm_common);
    pm_harfbuzz.linkLibrary(lib_harfbuzz);

    const pm_wasm = context.projectModule("wasm");
    _ = pm_wasm;

    const pm_wasmrt = context.projectModule("wasmrt");
    _ = pm_wasmrt;

    const app_hello_glfw = context.addApp("hello_glfw");
    pm_glfw.addTo(app_hello_glfw, "glfw");

    const app_hello_drm = context.addApp("hello_drm");
    app_hello_drm.linkLibrary(lib_drm);

    if (context.target.isDarwin()) {
        const pm_objc = context.projectModule("objc");
        pm_objc.linkSystemLibrary("objc");
    }

    context.addProjectModuleUnitTests();
}
