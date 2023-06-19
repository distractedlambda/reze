const std = @import("std");

const c = @import("c.zig");
const err = @import("err.zig");

const common = @import("common");
const CEnum = common.CEnum;
const FixedPoint = common.FixedPoint;
const pointeeCast = common.pointeeCast;

pub const F26Dot6 = FixedPoint(.signed, 26, 6);

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
        fn alloc(_: [*c]c.FT_MemoryRec_, size: c_long) callconv(.C) ?*anyopaque {
            return std.c.malloc(@intCast(usize, size));
        }

        fn free(_: [*c]c.FT_MemoryRec_, block: ?*anyopaque) callconv(.C) void {
            std.c.free(block);
        }

        fn realloc(
            _: [*c]c.FT_MemoryRec_,
            _: c_long,
            new_size: c_long,
            block: ?*anyopaque,
        ) callconv(.C) ?*anyopaque {
            return std.c.realloc(block, @intCast(usize, new_size));
        }
    };

    break :blk c.FT_MemoryRec_{
        .user = null,
        .alloc = &fns.alloc,
        .free = &fns.free,
        .realloc = &fns.realloc,
    };
};

pub const FaceSource = union(enum) {
    memory: []const u8,
    stream: *c.FT_StreamRec,
    path: [*:0]const u8,

    fn populateArgs(self: @This(), args: *c.FT_Open_Args) void {
        switch (self) {
            .memory => |m| {
                args.flags |= c.FT_OPEN_MEMORY;
                args.memory_base = m.ptr;
                args.memory_size = @intCast(c.FT_Long, m.len);
            },

            .stream => |s| {
                args.flags |= c.FT_OPEN_STREAM;
                args.stream = s;
            },

            .path => |p| {
                args.flags |= c.FT_OPEN_PATHNAME;
                args.pathname = @constCast(p);
            },
        }
    }
};

pub const Library = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.FT_LibraryRec_, self)) {
        return pointeeCast(c.FT_LibraryRec_, self);
    }

    pub const CreateOptions = struct {
        memory: *c.FT_MemoryRec_ = @constCast(&c_memory),
    };

    pub fn create(options: CreateOptions) !*@This() {
        var lib: c.FT_Library = null;
        try err.check(c.FT_New_Library(options.memory, &lib));
        const result = lib.?;
        c.FT_Add_Default_Modules(result);
        c.FT_Set_Default_Properties(result);
        return pointeeCast(Library, result);
    }

    pub fn retain(self: *@This()) !void {
        return err.check(c.FT_Reference_Library(self.toC()));
    }

    pub fn release(self: *Library) !void {
        return err.check(c.FT_Done_Library(self.toC()));
    }

    pub const OpenFaceOptions = struct {
        source: FaceSource,
        face_index: u16 = 0,
        named_instance_index: u15 = 0,
        driver: ?*c.FT_ModuleRec_ = null,
        params: []const c.FT_Parameter = &.{},
    };

    pub fn openFace(self: *@This(), options: OpenFaceOptions) !*Face {
        var args = std.mem.zeroes(c.FT_Open_Args);

        options.source.populateArgs(&args);

        if (options.driver) |d| {
            args.flags |= c.FT_OPEN_DRIVER;
            args.driver = d;
        }

        if (options.params.len != 0) {
            args.flags |= c.FT_OPEN_PARAMS;
            args.num_params = @intCast(c.FT_Int, options.params.len);
            args.params = @constCast(options.params.ptr);
        }

        const index = (@as(u31, options.named_instance_index) << 16) | options.face_index;

        var face: ?*c.FT_FaceRec = null;
        try err.check(c.FT_Open_Face(self.toC(), &args, index, &face));
        return pointeeCast(Face, face.?);
    }
};

pub const Face = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.FT_FaceRec, self)) {
        return pointeeCast(c.FT_FaceRec, self);
    }

    pub fn retain(self: *@This()) !void {
        return err.check(c.FT_Reference_Face(self.toC()));
    }

    pub fn release(self: *@This()) !void {
        return err.check(c.FT_Done_Face(self.toC()));
    }

    pub fn hasHorizontalMetrics(self: *const @This()) bool {
        return c.FT_HAS_HORIZONTAL(self.toC());
    }

    pub fn attachSource(self: *@This(), source: FaceSource) !void {
        var args = std.mem.zeroes(c.FT_Open_Args);
        source.populateArgs(&args);
        return err.check(c.FT_Attach_Stream(self.toC(), &args));
    }

    pub fn setCharSize(
        self: *Face,
        width: F26Dot6,
        height: F26Dot6,
        horz_dpi: c.FT_UInt,
        vert_dpi: c.FT_UInt,
    ) !void {
        return err.check(c.FT_Set_Char_Size(
            self.toC(),
            width.repr,
            height.repr,
            horz_dpi,
            vert_dpi,
        ));
    }

    pub fn setPixelSizes(self: *@This(), width: c_uint, height: c_uint) !void {
        return err.check(c.FT_Set_Pixel_Sizes(self.toC(), width, height));
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

    pub fn loadGlyph(self: *@This(), glyph_index: c_uint, flags: LoadFlags) !void {
        return err.check(c.FT_Load_Glyph(self.toC(), glyph_index, @bitCast(c.FT_Int32, flags)));
    }

    pub fn getCharIndex(self: *@This(), charcode: c_ulong) c_uint {
        return c.FT_Get_Char_Index(self.toC(), charcode);
    }

    pub fn loadChar(self: *@This(), charcode: c_ulong, flags: LoadFlags) !void {
        return err.check(c.FT_Load_Char(self.toC(), charcode, @bitCast(c.FT_Int32, flags)));
    }
};

pub const Size = opaque {};

pub const GlyphSlot = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.FT_GlyphSlotRec, self)) {
        return pointeeCast(c.FT_GlyphSlotRec, self);
    }

    pub const RenderMode = CEnum(c.FT_Render_Mode, c, .{
        .{ "FT_RENDER_MODE_NORMAL", "normal" },
        .{ "FT_RENDER_MODE_LIGHT", "light" },
        .{ "FT_RENDER_MODE_MONO", "mono" },
        .{ "FT_RENDER_MODE_LCD", "lcd" },
        .{ "FT_RENDER_MODE_LCD_V", "lcd_v" },
        .{ "FT_RENDER_MODE_SDF", "sdf" },
    });

    pub fn render(self: *@This(), mode: RenderMode) !void {
        return err.check(c.FT_Render_Glyph(self.toC(), @enumToInt(mode)));
    }
};

pub const CharMap = opaque {};

pub const GlyphFormat = CEnum(u32, c, .{
    .{ "FT_GLYPH_FORMAT_COMPOSITE", "composite" },
    .{ "FT_GLYPH_FORMAT_BITMAP", "bitmap" },
    .{ "FT_GLYPH_FORMAT_OUTLINE", "outline" },
    .{ "FT_GLYPH_FORMAT_PLOTTER", "plotter" },
    .{ "FT_GLYPH_FORMAT_SVG", "svg" },
});

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(Library);
    std.testing.refAllDecls(Face);
    std.testing.refAllDecls(GlyphSlot);
}
