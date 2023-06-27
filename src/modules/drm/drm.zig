const builtin = @import("builtin");
const std = @import("std");

const c = @cImport({
    @cInclude("xf86drm.h");
    @cInclude("sys/ioctl.h");
});

pub const Handle = packed struct(c_uint) { c_uint };

pub const Context = packed struct(c_uint) { c_uint };

pub const Drawable = packed struct(c_uint) { c_uint };

pub const Magic = packed struct(c_uint) { c_uint };

fn ioctl(fd: std.c.fd_t, comptime request: c_ulong, arg: ?*anyopaque) !c_int {
    while (true) {
        // FIXME: is the ioctl signature wrong in std.c?
        // FIXME: `request` type differs between musl and glibc
        const rc = c.ioctl(fd, request, arg);
        return switch (std.c.getErrno(rc)) {
            .SUCCESS => rc,
            .INTR, .AGAIN => continue,
            .BADF => unreachable,
            .FAULT => unreachable,
            .INVAL => error.Inval,
            .NOTTY => error.NoTty,
            else => |e| std.os.unexpectedErrno(e),
        };
    }
}

pub const Version = struct {
    major: c_int,
    minor: c_int,
    patch: c_int,
    name: []const u8,
    date: []const u8,
    desc: []const u8,

    pub fn get(device: std.c.fd_t, allocator: std.mem.Allocator) !@This() {
        var extern_version = std.mem.zeroes(c.drm_version_t);

        _ = try ioctl(device, c.DRM_IOCTL_VERSION, &extern_version);

        const name_len: usize = @intCast(extern_version.name_len);
        const date_len: usize = @intCast(extern_version.date_len);
        const desc_len: usize = @intCast(extern_version.desc_len);

        const name = try allocator.alloc(u8, name_len);
        errdefer allocator.free(name);

        const date = try allocator.alloc(u8, date_len);
        errdefer allocator.free(date);

        const desc = try allocator.alloc(u8, desc_len);
        errdefer allocator.free(desc);

        // FIXME: do we need an additional padding byte?
        extern_version.name = name.ptr;
        extern_version.date = date.ptr;
        extern_version.desc = desc.ptr;

        _ = try ioctl(device, c.DRM_IOCTL_VERSION, &extern_version);

        return .{
            .major = extern_version.version_major,
            .minor = extern_version.version_minor,
            .patch = extern_version.version_patchlevel,
            .name = name,
            .date = date,
            .desc = desc,
        };
    }

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.date);
        allocator.free(self.desc);
    }
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
