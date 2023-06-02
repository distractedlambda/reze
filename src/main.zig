pub fn main() !void {}

test {
    _ = @import("wasm.zig");
    _ = @import("ReadOnlyFileMapping.zig");
}
