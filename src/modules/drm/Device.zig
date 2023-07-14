const std = @import("std");
const Allocator = std.mem.Allocator;

const system = @import("system/system.zig");

const Device = @This();

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
    var get_cap = system.GetCap{ .capability = cap, .value = 0 };
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

pub const Framebuffer = packed struct {
    id: u32,

    pub const Info = struct {
        width: u32,
        height: u32,
        pitch: u32,
        bpp: u32,
        depth: u32,
        handle: u32,
    };
};

pub const Crtc = packed struct {
    id: u32,

    pub const Info = struct {
        framebuffer: Framebuffer,
        x: u32,
        y: u32,
        gamma_size: u32,
        mode: ?system.ModeModeinfo,
    };
};

pub const Connector = packed struct {
    id: u32,
};

pub const Encoder = packed struct {
    id: u32,

    pub const Info = struct {
        type: system.EncoderType,
        crtc: Crtc,
        possible_crtcs: u32,
        possible_clones: u32,
    };
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

    pub fn deinit(self: ModeResources, allocator: Allocator) void {
        allocator.free(self.fbs);
        allocator.free(self.crtcs);
        allocator.free(self.connectors);
        allocator.free(self.encoders);
    }
};

pub fn getModeResources(self: Device, allocator: Allocator) !ModeResources {
    while (true) {
        var resources = std.mem.zeroes(system.ModeCardRes);

        try system.ioctl(self.fd, system.ioctl_mode_getresources, &resources);

        var fbs = try allocator.alloc(Framebuffer, resources.count_fbs);
        errdefer allocator.free(fbs);
        resources.fb_id_ptr = @intFromPtr(fbs.ptr);

        var crtcs = try allocator.alloc(Crtc, resources.count_crtcs);
        errdefer allocator.free(crtcs);
        resources.crtc_id_ptr = @intFromPtr(crtcs.ptr);

        var connectors = try allocator.alloc(Connector, resources.count_connectors);
        errdefer allocator.free(connectors);
        resources.connector_id_ptr = @intFromPtr(connectors.ptr);

        var encoders = try allocator.alloc(Encoder, resources.count_encoders);
        errdefer allocator.free(encoders);
        resources.encoder_id_ptr = @intFromPtr(encoders.ptr);

        try system.ioctl(self.fd, system.ioctl_mode_getresources, &resources);

        if (fbs.len < resources.count_fbs or
            crtcs.len < resources.count_crtcs or
            connectors.len < resources.count_connectors or
            encoders.len < resources.count_encoders)
        {
            allocator.free(fbs);
            allocator.free(crtcs);
            allocator.free(connectors);
            allocator.free(encoders);
            continue;
        }

        fbs = try allocator.realloc(fbs, resources.count_fbs);
        crtcs = try allocator.realloc(crtcs, resources.count_crtcs);
        connectors = try allocator.realloc(connectors, resources.count_connectors);
        encoders = try allocator.realloc(encoders, resources.count_encoders);

        return .{
            .fbs = fbs,
            .crtcs = crtcs,
            .connectors = connectors,
            .encoders = encoders,
            .min_width = resources.min_width,
            .max_width = resources.max_width,
            .min_height = resources.min_height,
            .max_height = resources.max_height,
        };
    }
}

pub fn getFramebufferInfo(self: Device, fb: Framebuffer) !Framebuffer.Info {
    var info = std.mem.zeroes(system.ModeFbCmd);

    info.fb_id = fb.id;

    try system.ioctl(self.fd, system.ioctl_mode_getfb, &info);

    return .{
        .width = info.width,
        .height = info.height,
        .pitch = info.pitch,
        .bpp = info.bpp,
        .depth = info.depth,
        .handle = info.handle,
    };
}

pub fn getCrtcInfo(self: Device, crtc: Crtc) !Crtc.Info {
    var mode_crtc = std.mem.zeroes(system.ModeCrtc);

    mode_crtc.crtc_id = crtc.id;

    try system.ioctl(self.fd, system.ioctl_mode_getcrtc, &mode_crtc);

    return .{
        .framebuffer = .{ .id = mode_crtc.fb_id },
        .x = mode_crtc.x,
        .y = mode_crtc.y,
        .gamma_size = mode_crtc.gamma_size,
        .mode = if (mode_crtc.mode_valid != 0) mode_crtc.mode else null,
    };
}

pub fn getEncoderInfo(self: Device, encoder: Encoder) !Encoder.Info {
    var get_encoder = std.mem.zeroes(system.ModeGetEncoder);

    get_encoder.encoder_id = encoder.id;

    try system.ioctl(self.fd, system.ioctl_mode_getencoder, &get_encoder);

    return .{
        .type = get_encoder.encoder_type,
        .crtc = .{ .id = get_encoder.crtc_id },
        .possible_crtcs = get_encoder.possible_crtcs,
        .possible_clones = get_encoder.possible_clones,
    };
}
