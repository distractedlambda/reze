const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
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
    optimize_mode: OptimizeMode,
    glfw_lib: ?*Step.Compile = null,
    freetype_lib: ?*Step.Compile = null,

    fn init(b: *Build) @This() {
        return .{
            .build = b,
            .target = b.standardTargetOptions(.{}),
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

        lib.installHeadersDirectory("third_party/glfw/include", "");

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

    fn configureBuild(self: *Configurator) void {
        const unit_tests = self.build.addTest(.{
            .root_source_file = .{ .path = "src/reze/reze.zig" },
            .target = self.target,
            .optimize = self.optimize_mode,
        });

        unit_tests.linkLibrary(self.addGlfw());

        const test_step = self.build.step("test", "Run unit tests");
        test_step.dependOn(&self.build.addRunArtifact(unit_tests).step);
    }
};

pub fn build(b: *Build) void {
    var configurator = Configurator.init(b);
    configurator.configureBuild();
}
