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

const third_party_libs = &[_]ThirdPartyLibInfo{ .{
    .name = "glfw",
    .link_name = "glfw3",
    .configure_embedded = &configureEmbeddedGlfw,
}, .{
    .name = "freetype",
    .link_name = "freetype2",
    .configure_embedded = &configureEmbeddedFreetype,
} };

fn configureEmbeddedGlfw(lib: *Step.Compile) void {
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

    if (lib.target.isWindows()) {
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
    } else if (lib.target.isDarwin()) {
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
}

fn configureEmbeddedFreetype(lib: *Step.Compile) void {
    _ = lib;
    @panic("TODO support embedded FreeType");
}

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize_mode = b.standardOptimizeOption(.{});

    var embedded_libs = std.ArrayList(*std.Build.Step.Compile).init(b.allocator);
    var system_libs = std.ArrayList([]const u8).init(b.allocator);
    const build_options = b.addOptions();

    for (third_party_libs) |l| {
        const option = b.option(ThirdPartyLibOption, l.name, "") orelse .disabled;
        build_options.addOption(bool, b.fmt("use_{s}", .{l.name}), option != .disabled);
        switch (option) {
            .disabled => {},
            .system => system_libs.append(l.link_name) catch @panic("OOM"),
            .embedded => embedded_libs.append(blk: {
                const lib = b.addStaticLibrary(.{
                    .name = l.name,
                    .target = target,
                    .optimize = optimize_mode,
                    .link_libc = true,
                });

                (l.configure_embedded)(lib);

                break :blk lib;
            }) catch @panic("OOM"),
        }
    }

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/reze/reze.zig" },
        .target = target,
        .optimize = optimize_mode,
    });

    unit_tests.addModule("build_options", build_options.createModule());

    for (embedded_libs.items) |l| unit_tests.linkLibrary(l);
    for (system_libs.items) |l| unit_tests.linkSystemLibrary(l);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(unit_tests).step);
}
