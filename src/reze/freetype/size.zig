const c = @import("../c.zig");

pub const Size = opaque {
    fn raw(self: *@This()) *c.FT_SizeRec_ {
        return @ptrCast(*c.FT_SizeRec_, self);
    }
};
