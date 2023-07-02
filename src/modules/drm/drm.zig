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
    fbs: []const Framebuffer,
    crtcs: []const Crtc,
    connectors: []const Connector,
    encoders: []const Encoder,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,

    pub fn get(device: std.c.fd_t, allocator: std.mem.Allocator) !@This() {
        while (true) {
            var mcr = std.mem.zeroes(c.drm_mode_card_res);

            _ = try ioctl(device, c.DRM_IOCTL_MODE_GETRESOURCES, &mcr);

            const fbs = try allocator.alloc(Framebuffer, mcr.count_fbs);
            errdefer allocator.free(fbs);

            const crtcs = try allocator.alloc(Crtc, mcr.count_crtcs);
            errdefer allocator.free(crtcs);

            const connectors = try allocator.alloc(Connector, mcr.count_connectors);
            errdefer allocator.free(connectors);

            const encoders = try allocator.alloc(Encoder, mcr.count_encoders);
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

pub const Format = enum(u31) {
    c1 = c.DRM_FORMAT_C1,
    c2 = c.DRM_FORMAT_C2,
    c4 = c.DRM_FORMAT_C4,
    c8 = c.DRM_FORMAT_C8,

    d1 = c.DRM_FORMAT_D1,
    d2 = c.DRM_FORMAT_D2,
    d4 = c.DRM_FORMAT_D4,
    d8 = c.DRM_FORMAT_D8,

    r1 = c.DRM_FORMAT_R1,
    r2 = c.DRM_FORMAT_R2,
    r4 = c.DRM_FORMAT_R4,
    r8 = c.DRM_FORMAT_R8,
    r10 = c.DRM_FORMAT_R10,
    r12 = c.DRM_FORMAT_R12,
    r16 = c.DRM_FORMAT_R16,

    r8g8 = c.DRM_FORMAT_RG88,
    g8r8 = c.DRM_FORMAT_GR88,

    r16g16 = c.DRM_FORMAT_RG1616,
    g16r16 = c.DRM_FORMAT_GR1616,

    r3g3b2 = c.DRM_FORMAT_RGB332,
    b2g3r3 = c.DRM_FORMAT_BGR233,

    x4r4g4b4 = c.DRM_FORMAT_XRGB4444,
    x4b4g4r4 = c.DRM_FORMAT_XBGR4444,
    r4g4b4x4 = c.DRM_FORMAT_RGBX4444,
    b4g4r4x4 = c.DRM_FORMAT_BGRX4444,

    a4r4g4b4 = c.DRM_FORMAT_ARGB4444,
    a4b4g4r4 = c.DRM_FORMAT_ABGR4444,
    r4g4b4a4 = c.DRM_FORMAT_RGBA4444,
    b4g4r4a4 = c.DRM_FORMAT_BGRA4444,

    x1r5g5b5 = c.DRM_FORMAT_XRGB1555,
    x1b5g5r5 = c.DRM_FORMAT_XBGR1555,
    r5g5b5x1 = c.DRM_FORMAT_RGBX5551,
    b5g5r5x1 = c.DRM_FORMAT_BGRX5551,

    a1r5g5b5 = c.DRM_FORMAT_ARGB1555,
    a1b5g5r5 = c.DRM_FORMAT_ABGR1555,
    r5g5b5a1 = c.DRM_FORMAT_RGBA5551,
    b5g5r5a1 = c.DRM_FORMAT_BGRA5551,

    r5g6b5 = c.DRM_FORMAT_RGB565,
    b5g6r5 = c.DRM_FORMAT_BGR565,

    r8g8b8 = c.DRM_FORMAT_RGB888,
    b8g8r8 = c.DRM_FORMAT_BGR888,

    x8r8g8b8 = c.DRM_FORMAT_XRGB8888,
    x8b8g8r8 = c.DRM_FORMAT_XBGR8888,
    r8g8b8x8 = c.DRM_FORMAT_RGBX8888,
    b8g8r8x8 = c.DRM_FORMAT_BGRX8888,

    a8r8g8b8 = c.DRM_FORMAT_ARGB8888,
    a8b8g8r8 = c.DRM_FORMAT_ABGR8888,
    r8g8b8a8 = c.DRM_FORMAT_RGBA8888,
    b8g8r8a8 = c.DRM_FORMAT_BGRA8888,

    x2r10g10b10 = c.DRM_FORMAT_XRGB2101010,
    x2b10g10r10 = c.DRM_FORMAT_XBGR2101010,
    r10g10b10x2 = c.DRM_FORMAT_RGBX1010102,
    b10g10r10x2 = c.DRM_FORMAT_BGRX1010102,

    a2r10g10b10 = c.DRM_FORMAT_ARGB2101010,
    a2b10g10r10 = c.DRM_FORMAT_ABGR2101010,
    r10g10b10a2 = c.DRM_FORMAT_RGBA1010102,
    b10g10r10a2 = c.DRM_FORMAT_BGRA1010102,

    x16r16g16b16 = c.DRM_FORMAT_XRGB16161616,
    x16b16g16r16 = c.DRM_FORMAT_XBGR16161616,

    a16r16g16b16 = c.DRM_FORMAT_ARGB16161616,
    a16b16g16r16 = c.DRM_FORMAT_ABGR16161616,

    x16r16g16b16_f = c.DRM_FORMAT_XRGB16161616F,
    x16b16g16r16_f = c.DRM_FORMAT_XBGR16161616F,

    a16r16g16b16_f = c.DRM_FORMAT_ARGB16161616F,
    a16b16g16r16_f = c.DRM_FORMAT_ABGR16161616F,

    a10x6b10x6g10x6r10x6 = c.DRM_FORMAT_AXBXGXRX106106106106,

    yuyv = c.DRM_FORMAT_YUYV,
    yvyu = c.DRM_FORMAT_YVYU,
    uyvy = c.DRM_FORMAT_UYVY,
    vyuy = c.DRM_FORMAT_VYUY,

    ayuv = c.DRM_FORMAT_AYUV,
    a8v8u8y8 = c.DRM_FORMAT_AVUY8888,
    x8y8u8v8 = c.DRM_FORMAT_XYUV8888,
    x8v8u8y8 = c.DRM_FORMAT_XVUY8888,
    v8u8y8 = c.DRM_FORMAT_VUY888,
    v10u10y10 = c.DRM_FORMAT_VUY101010,

    y210 = c.DRM_FORMAT_Y210,
    y212 = c.DRM_FORMAT_Y212,
    y216 = c.DRM_FORMAT_Y216,

    _,
};

pub const EndianFormat = packed struct(u32) {
    format: Format,
    big_endian: bool,
};

pub const FormatModifier = enum(u64) {
    _,
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
