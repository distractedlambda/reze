const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const Module = Build.Module;
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

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize_mode = b.standardOptimizeOption(.{});

    _ = b.step("test", "Run all unit tests");

    const embedded_glfw = NativeDependency.createEmbeddedLibrary(b, EmbeddedGlfw{});

    const embedded_freetype = NativeDependency.createEmbeddedLibrary(b, EmbeddedFreetype{});

    const embedded_expat = NativeDependency.createEmbeddedLibrary(b, EmbeddedExpat{
        .xml_context_bytes = b.option(i32, "expat_context_bytes", "") orelse 1024,
        .xml_dtd = b.option(bool, "expat_dtd", "") orelse true,
        .xml_ns = b.option(bool, "expat_ns", "") orelse true,
        .xml_attr_info = b.option(bool, "expat_attr_info", "") orelse false,
        .xml_large_size = b.option(bool, "expat_large_size", "") orelse false,
        .xml_min_size = b.option(bool, "expat_min_size", "") orelse false,
    });

    const common_module = ZigModule.create(b, "common");
    common_module.registerUnitTests(target, optimize_mode);

    const wasmrt_module = ZigModule.create(b, "wasmrt");
    wasmrt_module.registerUnitTests(target, optimize_mode);

    const glfw_module = ZigModule.create(b, "glfw");
    glfw_module.addNativeDependency(embedded_glfw);
    glfw_module.addZigDependency(common_module);
    glfw_module.registerUnitTests(target, optimize_mode);

    const freetype_module = ZigModule.create(b, "freetype");
    freetype_module.addNativeDependency(embedded_freetype);
    freetype_module.addZigDependency(common_module);
    freetype_module.registerUnitTests(target, optimize_mode);

    const objc_module = ZigModule.create(b, "objc");
    objc_module.addNativeDependency(NativeDependency.createSystemFramework(b, "objc"));
    if (target.isDarwin()) objc_module.registerUnitTests(target, optimize_mode);

    const wasm_module = ZigModule.create(b, "wasm");
    wasm_module.registerUnitTests(target, optimize_mode);

    _ = embedded_expat;
}

const NativeDependency = struct {
    owner: *Build,
    apply_fn: *const fn (*NativeDependency, *Step.Compile) void,

    fn apply(self: *@This(), step: *Step.Compile) void {
        (self.apply_fn)(self, step);
    }

    fn create(owner: *Build, impl: anytype) *@This() {
        const Wrapper = struct {
            native_dependency: NativeDependency,
            impl: @TypeOf(impl),

            fn applyImpl(super: *NativeDependency, compile_step: *Step.Compile) void {
                const self = @fieldParentPtr(@This(), "native_dependency", super);
                self.impl.apply(super.owner, compile_step);
            }
        };

        const wrapper = owner.allocator.create(Wrapper) catch @panic("OOM");

        wrapper.* = .{
            .native_dependency = .{
                .owner = owner,
                .apply_fn = Wrapper.applyImpl,
            },

            .impl = impl,
        };

        return &wrapper.native_dependency;
    }

    fn createSystemLibrary(owner: *Build, name: []const u8) *@This() {
        return create(owner, struct {
            name: []const u8,

            fn apply(self: *@This(), _: *Build, step: *Step.Compile) void {
                step.linkSystemLibrary(self.name);
            }
        }{
            .name = name,
        });
    }

    fn createSystemFramework(owner: *Build, name: []const u8) *@This() {
        return create(owner, struct {
            name: []const u8,

            fn apply(self: *@This(), _: *Build, step: *Step.Compile) void {
                step.linkFramework(self.name);
            }
        }{
            .name = name,
        });
    }

    fn createEmbeddedLibrary(owner: *Build, impl: anytype) *@This() {
        return create(owner, struct {
            impl: @TypeOf(impl),

            instances: std.AutoHashMapUnmanaged(
                struct { CrossTarget, OptimizeMode },
                EmbeddedLibraryInstance,
            ) = .{},

            fn apply(self: *@This(), b: *Build, step: *Step.Compile) void {
                const slot = self.instances.getOrPut(
                    b.allocator,
                    .{ step.target, step.optimize },
                ) catch @panic("OOM");

                if (!slot.found_existing) {
                    slot.value_ptr.* = .{ .lib = b.addStaticLibrary(.{
                        .name = if (@hasField(@TypeOf(impl), "name"))
                            impl.name
                        else
                            @TypeOf(impl).name,

                        .target = step.target,
                        .optimize = step.optimize,
                        .link_libc = true,
                    }) };

                    self.impl.configure(slot.value_ptr);
                }

                step.linkLibrary(slot.value_ptr.lib);
                for (slot.value_ptr.public_include_paths.items) |it| step.addIncludePath(it);
                for (slot.value_ptr.public_config_headers.items) |it| step.addConfigHeader(it);
                for (slot.value_ptr.public_c_macros.items) |it| step.defineCMacro(it[0], it[1]);
            }
        }{
            .impl = impl,
        });
    }
};

const EmbeddedLibraryInstance = struct {
    lib: *Step.Compile,
    public_include_paths: std.ArrayListUnmanaged([]const u8) = .{},
    public_config_headers: std.ArrayListUnmanaged(*Step.ConfigHeader) = .{},
    public_c_macros: std.ArrayListUnmanaged(struct { []const u8, ?[]const u8 }) = .{},

    fn allocator(self: *const @This()) std.mem.Allocator {
        return self.lib.step.owner.allocator;
    }

    fn addPublicIncludePath(self: *@This(), path: []const u8) void {
        self.lib.addIncludePath(path);
        self.public_include_paths.append(self.allocator(), path) catch @panic("OOM");
    }

    fn addPublicConfigHeader(
        self: *@This(),
        options: Build.ConfigHeaderStep.Options,
        values: anytype,
    ) void {
        const step = self.lib.step.owner.addConfigHeader(options, values);
        self.lib.addConfigHeader(step);
        self.public_config_headers.append(self.allocator(), step) catch @panic("OOM");
    }

    fn addPublicCMacro(self: *@This(), name: []const u8, value: ?[]const u8) void {
        self.lib.defineCMacro(name, value);
        self.public_c_macros.append(self.allocator(), .{ name, value }) catch @panic("OOM");
    }
};

const EmbeddedGlfw = struct {
    const name = "glfw";

    fn configure(_: *@This(), instance: *EmbeddedLibraryInstance) void {
        instance.addPublicIncludePath("third_party/glfw/include");

        instance.lib.addCSourceFiles(&.{
            "third_party/glfw/src/context.c",
            "third_party/glfw/src/init.c",
            "third_party/glfw/src/input.c",
            "third_party/glfw/src/monitor.c",
            "third_party/glfw/src/window.c",
            "third_party/glfw/src/vulkan.c",
        }, &.{});

        if (instance.lib.target.isWindows()) {
            instance.lib.defineCMacro("_GLFW_WIN32", null);
            instance.lib.linkSystemLibraryName("gdi32");
            instance.lib.addCSourceFiles(&.{
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
        } else if (instance.lib.target.isDarwin()) {
            instance.lib.defineCMacro("_GLFW_COCOA", null);
            instance.lib.linkFramework("Cocoa");
            instance.lib.linkFramework("IOKit");
            instance.lib.linkFramework("CoreFoundation");
            instance.lib.addCSourceFiles(&.{
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
            instance.lib.defineCMacro("_GLFW_X11", null);
            instance.lib.linkSystemLibrary("x11");
            instance.lib.addCSourceFiles(&.{
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/glx_context.c",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/posix_thread.c",
                "third_party/glfw/src/posix_time.c",
                "third_party/glfw/src/x11_init.c",
                "third_party/glfw/src/x11_monitor.c",
                "third_party/glfw/src/x11_window.c",
                "third_party/glfw/src/xkb_unicode.c",
                if (instance.lib.target.isLinux())
                    "third_party/glfw/src/linux_joystick.c"
                else
                    "third_party/glfw/src/null_joystick.c",
            }, &.{});
        }
    }
};

const EmbeddedFreetype = struct {
    const name = "freetype";

    fn configure(_: *@This(), instance: *EmbeddedLibraryInstance) void {
        instance.addPublicIncludePath("third_party/freetype/include");

        instance.lib.defineCMacro("FT2_BUILD_LIBRARY", null);

        instance.lib.addCSourceFiles(&.{
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
    }
};

const EmbeddedExpat = struct {
    const name = "expat";

    xml_context_bytes: i32,
    xml_dtd: bool,
    xml_ns: bool,
    xml_attr_info: bool,
    xml_large_size: bool,
    xml_min_size: bool,

    fn configure(self: *@This(), instance: *EmbeddedLibraryInstance) void {
        if (self.xml_large_size) {
            instance.lib.defineCMacro("XML_LARGE_SIZE", null);
        }

        if (self.xml_min_size) {
            instance.lib.defineCMacro("XML_MIN_SIZE", null);
        }

        instance.addPublicConfigHeader(.{
            .style = .{ .cmake = .{ .path = "third_party/libexpat/expat/expat_config.h.cmake" } },
            .include_path = "expat_config.h",
        }, .{
            .PACKAGE_NAME = "expat",
            .PACKAGE_VERSION = "2.5.0",
            .PACKAGE_TARNAME = "expat",
            .PACKAGE_STRING = "expat 2.5.0",
            .PACKAGE_BUGREPORT = "expat-bugs@libexpat.org",

            .XML_ATTR_INFO = definedIf(self.xml_attr_info),
            .XML_CONTEXT_BYTES = self.xml_context_bytes,
            .XML_DEV_URANDOM = definedIf(instance.lib.target.isLinux()),
            .XML_DTD = definedIf(self.xml_dtd),
            .XML_NS = definedIf(self.xml_ns),

            .HAVE_LIBBSD = null,

            .HAVE_ARC4RANDOM = definedIf(instance.lib.target.getOsTag().isBSD()),
            .HAVE_ARC4RANDOM_BUF = definedIf(instance.lib.target.getOsTag().isBSD()),

            .HAVE_GETRANDOM = definedIf(instance.lib.target.isLinux()),
            .HAVE_SYSCALL_GETRANDOM = definedIf(instance.lib.target.isLinux()),

            .HAVE_MMAP = 1,
            .HAVE_GETPAGESIZE = 1,

            .HAVE_DLFCN_H = 1,
            .HAVE_FCNTL_H = 1,
            .HAVE_INTTYPES_H = 1,
            .HAVE_MEMORY_H = 1,
            .HAVE_STDINT_H = 1,
            .HAVE_STDLIB_H = 1,
            .HAVE_STRING_H = 1,
            .HAVE_STRINGS_H = 1,
            .HAVE_SYS_STAT_H = 1,
            .HAVE_SYS_TYPES_H = 1,
            .HAVE_UNISTD_H = 1,
            .STDC_HEADERS = 1,

            .BYTEORDER = @as(u32, switch (instance.lib.target.getCpuArch().endian()) {
                .Little => 1234,
                .Big => 4321,
            }),

            .WORDS_BIGENDIAN = definedIf(instance.lib.target.getCpuArch().endian() == .Big),

            .off_t = .off_t,
            .size_t = .size_t,
        });

        instance.addPublicIncludePath("third_party/libexpat/expat/lib");

        instance.lib.addCSourceFiles(&.{
            "third_party/libexpat/expat/lib/xmlparse.c",
            "third_party/libexpat/expat/lib/xmlrole.c",
            "third_party/libexpat/expat/lib/xmltok.c",
        }, &.{
            "-fno-strict-aliasing",
            "-fvisibility=hidden",
        });
    }
};

const ZigModule = struct {
    name: []const u8,
    module: *Build.Module,
    native_dependencies: std.ArrayListUnmanaged(*NativeDependency) = .{},

    fn create(owner: *Build, name: []const u8) *@This() {
        const zig_module = owner.allocator.create(@This()) catch @panic("OOM");

        zig_module.* = .{
            .name = name,
            .module = owner.addModule(name, .{ .source_file = .{
                .path = owner.fmt("src/{s}/{s}.zig", .{ name, name }),
            } }),
        };

        return zig_module;
    }

    fn addNativeDependency(self: *@This(), dep: *NativeDependency) void {
        self.native_dependencies.append(self.module.builder.allocator, dep) catch @panic("OOM");
    }

    fn addZigDependency(self: *@This(), dep: *@This()) void {
        self.module.dependencies.put(dep.name, dep.module) catch @panic("OOM");

        self.native_dependencies.appendSlice(
            self.module.builder.allocator,
            dep.native_dependencies.items,
        ) catch @panic("OOM");
    }

    fn registerUnitTests(self: *@This(), target: CrossTarget, optimize: OptimizeMode) void {
        const b = self.module.builder;

        const tests_name = b.fmt("test_{s}", .{self.name});

        const tests = b.addTest(.{
            .name = tests_name,
            .root_source_file = .{ .path = self.module.source_file.path },
            .target = target,
            .optimize = optimize,
        });

        for (self.native_dependencies.items) |d| d.apply(tests);

        const run_tests = b.addRunArtifact(tests);

        b.step(tests_name, b.fmt("Run unit tests for the '{s}' module", .{self.name}))
            .dependOn(&run_tests.step);

        b.top_level_steps.get("test").?.step.dependOn(&run_tests.step);
    }
};

fn definedIf(condition: bool) ?u1 {
    return if (condition) 1 else null;
}
