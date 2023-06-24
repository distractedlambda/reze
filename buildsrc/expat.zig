const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;

pub const Config = struct {
    target: CrossTarget,
    optimize: OptimizeMode,
};

pub fn addExpat(b: *Build, config: Config) *Step.Compile {
    const with_libbsd = b.option(
        bool,
        "expat_with_libbsd",
        "Whether to utilize libbsd (for arc4random_buf)",
    ) orelse false;

    const context_bytes = b.option(
        u31,
        "expat_context_bytes",
        "How much context to retain around the current parse point",
    ) orelse 1024;

    const dtd = b.option(
        bool,
        "expat_dtd",
        "Whether to make parameter entity parsing functionality available",
    ) orelse true;

    const ns = b.option(
        bool,
        "expat_ns",
        "Whether to make XML Namespaces functionality available",
    ) orelse true;

    const dev_urandom = b.option(
        bool,
        "expat_dev_urandom",
        "Whether to include code reading entropy from `/dev/urandom'",
    ) orelse switch (config.target.getOs().tag) {
        .freestanding, .windows => false,
        else => true,
    };

    const with_getrandom = b.option(
        bool,
        "expat_with_getrandom",
        "Whether to make use of getrandom function",
    ) orelse true;

    const with_sys_getrandom = b.option(
        bool,
        "expat_with_sys_getrandom",
        "Whether to make use of syscall SYS_getrandom",
    ) orelse true;

    const attr_info = b.option(
        bool,
        "expat_attr_info",
        "Whether to allow retrieving the byte offsets for attribute names and values",
    ) orelse false;

    const large_size = b.option(
        bool,
        "expat_large_size",
        "Whether to make XML_GetCurrent* functions return <(unsigned) long long> rather than <(unsigned) long>",
    ) orelse false;

    const min_size = b.option(
        bool,
        "expat_min_size",
        "Whether to get a smaller (but slower) parser (in particular avoid multiple copies of the tokenizer)",
    ) orelse config.optimize == .MinSizeRelease;

    const lib = b.addStaticLibrary(.{
        .name = "expat",
        .target = config.target,
        .optimize = config.optimize,
        .link_libc = true,
    });

    if (with_libbsd) lib.linkSystemLibrary("bsd");

    if (large_size) lib.defineCMacro("XML_LARGE_SIZE", "");

    if (min_size) lib.defineCMacro("XML_MIN_SIZE", "");

    const expat_config = b.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "third_party/libexpat/expat/expat_config.h.cmake" } },
        .include_path = "expat_config.h",
    }, .{
        .BYTEORDER = @as(i32, switch (config.target.getCpuArch().endian()) {
            .Little => 1234,
            .Big => 4321,
        }),

        .HAVE_ARC4RANDOM = 1,
        .HAVE_ARC4RANDOM_BUF = 1,
        .HAVE_DLFCN_H = 1,
        .HAVE_FCNTL_H = 1,
        .HAVE_GETPAGESIZE = 1,
        .HAVE_GETRANDOM = definedIf(with_getrandom),
        .HAVE_INTTYPES_H = 1,
        .HAVE_LIBBSD = definedIf(with_libbsd),
        .HAVE_MEMORY_H = 1,
        .HAVE_MMAP = 1,
        .HAVE_STDINT_H = 1,
        .HAVE_STDLIB_H = 1,
        .HAVE_STRINGS_H = 1,
        .HAVE_STRING_H = 1,
        .HAVE_SYSCALL_GETRANDOM = definedIf(with_sys_getrandom),
        .HAVE_SYS_STAT_H = 1,
        .HAVE_SYS_TYPES_H = 1,
        .HAVE_UNISTD_H = 1,
        .PACKAGE_BUGREPORT = "expat-bugs@libexpat.org",
        .PACKAGE_NAME = "expat",
        .PACKAGE_STRING = "expat 2.5.0",
        .PACKAGE_TARNAME = "expat",
        .PACKAGE_VERSION = "2.5.0",
        .STDC_HEADERS = 1,
        .WORDS_BIGENDIAN = definedIf(config.target.getCpuArch().endian() == .Big),
        .XML_ATTR_INFO = definedIf(attr_info),
        .XML_CONTEXT_BYTES = context_bytes,
        .XML_DEV_URANDOM = definedIf(dev_urandom),
        .XML_DTD = definedIf(dtd),
        .XML_NS = definedIf(ns),
        .off_t = .off_t,
        .size_t = .size_t,
    });

    lib.addConfigHeader(expat_config);
    lib.installConfigHeader(expat_config, .{});

    lib.addIncludePath("third_party/libexpat/expat/lib");
    lib.installHeader("third_party/libexpat/expat/lib/expat.h", "expat.h");
    lib.installHeader("third_party/libexpat/expat/lib/expat_external.h", "expat_external.h");

    lib.addCSourceFiles(&.{
        "third_party/libexpat/expat/lib/xmlparse.c",
        "third_party/libexpat/expat/lib/xmlrole.c",
        "third_party/libexpat/expat/lib/xmltok.c",
    }, &.{
        "-fno-strict-aliasing",
    });

    return lib;
}

fn definedIf(condition: bool) ?u1 {
    return if (condition) 1 else null;
}
