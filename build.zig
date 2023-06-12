const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const NativeTargetInfo = std.zig.system.NativeTargetInfo;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;
const Target = std.Target;

const wasm_cpu_model = Target.Cpu.Model{
    .name = "generic",
    .llvm_name = "generic",
    .features = Target.wasm.featureSet(&.{
        .bulk_memory,
        .multivalue,
        .mutable_globals,
        .nontrapping_fptoint,
        .reference_types,
        .sign_ext,
        .simd128,
    }),
};

const wasm_freestanding_target = CrossTarget{
    .cpu_arch = .wasm32,
    .cpu_model = .{ .explicit = &wasm_cpu_model },
    .os_tag = .freestanding,
};

const wasm_wasi_target = CrossTarget{
    .cpu_arch = .wasm32,
    .cpu_model = .{ .explicit = &wasm_cpu_model },
    .os_tag = .wasi,
};

// const Configurator = struct {
//     fn addWasmModule(
//         self: *@This(),
//         name: []const u8,
//         root_source_file: std.Build.FileSource,
//         target: std.zig.CrossTarget,
//         optimize: std.builtin.OptimizeMode,
//     ) *std.Build.Step.Compile {
//         const module = self.build.addSharedLibrary(.{
//             .name = name,
//             .root_source_file = root_source_file,
//             .target = target,
//             .optimize = optimize,
//         });
//
//         module.rdynamic = true;
//
//         return module;
//     }
//
//     fn addFreestandingWasmModule(
//         self: *@This(),
//         name: []const u8,
//         root_source_file: std.Build.FileSource,
//         optimize: std.builtin.OptimizeMode,
//     ) *std.Build.Step.Compile {
//         return self.addWasmModule(name, root_source_file, wasm_freestanding_target, optimize);
//     }
//
//     fn addWasiModule(
//         self: *@This(),
//         name: []const u8,
//         root_source_file: std.Build.FileSource,
//         optimize: std.builtin.OptimizeMode,
//     ) *std.Build.Step.Compile {
//         return self.addWasmModule(name, root_source_file, wasm_wasi_target, optimize);
//     }
//
//     fn configureTestWasmModule(self: *@This(), name: []const u8) void {
//         const root = std.build.FileSource{ .path = self.build.fmt("src/test_modules/{s}.zig", .{name}) };
//         for (std.meta.tags(std.builtin.OptimizeMode)) |mode| {
//             const mode_specific_name = self.build.fmt("{s}-{s}", .{ name, @tagName(mode) });
//             const module = self.addFreestandingWasmModule(mode_specific_name, root, mode);
//             const install_module = self.build.addInstallArtifact(module);
//             install_module.dest_dir = .{ .custom = "test_modules" };
//             self.run_unit_tests.?.step.dependOn(&install_module.step);
//         }
//     }
//
//     fn configureAllTestWasmModules(self: *@This()) void {
//         for (@import("src/test_modules/manifest.zig").module_names) |name| {
//             self.configureTestWasmModule(name);
//         }
//     }
// };

const ThirdPartyLibOption = enum {
    disabled,
    embedded,
    system,
};

const ThirdPartyLibInfo = struct {
    name: []const u8,
    link_name: []const u8,
    configure_embedded: *const fn (*Step.Compile) void,
};

const Configurator = struct {
    build: *Build,
    target: CrossTarget,
    target_info: NativeTargetInfo,
    optimize_mode: OptimizeMode,
    glfw_lib: ?*Step.Compile = null,
    freetype_lib: ?*Step.Compile = null,
    fontconfig_lib: ?*Step.Compile = null,
    expat_lib: ?*Step.Compile = null,

    fn init(b: *Build) @This() {
        const target = b.standardTargetOptions(.{});
        return .{
            .build = b,
            .target = target,
            .target_info = NativeTargetInfo.detect(target) catch @panic("failed to detect target"),
            .optimize_mode = b.standardOptimizeOption(.{}),
        };
    }

    fn createCLib(self: *Configurator, name: []const u8) *Step.Compile {
        return self.build.addStaticLibrary(.{
            .name = name,
            .target = self.target,
            .optimize = self.optimize_mode,
            .link_libc = true,
        });
    }

    fn addGlfw(self: *Configurator) *Step.Compile {
        if (self.glfw_lib) |it| return it;
        const lib = self.createCLib("glfw");
        self.glfw_lib = lib;

        lib.addIncludePath("third_party/glfw/include");

        lib.addCSourceFiles(&.{
            "third_party/glfw/src/context.c",
            "third_party/glfw/src/init.c",
            "third_party/glfw/src/input.c",
            "third_party/glfw/src/monitor.c",
            "third_party/glfw/src/window.c",
            "third_party/glfw/src/vulkan.c",
        }, &.{});

        if (self.target.isWindows()) {
            lib.defineCMacro("_GLFW_WIN32", null);
            lib.linkSystemLibraryName("gdi32");
            lib.addCSourceFiles(&.{
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/wgl_context.c",
                "third_party/glfw/src/win32_init.c",
                "third_party/glfw/src/win32_joystick.c",
                "third_party/glfw/src/win32_monitor.c",
                "third_party/glfw/src/win32_thread.c",
                "third_party/glfw/src/win32_time.c",
                "third_party/glfw/src/win32_window.c",
            }, &.{});
        } else if (self.target.isDarwin()) {
            lib.defineCMacro("_GLFW_COCOA", null);
            lib.linkFramework("Cocoa");
            lib.linkFramework("IOKit");
            lib.linkFramework("CoreFoundation");
            lib.addCSourceFiles(&.{
                "third_party/glfw/src/cocoa_init.m",
                "third_party/glfw/src/cocoa_joystick.m",
                "third_party/glfw/src/cocoa_monitor.m",
                "third_party/glfw/src/cocoa_time.c",
                "third_party/glfw/src/cocoa_window.m",
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/nsgl_context.m",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/posix_thread.c",
            }, &.{});
        } else {
            lib.defineCMacro("_GLFW_X11", null);
            lib.linkSystemLibrary("x11");
            lib.addCSourceFiles(&.{
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/glx_context.c",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/posix_thread.c",
                "third_party/glfw/src/posix_time.c",
                "third_party/glfw/src/x11_init.c",
                "third_party/glfw/src/x11_monitor.c",
                "third_party/glfw/src/x11_window.c",
                "third_party/glfw/src/xkb_unicode.c",
                if (lib.target.isLinux())
                    "third_party/glfw/src/linux_joystick.c"
                else
                    "third_party/glfw/src/null_joystick.c",
            }, &.{});
        }

        return lib;
    }

    fn addFreetype(self: *Configurator) *Step.Compile {
        if (self.freetype_lib) |it| return it;
        const lib = self.createCLib("freetype");
        self.freetype_lib = lib;

        lib.addIncludePath("third_party/freetype/include");

        lib.defineCMacro("FT2_BUILD_LIBRARY", null);

        lib.addCSourceFiles(&.{
            "third_party/freetype/src/autofit/autofit.c",
            "third_party/freetype/src/base/ftbase.c",
            "third_party/freetype/src/base/ftbbox.c",
            "third_party/freetype/src/base/ftbdf.c",
            "third_party/freetype/src/base/ftbitmap.c",
            "third_party/freetype/src/base/ftcid.c",
            "third_party/freetype/src/base/ftdebug.c",
            "third_party/freetype/src/base/ftfstype.c",
            "third_party/freetype/src/base/ftgasp.c",
            "third_party/freetype/src/base/ftglyph.c",
            "third_party/freetype/src/base/ftgxval.c",
            "third_party/freetype/src/base/ftinit.c",
            "third_party/freetype/src/base/ftmac.c",
            "third_party/freetype/src/base/ftmm.c",
            "third_party/freetype/src/base/ftotval.c",
            "third_party/freetype/src/base/ftpatent.c",
            "third_party/freetype/src/base/ftpfr.c",
            "third_party/freetype/src/base/ftstroke.c",
            "third_party/freetype/src/base/ftsynth.c",
            "third_party/freetype/src/base/ftsystem.c",
            "third_party/freetype/src/base/fttype1.c",
            "third_party/freetype/src/base/ftwinfnt.c",
            "third_party/freetype/src/bdf/bdf.c",
            "third_party/freetype/src/bzip2/ftbzip2.c",
            "third_party/freetype/src/cache/ftcache.c",
            "third_party/freetype/src/cff/cff.c",
            "third_party/freetype/src/cid/type1cid.c",
            "third_party/freetype/src/gxvalid/gxvalid.c",
            "third_party/freetype/src/gzip/ftgzip.c",
            "third_party/freetype/src/lzw/ftlzw.c",
            "third_party/freetype/src/otvalid/otvalid.c",
            "third_party/freetype/src/pcf/pcf.c",
            "third_party/freetype/src/pfr/pfr.c",
            "third_party/freetype/src/psaux/psaux.c",
            "third_party/freetype/src/pshinter/pshinter.c",
            "third_party/freetype/src/psnames/psnames.c",
            "third_party/freetype/src/raster/raster.c",
            "third_party/freetype/src/sdf/sdf.c",
            "third_party/freetype/src/sfnt/sfnt.c",
            "third_party/freetype/src/smooth/smooth.c",
            "third_party/freetype/src/truetype/truetype.c",
            "third_party/freetype/src/type1/type1.c",
            "third_party/freetype/src/type42/type42.c",
            "third_party/freetype/src/winfonts/winfnt.c",
        }, &.{});

        return lib;
    }

    fn definedIf(condition: bool) ?u1 {
        return if (condition) 1 else null;
    }

    fn addExpat(self: *Configurator) *Step.Compile {
        // FIXME: do a better job of detecting available things here

        if (self.expat_lib) |it| return it;
        const lib = self.createCLib("expat");
        self.expat_lib = lib;

        const with_libbsd = self.build.option(bool, "expat_with_libbsd", "") orelse
            false;

        const context_bytes = self.build.option(i32, "expat_context_bytes", "") orelse
            1024;

        const dtd = self.build.option(bool, "expat_dtd", "") orelse
            true;

        const ns = self.build.option(bool, "expat_ns", "") orelse
            true;

        const dev_urandom = self.build.option(bool, "expat_dev_urandom", "") orelse
            self.target.isLinux();

        const with_getrandom = self.build.option(bool, "expat_with_getrandom", "") orelse
            dev_urandom;

        const with_sys_getrandom = self.build.option(bool, "expat_with_sys_getrandom", "") orelse
            dev_urandom;

        const attr_info = self.build.option(bool, "expat_attr_info", "") orelse
            false;

        const large_size = self.build.option(bool, "expat_large_size", "") orelse
            false;

        const min_size = self.build.option(bool, "expat_min_size", "") orelse
            false;

        if (with_libbsd) {
            lib.linkSystemLibrary("bsd");
        }

        if (large_size) {
            lib.defineCMacro("XML_LARGE_SIZE", null);
        }

        if (min_size) {
            lib.defineCMacro("XML_MIN_SIZE", null);
        }

        const config_header = self.build.addConfigHeader(.{
            .style = .{
                .cmake = .{
                    .path = "third_party/libexpat/expat/expat_config.h.cmake",
                },
            },

            .include_path = "expat_config.h",
        }, .{
            .BYTEORDER = switch (self.target_info.target.cpu.arch.endian()) {
                .Little => @as(u32, 1234),
                .Big => @as(u32, 4321),
            },

            .HAVE_ARC4RANDOM = self.target.isDarwin(),
            .HAVE_ARC4RANDOM_BUF = self.target.isDarwin(),
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
            .PACKAGE_NAME = "expat",
            .PACKAGE_BUGREPORT = "expat-bugs@libexpat.org",
            .PACKAGE_STRING = "expat 2.5.0",
            .PACKAGE_TARNAME = "expat",
            .PACKAGE_VERSION = "2.5.0",
            .STDC_HEADERS = 1,
            .WORDS_BIGENDIAN = definedIf(self.target_info.target.cpu.arch.endian() == .Big),
            .XML_ATTR_INFO = definedIf(attr_info),
            .XML_CONTEXT_BYTES = context_bytes,
            .XML_DEV_URANDOM = definedIf(dev_urandom),
            .XML_DTD = definedIf(dtd),
            .XML_NS = definedIf(ns),
            .off_t = .off_t,
            .size_t = .size_t,
        });

        lib.addConfigHeader(config_header);
        lib.addIncludePath("third_party/libexpat/expat/lib");

        lib.installConfigHeader(config_header, .{});
        lib.installHeader("third_party/libexpat/expat/lib/expat.h", "expat.h");
        lib.installHeader("third_party/libexpat/expat/lib/expat_external.h", "expat_external.h");

        lib.addCSourceFiles(&.{
            "third_party/libexpat/expat/lib/xmlparse.c",
            "third_party/libexpat/expat/lib/xmlrole.c",
            "third_party/libexpat/expat/lib/xmltok.c",
        }, &.{
            "-fno-strict-aliasing",
            "-fvisibility=hidden",
        });

        return lib;
    }

    fn addFontconfig(self: *Configurator) void {
        if (self.fontconfig_lib) |it| return it;
        const lib = self.createCLib("fontconfig");
        self.fontconfig_lib = lib;

        return lib;
    }

    fn configureBuild(self: *Configurator) void {
        const unit_tests = self.build.addTest(.{
            .root_source_file = .{ .path = "src/reze/reze.zig" },
            .target = self.target,
            .optimize = self.optimize_mode,
        });

        unit_tests.linkLibrary(self.addGlfw());
        unit_tests.linkLibrary(self.addFreetype());
        unit_tests.linkLibrary(self.addExpat());

        const test_step = self.build.step("test", "Run unit tests");
        test_step.dependOn(&self.build.addRunArtifact(unit_tests).step);
    }
};

pub fn build(b: *Build) void {
    var configurator = Configurator.init(b);
    configurator.configureBuild();
}
