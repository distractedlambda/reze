const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;

pub const Config = struct {
    target: CrossTarget,
    optimize: OptimizeMode,
    zlib: ?*Step.Compile = null,
    bzip2: ?*Step.Compile = null,
    png: ?*Step.Compile = null,
    harfbuzz: ?*Step.Compile = null,
    brotli: ?*Step.Compile = null,
};

pub fn addFreetype(b: *Build, config: Config) *Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "freetype",
        .target = config.target,
        .optimize = config.optimize,
        .link_libc = true,
    });

    if (config.zlib) |l| lib.linkLibrary(l);
    if (config.bzip2) |l| lib.linkLibrary(l);
    if (config.png) |l| lib.linkLibrary(l);
    if (config.harfbuzz) |l| lib.linkLibrary(l);
    if (config.brotli) |l| lib.linkLibrary(l);

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
        "config/ftmodule.h",
        "config/ftstdlib.h",
        "config/integer-types.h",
        "config/mac-support.h",
        "config/public-macros.h",
    }) |name| lib.installHeader(
        b.fmt("third_party/freetype/include/freetype/{s}", .{name}),
        b.fmt("freetype2/freetype/{s}", .{name}),
    );

    const ftconfig = b.addConfigHeader(.{
        .style = .{ .autoconf = .{ .path = "third_party/freetype/builds/unix/ftconfig.h.in" } },
        .include_path = "freetype/config/ftconfig.h",
    }, .{
        .HAVE_UNISTD_H = {},
        .HAVE_FCNTL_H = {},
    });

    lib.addConfigHeader(ftconfig);
    lib.installConfigHeader(
        ftconfig,
        .{ .dest_rel_path = "freetype2/freetype/config/ftconfig.h" },
    );

    const ftoption = b.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "buildsrc/ftoption.h.in" } },
        .include_path = "freetype/config/ftoption.h",
    }, .{
        .FT_CONFIG_OPTION_USE_LZW = definedIf(config.zlib != null),
        .FT_CONFIG_OPTION_USE_ZLIB = definedIf(config.zlib != null),
        .FT_CONFIG_OPTION_USE_BZIP2 = definedIf(config.bzip2 != null),
        .FT_CONFIG_OPTION_USE_PNG = definedIf(config.png != null),
        .FT_CONFIG_OPTION_USE_HARFBUZZ = definedIf(config.harfbuzz != null),
        .FT_CONFIG_OPTION_USE_BROTLI = definedIf(config.brotli != null),
    });

    lib.addConfigHeader(ftoption);
    lib.installConfigHeader(
        ftoption,
        .{ .dest_rel_path = "freetype2/freetype/config/ftoption.h" },
    );

    lib.addCSourceFiles(&.{
        "third_party/freetype/src/autofit/autofit.c",
        "third_party/freetype/src/base/ftbase.c",
        "third_party/freetype/src/base/ftbbox.c",
        "third_party/freetype/src/base/ftbdf.c",
        "third_party/freetype/src/base/ftbitmap.c",
        "third_party/freetype/src/base/ftcid.c",
        "third_party/freetype/src/base/ftfstype.c",
        "third_party/freetype/src/base/ftgasp.c",
        "third_party/freetype/src/base/ftglyph.c",
        "third_party/freetype/src/base/ftgxval.c",
        "third_party/freetype/src/base/ftinit.c",
        "third_party/freetype/src/base/ftmm.c",
        "third_party/freetype/src/base/ftotval.c",
        "third_party/freetype/src/base/ftpatent.c",
        "third_party/freetype/src/base/ftpfr.c",
        "third_party/freetype/src/base/ftstroke.c",
        "third_party/freetype/src/base/ftsynth.c",
        "third_party/freetype/src/base/fttype1.c",
        "third_party/freetype/src/base/ftwinfnt.c",
        "third_party/freetype/src/bdf/bdf.c",
        "third_party/freetype/src/bzip2/ftbzip2.c",
        "third_party/freetype/src/cache/ftcache.c",
        "third_party/freetype/src/cff/cff.c",
        "third_party/freetype/src/cid/type1cid.c",
        "third_party/freetype/src/gzip/ftgzip.c",
        "third_party/freetype/src/lzw/ftlzw.c",
        "third_party/freetype/src/pcf/pcf.c",
        "third_party/freetype/src/pfr/pfr.c",
        "third_party/freetype/src/psaux/psaux.c",
        "third_party/freetype/src/pshinter/pshinter.c",
        "third_party/freetype/src/psnames/psnames.c",
        "third_party/freetype/src/raster/raster.c",
        "third_party/freetype/src/sdf/sdf.c",
        "third_party/freetype/src/sfnt/sfnt.c",
        "third_party/freetype/src/smooth/smooth.c",
        "third_party/freetype/src/svg/svg.c",
        "third_party/freetype/src/truetype/truetype.c",
        "third_party/freetype/src/type1/type1.c",
        "third_party/freetype/src/type42/type42.c",
        "third_party/freetype/src/winfonts/winfnt.c",
    }, &.{});

    lib.addCSourceFiles(&.{
        "third_party/freetype/builds/unix/ftsystem.c",
        "third_party/freetype/src/base/ftdebug.c",
    }, &.{});

    lib.defineCMacro("FT2_BUILD_LIBRARY", null);

    return lib;
}

fn definedIf(condition: bool) ?void {
    return if (condition) {} else null;
}
