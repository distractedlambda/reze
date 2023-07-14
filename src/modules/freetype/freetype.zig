const std = @import("std");

const common = @import("common");
const FixedPoint = common.FixedPoint;
const pointeeCast = common.pointeeCast;

const c = @cImport({
    @cInclude("freetype/freetype.h");
    @cInclude("freetype/ftmodapi.h");
});

pub const F26Dot6 = FixedPoint(.signed, 26, 6);

pub const PixelMode = enum(c.FT_Pixel_Mode) {
    none = c.FT_PIXEL_MODE_NONE,
    mono = c.FT_PIXEL_MODE_MONO,
    gray = c.FT_PIXEL_MODE_GRAY,
    gray2 = c.FT_PIXEL_MODE_GRAY2,
    gray4 = c.FT_PIXEL_MODE_GRAY4,
    lcd = c.FT_PIXEL_MODE_LCD,
    lcd_v = c.FT_PIXEL_MODE_LCD_V,
    bgra = c.FT_PIXEL_MODE_BGRA,

    test "completeness" {
        comptime {
            @setEvalBranchQuota(10000);
            for (@typeInfo(c).Struct.decls) |decl| {
                if (decl.is_pub and
                    std.mem.startsWith(u8, decl.name, "FT_PIXEL_MODE_") and
                    !std.mem.eql(u8, decl.name, "FT_PIXEL_MODE_MAX"))
                {
                    _ = @as(PixelMode, @enumFromInt(@field(c, decl.name)));
                }
            }
        }
    }
};

pub const Encoding = enum(c.FT_Encoding) {
    none = c.FT_ENCODING_NONE,
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

    test "completeness" {
        comptime {
            @setEvalBranchQuota(10000);
            for (@typeInfo(c).Struct.decls) |decl| {
                if (decl.is_pub and std.mem.startsWith(u8, decl.name, "FT_ENCODING_")) {
                    _ = @as(Encoding, @enumFromInt(@field(c, decl.name)));
                }
            }
        }
    }
};

pub const c_memory = blk: {
    const fns = struct {
        fn alloc(_: [*c]c.FT_MemoryRec_, size: c_long) callconv(.C) ?*anyopaque {
            return std.c.malloc(@intCast(size));
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
            return std.c.realloc(block, @intCast(new_size));
        }
    };

    break :blk c.FT_MemoryRec_{
        .user = null,
        .alloc = &fns.alloc,
        .free = &fns.free,
        .realloc = &fns.realloc,
    };
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
        try checkError(c.FT_New_Library(options.memory, &lib));
        const result = lib.?;
        c.FT_Add_Default_Modules(result);
        c.FT_Set_Default_Properties(result);
        return pointeeCast(Library, result);
    }

    pub fn retain(self: *@This()) !void {
        return checkError(c.FT_Reference_Library(self.toC()));
    }

    pub fn release(self: *Library) !void {
        return checkError(c.FT_Done_Library(self.toC()));
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
            args.num_params = @intCast(options.params.len);
            args.params = @constCast(options.params.ptr);
        }

        const index = (@as(u31, options.named_instance_index) << 16) | options.face_index;

        var face: ?*c.FT_FaceRec = null;
        try checkError(c.FT_Open_Face(self.toC(), &args, index, &face));
        return pointeeCast(Face, face.?);
    }
};

pub const Face = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.FT_FaceRec, self)) {
        return pointeeCast(c.FT_FaceRec, self);
    }

    pub fn retain(self: *@This()) !void {
        return checkError(c.FT_Reference_Face(self.toC()));
    }

    pub fn release(self: *@This()) !void {
        return checkError(c.FT_Done_Face(self.toC()));
    }

    pub fn hasHorizontalMetrics(self: *const @This()) bool {
        return c.FT_HAS_HORIZONTAL(self.toC());
    }

    pub fn attachSource(self: *@This(), source: FaceSource) !void {
        var args = std.mem.zeroes(c.FT_Open_Args);
        source.populateArgs(&args);
        return checkError(c.FT_Attach_Stream(self.toC(), &args));
    }

    pub fn setCharSize(
        self: *Face,
        width: F26Dot6,
        height: F26Dot6,
        horz_dpi: c.FT_UInt,
        vert_dpi: c.FT_UInt,
    ) !void {
        return checkError(c.FT_Set_Char_Size(
            self.toC(),
            width.repr,
            height.repr,
            horz_dpi,
            vert_dpi,
        ));
    }

    pub fn setPixelSizes(self: *@This(), width: c_uint, height: c_uint) !void {
        return checkError(c.FT_Set_Pixel_Sizes(self.toC(), width, height));
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
        return checkError(c.FT_Load_Glyph(self.toC(), glyph_index, @bitCast(flags)));
    }

    pub fn getCharIndex(self: *@This(), charcode: c_ulong) c_uint {
        return c.FT_Get_Char_Index(self.toC(), charcode);
    }

    pub fn loadChar(self: *@This(), charcode: c_ulong, flags: LoadFlags) !void {
        return checkError(c.FT_Load_Char(self.toC(), charcode, @bitCast(flags)));
    }
};

pub const Size = opaque {};

pub const GlyphSlot = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.FT_GlyphSlotRec, self)) {
        return pointeeCast(c.FT_GlyphSlotRec, self);
    }

    pub fn render(self: *@This(), mode: RenderMode) !void {
        return checkError(c.FT_Render_Glyph(self.toC(), @intFromEnum(mode)));
    }
};

pub const CharMap = opaque {};

pub const RenderMode = enum(c.FT_Render_Mode) {
    normal = c.FT_RENDER_MODE_NORMAL,
    light = c.FT_RENDER_MODE_LIGHT,
    mono = c.FT_RENDER_MODE_MONO,
    lcd = c.FT_RENDER_MODE_LCD,
    lcd_v = c.FT_RENDER_MODE_LCD_V,
    sdf = c.FT_RENDER_MODE_SDF,

    test "completeness" {
        comptime {
            @setEvalBranchQuota(10000);
            for (@typeInfo(c).Struct.decls) |decl| {
                if (decl.is_pub and
                    std.mem.startsWith(u8, decl.name, "FT_RENDER_MODE_") and
                    !std.mem.eql(u8, decl.name, "FT_RENDER_MODE_MAX"))
                {
                    _ = @as(RenderMode, @enumFromInt(@field(c, decl.name)));
                }
            }
        }
    }
};

pub const GlyphFormat = enum(c.FT_Glyph_Format) {
    none = c.FT_GLYPH_FORMAT_NONE,
    composite = c.FT_GLYPH_FORMAT_COMPOSITE,
    bitmap = c.FT_GLYPH_FORMAT_BITMAP,
    outline = c.FT_GLYPH_FORMAT_OUTLINE,
    plotter = c.FT_GLYPH_FORMAT_PLOTTER,
    svg = c.FT_GLYPH_FORMAT_SVG,

    test "completeness" {
        comptime {
            @setEvalBranchQuota(10000);
            for (@typeInfo(c).Struct.decls) |decl| {
                if (decl.is_pub and std.mem.startsWith(u8, decl.name, "FT_GLYPH_FORMAT_")) {
                    _ = @as(GlyphFormat, @enumFromInt(@field(c, decl.name)));
                }
            }
        }
    }
};

pub fn checkError(code: c_int) !void {
    return switch (code) {
        c.FT_Err_Ok => {},
        c.FT_Err_Cannot_Open_Resource => error.CannotOpenResource,
        c.FT_Err_Unknown_File_Format => error.UnknownFileFormat,
        c.FT_Err_Invalid_File_Format => error.InvalidFileFormat,
        c.FT_Err_Invalid_Version => error.InvalidVersion,
        c.FT_Err_Lower_Module_Version => error.LowerModuleVersion,
        c.FT_Err_Invalid_Argument => error.InvalidArgument,
        c.FT_Err_Unimplemented_Feature => error.UnimplementedFeature,
        c.FT_Err_Invalid_Table => error.InvalidTable,
        c.FT_Err_Invalid_Offset => error.InvalidOffset,
        c.FT_Err_Array_Too_Large => error.ArrayTooLarge,
        c.FT_Err_Missing_Module => error.MissingModule,
        c.FT_Err_Missing_Property => error.MissingProperty,
        c.FT_Err_Invalid_Glyph_Index => error.InvalidGlyphIndex,
        c.FT_Err_Invalid_Character_Code => error.InvalidCharacterCode,
        c.FT_Err_Invalid_Glyph_Format => error.InvalidGlyphFormat,
        c.FT_Err_Cannot_Render_Glyph => error.CannotRenderGlyph,
        c.FT_Err_Invalid_Outline => error.InvalidOutline,
        c.FT_Err_Invalid_Composite => error.InvalidComposite,
        c.FT_Err_Too_Many_Hints => error.TooManyHints,
        c.FT_Err_Invalid_Pixel_Size => error.InvalidPixelSize,
        c.FT_Err_Invalid_SVG_Document => error.InvalidSVGDocument,
        c.FT_Err_Invalid_Handle => error.InvalidHandle,
        c.FT_Err_Invalid_Library_Handle => error.InvalidLibraryHandle,
        c.FT_Err_Invalid_Driver_Handle => error.InvalidDriverHandle,
        c.FT_Err_Invalid_Face_Handle => error.InvalidFaceHandle,
        c.FT_Err_Invalid_Size_Handle => error.InvalidSizeHandle,
        c.FT_Err_Invalid_Slot_Handle => error.InvalidSlotHandle,
        c.FT_Err_Invalid_CharMap_Handle => error.InvalidCharMapHandle,
        c.FT_Err_Invalid_Cache_Handle => error.InvalidCacheHandle,
        c.FT_Err_Invalid_Stream_Handle => error.InvalidStreamHandle,
        c.FT_Err_Too_Many_Drivers => error.TooManyDrivers,
        c.FT_Err_Too_Many_Extensions => error.TooManyExtensions,
        c.FT_Err_Out_Of_Memory => error.OutOfMemory,
        c.FT_Err_Unlisted_Object => error.UnlistedObject,
        c.FT_Err_Cannot_Open_Stream => error.CannotOpenStream,
        c.FT_Err_Invalid_Stream_Seek => error.InvalidStreamSeek,
        c.FT_Err_Invalid_Stream_Skip => error.InvalidStreamSkip,
        c.FT_Err_Invalid_Stream_Read => error.InvalidStreamRead,
        c.FT_Err_Invalid_Stream_Operation => error.InvalidStreamOperation,
        c.FT_Err_Invalid_Frame_Operation => error.InvalidFrameOperation,
        c.FT_Err_Nested_Frame_Access => error.NestedFrameAccess,
        c.FT_Err_Invalid_Frame_Read => error.InvalidFrameRead,
        c.FT_Err_Raster_Uninitialized => error.RasterUninitialized,
        c.FT_Err_Raster_Corrupted => error.RasterCorrupted,
        c.FT_Err_Raster_Overflow => error.RasterOverflow,
        c.FT_Err_Raster_Negative_Height => error.RasterNegativeHeight,
        c.FT_Err_Too_Many_Caches => error.TooManyCaches,
        c.FT_Err_Invalid_Opcode => error.InvalidOpcode,
        c.FT_Err_Too_Few_Arguments => error.TooFewArguments,
        c.FT_Err_Stack_Overflow => error.StackOverflow,
        c.FT_Err_Code_Overflow => error.CodeOverflow,
        c.FT_Err_Bad_Argument => error.BadArgument,
        c.FT_Err_Divide_By_Zero => error.DivideByZero,
        c.FT_Err_Invalid_Reference => error.InvalidReference,
        c.FT_Err_Debug_OpCode => error.DebugOpCode,
        c.FT_Err_ENDF_In_Exec_Stream => error.ENDFInExecStream,
        c.FT_Err_Nested_DEFS => error.NestedDEFS,
        c.FT_Err_Invalid_CodeRange => error.InvalidCodeRange,
        c.FT_Err_Execution_Too_Long => error.ExecutionTooLong,
        c.FT_Err_Too_Many_Function_Defs => error.TooManyFunctionDefs,
        c.FT_Err_Too_Many_Instruction_Defs => error.TooManyInstructionDefs,
        c.FT_Err_Table_Missing => error.TableMissing,
        c.FT_Err_Horiz_Header_Missing => error.HorizHeaderMissing,
        c.FT_Err_Locations_Missing => error.LocationsMissing,
        c.FT_Err_Name_Table_Missing => error.NameTableMissing,
        c.FT_Err_CMap_Table_Missing => error.CMapTableMissing,
        c.FT_Err_Hmtx_Table_Missing => error.HmtxTableMissing,
        c.FT_Err_Post_Table_Missing => error.PostTableMissing,
        c.FT_Err_Invalid_Horiz_Metrics => error.InvalidHorizMetrics,
        c.FT_Err_Invalid_CharMap_Format => error.InvalidCharMapFormat,
        c.FT_Err_Invalid_PPem => error.InvalidPPem,
        c.FT_Err_Invalid_Vert_Metrics => error.InvalidVertMetrics,
        c.FT_Err_Could_Not_Find_Context => error.CouldNotFindContext,
        c.FT_Err_Invalid_Post_Table_Format => error.InvalidPostTableFormat,
        c.FT_Err_Invalid_Post_Table => error.InvalidPostTable,
        c.FT_Err_DEF_In_Glyf_Bytecode => error.DEFInGlyfBytecode,
        c.FT_Err_Missing_Bitmap => error.MissingBitmap,
        c.FT_Err_Missing_SVG_Hooks => error.MissingSVGHooks,
        c.FT_Err_Syntax_Error => error.SyntaxError,
        c.FT_Err_Stack_Underflow => error.StackUnderflow,
        c.FT_Err_Ignore => error.Ignore,
        c.FT_Err_No_Unicode_Glyph_Name => error.NoUnicodeGlyphName,
        c.FT_Err_Glyph_Too_Big => error.GlyphTooBig,
        c.FT_Err_Missing_Startfont_Field => error.MissingStartfontField,
        c.FT_Err_Missing_Font_Field => error.MissingFontField,
        c.FT_Err_Missing_Size_Field => error.MissingSizeField,
        c.FT_Err_Missing_Fontboundingbox_Field => error.MissingFontboundingboxField,
        c.FT_Err_Missing_Chars_Field => error.MissingCharsField,
        c.FT_Err_Missing_Startchar_Field => error.MissingStartcharField,
        c.FT_Err_Missing_Encoding_Field => error.MissingEncodingField,
        c.FT_Err_Missing_Bbx_Field => error.MissingBbxField,
        c.FT_Err_Bbx_Too_Big => error.BbxTooBig,
        c.FT_Err_Corrupted_Font_Header => error.CorruptedFontHeader,
        c.FT_Err_Corrupted_Font_Glyphs => error.CorruptedFontGlyphs,
        else => unreachable,
    };
}

test "error code coverage" {
    comptime {
        @setEvalBranchQuota(10000);
        for (@typeInfo(c).Struct.decls) |decl| {
            if (decl.is_pub and
                std.mem.startsWith(u8, decl.name, "FT_Err_") and
                !std.mem.eql(u8, decl.name, "FT_Err_Max"))
            {
                _ = checkError(@field(c, decl.name)) catch {};
            }
        }
    }
}

test {
    std.testing.refAllDecls(@This());
}
