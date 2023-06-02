const std = @import("std");

fd: std.os.fd_t,
contents: []align(std.mem.page_size) const u8,

pub fn open(path: []const u8) !@This() {
    const fd = try std.os.open(path, std.os.O.RDONLY, 0);
    errdefer std.os.close(fd);
    return .{
        .fd = fd,
        .contents = try std.os.mmap(
            null,
            @intCast(usize, (try std.os.fstat(fd)).size),
            std.os.PROT.READ,
            std.os.MAP.PRIVATE,
            fd,
            0,
        ),
    };
}

pub fn deinit(self: @This()) void {
    std.os.munmap(self.contents);
    std.os.close(self.fd);
}

test "ref all decls" {
    std.testing.refAllDecls(@This());
}
