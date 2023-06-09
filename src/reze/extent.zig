pub fn Extent(comptime n_dims: comptime_int, comptime T: type) type {
    return struct {
        start: [n_dims]T,
        size: [n_dims]T,
    };
}
