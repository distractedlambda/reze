const c = @import("../c.zig");
const Extent = @import("../extent.zig").Extent;

const err = @import("err.zig");
const Error = err.Error;

pub const Monitor = opaque {
    fn glfwMonitor(self: *Monitor) *c.GLFWmonitor {
        return @ptrCast(*c.GLFWmonitor, self);
    }

    pub fn getAll() Error![]const *Monitor {
        var count: c_int = undefined;
        const glfw_monitors = c.glfwGetMonitors(&count);
        try err.check();
        const monitors = @ptrCast([*]const *Monitor, glfw_monitors orelse return &.{});
        return monitors[0..@intCast(usize, count)];
    }

    pub fn getPrimary() Error!?*Monitor {
        const glfw_monitor = c.glfwGetPrimaryMonitor();
        try err.check();
        return @ptrCast(?*Monitor, glfw_monitor);
    }

    pub fn getPos(self: *Monitor) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetMonitorPos(self.glfwMonitor(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getWorkarea(self: *Monitor) Error!Extent(2, c_int) {
        var result: Extent(2, c_int) = undefined;

        c.glfwGetMonitorWorkarea(
            self.glfwMonitor(),
            &result.start[0],
            &result.start[1],
            &result.size[0],
            &result.size[1],
        );

        try err.check();

        return result;
    }

    pub fn getPhysicalSize_mm(self: *Monitor) Error![2]c_int {
        var result: [2]c_int = undefined;
        c.glfwGetMonitorPhysicalSize(self.glfwMonitor(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getContentScale(self: *Monitor) Error![2]f32 {
        var result: [2]f32 = undefined;
        c.glfwGetMonitorContentScale(self.glfwMonitor(), &result[0], &result[1]);
        try err.check();
        return result;
    }

    pub fn getName(self: *Monitor) Error![*:0]u8 {
        const name = c.glfwGetMonitorName(self.glfwMonitor());
        try err.check();
        return name.?;
    }
};
