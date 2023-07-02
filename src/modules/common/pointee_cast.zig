pub fn pointeeCast(comptime T: type, ptr: anytype) PointeeCast(T, @TypeOf(ptr)) {
    return switch (@typeInfo(@TypeOf(ptr))) {
        .Optional => if (ptr) |p| pointeeCast(T, p) else null,

        .ErrorUnion => pointeeCast(T, try ptr),

        .Pointer => |tinfo| if (@typeInfo(tinfo.child) == .Opaque)
            @ptrCast(@alignCast(ptr))
        else
            @ptrCast(ptr),

        else => unreachable,
    };
}

fn PointeeCast(comptime T: type, comptime Ptr: type) type {
    return switch (@typeInfo(Ptr)) {
        .Optional => |info| ?PointeeCast(T, info.child),

        .ErrorUnion => |info| info.error_set!PointeeCast(T, info.payload),

        .Pointer => |info| blk: {
            var new_info = info;
            new_info.child = T;
            if (@typeInfo(info.child) == .Opaque) new_info.alignment = @alignOf(T);
            break :blk @Type(.{ .Pointer = new_info });
        },

        else => @compileError(
            "expected pointer, optional, or error union, but got " ++ @typeName(Ptr),
        ),
    };
}
