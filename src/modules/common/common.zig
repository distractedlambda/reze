pub const scaled_int = @import("scaled_int.zig");

pub const Aabb = @import("aabb.zig").Aabb;
pub const ComptimeRatio = @import("ComptimeRatio.zig");
pub const Extent = @import("extent.zig").Extent;
pub const FixedPoint = scaled_int.FixedPoint;
pub const ReadOnlyFileMapping = @import("ReadOnlyFileMapping.zig");
pub const ScaledInt = scaled_int.ScaledInt;

test {
    _ = &scaled_int;
    _ = &Aabb;
    _ = &ComptimeRatio;
    _ = &Extent;
    _ = &FixedPoint;
    _ = &ReadOnlyFileMapping;
    _ = &ScaledInt;
}
