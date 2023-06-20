pub const Aabb = @import("aabb.zig").Aabb;
pub const ComptimeRatio = @import("ComptimeRatio.zig");
pub const Extent = @import("extent.zig").Extent;
pub const ReadOnlyFileMapping = @import("ReadOnlyFileMapping.zig");

pub const CBitFlags = @import("c_bit_flags.zig").CBitFlags;
pub const CEnum = @import("c_enum.zig").CEnum;

pub const scaled_int = @import("scaled_int.zig");
pub const FixedPoint = scaled_int.FixedPoint;
pub const ScaledInt = scaled_int.ScaledInt;

pub const pointeeCast = @import("pointee_cast.zig").pointeeCast;
pub const translateCError = @import("translate_c_error.zig").translateCError;

test {
    _ = @import("aabb.zig");
    _ = @import("c_bit_flags.zig");
    _ = @import("c_enum.zig");
    _ = @import("ComptimeRatio.zig");
    _ = @import("extent.zig");
    _ = @import("pointee_cast.zig");
    _ = @import("ReadOnlyFileMapping.zig");
    _ = @import("scaled_int.zig");
    _ = @import("translate_c_error.zig");
}
