const std = @import("std");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Build = std.Build;
const FileSource = Build.FileSource;
const Module = Build.Module;
const Step = Build.Step;

config_items: ArrayList(ConfigItem),

const ConfigItem = union(enum) {
    add_config_header: *Step.ConfigHeader,
    add_include_path: []const u8,
    define_c_macro: struct { name: []const u8, value: ?[]const u8 },
    link_framework: []const u8,
    link_lib_c: void,
    link_lib_cpp: void,
    link_library: *Step.Compile,
    link_system_library: []const u8,

    include: *const @This(),

    fn applyTo(self: @This(), step: *Step.Compile) void {
        switch (self) {
            .add_config_header => |ch| step.addConfigHeader(ch),
            .add_include_path => |p| step.addIncludePath(p),
            .add_module => |m| step.addModule(m.name, m.module),
            .define_c_macro => |nv| step.defineCMacro(nv.name, nv.value),
            .link_framework => |name| step.linkFramework(name),
            .link_lib_c => step.linkLibC(),
            .link_lib_cpp => step.linkLibCpp(),
            .link_library => |lib| step.linkLibrary(lib),
            .link_system_library => |name| step.linkSystemLibrary(name),
            .include => |cc| cc.applyTo(step),
        }
    }
};

pub fn create(allocator: Allocator) *@This() {
    const self = allocator.alloc(@This()) catch @panic("OOM");
    self.* = .{ .config_items = ArrayList(ConfigItem).init(allocator) };
    return self;
}

pub fn applyTo(self: *const @This(), step: *Step.Compile) void {
    for (self.config_items.items) |ci| ci.applyTo(step);
}

fn addConfigItem(self: *@This(), item: ConfigItem) void {
    self.config_items.append(item) catch @panic("OOM");
}

pub fn addConfigHeader(self: *@This(), ch: *Step.ConfigHeader) void {
    self.addConfigItem(.{ .add_config_header = ch });
}

pub fn addIncludePath(self: *@This(), path: []const u8) void {
    self.addConfigItem(.{ .add_include_path = path });
}

pub fn defineCMacro(self: *@This(), name: []const u8, value: ?[]const u8) void {
    self.addConfigItem(.{ .define_c_macro = .{ .name = name, .value = value } });
}

pub fn linkFramework(self: *@This(), name: []const u8) void {
    self.addConfigItem(.{ .link_framework = name });
}

pub fn linkLibC(self: *@This()) void {
    self.addConfigItem(.link_lib_c);
}

pub fn linkLibCpp(self: *@This()) void {
    self.addConfigItem(.link_lib_cpp);
}

pub fn linkLibrary(self: *@This(), lib: *Step.Compile) void {
    self.addConfigItem(.{ .link_library = lib });
}

pub fn linkSystemLibrary(self: *@This(), name: []const u8) void {
    self.addConfigItem(.{ .link_system_library = name });
}

pub fn include(self: *@This(), config: *const @This()) void {
    self.addConfigItem(.{ .include = config });
}
