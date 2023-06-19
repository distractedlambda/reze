const common = @import("common");
const std = @import("std");

const c = @import("c.zig");

const translateCError = common.translateCError;

const known_errors = .{
    .{ "FT_Err_Cannot_Open_Resource", error.CannotOpenResource },
    .{ "FT_Err_Unknown_File_Format", error.UnknownFileFormat },
    .{ "FT_Err_Invalid_File_Format", error.InvalidFileFormat },
    .{ "FT_Err_Invalid_Version", error.InvalidVersion },
    .{ "FT_Err_Lower_Module_Version", error.LowerModuleVersion },
    .{ "FT_Err_Invalid_Argument", error.InvalidArgument },
    .{ "FT_Err_Unimplemented_Feature", error.UnimplementedFeature },
    .{ "FT_Err_Invalid_Table", error.InvalidTable },
    .{ "FT_Err_Invalid_Offset", error.InvalidOffset },
    .{ "FT_Err_Array_Too_Large", error.ArrayTooLarge },
    .{ "FT_Err_Missing_Module", error.MissingModule },
    .{ "FT_Err_Missing_Property", error.MissingProperty },
    .{ "FT_Err_Invalid_Glyph_Index", error.InvalidGlyphIndex },
    .{ "FT_Err_Invalid_Character_Code", error.InvalidCharacterCode },
    .{ "FT_Err_Invalid_Glyph_Format", error.InvalidGlyphFormat },
    .{ "FT_Err_Cannot_Render_Glyph", error.CannotRenderGlyph },
    .{ "FT_Err_Invalid_Outline", error.InvalidOutline },
    .{ "FT_Err_Invalid_Composite", error.InvalidComposite },
    .{ "FT_Err_Too_Many_Hints", error.TooManyHints },
    .{ "FT_Err_Invalid_Pixel_Size", error.InvalidPixelSize },
    .{ "FT_Err_Invalid_SVG_Document", error.InvalidSVGDocument },
    .{ "FT_Err_Invalid_Handle", error.InvalidHandle },
    .{ "FT_Err_Invalid_Library_Handle", error.InvalidLibraryHandle },
    .{ "FT_Err_Invalid_Driver_Handle", error.InvalidDriverHandle },
    .{ "FT_Err_Invalid_Face_Handle", error.InvalidFaceHandle },
    .{ "FT_Err_Invalid_Size_Handle", error.InvalidSizeHandle },
    .{ "FT_Err_Invalid_Slot_Handle", error.InvalidSlotHandle },
    .{ "FT_Err_Invalid_CharMap_Handle", error.InvalidCharMapHandle },
    .{ "FT_Err_Invalid_Cache_Handle", error.InvalidCacheHandle },
    .{ "FT_Err_Invalid_Stream_Handle", error.InvalidStreamHandle },
    .{ "FT_Err_Too_Many_Drivers", error.TooManyDrivers },
    .{ "FT_Err_Too_Many_Extensions", error.TooManyExtensions },
    .{ "FT_Err_Out_Of_Memory", error.OutOfMemory },
    .{ "FT_Err_Unlisted_Object", error.UnlistedObject },
    .{ "FT_Err_Cannot_Open_Stream", error.CannotOpenStream },
    .{ "FT_Err_Invalid_Stream_Seek", error.InvalidStreamSeek },
    .{ "FT_Err_Invalid_Stream_Skip", error.InvalidStreamSkip },
    .{ "FT_Err_Invalid_Stream_Read", error.InvalidStreamRead },
    .{ "FT_Err_Invalid_Stream_Operation", error.InvalidStreamOperation },
    .{ "FT_Err_Invalid_Frame_Operation", error.InvalidFrameOperation },
    .{ "FT_Err_Nested_Frame_Access", error.NestedFrameAccess },
    .{ "FT_Err_Invalid_Frame_Read", error.InvalidFrameRead },
    .{ "FT_Err_Raster_Uninitialized", error.RasterUninitialized },
    .{ "FT_Err_Raster_Corrupted", error.RasterCorrupted },
    .{ "FT_Err_Raster_Overflow", error.RasterOverflow },
    .{ "FT_Err_Raster_Negative_Height", error.RasterNegativeHeight },
    .{ "FT_Err_Too_Many_Caches", error.TooManyCaches },
    .{ "FT_Err_Invalid_Opcode", error.InvalidOpcode },
    .{ "FT_Err_Too_Few_Arguments", error.TooFewArguments },
    .{ "FT_Err_Stack_Overflow", error.StackOverflow },
    .{ "FT_Err_Code_Overflow", error.CodeOverflow },
    .{ "FT_Err_Bad_Argument", error.BadArgument },
    .{ "FT_Err_Divide_By_Zero", error.DivideByZero },
    .{ "FT_Err_Invalid_Reference", error.InvalidReference },
    .{ "FT_Err_Debug_OpCode", error.DebugOpCode },
    .{ "FT_Err_ENDF_In_Exec_Stream", error.ENDFInExecStream },
    .{ "FT_Err_Nested_DEFS", error.NestedDEFS },
    .{ "FT_Err_Invalid_CodeRange", error.InvalidCodeRange },
    .{ "FT_Err_Execution_Too_Long", error.ExecutionTooLong },
    .{ "FT_Err_Too_Many_Function_Defs", error.TooManyFunctionDefs },
    .{ "FT_Err_Too_Many_Instruction_Defs", error.TooManyInstructionDefs },
    .{ "FT_Err_Table_Missing", error.TableMissing },
    .{ "FT_Err_Horiz_Header_Missing", error.HorizHeaderMissing },
    .{ "FT_Err_Locations_Missing", error.LocationsMissing },
    .{ "FT_Err_Name_Table_Missing", error.NameTableMissing },
    .{ "FT_Err_CMap_Table_Missing", error.CMapTableMissing },
    .{ "FT_Err_Hmtx_Table_Missing", error.HmtxTableMissing },
    .{ "FT_Err_Post_Table_Missing", error.PostTableMissing },
    .{ "FT_Err_Invalid_Horiz_Metrics", error.InvalidHorizMetrics },
    .{ "FT_Err_Invalid_CharMap_Format", error.InvalidCharMapFormat },
    .{ "FT_Err_Invalid_PPem", error.InvalidPPem },
    .{ "FT_Err_Invalid_Vert_Metrics", error.InvalidVertMetrics },
    .{ "FT_Err_Could_Not_Find_Context", error.CouldNotFindContext },
    .{ "FT_Err_Invalid_Post_Table_Format", error.InvalidPostTableFormat },
    .{ "FT_Err_Invalid_Post_Table", error.InvalidPostTable },
    .{ "FT_Err_DEF_In_Glyf_Bytecode", error.DEFInGlyfBytecode },
    .{ "FT_Err_Missing_Bitmap", error.MissingBitmap },
    .{ "FT_Err_Missing_SVG_Hooks", error.MissingSVGHooks },
    .{ "FT_Err_Syntax_Error", error.SyntaxError },
    .{ "FT_Err_Stack_Underflow", error.StackUnderflow },
    .{ "FT_Err_Ignore", error.Ignore },
    .{ "FT_Err_No_Unicode_Glyph_Name", error.NoUnicodeGlyphName },
    .{ "FT_Err_Glyph_Too_Big", error.GlyphTooBig },
    .{ "FT_Err_Missing_Startfont_Field", error.MissingStartfontField },
    .{ "FT_Err_Missing_Font_Field", error.MissingFontField },
    .{ "FT_Err_Missing_Size_Field", error.MissingSizeField },
    .{ "FT_Err_Missing_Fontboundingbox_Field", error.MissingFontboundingboxField },
    .{ "FT_Err_Missing_Chars_Field", error.MissingCharsField },
    .{ "FT_Err_Missing_Startchar_Field", error.MissingStartcharField },
    .{ "FT_Err_Missing_Encoding_Field", error.MissingEncodingField },
    .{ "FT_Err_Missing_Bbx_Field", error.MissingBbxField },
    .{ "FT_Err_Bbx_Too_Big", error.BbxTooBig },
    .{ "FT_Err_Corrupted_Font_Header", error.CorruptedFontHeader },
    .{ "FT_Err_Corrupted_Font_Glyphs", error.CorruptedFontGlyphs },
};

pub fn check(code: c_int) !void {
    if (code != c.FT_Err_Ok) {
        try raise(code);
    }
}

fn raise(code: c_int) !noreturn {
    if (c.FT_Error_String(code)) |s| {
        std.log.scoped(.freetype).err("{s}", .{s});
    }

    try translateCError(code, c, known_errors);

    return error.UnknownFreetypeError;
}
