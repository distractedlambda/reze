const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;

const MixedModule = @import("MixedModule.zig");

builder: *Build,
target: CrossTarget,
optimize: OptimizeMode,
single_threaded: bool,
run_all_tests: *Step,
python_program: ?[]const u8,
project_modules: std.StringHashMapUnmanaged(*MixedModule) = .{},

pub fn create(builder: *Build) *@This() {
    const self = builder.allocator.create(@This()) catch @panic("OOM");

    self.* = .{
        .builder = builder,
        .target = builder.standardTargetOptions(.{}),
        .optimize = builder.standardOptimizeOption(.{}),
        .single_threaded = builder.option(bool, "single_threaded", "") orelse false,
        .run_all_tests = builder.step("test", "Run all unit tests"),
        .python_program = builder.option(
            []const u8,
            "python",
            "Python interpreter executable",
        ) orelse builder.findProgram(
            &.{ "python3", "python" },
            &.{},
        ) catch null,
    };

    return self;
}

pub fn addApp(self: *@This(), name: []const u8) *Step.Compile {
    const app = self.builder.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = self.builder.fmt("src/apps/{s}/main.zig", .{name}) },
        .target = self.target,
        .optimize = self.optimize,
    });

    const install = &self.builder.addInstallArtifact(app).step;

    self.builder.step(
        name,
        self.fmt("Build and install the '{s}' executable", .{name}),
    ).dependOn(install);

    self.builder.getInstallStep().dependOn(install);

    return app;
}

pub fn projectModule(self: *@This(), name: []const u8) *MixedModule {
    const slot = self.project_modules.getOrPut(
        self.builder.allocator,
        self.builder.dupe(name),
    ) catch @panic("OOM");

    if (!slot.found_existing) slot.value_ptr.* = MixedModule.create(
        self.builder,
        .{ .path = self.builder.fmt("src/modules/{s}/{s}.zig", .{ name, name }) },
    );

    return slot.value_ptr.*;
}

pub fn addProjectModuleUnitTests(self: *@This()) void {
    var pm_iter = self.project_modules.iterator();
    while (pm_iter.next()) |pm_kv| {
        const name = pm_kv.key_ptr.*;
        const module = pm_kv.value_ptr.*;

        const tests_name = self.builder.fmt("test_{s}", .{name});

        const tests = self.builder.addTest(.{
            .name = tests_name,
            .root_source_file = module.zig_module.source_file,
            .target = self.target,
            .optimize = self.optimize,
        });

        module.applyAdditionalConfigTo(tests);

        var dep_iter = module.zig_module.dependencies.iterator();
        while (dep_iter.next()) |dep_kv| {
            tests.addModule(dep_kv.key_ptr.*, dep_kv.value_ptr.*);
        }

        const run_tests = self.builder.addRunArtifact(tests);
        run_tests.skip_foreign_checks = true;

        self.builder.step(
            tests_name,
            self.builder.fmt("Run unit tests for the '{s}' module", .{name}),
        ).dependOn(&run_tests.step);

        self.run_all_tests.dependOn(&run_tests.step);
    }
}

pub fn addStaticCLibrary(self: *@This(), name: []const u8) *Step.Compile {
    return self.builder.addStaticLibrary(.{
        .name = name,
        .target = self.target,
        .optimize = self.optimize,
        .single_threaded = self.single_threaded,
        .link_libc = true,
    });
}

pub fn addStaticCppLibrary(self: *@This(), name: []const u8) *Step.Compile {
    const lib = self.addStaticCLibrary(name);
    lib.linkLibCpp();
    return lib;
}

pub fn fmt(self: *@This(), comptime format: []const u8, args: anytype) []u8 {
    return self.builder.fmt(format, args);
}

pub fn addConfigHeader(
    self: *@This(),
    options: Step.ConfigHeader.Options,
    values: anytype,
) *Step.ConfigHeader {
    const config_header = self.builder.addConfigHeader(options, values);

    // Work around bug in std.Build
    if (options.style.getFileSource()) |fs| fs.addStepDependencies(&config_header.step);

    return config_header;
}
