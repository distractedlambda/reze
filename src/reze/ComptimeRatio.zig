const std = @import("std");

numerator: comptime_int,
denominator: comptime_int,

pub fn init(comptime numerator: comptime_int, comptime denominator: comptime_int) @This() {
    var n = numerator;
    var d = denominator;

    if (d < 0) {
        n = -n;
        d = -d;
    }

    const gcd = std.math.gcd(std.math.absCast(n), std.math.absCast(d));

    return .{
        .numerator = @divExact(n, gcd),
        .denominator = @divExact(d, gcd),
    };
}

pub fn from(comptime value: anytype) @This() {
    return switch (@typeInfo(@TypeOf(value))) {
        .Int, .ComptimeInt => init(value, 1),

        .Float, .ComptimeFloat => @compileError("TODO implement conversion from floats"),

        else => if (@TypeOf(value) == @This())
            value
        else
            @compileError("unsupported type: " ++ @typeName(@TypeOf(value))),
    };
}

pub fn neg(comptime self: @This()) @This() {
    return init(-self.numerator, self.denominator);
}

pub fn recip(comptime self: @This()) @This() {
    return init(self.denominator, self.numerator);
}

pub fn add(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return init(
        lhs.numerator * rhs.denominator + lhs.denominator * rhs.numerator,
        lhs.denominator * rhs.denominator,
    );
}

pub fn sub(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return add(lhs, rhs.neg());
}

pub fn mul(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return init(
        lhs.numerator * rhs.numerator,
        lhs.denominator * rhs.denominator,
    );
}

pub fn div(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return mul(lhs, rhs.recip());
}
