pub fn Ratio(comptime T: type) type {
    return struct {
        numerator: T,
        denominator: T,
    };
}
