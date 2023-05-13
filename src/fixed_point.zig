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

                    const f128_bits = @bitCast(u128, f128_value);
                    const f128_stored_exp = @as(comptime_int, @truncate(u15, f128_bits >> 112));
                    const f128_mant = @as(comptime_int, @truncate(u112, f128_bits));
                    const f128_sign = if (f128_bits >> 127 != 0) -1 else 1;
                    const f128_sig = f128_sign * (f128_mant + (if (f128_stored_exp != 0) 1 << 112 else 0));
                    const eff_exp = (if (f128_stored_exp == 0) -16494 else f128_stored_exp - 16495) - exponent;

                    break :blk if (eff_exp >= 0)
                        f128_sig << eff_exp
                    else
                        @divExact(f128_sig, 1 << -eff_exp);
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

pub fn isFixedPoint(comptime T: type) bool {
    return @hasDecl(T, "marker") and @TypeOf(T.marker) == Marker;
}
