const std = @import("std");

const Build = std.Build;

const BuildContext = @import("buildsrc/BuildContext.zig");

pub fn build(b: *Build) void {
    const context = BuildContext.create(b);

    const config_freetype = @import("buildsrc/freetype.zig").addFreetype(context);

    const config_harfbuzz = @import("buildsrc/harfbuzz.zig").addHarfbuzz(context, config_freetype);

    const pm_common = context.projectModule("common");

    const pm_drm = context.projectModule("drm");

    const pm_freetype = context.projectModule("freetype");
    pm_freetype.dependOn(pm_common);
    pm_freetype.compile_config.include(config_freetype);

    const pm_harfbuzz = context.projectModule("harfbuzz");
    pm_harfbuzz.dependOn(pm_common);
    pm_harfbuzz.compile_config.include(config_harfbuzz);

    const pm_wasm = context.projectModule("wasm");
    _ = pm_wasm;

    const pm_wasmrt = context.projectModule("wasmrt");
    _ = pm_wasmrt;

    const app_hello_drm = context.addApp("hello_drm");
    pm_drm.addTo(app_hello_drm, "drm");

    if (context.target.isDarwin()) {
        const pm_objc = context.projectModule("objc");
        pm_objc.linkSystemLibrary("objc");
    }

    context.addProjectModuleUnitTests();
}
