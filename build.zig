const std = @import("std");

const Build = std.Build;

const BuildContext = @import("buildsrc/BuildContext.zig");

pub fn build(b: *Build) void {
    const context = BuildContext.create(b);

    const pm_common = context.projectModule("common");

    const pm_freetype = context.projectModule("freetype");
    pm_freetype.addMixedModule("common", pm_common);
    pm_freetype.linkSystemLibrary("freetype2");

    const pm_glfw = context.projectModule("glfw");
    pm_glfw.addMixedModule("common", pm_common);
    pm_glfw.linkSystemLibrary("glfw3");

    const pm_wasm = context.projectModule("wasm");
    _ = pm_wasm;

    const pm_wasmrt = context.projectModule("wasmrt");
    _ = pm_wasmrt;

    if (context.target.isDarwin()) {
        const pm_objc = context.projectModule("objc");
        pm_objc.linkSystemLibrary("objc");
    }

    context.addProjectModuleUnitTests();
}
