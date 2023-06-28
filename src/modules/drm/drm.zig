const builtin = @import("builtin");
const std = @import("std");

const c = @cImport({
    @cInclude("drm.h");
    @cInclude("sys/ioctl.h");
});

pub const Handle = packed struct(c_uint) { c_uint };

pub const Context = packed struct(c_uint) { c_uint };

pub const Drawable = packed struct(c_uint) { c_uint };

pub const Magic = packed struct(c_uint) { c_uint };

fn ioctl(fd: std.c.fd_t, request: c_ulong, arg: ?*anyopaque) !c_int {
    while (true) {
        // FIXME: is the ioctl signature wrong in std.c?
        // FIXME: `request` type differs between musl and glibc
        const rc = c.ioctl(fd, request, arg);
        return switch (std.c.getErrno(rc)) {
            .SUCCESS => rc,
            .INTR, .AGAIN => continue,
            .BADF => unreachable,
            .FAULT => unreachable,
            .ACCES => error.PermissionDenied,
            .INVAL => error.InvalidArgument,
            .NOTTY => error.InappropriateRequest,
            .OPNOTSUPP => error.NotSupported,
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
        var ext = std.mem.zeroes(c.drm_version_t);

        _ = try ioctl(device, c.DRM_IOCTL_VERSION, &ext);

        const name_len: usize = @intCast(ext.name_len);
        const date_len: usize = @intCast(ext.date_len);
        const desc_len: usize = @intCast(ext.desc_len);

        const name = try allocator.alloc(u8, name_len);
        errdefer allocator.free(name);

        const date = try allocator.alloc(u8, date_len);
        errdefer allocator.free(date);

        const desc = try allocator.alloc(u8, desc_len);
        errdefer allocator.free(desc);

        // FIXME: do we need an additional padding byte?
        ext.name = name.ptr;
        ext.date = date.ptr;
        ext.desc = desc.ptr;

        _ = try ioctl(device, c.DRM_IOCTL_VERSION, &ext);

        return .{
            .major = ext.version_major,
            .minor = ext.version_minor,
            .patch = ext.version_patchlevel,
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

pub const ModeResources = struct {
    fbs: []const u32,
    crtcs: []const u32,
    connectors: []const u32,
    encoders: []const u32,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,

    pub fn get(device: std.c.fd_t, allocator: std.mem.Allocator) !@This() {
        while (true) {
            var mcr = std.mem.zeroes(c.drm_mode_card_res);

            _ = try ioctl(device, c.DRM_IOCTL_MODE_GETRESOURCES, &mcr);

            const fbs = try allocator.alloc(u32, mcr.count_fbs);
            errdefer allocator.free(fbs);

            const crtcs = try allocator.alloc(u32, mcr.count_crtcs);
            errdefer allocator.free(crtcs);

            const connectors = try allocator.alloc(u32, mcr.count_connectors);
            errdefer allocator.free(connectors);

            const encoders = try allocator.alloc(u32, mcr.count_encoders);
            errdefer allocator.free(encoders);

            mcr.fb_id_ptr = @intFromPtr(fbs.ptr);
            mcr.crtc_id_ptr = @intFromPtr(crtcs.ptr);
            mcr.connector_id_ptr = @intFromPtr(connectors.ptr);
            mcr.encoder_id_ptr = @intFromPtr(encoders.ptr);

            _ = try ioctl(device, c.DRM_IOCTL_MODE_GETRESOURCES, &mcr);

            if (fbs.len < mcr.count_fbs or
                crtcs.len < mcr.count_crtcs or
                connectors.len < mcr.count_connectors or
                encoders.len < mcr.count_encoders)
            {
                allocator.free(fbs);
                allocator.free(crtcs);
                allocator.free(connectors);
                allocator.free(encoders);
                continue;
            }

            return .{
                .fbs = try allocator.realloc(fbs, mcr.count_fbs),
                .crtcs = try allocator.realloc(crtcs, mcr.count_crtcs),
                .connectors = try allocator.realloc(connectors, mcr.count_connectors),
                .encoders = try allocator.realloc(encoders, mcr.count_encoders),
                .min_width = mcr.min_width,
                .max_width = mcr.max_width,
                .min_height = mcr.min_height,
                .max_height = mcr.max_height,
            };
        }
    }

    pub fn deinit(self: @This(), allocator: std.mem.Allocator) void {
        allocator.free(self.fbs);
        allocator.free(self.crtcs);
        allocator.free(self.connectors);
        allocator.free(self.encoders);
    }
};

pub fn getBusId(device: std.c.fd_t, allocator: std.mem.Allocator) ![]const u8 {
    var ext = std.mem.zeroes(c.drm_unique_t);
    _ = try ioctl(device, c.DRM_IOCTL_GET_UNIQUE, &ext);
    const id = try allocator.alloc(u8, ext.unique_len);
    errdefer allocator.free(id);
    ext.unique = id.ptr;
    _ = try ioctl(device, c.DRM_IOCTL_GET_UNIQUE, &ext);
    return id;
}

pub fn getMagic(device: std.c.fd_t) !c.drm_magic_t {
    var auth = std.mem.zeroes(c.drm_auth_t);
    _ = try ioctl(device, c.DRM_IOCTL_GET_MAGIC, &auth);
    return auth.magic;
}

pub fn authMagic(device: std.c.fd_t, magic: c.drm_magic_t) !void {
    var auth = c.drm_auth_t{ .magic = magic };
    _ = try ioctl(device, c.DRM_IOCTL_AUTH_MAGIC, &auth);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
