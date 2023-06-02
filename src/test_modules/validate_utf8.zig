const std = @import("std");

comptime {
    _ = @import("export_allocator.zig");
}

export fn validateUtf8(start: [*]const u8, len: usize) bool {
    return std.unicode.utf8ValidateSlice(start[0..len]);
}
