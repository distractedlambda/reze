pub fn pointeeCast(comptime T: type, ptr: anytype) PointeeCast(T, @TypeOf(ptr)) {
    return @ptrCast(PointeeCast(T, @TypeOf(ptr)), ptr);
}

fn PointeeCast(comptime T: type, comptime Ptr: type) type {
    return switch (@typeInfo(Ptr)) {
        .Optional => |info| ?PointeeCast(T, info.child),

        .ErrorUnion => |info| info.error_set!PointeeCast(T, info.payload),

        .Pointer => |info| blk: {
            var new_info = info;
            new_info.child = T;
            break :blk @Type(.{ .Pointer = new_info });
        },

        else => @compileError(
            "expected pointer, optional, or error union, but got " ++ @typeName(Ptr),
        ),
    };
}
