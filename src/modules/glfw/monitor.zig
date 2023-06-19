const std = @import("std");

const common = @import("common");
const Extent = common.Extent;
const pointeeCast = common.pointeeCast;

const c = @import("c.zig");
const err = @import("err.zig");

pub const Monitor = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.GLFWmonitor, self)) {
        return pointeeCast(c.GLFWmonitor, self);
    }

    pub fn getAll() ![]const *Monitor {
        var count: c_int = undefined;
        const monitors = c.glfwGetMonitors(&count);
        try err.check();
        return pointeeCast(*Monitor, monitors orelse return &.{})[0..@intCast(usize, count)];
    }

    pub fn getPrimary() !?*Monitor {
        const monitor = c.glfwGetPrimaryMonitor();
        try err.check();
        return pointeeCast(Monitor, monitor);
    }

    pub fn getPos(self: *Monitor) ![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetMonitorPos(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getWorkarea(self: *Monitor) !Extent(2, c_int) {
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

    pub fn getPhysicalSize(self: *Monitor) ![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetMonitorPhysicalSize(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getContentScale(self: *Monitor) ![2]f32 {
        var result: [2]f32 = undefined;
        c.glfwGetMonitorContentScale(self.toC(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getName(self: *Monitor) ![*:0]const u8 {
        const result = c.glfwGetMonitorName(self.toC());
        try err.check();
        return result;
    }
};

test {
    std.testing.refAllDecls(Monitor);
}
