const std = @import("std");

fn code(comptime name: *const [4]u8) comptime_int {
    return std.mem.readIntLittle(u32, name);
}

pub const Format = enum(u31) {
    c1 = code("C1  "),
    c2 = code("C2  "),
    c4 = code("C4  "),
    c8 = code("C8  "),

    d1 = code("D1  "),
    d2 = code("D2  "),
    d4 = code("D4  "),
    d8 = code("D8  "),

    r1 = code("R1  "),
    r2 = code("R2  "),
    r4 = code("R4  "),
    r8 = code("R8  "),
    r10 = code("R10 "),
    r12 = code("R12 "),
    r16 = code("R16 "),

    rg88 = code("RG88"),
    gr88 = code("GR88"),

    rg1616 = code("RG32"),
    gr1616 = code("GR32"),

    rgb332 = code("RGB8"),
    bgr233 = code("BGR8"),

    xrgb4444 = code("XR12"),
    xbgr4444 = code("XB12"),
    rgbx4444 = code("RX12"),
    bgrx4444 = code("BX12"),

    argb4444 = code("AR12"),
    abgr4444 = code("AB12"),
    rgba4444 = code("RA12"),
    bgra4444 = code("BA12"),

    xrgb1555 = code("XR15"),
    xbgr1555 = code("XB15"),
    rgbx5551 = code("RX15"),
    bgrx5551 = code("BX15"),

    argb1555 = code("AR15"),
    abgr1555 = code("AB15"),
    rgba5551 = code("RA15"),
    bgra5551 = code("BA15"),

    rgb565 = code("RG16"),
    bgr565 = code("BG16"),

    rgb888 = code("RG24"),
    bgr888 = code("BG24"),

    xrgb8888 = code("XR24"),
    xbgr8888 = code("XB24"),
    rgbx8888 = code("RX24"),
    bgrx8888 = code("BX24"),

    argb8888 = code("AR24"),
    abgr8888 = code("AB24"),
    rgba8888 = code("RA24"),
    bgra8888 = code("BA24"),

    xrgb2101010 = code("XR30"),
    xbgr2101010 = code("XB30"),
    rgbx1010102 = code("RX30"),
    bgrx1010102 = code("BX30"),

    argb2101010 = code("AR30"),
    abgr2101010 = code("AB30"),
    rgba1010102 = code("RA30"),
    bgra1010102 = code("BA30"),

    xrgb16161616 = code("XR48"),
    xbgr16161616 = code("XB48"),

    argb16161616 = code("AR48"),
    abgr16161616 = code("AB48"),

    xrgb16161616f = code("XR4H"),
    xbgr16161616f = code("XB4H"),

    argb16161616f = code("AR4H"),
    abgr16161616f = code("AB4H"),

    axbxgxrx106106106106 = code("AB10"),

    yuyv = code("YUYV"),
    yvyu = code("YVYU"),
    uyvy = code("UYVY"),
    vyuy = code("VYUY"),

    ayuv = code("AYUV"),
    avuy8888 = code("AVUY"),
    xyuv8888 = code("XYUV"),
    xvuy8888 = code("XVUY"),
    vuy888 = code("VU24"),
    vuy101010 = code("VU30"),

    y210 = code("Y210"),
    y212 = code("Y212"),
    y216 = code("Y216"),

    y410 = code("Y410"),
    y412 = code("Y412"),
    y416 = code("Y416"),

    xvyu2101010 = code("XV30"),
    xvyu12_16161616 = code("XV36"),
    xvyu16161616 = code("XV48"),

    y0l0 = code("Y0L0"),
    x0l0 = code("X0L0"),

    y0l2 = code("Y0L2"),
    x0l2 = code("X0L2"),

    yuv420_8bit = code("YU08"),
    yuv420_10bit = code("YU10"),

    xrgb8888_a8 = code("XRA8"),
    xbgr8888_a8 = code("XBA8"),
    rgbx8888_a8 = code("RXA8"),
    bgrx8888_a8 = code("BXA8"),

    rgb888_a8 = code("R8A8"),
    bgr888_a8 = code("B8A8"),
    rgb565_a8 = code("R5A8"),
    bgr565_a8 = code("B5A8"),

    nv12 = code("NV12"),
    nv21 = code("NV21"),
    nv16 = code("NV16"),
    nv61 = code("NV61"),
    nv24 = code("NV24"),
    nv42 = code("NV42"),
    nv15 = code("NV15"),

    p210 = code("P210"),
    p010 = code("P010"),
    p012 = code("P012"),
    p016 = code("P016"),
    p030 = code("P030"),

    q410 = code("Q410"),
    q401 = code("Q401"),

    yuv410 = code("YUV9"),
    yvu410 = code("YVU9"),
    yuv411 = code("YU11"),
    yvu411 = code("YV11"),
    yuv420 = code("YU12"),
    yvu420 = code("YV12"),
    yuv422 = code("YU16"),
    yvu422 = code("YV16"),
    yuv444 = code("YU24"),
    yvu444 = code("YV24"),

    _,
};

pub const EndianFormat = packed struct(u32) {
    format: Format,
    big_endian: bool,
};

pub const FormatModifier = packed struct(u64) {
    value: Value,
    vendor: Vendor,

    pub const Value = packed union {
        linear: void,
        intel: Intel,
        amd: Amd,
        nvidia: Nvidia,
        samsung: Samsung,
        qcom: Qcom,
        vivante: Vivante,
        broadcom: Broadcom,
        arm: Arm,
        allwinner: Allwinner,
        amlogic: Amlogic,

        pub const Intel = enum(u56) {
            x_tiled = 1,
            y_tiled,
            yf_tiled,
            y_tiled_ccs,
            yf_tiled_ccs,
            y_tiled_gen12_rc_ccs,
            y_tiled_gen12_mc_ccs,
            y_tiled_gen12_rc_ccs_cc,
            @"4_tiled",
            @"4_tiled_dg2_rc_ccs",
            @"4_tiled_dg2_mc_ccs",
            @"4_tiled_dg2_rc_ccs_cc",
            _,
        };

        pub const Amd = u56; // TODO

        pub const Nvidia = u56; // TODO

        pub const Samsung = enum(u56) {
            @"64_32_tile" = 1,
            @"16_16_tile",
            _,
        };

        pub const Qcom = enum(u56) {
            compressed = 1,
            tiled2,
            tiled3,
            _,
        };

        pub const Vivante = packed struct(u56) {
            layout: Layout,
            tile_status: TileStatus,
            compression: Compression,

            pub const Layout = enum(u48) {
                tiled = 1,
                super_tiled,
                split_tiled,
                split_super_tiled,
                _,
            };

            pub const TileStatus = enum(u4) {
                none,
                @"64_4",
                @"64_2",
                @"128_4",
                @"256_4",
                _,
            };

            pub const Compression = enum(u4) {
                none,
                dec400,
                _,
            };
        };

        pub const Broadcom = packed struct(u56) {
            type: Type,
            parameters: u48,

            pub const Type = enum(u8) {
                vc4_t_tiled = 1,
                sand32,
                sand64,
                sand128,
                sand256,
                uif,
                _,
            };
        };

        pub const Arm = u56; // TODO

        pub const Allwinner = u56; // TODO

        pub const Amlogic = u56; // TODO
    };

    pub const Vendor = enum(u8) {
        none,
        intel,
        amd,
        nvidia,
        samsung,
        qcom,
        vivante,
        broadcom,
        arm,
        allwinner,
        amlogic,
        _,
    };
};
