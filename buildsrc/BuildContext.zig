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
project_modules: std.StringHashMapUnmanaged(*MixedModule) = .{},

pub fn create(builder: *Build) *@This() {
    const self = builder.allocator.create(@This()) catch @panic("OOM");

    self.* = .{
        .builder = builder,
        .target = builder.standardTargetOptions(.{}),
        .optimize = builder.standardOptimizeOption(.{}),
        .single_threaded = builder.option(bool, "single_threaded", "") orelse false,
        .run_all_tests = builder.step("test", "Run all unit tests"),
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

    self.builder.installArtifact(app);

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
