const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const FileSource = Build.FileSource;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;

pub fn build(b: *Build) void {
    var context = Context.init(b);
    _ = context.addProjectModule("io");
}

const Context = struct {
    builder: *Build,
    target: CrossTarget,
    optimize: OptimizeMode,
    test_step: *Step,

    fn init(b: *Build) @This() {
        return .{
            .builder = b,
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
            .test_step = b.step("test", "Run all unit tests"),
        };
    }

    fn fmt(self: *@This(), comptime format: []const u8, args: anytype) []const u8 {
        return self.builder.fmt(format, args);
    }

    fn addProjectModule(self: *@This(), name: []const u8) *Build.Module {
        const root_file = FileSource{
            .path = self.fmt("src/modules/{s}/{s}.zig", .{ name, name }),
        };

        const tests = self.builder.addTest(.{
            .root_source_file = root_file,
            .target = self.target,
            .optimize = self.optimize,
        });

        const run_tests = &self.builder.addRunArtifact(tests).step;

        self.builder.step(
            self.fmt("test_{s}", .{name}),
            self.fmt("Run unit tests for the '{s}' module", .{name}),
        ).dependOn(run_tests);

        self.test_step.dependOn(run_tests);

        return self.builder.addModule(name, .{ .source_file = root_file });
    }
};
