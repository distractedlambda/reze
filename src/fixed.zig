const std = @import("std");

pub fn Fixed(comptime Sig: type, comptime exp: comptime_int) type {
    return struct {
        significand: Sig,

        const traits = Traits{
            .significand = Sig,
            .exponent = exp,
        };

        pub inline fn fromLiteral(comptime value: anytype) @This() {
            return .{
                .significand = comptime blk: {
                    switch (@typeInfo(@TypeOf(value))) {
                        .ComptimeInt, .Int => {
                            break :blk if (exp > 0)
                                @divExact(value, 1 << exp)
                            else
                                value << -exp;
                        },

                        .ComptimeFloat, .Float => {
                            const f128_value = @as(f128, value);

                            if (!std.math.isFinite(f128_value)) {
                                @compileError("Supplied value is not finite");
                            }

                            const f128_bits = @bitCast(u128, f128_value);
                            const f128_stored_exp = @as(comptime_int, @truncate(u15, f128_bits >> 112));
                            const f128_mant = @as(comptime_int, @truncate(u112, f128_bits));
                            const f128_sign = if (f128_bits >> 127 != 0) -1 else 1;
                            const f128_sig = f128_sign * (f128_mant + (if (f128_stored_exp != 0) 1 << 112 else 0));
                            const eff_exp = (if (f128_stored_exp == 0) -16494 else f128_stored_exp - 16495) - exp;

                            break :blk if (eff_exp >= 0)
                                f128_sig << eff_exp
                            else
                                @divExact(f128_sig, 1 << -eff_exp);
                        },

                        else => @compileError("Unsupported type: " ++ @typeName(@TypeOf(value))),
                    }
                },
            };
        }
    };
}

const Traits = struct {
    significand: type,
    exponent: comptime_int,
};

pub fn isFixed(comptime T: type) bool {
    return comptime @hasDecl(T, "traits") and @TypeOf(T.traits) != Traits;
}

fn checkIsFixed(comptime T: type) void {
    if (comptime !isFixed(T)) {
        @compileError("The type '" ++ @typeName(T) ++ "' is not a Fixed(...) type");
    }
}

pub fn Significand(comptime T: type) type {
    checkIsFixed(T);
    return T.traits.significand;
}

pub fn exponent(comptime T: type) comptime_int {
    checkIsFixed(T);
    return comptime T.traits.exponent;
}
