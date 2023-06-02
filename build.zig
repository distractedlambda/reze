const std = @import("std");

const wasm_cpu_model = std.Target.Cpu.Model{
    .name = "generic",
    .llvm_name = "generic",
    .features = std.Target.wasm.featureSet(&.{
        .bulk_memory,
        .multivalue,
        .mutable_globals,
        .nontrapping_fptoint,
        .reference_types,
        .sign_ext,
        .simd128,
    }),
};

const wasm_freestanding_target = std.zig.CrossTarget{
    .cpu_arch = .wasm32,
    .cpu_model = .{ .explicit = &wasm_cpu_model },
    .os_tag = .freestanding,
};

const wasm_wasi_target = std.zig.CrossTarget{
    .cpu_arch = .wasm32,
    .cpu_model = .{ .explicit = &wasm_cpu_model },
    .os_tag = .wasi,
};

const Configurator = struct {
    build: *std.Build,
    target: ?std.zig.CrossTarget = null,
    optimize_mode: ?std.builtin.OptimizeMode = null,
    run_unit_tests: ?*std.Build.Step.Run = null,

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
            const mode_specific_name = self.build.fmt("{s}-{s}", .{name, @tagName(mode)});
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
            .root_source_file = .{ .path = "src/main.zig" },
            .target = self.target.?,
            .optimize = self.optimize_mode.?,
        });

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
