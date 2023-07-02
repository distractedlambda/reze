const std = @import("std");

const Build = std.Build;
const FileSource = Build.FileSource;
const Module = Build.Module;
const Step = Build.Step;

const CompileConfig = @import("CompileConfig.zig");

name: []const u8,
module: *Module,
compile_config: *CompileConfig,

pub fn create(builder: *Build, name: []const u8, source_file: FileSource) *@This() {
    const self = builder.allocator.create(@This()) catch @panic("OOM");

    self.* = .{
        .name = name,
        .module = builder.createModule(.{ .source_file = source_file }),
        .compile_config = CompileConfig.create(builder.allocator),
    };

    return self;
}

pub fn dependOn(self: *@This(), other: *const @This()) void {
    self.module.dependencies.put(other.name, other.module) catch @panic("OOM");
    self.compile_config.include(other.compile_config);
}

pub fn addTo(self: *const @This(), step: *Step.Compile) void {
    step.addModule(self.name, self.module);
    self.compile_config.applyTo(step);
}
