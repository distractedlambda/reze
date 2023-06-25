const std = @import("std");

const Build = std.Build;
const FileSource = Build.FileSource;
const Step = Build.Step;

const BuildContext = @import("BuildContext.zig");

pub fn addLibdrm(context: *BuildContext) *Step.Compile {
    const lib = context.addStaticCLibrary("drm");

    lib.defineCMacro("_GNU_SOURCE", "");
    lib.defineCMacro("HAVE_LIBDRM_ATOMIC_PRIMITIVES", "1");
    lib.defineCMacro("HAVE_LIB_ATOMIC_OPS", "1");
    lib.defineCMacro("HAVE_SYS_SYSCTL_H", if (context.target.isLinux()) "0" else "1");
    lib.defineCMacro("HAVE_SYS_SELECT_H", "1");
    lib.defineCMacro("HAVE_ALLOCA_H", "1");
    lib.defineCMacro("MAJOR_IN_SYSMACROS", "1");
    // lib.defineCMacro("MAJOR_IN_MKDEV", "1");
    lib.defineCMacro("HAVE_OPEN_MEMSTREAM", "1");
    lib.defineCMacro("HAVE_VISIBILITY", "1");
    lib.defineCMacro("HAVE_EXYNOS", "0");
    lib.defineCMacro("HAVE_FREEDRENO_KGSL", "0");
    lib.defineCMacro("HAVE_INTEL", "0");
    lib.defineCMacro("HAVE_NOUVEAU", "0");
    lib.defineCMacro("HAVE_RADEON", "0");
    lib.defineCMacro("HAVE_VC4", "0");
    lib.defineCMacro("HAVE_VMWGFX", "0");
    lib.defineCMacro("HAVE_CAIRO", "0");
    lib.defineCMacro("HAVE_VALGRIND", "0");

    // Just copying the file, as a workaround for not being able to directly include a generated
    // file
    lib.addConfigHeader(context.addConfigHeader(.{
        .style = .{ .autoconf = genFormatModStaticTable(context) },
        .include_path = "generated_static_table_fourcc.h",
    }, .{}));

    lib.addIncludePath("third_party/libdrm/include/drm");

    for ([_][]const u8{
        "libsync.h",
        "xf86drm.h",
        "xf86drmMode.h",
    }) |name| lib.installHeader(
        context.fmt("third_party/libdrm/{s}", .{name}),
        context.fmt("libdrm/{s}", .{name}),
    );

    for ([_][]const u8{
        "drm.h",
        "drm_fourcc.h",
        "drm_mode.h",
        "drm_sarea.h",
        "i915_drm.h",
        "mach64_drm.h",
        "mga_drm.h",
        "msm_drm.h",
        "nouveau_drm.h",
        "qxl_drm.h",
        "r128_drm.h",
        "radeon_drm.h",
        "amdgpu_drm.h",
        "savage_drm.h",
        "sis_drm.h",
        "tegra_drm.h",
        "vc4_drm.h",
        "via_drm.h",
        "virtgpu_drm.h",
    }) |name| lib.installHeader(
        context.fmt("third_party/libdrm/include/drm/{s}", .{name}),
        context.fmt("libdrm/{s}", .{name}),
    );

    lib.addCSourceFiles(&.{
        "third_party/libdrm/xf86drm.c",
        "third_party/libdrm/xf86drmHash.c",
        "third_party/libdrm/xf86drmMode.c",
        "third_party/libdrm/xf86drmRandom.c",
        "third_party/libdrm/xf86drmSL.c",
    }, &.{});

    return lib;
}

fn genFormatModStaticTable(context: *BuildContext) FileSource {
    const python = context.python_program orelse @panic("Python is required to build libdrm");
    const cmd = context.builder.addSystemCommand(&.{python});
    cmd.addFileSourceArg(.{ .path = "third_party/libdrm/gen_table_fourcc.py" });
    cmd.addFileSourceArg(.{ .path = "third_party/libdrm/include/drm/drm_fourcc.h" });
    return cmd.addOutputFileArg("generated_static_table_fourcc.h");
}