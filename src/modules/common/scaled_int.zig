const std = @import("std");

const ComptimeRatio = @import("ComptimeRatio.zig");

pub fn ScaledInt(comptime Repr: type, comptime scale: ComptimeRatio) type {
    if (@typeInfo(Repr) != .Int) {
        @compileError("repr type must be a fixed-width integer type");
    }

    return packed struct {
        repr: Repr,

        const traits = Traits{
            .repr = Repr,
            .scale = scale,
        };

        pub fn init(repr: Repr) @This() {
            return .{ .repr = repr };
        }
    };
}

pub fn FixedPoint(
    comptime signedness: std.builtin.Signedness,
    comptime int_bits: comptime_int,
    comptime frac_bits: comptime_int,
) type {
    return ScaledInt(
        std.meta.Int(signedness, int_bits + frac_bits),
        ComptimeRatio.init(1, 1 << frac_bits),
    );
}

const Traits = struct {
    repr: type,
    scale: ComptimeRatio,
};

fn traitsOf(comptime T: type) Traits {
    return comptime switch (@typeInfo(T)) {
        .Int => .{
            .repr = T,
            .scale = ComptimeRatio.from(1),
        },

        else => if (@hasDecl(T, "traits") and @TypeOf(T.traits) == Traits)
            T.traits
        else
            @compileError("expected int or ScaledInt, but got " ++ @typeName(T)),
    };
}

pub fn ReprOf(comptime T: type) type {
    return traitsOf(T).repr;
}

pub fn reprOf(value: anytype) ReprOf(@TypeOf(value)) {
    return switch (@typeInfo(@TypeOf(value))) {
        .Int => value,
        else => value.repr,
    };
}

pub fn scaleOf(comptime T: type) ComptimeRatio {
    return comptime traitsOf(T).scale;
}

pub fn coerce(value: anytype) ScaledInt(ReprOf(@TypeOf(value)), scaleOf(@TypeOf(value))) {
    return ScaledInt(ReprOf(@TypeOf(value)), scaleOf(@TypeOf(value))).init(reprOf(value));
}
