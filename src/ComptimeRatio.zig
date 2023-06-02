const std = @import("std");

numerator: comptime_int,
denominator: comptime_int,

pub fn init(comptime numerator: comptime_int, comptime denominator: comptime_int) @This() {
    const gcd = std.math.gcd(numerator, denominator);
    return .{
        .numerator = numerator / gcd,
        .denominator = denominator / gcd,
    };
}

pub fn add(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return init(
        lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator,
        lhs.denominator * rhs.denominator,
    );
}

pub fn sub(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return init(
        lhs.numerator * rhs.denominator - rhs.numerator * lhs.denominator,
        lhs.denominator * rhs.denominator,
    );
}

pub fn mul(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return init(
        lhs.numerator * rhs.numerator,
        lhs.denominator * rhs.denominator,
    );
}

pub fn div(comptime lhs: @This(), comptime rhs: @This()) @This() {
    return init(
        lhs.numerator * rhs.denominator,
        lhs.denominator * rhs.numerator,
    );
}
