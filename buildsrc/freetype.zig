const std = @import("std");

const BuildContext = @import("BuildContext.zig");

pub fn addFreetype(context: *BuildContext) *std.Build.Step.Compile {
    const lib = context.addStaticCLibrary("freetype");

    if (context.target.isWindows()) {
        lib.installHeader(
            "third_party/freetype/include/freetype/config/ftconfig.h",
            "freetype/config/ftconfig.h",
        );
    } else {
        const ftconfig = context.addConfigHeader(.{
            .style = .{ .autoconf = .{ .path = "third_party/freetype/builds/unix/ftconfig.h.in" } },
            .include_path = "freetype/config/ftconfig.h",
        }, .{
            .HAVE_UNISTD_H = {},
            .HAVE_FCNTL_H = {},
        });

        lib.addConfigHeader(ftconfig);
        lib.installConfigHeader(ftconfig, .{});
    }

    const ftmodule = context.addConfigHeader(.{
        .style = .{.cmake = .{.path = "buildsrc/ftmodule.h.in"}},
        .include_path = "freetype/config/ftmodule.h",
    }, .{});

    lib.addConfigHeader(ftmodule);
    lib.installConfigHeader(ftmodule, .{});

    const ftoption = context.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "buildsrc/ftoption.h.in" } },
        .include_path = "freetype/config/ftoption.h",
    }, .{
        .FT_CONFIG_OPTION_ENVIRONMENT_PROPERTIES = null,
        .FT_CONFIG_OPTION_SUBPIXEL_RENDERING = null,
        .FT_CONFIG_OPTION_FORCE_INT64 = null,
        .FT_CONFIG_OPTION_NO_ASSEMBLER = null,
        .FT_CONFIG_OPTION_INLINE_MULFIX = {},
        .FT_CONFIG_OPTION_USE_LZW = null,
        .FT_CONFIG_OPTION_USE_ZLIB = null,
        .FT_CONFIG_OPTION_SYSTEM_ZLIB = null,
        .FT_CONFIG_OPTION_USE_BZIP2 = null,
        .FT_CONFIG_OPTION_DISABLE_STREAM_SUPPORT = {},
        .FT_CONFIG_OPTION_USE_PNG = null,
        .FT_CONFIG_OPTION_USE_HARFBUZZ = null,
        .FT_CONFIG_OPTION_USE_BROTLI = null,
        .FT_CONFIG_OPTION_POSTSCRIPT_NAMES = null,
        .FT_CONFIG_OPTION_ADOBE_GLYPH_LIST = null,
        .FT_CONFIG_OPTION_MAC_FONTS = null,
        .FT_CONFIG_OPTION_GUESSING_EMBEDDED_RFORK = null,
        .FT_CONFIG_OPTION_INCREMENTAL = null,
        .FT_RENDER_POOL_SIZE = 16384,
        .FT_MAX_MODULES = 32,
        .FT_DEBUG_LEVEL_ERROR = context.optimize == .Debug,
        .FT_DEBUG_LEVEL_TRACE = null,
        .FT_DEBUG_LOGGING = null,
        .FT_DEBUG_AUTOFIT = null,
        .FT_DEBUG_MEMORY = null,
        .FT_CONFIG_OPTION_USE_MODULE_ERRORS = null,
        .FT_CONFIG_OPTION_SVG = null,
        .FT_CONFIG_OPTION_ERROR_STRINGS = null,
        .TT_CONFIG_OPTION_EMBEDDED_BITMAPS = null,
        .TT_CONFIG_OPTION_COLOR_LAYERS = {},
        .TT_CONFIG_OPTION_POSTSCRIPT_NAMES = null,
        .TT_CONFIG_OPTION_SFNT_NAMES = null,
        .TT_CONFIG_CMAP_FORMAT_0 = {},
        .TT_CONFIG_CMAP_FORMAT_2 = null,
        .TT_CONFIG_CMAP_FORMAT_4 = {},
        .TT_CONFIG_CMAP_FORMAT_6 = {},
        .TT_CONFIG_CMAP_FORMAT_8 = {},
        .TT_CONFIG_CMAP_FORMAT_10 = {},
        .TT_CONFIG_CMAP_FORMAT_12 = {},
        .TT_CONFIG_CMAP_FORMAT_13 = {},
        .TT_CONFIG_CMAP_FORMAT_14 = {},
        .TT_CONFIG_OPTION_BYTECODE_INTERPRETER = {},
        .TT_CONFIG_OPTION_SUBPIXEL_HINTING = 2,
        .TT_CONFIG_OPTION_COMPONENT_OFFSET_SCALED = null,
        .TT_CONFIG_OPTION_GX_VAR_SUPPORT = {},
        .TT_CONFIG_OPTION_NO_BORING_EXPANSION = null,
        .TT_CONFIG_OPTION_BDF = null,
        .TT_CONFIG_OPTION_MAX_RUNNABLE_OPCODES = 1000000,
        .T1_MAX_DICT_DEPTH = 5,
        .T1_MAX_SUBRS_CALLS = 16,
        .T1_MAX_CHARSTRINGS_OPERANDS = 256,
        .T1_CONFIG_OPTION_NO_AFM = null,
        .T1_CONFIG_OPTION_NO_MM_SUPPORT = null,
        .T1_CONFIG_OPTION_OLD_ENGINE = null,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_X1 = 500,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y1 = 400,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_X2 = 1000,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y2 = 275,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_X3 = 1667,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y3 = 275,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_X4 = 2333,
        .CFF_CONFIG_OPTION_DARKENING_PARAMETER_Y4 = 0,
        .CFF_CONFIG_OPTION_OLD_ENGINE = null,
        .PCF_CONFIG_OPTION_LONG_FAMILY_NAMES = null,
        .AF_CONFIG_OPTION_CJK = {},
        .AF_CONFIG_OPTION_INDIC = {},
        .AF_CONFIG_OPTION_TT_SIZE_METRICS = null,
    });

    lib.addConfigHeader(ftoption);
    lib.installConfigHeader(ftoption, .{});

    lib.addIncludePath("third_party/freetype/include");

    lib.installHeader("third_party/freetype/include/ft2build.h", "ft2build.h");

    for ([_][]const u8{
        "freetype.h",
        "ftadvanc.h",
        "ftbbox.h",
        "ftbdf.h",
        "ftbitmap.h",
        "ftbzip2.h",
        "ftcache.h",
        "ftchapters.h",
        "ftcid.h",
        "ftcolor.h",
        "ftdriver.h",
        "fterrdef.h",
        "fterrors.h",
        "ftfntfmt.h",
        "ftgasp.h",
        "ftglyph.h",
        "ftgxval.h",
        "ftgzip.h",
        "ftimage.h",
        "ftincrem.h",
        "ftlcdfil.h",
        "ftlist.h",
        "ftlogging.h",
        "ftlzw.h",
        "ftmac.h",
        "ftmm.h",
        "ftmodapi.h",
        "ftmoderr.h",
        "ftotval.h",
        "ftoutln.h",
        "ftparams.h",
        "ftpfr.h",
        "ftrender.h",
        "ftsizes.h",
        "ftsnames.h",
        "ftstroke.h",
        "ftsynth.h",
        "ftsystem.h",
        "fttrigon.h",
        "fttypes.h",
        "ftwinfnt.h",
        "otsvg.h",
        "t1tables.h",
        "ttnameid.h",
        "tttables.h",
        "tttags.h",
        "config/ftheader.h",
        "config/ftstdlib.h",
        "config/integer-types.h",
        "config/mac-support.h",
        "config/public-macros.h",
    }) |name| lib.installHeader(
        context.fmt("third_party/freetype/include/freetype/{s}", .{name}),
        context.fmt("freetype/{s}", .{name}),
    );

    lib.addCSourceFiles(&.{
        "third_party/freetype/src/autofit/autofit.c",
        "third_party/freetype/src/base/ftbase.c",
        "third_party/freetype/src/base/ftinit.c",
        "third_party/freetype/src/sfnt/sfnt.c",
        "third_party/freetype/src/smooth/smooth.c",
        "third_party/freetype/src/truetype/truetype.c",
    }, &.{});

    if (context.target.isWindows()) {
        lib.addCSourceFiles(&.{
            "third_party/freetype/builds/windows/ftdebug.c",
            "third_party/freetype/builds/windows/ftsystem.c",
        }, &.{});
    } else {
        lib.addCSourceFiles(&.{
            "third_party/freetype/builds/unix/ftsystem.c",
            "third_party/freetype/src/base/ftdebug.c",
        }, &.{});
    }

    lib.defineCMacro("FT2_BUILD_LIBRARY", null);

    return lib;
}

fn definedIf(condition: bool) ?void {
    return if (condition) {} else null;
}
