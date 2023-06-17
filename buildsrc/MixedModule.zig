const std = @import("std");

const Build = std.Build;
const CreateModuleOptions = Build.CreateModuleOptions;
const FileSource = Build.FileSource;
const Module = Build.Module;
const Step = Build.Step;

const MixedModule = @This();

zig_module: *Module,
additional_config: std.ArrayListUnmanaged(AdditionalConfig) = .{},

const AdditionalConfig = union(enum) {
    link_framework: []const u8,
    link_library: *Step.Compile,
    link_lib_c: void,
    link_lib_cpp: void,
    define_c_macro: struct { name: []const u8, value: ?[]const u8 },
    link_system_library: []const u8,
    add_mixed_module: *MixedModule,

    fn applyTo(self: @This(), step: *Step.Compile) void {
        switch (self) {
            .link_framework => |name| step.linkFramework(name),
            .link_library => |lib| step.linkLibrary(lib),
            .link_lib_c => step.linkLibC(),
            .link_lib_cpp => step.linkLibCpp(),
            .define_c_macro => |nv| step.defineCMacro(nv.name, nv.value),
            .link_system_library => |name| step.linkSystemLibrary(name),
            .add_mixed_module => |mm| mm.applyAdditionalConfigTo(step),
        }
    }
};

pub fn create(builder: *Build, source_file: FileSource) *@This() {
    const self = builder.allocator.create(@This()) catch @panic("OOM");
    self.* = .{ .zig_module = builder.createModule(.{ .source_file = source_file }) };
    return self;
}

pub fn applyAdditionalConfigTo(self: *@This(), step: *Step.Compile) void {
    for (self.additional_config.items) |ac| ac.applyTo(step);
}

pub fn addTo(self: *@This(), step: *Step.Compile, name: []const u8) void {
    step.addModule(name, self.zig_module);
    self.applyAdditionalConfigTo(step);
}

fn appendAdditionalConfig(self: *@This(), item: AdditionalConfig) void {
    self.additional_config.append(self.zig_module.builder.allocator, item) catch @panic("OOM");
}

fn dupe(self: *@This(), bytes: []const u8) []const u8 {
    return self.zig_module.builder.dupe(bytes);
}

pub fn linkFramework(self: *@This(), name: []const u8) void {
    self.appendAdditionalConfig(.{ .link_framework = self.dupe(name) });
}

pub fn linkLibrary(self: *@This(), lib: *Step.Compile) void {
    self.appendAdditionalConfig(.{ .link_library = lib });
}

pub fn linkLibC(self: *@This()) void {
    self.appendAdditionalConfig(.link_lib_c);
}

pub fn linkLibCpp(self: *@This()) void {
    self.appendAdditionalConfig(.link_lib_cpp);
}

pub fn defineCMacro(self: *@This(), name: []const u8, value: ?[]const u8) void {
    self.appendAdditionalConfig(.{
        .define_c_macro = .{
            .name = self.dupe(name),
            .value = self.dupe(value),
        },
    });
}

pub fn linkSystemLibrary(self: *@This(), name: []const u8) void {
    self.appendAdditionalConfig(.{ .link_system_library = self.dupe(name) });
}

pub fn addModule(self: *@This(), name: []const u8, module: *Module) void {
    self.zig_module.dependencies.put(self.dupe(name), module) catch @panic("OOM");
}

pub fn addAnonymousModule(self: *@This(), name: []const u8, options: CreateModuleOptions) void {
    self.addModule(name, self.zig_module.builder.createModule(options));
}

pub fn addOptions(self: *@This(), module_name: []const u8, options: *Step.Options) void {
    self.addAnonymousModule(module_name, options.createModule());
}

pub fn addMixedModule(self: *@This(), name: []const u8, mm: *MixedModule) void {
    self.addModule(name, mm.zig_module);
    self.appendAdditionalConfig(.{ .add_mixed_module = mm });
}
