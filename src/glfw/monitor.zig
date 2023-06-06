const c = @import("c.zig");
const err = @import("err.zig");

const ContentScale = @import("ContentScale.zig");
const Error = err.Error;
const PhysicalSize = @import("PhysicalSize.zig");
const Pos = @import("Pos.zig");
const Workarea = @import("Workarea.zig");

pub const Monitor = opaque {
    fn glfwMonitor(self: *Monitor) *c.GLFWmonitor {
        return @ptrCast(*c.GLFWmonitor, self);
    }

    pub fn getAll() Error![]const *Monitor {
        var count: c_int = undefined;
        const glfw_monitors = c.glfwGetMonitors(&count);
        try err.check();
        const monitors = @ptrCast([*]const *Monitor, (glfw_monitors orelse return &.{}));
        return monitors[0..@intCast(usize, count)];
    }

    pub fn getPrimary() Error!?*Monitor {
        const glfw_monitor = c.glfwGetPrimaryMonitor();
        try err.check();
        return @ptrCast(?*Monitor, glfw_monitor);
    }

    pub fn getPos(self: *Monitor) Error!Pos {
        var result: Pos = undefined;
        c.glfwGetMonitorPos(self.glfwMonitor(), &result.xpos, &result.ypos);
        try err.check();
        return result;
    }

    pub fn getWorkarea(self: *Monitor) Error!Workarea {
        var res: Workarea = undefined;
        c.glfwGetMonitorWorkarea(self.glfwMonitor(), &res.xpos, &res.ypos, &res.width, &res.height);
        try err.check();
        return res;
    }

    pub fn getPhysicalSize(self: *Monitor) Error!PhysicalSize {
        var result: PhysicalSize = undefined;
        c.glfwGetMonitorPhysicalSize(self.glfwMonitor(), &result.width_mm, &result.height_mm);
        try err.check();
        return result;
    }

    pub fn getContentScale(self: *Monitor) Error!ContentScale {
        var result: ContentScale = undefined;
        c.glfwGetMonitorContentScale(self.glfwMonitor(), &result.xscale, &result.yscale);
        try err.check();
        return result;
    }

    pub fn getName(self: *Monitor) Error![*:0]u8 {
        const name = c.glfwGetMonitorName(self.glfwMonitor());
        try err.check();
        return name.?;
    }
};
