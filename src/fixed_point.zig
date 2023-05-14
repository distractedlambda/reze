const std = @import("std");

const Marker = struct {};

pub fn FixedPoint(comptime Significand_: type, comptime exponent_: comptime_int) type {
    return packed struct {
        significand: Significand,

        const marker = Marker{};

        pub const Significand = Significand_;

        pub const exponent = exponent_;

        pub const signedness = @typeInfo(Significand).Int.signedness;

        pub const bits = @typeInfo(Significand).Int.bits;

        pub const integral_bits = if (-exponent > bits) 0 else bits - exponent;

        pub const fractional_bits = if (exponent >= 0) 0 else @max(bits, -exponent);

        pub fn init(value: anytype) @This() {
            return .{ .significand = switch (@typeInfo(@TypeOf(value))) {
                .Int => |info| blk: {
                    if (info.bits == 0) {
                        break :blk 0;
                    }

                    if (exponent > 0) {
                        @compileError("Conversion from runtime integers can be lossy for positive exponents");
                    }

                    break :blk @as(Significand, @as(std.meta.Int(signedness, integral_bits), value)) << -exponent;
                },

                .ComptimeInt => comptime if (exponent > 0)
                    @divExact(value, 1 << exponent)
                else
                    value << -exponent,

                .ComptimeFloat => comptime blk: {
                    const f128_value = @as(f128, value);

                    if (!std.math.isFinite(f128_value)) {
                        @compileError("Source value is not finite");
                    }

                    const f128_fields = @bitCast(F128Fields, f128_value);
                    const effective_exponent = f128_fields.trueExponent() - exponent;

                    break :blk if (effective_exponent >= 0)
                        f128_fields.trueSignificand() << effective_exponent
                    else
                        @divExact(f128_fields.trueSignificand(), 1 << -effective_exponent);
                },

                else => blk: {
                    if (comptime !isFixedPoint(@TypeOf(value))) {
                        @compileError("Unsupported source type: " ++ @tagName(@TypeOf(value)));
                    }

                    if (@TypeOf(value).bits == 0) {
                        break :blk 0;
                    }

                    if (@TypeOf(value).exponent < exponent) {
                        @compileError("Source has finer resolution than destination");
                    }

                    const shift = @TypeOf(value).exponent - exponent;

                    if (shift + @TypeOf(value).bits > bits) {
                        @compileError("Destination does not have enough significant bits");
                    }

                    break :blk @as(Significand, value.significand) << shift;
                },
            } };
        }
    };
}

const F128Fields = packed struct(u128) {
    fraction: u112,
    exponent: u15,
    negative: bool,

    fn isSubnormal(self: @This()) bool {
        return self.exponent == 0;
    }

    fn trueSignificand(self: @This()) i114 {
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
};

pub fn isFixedPoint(comptime T: type) bool {
    return @hasDecl(T, "marker") and @TypeOf(T.marker) == Marker;
}

pub fn init(value: anytype) switch (@typeInfo(@TypeOf(value))) {
    .Int => FixedPoint(@TypeOf(value), 0),

    .ComptimeInt => FixedPoint(std.math.IntFittingRange(value, value), 0),

    .ComptimeFloat => blk: {
        const f128_value = @as(f128, value);

        if (!std.math.isFinite(f128_value)) {
            @compileError("Source value is not finite");
        }

        if (f128_value == 0) {
            break :blk FixedPoint(u0, 0);
        }

        const f128_fields = @bitCast(F128Fields, f128_value);
        const exponent_adjustment = @ctz(f128_fields.trueSignificand());
        const trimmed_significand = f128_fields.trueSignificand() >> exponent_adjustment;

        break :blk FixedPoint(
            std.math.IntFittingRange(trimmed_significand, trimmed_significand),
            f128_fields.trueExponent() + exponent_adjustment,
        );
    },

    else => if (isFixedPoint(@TypeOf(value)))
        @TypeOf(value)
    else
        @compileError("Unsupported type: " ++ @typeName(@TypeOf(value))),
} {
    return switch (@typeInfo(@TypeOf(value))) {
        .Int, .ComptimeInt => .{ .significand = value },

        .ComptimeFloat => comptime blk: {
            const f128_fields = @bitCast(F128Fields, @as(f128, value));
            const exponent_adjustment = @ctz(f128_fields.trueSignificand());
            const trimmed_significand = @as(comptime_int, f128_fields.trueSignificand() >> exponent_adjustment);
            break :blk .{ .significand = trimmed_significand };
        },

        else => value,
    };
}
