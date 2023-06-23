const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;

pub const Config = struct {
    target: CrossTarget,
    optimize: OptimizeMode,
};

pub fn addZlib(b: *Build, config: Config) *Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "zlib",
        .target = config.target,
        .optimize = config.optimize,
        .link_libc = true,
    });

    lib.defineCMacro("_LARGEFILE64_SOURCE", "1");

    const zlib_conf = b.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "third_party/zlib/zconf.h.cmakein" } },
        .include_path = "zconf.h",
    }, .{
        .Z_PREFIX = null,
        .Z_HAVE_UNISTD_H = 1,
    });

    lib.addConfigHeader(zlib_conf);
    lib.addIncludePath("third_party/zlib");

    lib.installConfigHeader(zlib_conf, .{});
    lib.installHeader("third_party/zlib/zlib.h", "zlib.h");

    lib.addCSourceFiles(&.{
        "third_party/zlib/adler32.c",
        "third_party/zlib/compress.c",
        "third_party/zlib/crc32.c",
        "third_party/zlib/deflate.c",
        "third_party/zlib/gzclose.c",
        "third_party/zlib/gzlib.c",
        "third_party/zlib/gzread.c",
        "third_party/zlib/gzwrite.c",
        "third_party/zlib/inflate.c",
        "third_party/zlib/infback.c",
        "third_party/zlib/inftrees.c",
        "third_party/zlib/inffast.c",
        "third_party/zlib/trees.c",
        "third_party/zlib/uncompr.c",
        "third_party/zlib/zutil.c",
    }, &.{});

    return lib;
}
