const std = @import("std");

const Allocator = std.mem.Allocator;

const system = @import("system/system.zig");

pub const Device = struct {
    fd: std.os.fd_t,

    pub fn init(fd: std.os.fd_t) @This() {
        return .{ .fd = fd };
    }

    pub const Version = struct {
        major: c_int,
        minor: c_int,
        patch: c_int,
        name: []const u8,
        date: []const u8,
        desc: []const u8,

        pub fn deinit(self: Version, allocator: Allocator) void {
            allocator.free(self.name);
            allocator.free(self.date);
            allocator.free(self.desc);
        }
    };

    pub fn getVersion(self: Device, allocator: Allocator) !Version {
        var version = std.mem.zeroes(system.Version);

        try system.ioctl(self.fd, system.ioctl_version, &version);

        const name = try allocator.alloc(u8, version.name_len);
        errdefer allocator.free(name);
        version.name = name.ptr;

        const date = try allocator.alloc(u8, version.date_len);
        errdefer allocator.free(date);
        version.date = date.ptr;

        const desc = try allocator.alloc(u8, version.desc_len);
        errdefer allocator.free(desc);
        version.desc = desc.ptr;

        try system.ioctl(self.fd, system.ioctl_version, &version);

        return .{
            .major = version.version_major,
            .minor = version.version_minor,
            .patch = version.version_patchlevel,
            .name = name,
            .date = date,
            .desc = desc,
        };
    }

    fn getCap(self: Device, cap: system.Cap) !u64 {
        var get_cap = system.GetCap{
            .capability = @intFromEnum(cap),
            .value = 0,
        };

        try system.ioctl(self.fd, system.ioctl_get_cap, &get_cap);

        return get_cap.value;
    }

    pub fn getSupportsDumbBuffers(self: Device) !bool {
        return (try self.getCap(.dumb_buffer)) == 1;
    }

    pub fn getDumbBufferPreferredBitDepth(self: Device) !u64 {
        return self.getCap(.dumb_preferred_depth);
    }

    pub fn getDumbBuffersPreferShadowBuffer(self: Device) !bool {
        return (try self.getCap(.dumb_prefer_shadow)) == 1;
    }

    pub fn getPRIMECapabilities(self: Device) !system.PrimeCap {
        return @bitCast(try self.getCap(.prime));
    }

    pub fn getSupportsAsyncPageFlip(self: Device) !bool {
        return (try self.getCap(.async_page_flip)) == 1;
    }

    pub fn getSupportsSyncObjects(self: Device) !bool {
        return (try self.getCap(.syncobj)) == 1;
    }

    pub fn getSupportsSyncObjectTimelineOperations(self: Device) !bool {
        return (try self.getCap(.syncobj_timeline)) == 1;
    }
};

pub const ModeResources = struct {
    fbs: []const Framebuffer,
    crtcs: []const Crtc,
    connectors: []const Connector,
    encoders: []const Encoder,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,

    pub fn deinit(self: @This(), allocator: Allocator) void {
        allocator.free(self.fbs);
        allocator.free(self.crtcs);
        allocator.free(self.connectors);
        allocator.free(self.encoders);
    }
};

pub const Framebuffer = packed struct {
    id: u32,

    pub const Info = struct {
        width: u32,
        height: u32,
    };
};

pub const Crtc = packed struct {
    id: u32,
};

pub const Connector = packed struct {
    id: u32,
};

pub const Encoder = packed struct {
    id: u32,
};

test {
    std.testing.refAllDeclsRecursive(@This());
}
