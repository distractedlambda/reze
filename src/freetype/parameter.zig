const std = @import("std");

const c = @import("../c.zig");

pub const Parameter = extern struct {
    tag: c_ulong,
    data: ?*const anyopaque = null,
};

comptime {
    std.debug.assert(@sizeOf(Parameter) == @sizeOf(c.FT_Parameter));
    std.debug.assert(@alignOf(Parameter) == @alignOf(c.FT_Parameter));
}
