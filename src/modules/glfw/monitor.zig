const common = @import("common");
const std = @import("std");

const Extent = common.Extent;

const c = @import("c.zig");
const err = @import("err.zig");
const Error = err.Error;

pub const Monitor = opaque {
    inline fn toC(self: *Monitor) *c.GLFWmonitor {
        return @ptrCast(*c.GLFWmonitor, self);
    }

    pub fn getAll() Error![]const *Monitor {
        var count: c_int = undefined;
        const monitors = c.glfwGetMonitors(&count);
        try err.check();
        return @ptrCast([*]const *Monitor, monitors orelse return &.{})[0..@intCast(usize, count)];
    }

    pub fn getPrimary() Error!?*Monitor {
        const monitor = c.glfwGetPrimaryMonitor();
        try err.check();
        return @ptrCast(?*Monitor, monitor);
    }

    pub fn getPos(self: *Monitor) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetMonitorPos(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getWorkarea(self: *Monitor) Error!Extent(2, c_int) {
        var result: Extent(2, c_int) = undefined;

        c.glfwGetMonitorWorkarea(
            self.toC(),
            &result.start[0],
            &result.start[1],
            &result.size[0],
            &result.size[1],
        );

        try err.check();

        return result;
    }

    pub fn getPhysicalSize(self: *Monitor) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetMonitorPhysicalSize(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getContentScale(self: *Monitor) Error![2]f32 {
        var result: [2]f32 = undefined;
        c.glfwGetMonitorContentScale(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getName(self: *Monitor) Error![*:0]const u8 {
        const result = c.glfwGetMonitorName(self.toC());
        try err.check();
        return result;
    }
};

test {
    std.testing.refAllDecls(Monitor);
}
