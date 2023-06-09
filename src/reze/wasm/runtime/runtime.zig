pub const funcref = ?Funcref;
pub const externref = ?*anyopaque;
pub const v128 = @Vector(u8, 16);
pub const Funcref = @import("Funcref.zig");
pub const Memory = @import("Memory.zig");
