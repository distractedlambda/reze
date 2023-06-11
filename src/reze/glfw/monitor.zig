const Extent = @import("../extent.zig").Extent;

const err = @import("err.zig");
const Error = err.Error;

pub const Monitor = opaque {
    extern fn glfwGetMonitors(count: *c_int) ?[*]const *Monitor;

    pub fn getAll() Error![]const *Monitor {
        var count: c_int = undefined;
        const monitors = glfwGetMonitors(&count);
        try err.check();
        return (monitors orelse return &.{})[0..@intCast(usize, count)];
    }

    extern fn glfwGetPrimaryMonitor() ?*Monitor;

    pub fn getPrimary() Error!?*Monitor {
        const result = glfwGetPrimaryMonitor();
        try err.check();
        return result;
    }

    extern fn glfwGetMonitorPos(monitor: *Monitor, xpos: *c_int, ypos: *c_int) void;

    pub fn getPos(self: *Monitor) Error![2]c_int {
        var result: [2]c_int = undefined;
        glfwGetMonitorPos(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwGetMonitorWorkarea(
        monitor: *Monitor,
        xpos: *c_int,
        ypos: *c_int,
        width: *c_int,
        height: *c_int,
    ) void;

    pub fn getWorkarea(self: *Monitor) Error!Extent(2, c_int) {
        var result: Extent(2, c_int) = undefined;

        glfwGetMonitorWorkarea(
            self,
            &result.start[0],
            &result.start[1],
            &result.size[0],
            &result.size[1],
        );

        try err.check();

        return result;
    }

    extern fn glfwGetMonitorPhysicalSize(monitor: *Monitor, widthMM: *c_int, heightMM: *c_int) void;

    pub fn getPhysicalSize_mm(self: *Monitor) Error![2]c_int {
        var result: [2]c_int = undefined;
        glfwGetMonitorPhysicalSize(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwGetMonitorContentScale(monitor: *Monitor, xscale: *f32, yscale: *f32) void;

    pub fn getContentScale(self: *Monitor) Error![2]f32 {
        var result: [2]f32 = undefined;
        glfwGetMonitorContentScale(self, &result[0], &result[1]);
        try err.check();
        return result;
    }

    extern fn glfwGetMonitorName(monitor: *Monitor) ?[*:0]const u8;

    pub fn getName(self: *Monitor) Error![*:0]const u8 {
        const result = glfwGetMonitorName(self);
        try err.check();
        return result.?;
    }

    test {
        _ = &getAll;
        _ = &getContentScale;
        _ = &getName;
        _ = &getPhysicalSize_mm;
        _ = &getPos;
        _ = &getPrimary;
        _ = &getWorkarea;
    }
};

test {
    _ = Monitor;
}
