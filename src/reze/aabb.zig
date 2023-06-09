pub fn Aabb(comptime n_dims: comptime_int, comptime T: type) type {
    return struct {
        min: [n_dims]T,
        max: [n_dims]T,
    };
}
