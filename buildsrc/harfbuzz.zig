const std = @import("std");

const Step = std.build.Step;

const BuildContext = @import("BuildContext.zig");

pub fn addHarfbuzz(context: *BuildContext, lib_freetype: *Step.Compile) *Step.Compile {
    const lib = context.addStaticCppLibrary("harfbuzz");

    lib.linkLibrary(lib_freetype);

    lib.defineCMacro("HB_NO_OT_FONT", null);
    lib.defineCMacro("HB_NO_FALLBACK_SHAPE", null);
    lib.defineCMacro("HB_MINI", null);
    lib.defineCMacro("HB_LEAN", null);
    if (context.single_threaded) {
        lib.defineCMacro("HB_NO_MT", null);
        if (context.optimize == .ReleaseSmall) lib.defineCMacro("HB_TINY", null);
    }

    lib.defineCMacro("HAVE_CONFIG_H", null);

    const config_h = context.builder.addConfigHeader(.{
        .include_path = "config.h",
    }, .{
        .HAVE_GLIB = null,
        .HAVE_GOBJECT = null,
        .HAVE_CAIRO = null,
        .HAVE_CAIRO_USER_FONT_FACE_SET_RENDER_COLOR_GLYPH_FUNC = null,
        .HAVE_CAIRO_FONT_OPTIONS_GET_CUSTOM_PALETTE_COLOR = null,
        .HAVE_CAIRO_USER_SCALED_FONT_GET_FOREGROUND_SOURCE = null,
        .HAVE_CAIRO_FT = null,
        .HAVE_CHAFA = null,
        .HAVE_GRAPHITE2 = null,
        .HAVE_ICU = null,
        .HAVE_ICU_BUILTIN = null,
        .HB_EXPERIMENTAL_API = null,
        .HAVE_FREETYPE = 1,
        .HAVE_FT_GET_VAR_BLEND_COORDINATES = 1,
        .HAVE_FT_SET_VAR_BLEND_COORDINATES = 1,
        .HAVE_FT_DONE_MM_VAR = 1,
        .HAVE_FT_GET_TRANSFORM = 1,
        .HAVE_UNISCRIBE = null,
        .HAVE_GDI = null,
        .HAVE_DIRECTWRITE = null,
        .HAVE_CORETEXT = null,
        .HAVE_PTHREAD = definedIf(!context.target.isWindows() and !context.single_threaded),
        .PACKAGE_NAME = "HardBuzz",
        .PACKAGE_VERSION = "7.3.0",
        .HAVE_UNISTD_H = 1,
        .HAVE_SYS_MMAN_H = definedIf(!context.target.isWindows()),
        .HAVE_STDBOOL_H = 1,
        .HAVE_XLOCALE_H = 1,
        .HAVE_ATEXIT = 1,
        .HAVE_MPROTECT = 1,
        .HAVE_SYSCONF = 1,
        .HAVE_GETPAGESIZE = 1,
        .HAVE_MMAP = 1,
        .HAVE_ISATTY = 1,
        .HAVE_USELOCALE = 1,
        .HAVE_NEWLOCALE = 1,
        .HAVE_SINCOSF = definedIf(!context.target.isDarwin()),
    });

    lib.addConfigHeader(config_h);

    const hb_version_h = context.builder.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "buildsrc/hb-version.h.in" } },
        .include_path = "hb-version.h",
    }, .{
        .HB_VERSION_MAJOR = 7,
        .HB_VERSION_MINOR = 3,
        .HB_VERSION_MICRO = 0,
        .HB_VERSION_STRING = "7.3.0",
    });

    lib.addConfigHeader(hb_version_h);
    lib.installConfigHeader(hb_version_h, .{ .dest_rel_path = "harfbuzz/hb-version.h" });

    const hb_features_h = context.builder.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "buildsrc/hb-features.h.in" } },
        .include_path = "hb-features.h",
    }, .{
        .HB_HAS_CAIRO = null,
        .HB_HAS_CORETEXT = null,
        .HB_HAS_DIRECTWRITE = null,
        .HB_HAS_FREETYPE = {},
        .HB_HAS_GDI = null,
        .HB_HAS_GLIB = null,
        .HB_HAS_GOBJECT = null,
        .HB_HAS_GRAPHITE = null,
        .HB_HAS_ICU = null,
        .HB_HAS_UNISCRIBE = null,
    });

    lib.addConfigHeader(hb_features_h);
    lib.installConfigHeader(hb_features_h, .{ .dest_rel_path = "harfbuzz/hb-features.h" });

    // lib.addIncludePath("third_party/harfbuzz/src");

    for ([_][]const u8{
        "hb-aat-layout.h",
        "hb-aat.h",
        "hb-blob.h",
        "hb-buffer.h",
        "hb-common.h",
        "hb-cplusplus.hh",
        "hb-deprecated.h",
        "hb-draw.h",
        "hb-face.h",
        "hb-font.h",
        "hb-ft.h",
        "hb-map.h",
        "hb-ot-color.h",
        "hb-ot-deprecated.h",
        "hb-ot-font.h",
        "hb-ot-layout.h",
        "hb-ot-math.h",
        "hb-ot-meta.h",
        "hb-ot-metrics.h",
        "hb-ot-name.h",
        "hb-ot-shape.h",
        "hb-ot-var.h",
        "hb-ot.h",
        "hb-paint.h",
        "hb-set.h",
        "hb-shape-plan.h",
        "hb-shape.h",
        "hb-style.h",
        "hb-unicode.h",
        "hb.h",
    }) |name| lib.installHeader(
        context.builder.fmt("third_party/harfbuzz/src/{s}", .{name}),
        context.builder.fmt("harfbuzz/{s}", .{name}),
    );

    lib.addCSourceFiles(&.{
        "third_party/harfbuzz/src/hb-aat-layout.cc",
        "third_party/harfbuzz/src/hb-aat-map.cc",
        "third_party/harfbuzz/src/hb-blob.cc",
        "third_party/harfbuzz/src/hb-buffer-serialize.cc",
        "third_party/harfbuzz/src/hb-buffer-verify.cc",
        "third_party/harfbuzz/src/hb-buffer.cc",
        "third_party/harfbuzz/src/hb-common.cc",
        "third_party/harfbuzz/src/hb-draw.cc",
        "third_party/harfbuzz/src/hb-face-builder.cc",
        "third_party/harfbuzz/src/hb-face.cc",
        "third_party/harfbuzz/src/hb-fallback-shape.cc",
        "third_party/harfbuzz/src/hb-font.cc",
        "third_party/harfbuzz/src/hb-ft.cc",
        "third_party/harfbuzz/src/hb-map.cc",
        "third_party/harfbuzz/src/hb-number.cc",
        "third_party/harfbuzz/src/hb-ot-cff1-table.cc",
        "third_party/harfbuzz/src/hb-ot-cff2-table.cc",
        "third_party/harfbuzz/src/hb-ot-color.cc",
        "third_party/harfbuzz/src/hb-ot-face.cc",
        "third_party/harfbuzz/src/hb-ot-font.cc",
        "third_party/harfbuzz/src/hb-ot-layout.cc",
        "third_party/harfbuzz/src/hb-ot-map.cc",
        "third_party/harfbuzz/src/hb-ot-math.cc",
        "third_party/harfbuzz/src/hb-ot-meta.cc",
        "third_party/harfbuzz/src/hb-ot-metrics.cc",
        "third_party/harfbuzz/src/hb-ot-name.cc",
        "third_party/harfbuzz/src/hb-ot-shape-fallback.cc",
        "third_party/harfbuzz/src/hb-ot-shape-normalize.cc",
        "third_party/harfbuzz/src/hb-ot-shape.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-arabic.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-default.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-hangul.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-hebrew.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-indic-table.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-indic.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-khmer.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-myanmar.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-syllabic.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-thai.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-use.cc",
        "third_party/harfbuzz/src/hb-ot-shaper-vowel-constraints.cc",
        "third_party/harfbuzz/src/hb-ot-tag.cc",
        "third_party/harfbuzz/src/hb-ot-var.cc",
        "third_party/harfbuzz/src/hb-outline.cc",
        "third_party/harfbuzz/src/hb-paint-extents.cc",
        "third_party/harfbuzz/src/hb-paint.cc",
        "third_party/harfbuzz/src/hb-set.cc",
        "third_party/harfbuzz/src/hb-shape-plan.cc",
        "third_party/harfbuzz/src/hb-shape.cc",
        "third_party/harfbuzz/src/hb-shaper.cc",
        "third_party/harfbuzz/src/hb-static.cc",
        "third_party/harfbuzz/src/hb-style.cc",
        "third_party/harfbuzz/src/hb-ucd.cc",
        "third_party/harfbuzz/src/hb-unicode.cc",
    }, &.{
        "-std=c++11",
        "-fno-exceptions",
        "-fno-rtti",
        "-fno-threadsafe-statics",
        "-fvisibility-inlines-hidden",
    });

    return lib;
}

fn definedIf(condition: bool) ?u1 {
    return if (condition) 1 else null;
}
