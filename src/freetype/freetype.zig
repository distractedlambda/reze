const common = @import("common");
const std = @import("std");

const c = @import("c.zig");
const err = @import("err.zig");
pub const Error = err.Error;

const FixedPoint = common.FixedPoint;

pub const PixelMode = enum(u8) {
    none = c.FT_PIXEL_MODE_NONE,
    mono = c.FT_PIXEL_MODE_MONO,
    gray = c.FT_PIXEL_MODE_GRAY,
    gray2 = c.FT_PIXEL_MODE_GRAY2,
    gray4 = c.FT_PIXEL_MODE_GRAY4,
    lcd = c.FT_PIXEL_MODE_LCD,
    lcd_v = c.FT_PIXEL_MODE_LCD_V,
    bgra = c.FT_PIXEL_MODE_BGRA,
    _,
};

pub const Encoding = enum(c_int) {
    ms_symbol = c.FT_ENCODING_MS_SYMBOL,
    unicode = c.FT_ENCODING_UNICODE,
    sjis = c.FT_ENCODING_SJIS,
    prc = c.FT_ENCODING_PRC,
    big5 = c.FT_ENCODING_BIG5,
    wansung = c.FT_ENCODING_WANSUNG,
    johab = c.FT_ENCODING_JOHAB,
    adobe_standard = c.FT_ENCODING_ADOBE_STANDARD,
    adobe_expert = c.FT_ENCODING_ADOBE_EXPERT,
    adobe_custom = c.FT_ENCODING_ADOBE_CUSTOM,
    adobe_latin_1 = c.FT_ENCODING_ADOBE_LATIN_1,
    old_latin_2 = c.FT_ENCODING_OLD_LATIN_2,
    apple_roman = c.FT_ENCODING_APPLE_ROMAN,
    _,
};

pub const c_memory = blk: {
    const fns = struct {
        fn alloc(_: *c.FT_MemoryRec_, size: c_long) callconv(.C) ?*anyopaque {
            return std.c.malloc(@intCast(usize, size));
        }

        fn free(_: *c.FT_MemoryRec_, block: ?*anyopaque) callconv(.C) void {
            std.c.free(block);
        }

        fn realloc(
            _: *c.FT_MemoryRec_,
            _: c_long,
            new_size: c_long,
            block: ?*anyopaque,
        ) callconv(.C) ?*anyopaque {
            return std.c.realloc(block, new_size);
        }
    };

    break :blk c.FT_MemoryRec_{
        .user = null,
        .alloc = &fns.alloc,
        .free = &fns.free,
        .realloc = &fns.realloc,
    };
};

const OpenArgs = extern struct {
    flags: Flags = .{},
    memory_base: ?[*]const u8 = null,
    memory_size: c_long = 0,
    pathname: ?[*:0]const u8 = null,
    stream: ?*c.FT_StreamRec = null,
    driver: ?*c.FT_ModuleRec_ = null,
    num_params: c_int = 0,
    params: ?[*]const c.FT_Parameter = null,

    const Flags = packed struct(c_uint) {
        memory: bool = false,
        stream: bool = false,
        pathname: bool = false,
        driver: bool = false,
        params: bool = false,
        _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_uint) - 5),
    };

    fn fillInSource(self: *OpenArgs, source: FaceSource) void {
        switch (source) {
            .memory => |m| {
                self.flags.memory = true;
                self.memory_base = m.ptr;
                self.memory_size = @intCast(c_long, m.len);
            },

            .stream => |s| {
                self.flags.stream = true;
                self.stream = s;
            },

            .path => |p| {
                self.flags.pathname = true;
                self.pathname = p;
            },
        }
    }

    fn fillInDriver(self: *OpenArgs, driver: ?*Driver) void {
        if (driver) |d| {
            self.flags.driver = true;
            self.driver = d;
        }
    }

    fn fillInParams(self: *OpenArgs, params: []const c.FT_Parameter) void {
        if (params.len != 0) {
            self.flags.params = true;
            self.num_params = @intCast(c_int, params.len);
            self.params = params.ptr;
        }
    }
};

pub const FaceSource = union(enum) {
    memory: []const u8,
    stream: *c.FT_StreamRec,
    path: [*:0]const u8,
};

pub const Library = opaque {
    extern fn FT_New_Library(*Memory, *?*Library) c_int;

    extern fn FT_Add_Default_Modules(*Library) void;

    extern fn FT_Set_Default_Properties(*Library) void;

    pub const CreateOptions = struct {
        memory: *Memory = @constCast(&c_memory),
    };

    pub fn new(options: CreateOptions) Error!*Library {
        var lib: ?*Library = null;
        try checkError(FT_New_Library(options.memory, &lib));
        const result = lib.?;
        FT_Add_Default_Modules(result);
        FT_Set_Default_Properties(result);
        return result;
    }

    extern fn FT_Done_Library(*Library) c_int;

    pub fn done(self: *Library) Error!void {
        return checkError(FT_Done_Library(self));
    }

    extern fn FT_Open_Face(*Library, *const OpenArgs, face_index: c_long, *?*Face) c_int;

    pub const OpenFaceOptions = struct {
        source: FaceSource,
        face_index: u16 = 0,
        named_instance_index: u15 = 0,
        driver: ?*Driver = null,
        params: []const Parameter = &.{},
    };

    pub fn openFace(self: *Library, options: OpenFaceOptions) Error!*Face {
        var result: ?*Face = null;
        var args = OpenArgs{};
        args.fillInSource(options.source);
        args.fillInDriver(options.driver);
        args.fillInParams(options.params);
        const index = (@as(u31, options.named_instance_index) << 16) | options.face_index;
        try checkError(FT_Open_Face(self, &args, index, &result));
        return result.?;
    }
};

pub const GlyphSlot = extern struct {
    library: *Library,
    face: *Face,
    next: ?*GlyphSlot,
    glyph_index: c_uint,
    generic: Generic,

    metrics: GlyphMetrics,
    linear_hori_advance: c_long,
    linear_vert_advance: c_long,
    advance: Vector,

    format: GlyphFormat,

    bitmap: Bitmap,
    bitmap_left: c_int,
    bitmap_top: c_int,

    outline: Outline,

    num_subglyphs: c_uint,
    subglyphs: *SubGlyph,

    control_data: ?*anyopaque,
    control_len: c_long,

    lsb_delta: c_long,
    rsb_delta: c_long,

    other: ?*anyopaque,

    internal: ?*Internal,

    pub const Internal = opaque {};
};

pub const SubGlyph = opaque {};

pub const GlyphMetrics = extern struct {
    width: c_long,
    height: c_long,

    hori_bearing_x: c_long,
    hori_breaing_y: c_long,
    hori_advance: c_long,

    vert_bearing_x: c_long,
    vert_bearing_y: c_long,
    vert_advance: c_long,
};

pub const GlyphFormat = enum(u32) {
    composite = makeTag("comp"),
    bitmap = makeTag("bits"),
    outline = makeTag("outl"),
    plotter = makeTag("plot"),
    svg = makeTag("SVG "),
    _,
};

pub const Outline = extern struct {
    n_contours: c_short,
    n_points: c_short,

    points: ?[*]Vector,
    tags: ?[*]Tag,
    contours: ?[*]c_short,

    flags: Flags,

    pub const Tag = packed struct(u8) {
        on_curve: bool,
        third_order_bezier: bool,
        has_dropout_mode: bool,
        _reserved: u2,
        dropout_mode: u3,
    };

    pub const Flags = packed struct(c_int) {
        owner: bool,
        even_odd_fill: bool,
        reverse_fill: bool,
        ignore_dropouts: bool,
        smart_dropouts: bool,
        include_stubs: bool,
        overlap: bool,
        _reserved0: u1,
        high_precision: bool,
        single_pass: bool,
        _reserved1: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 10),
    };
};

pub const Size = extern struct {
    face: *Face,
    generic: Generic,
    metrics: Metrics,
    internal: ?*Internal,

    pub const Metrics = extern struct {
        x_ppem: c_ushort,
        y_ppem: c_ushort,

        x_scale: c_long,
        y_scale: c_long,

        ascender: c_long,
        descender: c_long,
        height: c_long,
        max_advance: c_long,
    };

    pub const Internal = opaque {};
};

pub const Driver = opaque {};

pub const List = extern struct {
    head: ?*Node,
    tail: ?*Node,

    pub const Node = extern struct {
        prev: ?*Node,
        next: ?*Node,
        data: ?*anyopaque,
    };
};

pub const Face = extern struct {
    num_faces: c_long,
    face_index: c_long,

    face_flags: c_long,
    style_flags: c_long,

    num_glyphs: c_long,

    family_name: ?[*:0]const u8,
    style_name: ?[*:0]const u8,

    num_fixed_sizes: c_int,
    available_sizes: ?[*]BitmapSize,

    num_charmaps: c_int,
    charmaps: ?[*]CharMap,

    generic: Generic,

    bbox: Bbox,

    units_per_em: c_ushort,
    ascender: c_short,
    descender: c_short,
    height: c_short,

    max_advance_width: c_short,
    max_advance_height: c_short,

    underline_position: c_short,
    underline_thickness: c_short,

    glyph: ?*GlyphSlot,
    size: ?*Size,
    charmap: ?*CharMap,

    driver: ?*Driver,
    memory: ?*Memory,
    stream: ?*Stream,

    sizes_list: List,

    autohint: Generic,
    extensions: ?*anyopaque,

    internal: ?*Internal,

    pub const Internal = opaque {};

    extern fn FT_Done_Face(*Face) c_int;

    pub fn done(self: *Face) Error!void {
        return checkError(FT_Done_Face(self));
    }

    extern fn FT_Attach_Stream(*Face, *const OpenArgs) c_int;

    pub fn attachSource(self: *Face, source: FaceSource) Error!void {
        var args = OpenArgs{};
        args.fillInSource(source);
        return checkError(FT_Attach_Stream(self, &args));
    }

    extern fn FT_Set_Char_Size(
        *Face,
        char_width: c_long,
        char_height: c_long,
        horz_resolution: c_uint,
        vert_resolution: c_uint,
    ) c_int;

    pub fn setCharSize(
        self: *Face,
        width: FixedPoint(.signed, 26, 6),
        height: FixedPoint(.signed, 26, 6),
        horz_dpi: c_uint,
        vert_dpi: c_uint,
    ) Error!void {
        return checkError(FT_Set_Char_Size(self, width.repr, height.repr, horz_dpi, vert_dpi));
    }

    extern fn FT_Set_Pixel_Sizes(*Face, pixel_width: c_uint, pixel_height: c_uint) c_int;

    pub fn setPixelSizes(self: *Face, width: c_uint, height: c_uint) Error!void {
        return checkError(FT_Set_Pixel_Sizes(self, width, height));
    }

    pub const LoadFlags = packed struct(u32) {
        no_scale: bool = false,
        no_hinting: bool = false,
        render: bool = false,
        no_bitmap: bool = false,
        vertical_layout: bool = false,
        force_autohint: bool = false,
        crop_bitmap: bool = false,
        pedantic: bool = false,
        _reserved0: u1 = 0,
        ignore_global_advance_width: bool = false,
        no_recurse: bool = false,
        ignore_transform: bool = false,
        monochrome: bool = false,
        linear_design: bool = false,
        sbits_only: bool = false,
        no_autohint: bool = false,
        target: Target = .normal,
        color: bool = false,
        compute_metrics: bool = false,
        bitmap_metrics_only: bool = false,
        _reserved1: u9 = 0,

        pub const Target = enum(u4) {
            normal = c.FT_RENDER_MODE_NORMAL,
            light = c.FT_RENDER_MODE_LIGHT,
            mono = c.FT_RENDER_MODE_MONO,
            lcd = c.FT_RENDER_MODE_LCD,
            lcd_v = c.FT_RENDER_MODE_LCD_V,
        };
    };

    pub fn loadGlyph(self: *Face, glyph_index: c_uint, flags: LoadFlags) Error!void {
        return err.check(c.FT_Load_Glyph(self.raw(), glyph_index, @bitCast(c.FT_Int32, flags)));
    }

    pub fn getCharIndex(self: *Face, charcode: c_ulong) c_uint {
        return c.FT_Get_Char_index(self.raw(), charcode);
    }

    pub fn loadChar(self: *Face, charcode: c_ulong, flags: LoadFlags) Error!void {
        return err.check(c.FT_Load_Char(self.raw(), charcode, @bitCast(c.FT_Int32, flags)));
    }
};
