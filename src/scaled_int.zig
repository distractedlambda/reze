const std = @import("std");

const ComptimeRatio = @import("ComptimeRatio.zig");

const Traits = struct {
    significand: type,
    scale: ComptimeRatio,
};

pub fn ScaledInt(comptime Significand: type, comptime scale: ComptimeRatio) type {
    return packed struct {
        significand: Significand,

        const traits = Traits{
            .significand = Significand,
            .scale = scale,
        };

        pub fn fromSignificand(significand: Significand) @This() {
            return .{ .significand = significand };
        }

        pub fn fromComptime(comptime value: anytype) @This() {
            return comptime switch (@typeInfo(@TypeOf(value))) {
                .Int => fromComptime(@as(comptime_int, value)),

                .Float => fromComptime(@as(comptime_float, value)),

                .ComptimeInt => fromSignificand(@divExact(value, scale.numerator) * scale.denominator),

                .ComptimeFloat => blk: {
                    const f128_value = @as(f128, value);

                    if (!std.math.isFinite(f128_value))
                        @compileError("source value is not finite");

                    break :blk fromComptime(@bitCast(F128Fields, f128_value).asScaledInt());
                },

                else => {
                    if (!isScaledIntType(@TypeOf(value)))
                        @compileError("unsupported source type");
                },
            };
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

fn isScaledIntType(comptime T: type) bool {
    return @hasDecl(T, "traits") and @TypeOf(T.traits) == Traits;
}

const F128Fields = packed struct(u128) {
    fraction: u112,
    exponent: u15,
    negative: bool,

    fn isSubnormal(self: @This()) bool {
        return self.exponent == 0;
    }

    fn significand(self: @This()) i114 {
        var result: i114 = self.fraction;
        if (!self.isSubnormal()) result |= (1 << 112);
        if (self.negative) result = -result;
        return result;
    }

    fn trueExponent(self: @This()) i16 {
        return if (self.isSubnormal())
            -16494
        else
            @as(i16, self.exponent) - 16495;
    }

    fn scale(comptime self: @This()) ComptimeRatio {
        return if (self.trueExponent() < 0)
            ComptimeRatio.init(1, 1 << -self.trueExponent())
        else
            ComptimeRatio.init(1 << self.trueExponent, 1);
    }

    fn asScaledInt(comptime self: @This()) ScaledInt(i114, self.scale()) {
        return ScaledInt(i114, self.scale()).fromSignificand(self.significand());
    }
};
