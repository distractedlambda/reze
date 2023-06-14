const std = @import("std");

const FixedPoint = @import("../scaled_int.zig").FixedPoint;

pub const Error = error{
    CannotOpenResource,
    UnknownFileFormat,
    InvalidFileFormat,
    InvalidVersion,
    LowerModuleVersion,
    InvalidArgument,
    UnimplementedFeature,
    InvalidTable,
    InvalidOffset,
    ArrayTooLarge,
    MissingModule,
    MissingProperty,
    InvalidGlyphIndex,
    InvalidCharacterCode,
    InvalidGlyphFormat,
    CannotRenderGlyph,
    InvalidOutline,
    InvalidComposite,
    TooManyHints,
    InvalidPixelSize,
    InvalidSVGDocument,
    InvalidHandle,
    InvalidLibraryHandle,
    InvalidDriverHandle,
    InvalidFaceHandle,
    InvalidSizeHandle,
    InvalidSlotHandle,
    InvalidCharMapHandle,
    InvalidCacheHandle,
    InvalidStreamHandle,
    TooManyDrivers,
    TooManyExtensions,
    OutOfMemory,
    UnlistedObject,
    CannotOpenStream,
    InvalidStreamSeek,
    InvalidStreamSkip,
    InvalidStreamRead,
    InvalidStreamOperation,
    InvalidFrameOperation,
    NestedFrameAccess,
    InvalidFrameRead,
    RasterUninitialized,
    RasterCorrupted,
    RasterOverflow,
    RasterNegativeHeight,
    TooManyCaches,
    InvalidOpcode,
    TooFewArguments,
    StackOverflow,
    CodeOverflow,
    BadArgument,
    DivideByZero,
    InvalidReference,
    DebugOpCode,
    ENDFInExecStream,
    NestedDEFS,
    InvalidCodeRange,
    ExecutionTooLong,
    TooManyFunctionDefs,
    TooManyInstructionDefs,
    TableMissing,
    HorizHeaderMissing,
    LocationsMissing,
    NameTableMissing,
    CMapTableMissing,
    HmtxTableMissing,
    PostTableMissing,
    InvalidHorizMetrics,
    InvalidCharMapFormat,
    InvalidPPem,
    InvalidVertMetrics,
    CouldNotFindContext,
    InvalidPostTableFormat,
    InvalidPostTable,
    DEFInGlyfBytecode,
    MissingBitmap,
    MissingSVGHooks,
    SyntaxError,
    StackUnderflow,
    Ignore,
    NoUnicodeGlyphName,
    GlyphTooBig,
    MissingStartfontField,
    MissingFontField,
    MissingSizeField,
    MissingFontboundingboxField,
    MissingCharsField,
    MissingStartcharField,
    MissingEncodingField,
    MissingBbxField,
    BbxTooBig,
    CorruptedFontHeader,
    CorruptedFontGlyphs,
};

fn checkError(code: c_int) Error!void {
    if (code != 0) return raiseError(code);
}

extern fn FT_Error_String(error_code: c_int) ?[*:0]const u8;

fn raiseError(code: c_int) Error {
    if (FT_Error_String(code)) |s| std.log.scoped(.freetype).err("{s}", .{s});
    return switch (code) {
        0x01 => error.CannotOpenResource,
        0x02 => error.UnknownFileFormat,
        0x03 => error.InvalidFileFormat,
        0x04 => error.InvalidVersion,
        0x05 => error.LowerModuleVersion,
        0x06 => error.InvalidArgument,
        0x07 => error.UnimplementedFeature,
        0x08 => error.InvalidTable,
        0x09 => error.InvalidOffset,
        0x0A => error.ArrayTooLarge,
        0x0B => error.MissingModule,
        0x0C => error.MissingProperty,
        0x10 => error.InvalidGlyphIndex,
        0x11 => error.InvalidCharacterCode,
        0x12 => error.InvalidGlyphFormat,
        0x13 => error.CannotRenderGlyph,
        0x14 => error.InvalidOutline,
        0x15 => error.InvalidComposite,
        0x16 => error.TooManyHints,
        0x17 => error.InvalidPixelSize,
        0x18 => error.InvalidSVGDocument,
        0x20 => error.InvalidHandle,
        0x21 => error.InvalidLibraryHandle,
        0x22 => error.InvalidDriverHandle,
        0x23 => error.InvalidFaceHandle,
        0x24 => error.InvalidSizeHandle,
        0x25 => error.InvalidSlotHandle,
        0x26 => error.InvalidCharMapHandle,
        0x27 => error.InvalidCacheHandle,
        0x28 => error.InvalidStreamHandle,
        0x30 => error.TooManyDrivers,
        0x31 => error.TooManyExtensions,
        0x40 => error.OutOfMemory,
        0x41 => error.UnlistedObject,
        0x51 => error.CannotOpenStream,
        0x52 => error.InvalidStreamSeek,
        0x53 => error.InvalidStreamSkip,
        0x54 => error.InvalidStreamRead,
        0x55 => error.InvalidStreamOperation,
        0x56 => error.InvalidFrameOperation,
        0x57 => error.NestedFrameAccess,
        0x58 => error.InvalidFrameRead,
        0x60 => error.RasterUninitialized,
        0x61 => error.RasterCorrupted,
        0x62 => error.RasterOverflow,
        0x63 => error.RasterNegativeHeight,
        0x70 => error.TooManyCaches,
        0x80 => error.InvalidOpcode,
        0x81 => error.TooFewArguments,
        0x82 => error.StackOverflow,
        0x83 => error.CodeOverflow,
        0x84 => error.BadArgument,
        0x85 => error.DivideByZero,
        0x86 => error.InvalidReference,
        0x87 => error.DebugOpCode,
        0x88 => error.ENDFInExecStream,
        0x89 => error.NestedDEFS,
        0x8A => error.InvalidCodeRange,
        0x8B => error.ExecutionTooLong,
        0x8C => error.TooManyFunctionDefs,
        0x8D => error.TooManyInstructionDefs,
        0x8E => error.TableMissing,
        0x8F => error.HorizHeaderMissing,
        0x90 => error.LocationsMissing,
        0x91 => error.NameTableMissing,
        0x92 => error.CMapTableMissing,
        0x93 => error.HmtxTableMissing,
        0x94 => error.PostTableMissing,
        0x95 => error.InvalidHorizMetrics,
        0x96 => error.InvalidCharMapFormat,
        0x97 => error.InvalidPPem,
        0x98 => error.InvalidVertMetrics,
        0x99 => error.CouldNotFindContext,
        0x9A => error.InvalidPostTableFormat,
        0x9B => error.InvalidPostTable,
        0x9C => error.DEFInGlyfBytecode,
        0x9D => error.MissingBitmap,
        0x9E => error.MissingSVGHooks,
        0xA0 => error.SyntaxError,
        0xA1 => error.StackUnderflow,
        0xA2 => error.Ignore,
        0xA3 => error.NoUnicodeGlyphName,
        0xA4 => error.GlyphTooBig,
        0xB0 => error.MissingStartfontField,
        0xB1 => error.MissingFontField,
        0xB2 => error.MissingSizeField,
        0xB3 => error.MissingFontboundingboxField,
        0xB4 => error.MissingCharsField,
        0xB5 => error.MissingStartcharField,
        0xB6 => error.MissingEncodingField,
        0xB7 => error.MissingBbxField,
        0xB8 => error.BbxTooBig,
        0xB9 => error.CorruptedFontHeader,
        0xBA => error.CorruptedFontGlyphs,
        else => error.UnknownFreetypeError,
    };
}

fn makeTag(chars: *const [4]u8) u32 {
    return std.mem.readIntBig(u32, chars);
}

pub const Vector = extern struct {
    x: c_long,
    y: c_long,
};

pub const Bbox = extern struct {
    x_min: c_long,
    y_min: c_long,
    x_max: c_long,
    y_max: c_long,
};

pub const Matrix = extern struct {
    xx: c_long,
    xy: c_long,
    yx: c_long,
    yy: c_long,
};

pub const UnitVector = extern struct {
    x: c_short,
    y: c_short,
};

pub const Data = extern struct {
    pointer: ?[*]const u8,
    length: c_uint,
};

pub const Generic = extern struct {
    data: ?*anyopaque,
    finalizer: ?Finalizer,

    pub const Finalizer = *const fn (?*anyopaque) callconv(.C) void;
};

pub const Bitmap = extern struct {
    rows: c_uint,
    width: c_int,
    pitch: c_int,
    buffer: [*]u8,
    num_grays: c_ushort,
    pixel_mode: PixelMode,
    palette_mode: u8,
    palette: ?*anyopaque,
};

pub const PixelMode = enum(u8) {
    none,
    mono,
    gray,
    gray2,
    gray4,
    lcd,
    lcd_v,
    bgra,
    _,
};

pub const BitmapSize = extern struct {
    height: c_short,
    width: c_short,
    size: c_long,
    x_ppem: c_long,
    y_ppem: c_long,
};

pub const CharMap = extern struct {
    face: *Face,
    encoding: Encoding,
    platform_id: c_ushort,
    encoding_id: c_ushort,
};

pub const Encoding = enum(u32) {
    ms_symbol = makeTag("symb"),
    unicode = makeTag("unic"),
    sjis = makeTag("sjis"),
    prc = makeTag("gb  "),
    big5 = makeTag("big5"),
    wansung = makeTag("wans"),
    johab = makeTag("joha"),
    adobe_standard = makeTag("ADOB"),
    adobe_expert = makeTag("ADBE"),
    adobe_custom = makeTag("ADBC"),
    adobe_latin_1 = makeTag("lat1"),
    old_latin_2 = makeTag("lat2"),
    apple_roman = makeTag("armn"),
    _,
};

pub const Memory = extern struct {
    user: ?*anyopaque,
    alloc: AllocFunc,
    free: FreeFunc,
    realloc: ReallocFunc,

    pub const AllocFunc = *const fn (*Memory, size: c_long) callconv(.C) ?*anyopaque;

    pub const FreeFunc = *const fn (*Memory, block: ?*anyopaque) callconv(.C) void;

    pub const ReallocFunc = *const fn (
        *Memory,
        cur_size: c_long,
        new_size: c_long,
        block: ?*anyopaque,
    ) callconv(.C) ?*anyopaque;
};

pub const c_memory = blk: {
    const fns = struct {
        fn alloc(_: *Memory, size: c_long) callconv(.C) ?*anyopaque {
            return std.c.malloc(@intCast(usize, size));
        }

        fn free(_: *Memory, block: ?*anyopaque) callconv(.C) void {
            std.c.free(block);
        }

        fn realloc(
            _: *Memory,
            _: c_long,
            new_size: c_long,
            block: ?*anyopaque,
        ) callconv(.C) ?*anyopaque {
            return std.c.realloc(block, new_size);
        }
    };

    break :blk Memory{
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
    stream: ?*Stream = null,
    driver: ?*Module = null,
    num_params: c_int = 0,
    params: ?[*]const Parameter = null,

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

    fn fillInParams(self: *OpenArgs, params: []const Parameter) void {
        if (params.len != 0) {
            self.flags.params = true;
            self.num_params = @intCast(c_int, params.len);
            self.params = params.ptr;
        }
    }
};

pub const Parameter = extern struct {
    tag: c_ulong,
    data: ?*anyopaque,
};

pub const Stream = extern struct {
    base: ?[*]u8,
    size: c_ulong,
    pos: c_ulong,

    descriptor: Desc,
    pathname: Desc,
    read: IoFunc,
    close: CloseFunc,

    memory: ?*Memory,
    cursor: ?[*]u8,
    limit: ?[*]u8,

    pub const Desc = extern union {
        value: c_long,
        pointer: ?*anyopaque,
    };

    pub const IoFunc = *const fn (
        *Stream,
        offset: c_ulong,
        buffer: ?[*]u8,
        count: c_ulong,
    ) callconv(.C) c_ulong;

    pub const CloseFunc = *const fn (*Stream) callconv(.C) void;
};

pub const Module = opaque {};

pub const FaceSource = union(enum) {
    memory: []const u8,
    stream: *Stream,
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
