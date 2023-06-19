pub fn translateCError(code: anytype, comptime c: type, comptime known_errors: anytype) !void {
    inline for (known_errors) |ke| {
        if (@hasDecl(c, ke[0]) and code == @field(c, ke[0])) {
            return ke[1];
        }
    }
}
