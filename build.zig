const std = @import("std");

const Allocator = std.mem.Allocator;
const AutoHashMapUnmanaged = std.AutoHashMapUnmanaged;
const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const Module = Build.Module;
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

const third_party_dir = "third_party";

fn joinComptimePaths(comptime paths: []const []const u8) []const u8 {
    return comptime blk: {
        var joined: []const u8 = "";

        for (paths) |path| {
            if (path.len == 0)
                continue;

            if (joined.len != 0)
                joined = joined ++ std.fs.path.sep_str;

            joined = joined ++ path;
        }

        break :blk joined;
    };
}

fn prefixComptimePaths(comptime prefix: []const u8, comptime paths: []const []const u8) []const []const u8 {
    return comptime blk: {
        var results: [paths.len][]const u8 = undefined;

        for (&results, paths) |*result, path|
            result.* = joinComptimePaths(&.{ prefix, path });

        break :blk &results;
    };
}

const Configurator = struct {
    build: *Build,
    target: ?CrossTarget = null,
    optimize_mode: ?OptimizeMode = null,
    run_unit_tests: ?*Step.Run = null,

    const GlfwOptions = struct {
        target: CrossTarget,
        mode: OptimizeMode,
    };

    fn addGlfw(self: *@This(), options: GlfwOptions) *Step.Compile {
        const glfw_dir = comptime joinComptimePaths(&.{ third_party_dir, "glfw" });
        const include_dir = joinComptimePaths(&.{ glfw_dir, "include" });
        const src_dir = comptime joinComptimePaths(&.{ glfw_dir, "src" });

        const lib = self.build.addStaticLibrary(.{
            .name = "glfw",
            .target = options.target,
            .optimize = options.mode,
            .link_libc = true,
        });

        lib.addIncludePath(include_dir);
        lib.installHeadersDirectory(include_dir, "");

        lib.addCSourceFiles(prefixComptimePaths(src_dir, &.{
            "context.c",
            "egl_context.c",
            "init.c",
            "input.c",
            "monitor.c",
            "window.c",
        }), &.{});

        if (options.target.isDarwin()) {
            lib.defineCMacro("_GLFW_COCOA", null);
            lib.addCSourceFiles(prefixComptimePaths(src_dir, &.{
                "cocoa_init.m",
                "cocoa_joystick.m",
                "cocoa_monitor.m",
                "cocoa_time.c",
                "cocoa_window.m",
                "nsgl_context.m",
            }), &.{});
        } else if (options.target.isWindows()) {
            lib.defineCMacro("_GLFW_WIN32", null);
            lib.addCSourceFiles(prefixComptimePaths(src_dir, &.{
                "wgl_context.c",
                "win32_init.c",
                "win32_joystick.c",
                "win32_monitor.c",
                "win32_thread.c",
                "win32_time.c",
                "win32_window.c",
            }), &.{});
        } else {
            lib.defineCMacro("_GLFW_X11", null);
            lib.addCSourceFiles(prefixComptimePaths(src_dir, &.{
                "glx_context.c",
                "linux_joystick.c",
                "posix_thread.c",
                "posix_time.c",
                "x11_init.c",
                "x11_monitor.c",
                "x11_window.c",
                "xkb_unicode.c",
            }), &.{});
        }

        return lib;
    }

    const FreetypeOptions = struct {
        target: CrossTarget,
        mode: OptimizeMode,
    };

    fn getFreetypeLib(self: *@This(), options: FreetypeOptions) *Step.Compile {
        const slot = self.freetype_libs.getOrPut(self.getAllocator(), options) catch @panic("OOM");
        if (slot.found_existing) return slot.value_ptr.*;
        @panic("TODO");
    }

    fn addWasmModule(
        self: *@This(),
        name: []const u8,
        root_source_file: std.Build.FileSource,
        target: std.zig.CrossTarget,
        optimize: std.builtin.OptimizeMode,
    ) *std.Build.Step.Compile {
        const module = self.build.addSharedLibrary(.{
            .name = name,
            .root_source_file = root_source_file,
            .target = target,
            .optimize = optimize,
        });

        module.rdynamic = true;

        return module;
    }

    fn addFreestandingWasmModule(
        self: *@This(),
        name: []const u8,
        root_source_file: std.Build.FileSource,
        optimize: std.builtin.OptimizeMode,
    ) *std.Build.Step.Compile {
        return self.addWasmModule(name, root_source_file, wasm_freestanding_target, optimize);
    }

    fn addWasiModule(
        self: *@This(),
        name: []const u8,
        root_source_file: std.Build.FileSource,
        optimize: std.builtin.OptimizeMode,
    ) *std.Build.Step.Compile {
        return self.addWasmModule(name, root_source_file, wasm_wasi_target, optimize);
    }

    fn configureTestWasmModule(self: *@This(), name: []const u8) void {
        const root = std.build.FileSource{ .path = self.build.fmt("src/test_modules/{s}.zig", .{name}) };
        for (std.meta.tags(std.builtin.OptimizeMode)) |mode| {
            const mode_specific_name = self.build.fmt("{s}-{s}", .{ name, @tagName(mode) });
            const module = self.addFreestandingWasmModule(mode_specific_name, root, mode);
            const install_module = self.build.addInstallArtifact(module);
            install_module.dest_dir = .{ .custom = "test_modules" };
            self.run_unit_tests.?.step.dependOn(&install_module.step);
        }
    }

    fn configureAllTestWasmModules(self: *@This()) void {
        for (@import("src/test_modules/manifest.zig").module_names) |name| {
            self.configureTestWasmModule(name);
        }
    }

    fn configureUnitTests(self: *@This()) void {
        const unit_tests = self.build.addTest(.{
            .root_source_file = .{ .path = "src/tests.zig" },
            .target = self.target.?,
            .optimize = self.optimize_mode.?,
        });

        unit_tests.addAnonymousModule("reze", .{
            .source_file = .{ .path = "src/reze/reze.zig" },
            .dependencies = &.{
                .{
                    .name = "build_options",
                    .module = blk: {
                        const options = self.build.addOptions();
                        options.addOption(bool, "linking_glfw", true);
                        options.addOption(bool, "linking_freetype", false);
                        options.addOption(bool, "linking_fontconfig", false);
                        break :blk options.createModule();
                    },
                },
            },
        });

        unit_tests.linkLibrary(self.addGlfw(.{
            .target = self.target.?,
            .mode = self.optimize_mode.?,
        }));

        self.run_unit_tests = self.build.addRunArtifact(unit_tests);
        self.run_unit_tests.?.cwd = self.build.install_path;

        self.configureAllTestWasmModules();

        const test_step = self.build.step("test", "Run unit tests");
        test_step.dependOn(&self.run_unit_tests.?.step);
    }

    fn configureBuild(self: *@This()) void {
        self.target = self.build.standardTargetOptions(.{});
        self.optimize_mode = self.build.standardOptimizeOption(.{});
        self.configureUnitTests();
    }
};

pub fn build(b: *std.Build) void {
    var configurator = Configurator{ .build = b };
    configurator.configureBuild();
}
