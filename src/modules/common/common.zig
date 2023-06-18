pub const Aabb = @import("aabb.zig").Aabb;
pub const ComptimeRatio = @import("ComptimeRatio.zig");
pub const Extent = @import("extent.zig").Extent;
pub const ReadOnlyFileMapping = @import("ReadOnlyFileMapping.zig");

pub const scaled_int = @import("scaled_int.zig");
pub const FixedPoint = scaled_int.FixedPoint;
pub const ScaledInt = scaled_int.ScaledInt;

pub const pointeeCast = @import("pointee_cast.zig").pointeeCast;

test {
    _ = @import("aabb.zig");
    _ = @import("ComptimeRatio.zig");
    _ = @import("extent.zig");
    _ = @import("pointee_cast.zig");
    _ = @import("ReadOnlyFileMapping.zig");
    _ = @import("scaled_int.zig");
}
