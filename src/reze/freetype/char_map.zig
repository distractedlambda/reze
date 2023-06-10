const c = @import("../c.zig");

pub const CharMap = opaque {
    fn raw(self: *@This()) *c.FT_CharMapRec_ {
        return @ptrCast(*c.FT_CharMapRec_, self);
    }
};
