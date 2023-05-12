const std = @import("std");

pub const Tag = [4]u8;
pub const Offset16 = ?u16;
pub const Offset24 = ?u24;
pub const Offset32 = ?u32;
pub const Fixed = i32;
pub const FWORD = i16;
pub const UFWORD = u16;
pub const F2DOT14 = i16;
pub const LONGDATETIME = i64;
pub const Version16Dot16 = u32;

const Reader = struct {
    source: []const u8,

    fn init(source: []const u8) @This() {
        return .{ .source = source };
    }

    fn nextBytes(self: *@This(), comptime len: usize) ![len]u8 {
        if (self.source.len < len) return error.OutOfBounds;
        defer self.source = self.source[len..];
        return self.source[0..len].*;
    }

    fn nextInt(self: *@This(), comptime T: type) !T {
        switch (@typeInfo(T)) {
            .Int => {
                const int = @bitCast(T, try self.nextBytes(@divExact(@bitSizeOf(T), 8)));
                return if (@import("builtin").cpu.arch.endian() == .Big) int else @byteSwap(int);
            },

            .Enum => |info| {
                return std.meta.intToEnum(T, try self.nextInt(info.tag_type));
            },

            .Struct => |info| {
                return @bitCast(T, try self.nextInt(info.backing_integer.?));
            },

            else => unreachable,
        }
    }

    fn nextUint8(self: *@This()) !u8 {
        return self.nextInt(u8);
    }

    fn nextInt8(self: *@This()) !i8 {
        return self.nextInt(i8);
    }

    fn nextUint16(self: *@This()) !u16 {
        return self.nextInt(u16);
    }

    fn nextInt16(self: *@This()) !i16 {
        return self.nextInt(i16);
    }

    fn nextUint24(self: *@This()) !u24 {
        return self.nextInt(u24);
    }

    fn nextUint32(self: *@This()) !u32 {
        return self.nextInt(u32);
    }

    fn nextInt32(self: *@This()) !i32 {
        return self.nextInt(i32);
    }

    const nextFWORD = nextInt16;

    const nextUFWORD = nextUint16;

    const nextF2DOT4 = nextInt16;

    const nextFixed = nextInt32;

    fn nextLONGDATETIME(self: *@This()) !LONGDATETIME {
        return self.nextInt(LONGDATETIME);
    }

    fn nextTag(self: *@This()) !Tag {
        return self.nextBytes(4);
    }

    fn nextOffset16(self: *@This()) !Offset16 {
        const value = try self.nextUint16();
        return if (value != 0) value else null;
    }

    fn nextOffset24(self: *@This()) !Offset24 {
        const value = try self.nextUint24();
        return if (value != 0) value else null;
    }

    fn nextOffset32(self: *@This()) !Offset32 {
        const value = try self.nextUint32();
        return if (value != 0) value else null;
    }

    const nextVersion16Dot16 = nextUint32;

    fn slice(self: *@This(), len: usize) !@This() {
        if (self.source.len < len) return error.OutOfBounds;
        defer self.source = self.source[len..];
        return .{ .source = self.source[0..len] };
    }

    fn limit(self: *@This(), len: usize) !void {
        if (self.source.len < len) return error.OutOfBounds;
        self.source = self.source[0..len];
    }

    fn remaining(self: @This()) usize {
        return self.source.len;
    }

    fn empty(self: @This()) bool {
        return self.source.len != 0;
    }
};

const Directory = struct {
    entries: []const Entry,

    const Entry = struct {
        tag: Tag,
        table_data: []const u8,
    };

    fn extract(comptime font_data: []const u8) !@This() {
        var reader = Reader.init(font_data);

        const sfnt_version = try reader.nextUint32();
        if (sfnt_version != 0x00010000) return error.UnsupportedSfntVersion;
        const num_tables = try reader.nextUint16();
        _ = try reader.nextUint16(); // searchRange
        _ = try reader.nextUint16(); // entrySelector
        _ = try reader.nextUint16(); // rangeShift

        var entries: [num_tables]Entry = undefined;

        for (&entries) |*entry| {
            const tag = try reader.nextTag();
            _ = try reader.nextUint32(); // checksum
            const offset = try reader.nextUint32();
            const length = try reader.nextUint32();
            if (offset > font_data.len or font_data.len - offset < length) return error.OutOfBounds;
            entry.* = .{ .tag = tag, .table_data = font_data[offset..][0..length] };
        }

        return comptime .{ .entries = &entries };
    }

    fn tableData(self: @This(), tag: *const [4]u8) ?[]const u8 {
        for (self.entries) |entry| {
            if (std.meta.eql(tag.*, entry.tag)) {
                return entry.table_data;
            }
        }

        return null;
    }
};

const Cmap = union(enum) {
    Format4: Format4,
    Format12: []const SequentialMapGroup,

    const Format4 = struct {
        end_codes: []const u16,
        start_codes: []const u16,
        id_deltas: []const i16,
        id_range_offsets_and_glyph_id_array: []const u16,
    };

    const SequentialMapGroup = struct {
        start_char_code: u32,
        end_char_code: u32,
        start_glyph_id: u32,
    };

    fn parse(comptime data: []const u8) !@This() {
        @setEvalBranchQuota(10000);

        var reader = Reader.init(data);

        const version = try reader.nextUint16();
        if (version != 0) return error.UnsupportedTableVersion;

        const num_tables = try reader.nextUint16();

        var format_4_reader: ?Reader = null;
        var format_12_reader: ?Reader = null;

        for (0..num_tables) |_| {
            const platform_id = try reader.nextUint16();
            const encoding_id = try reader.nextUint16();
            const subtable_offset = try reader.nextUint32();

            if (platform_id != 0) continue;
            if (encoding_id != 3 and encoding_id != 4) continue;

            var subtable_reader = Reader.init(data[subtable_offset..]);

            const format = try subtable_reader.nextUint16();

            switch (format) {
                4 => format_4_reader = subtable_reader,
                12 => format_12_reader = subtable_reader,
                else => {},
            }
        }

        if (format_12_reader) |*subtable_reader| {
            _ = try subtable_reader.nextUint16(); // reserved
            _ = try subtable_reader.nextUint32(); // length
            _ = try subtable_reader.nextUint32(); // language
            const num_groups = try subtable_reader.nextUint32();

            var parsed_groups: [num_groups]SequentialMapGroup = undefined;

            for (&parsed_groups) |*group| group.* = .{
                .start_char_code = try reader.nextUint32(),
                .end_char_code = try reader.nextUint32(),
                .start_glyph_id = try reader.nextUint32(),
            };

            return comptime .{ .Format12 = &parsed_groups };
        }

        if (format_4_reader) |*subtable_reader| {
            const length = try subtable_reader.nextUint16();
            try subtable_reader.limit(length - 4);

            _ = try subtable_reader.nextUint16(); // language
            const seg_count_x2 = try subtable_reader.nextUint16();
            _ = try subtable_reader.nextUint16(); // searchRange
            _ = try subtable_reader.nextUint16(); // entrySelector
            _ = try subtable_reader.nextUint16(); // rangeShift
            var end_code_reader = try subtable_reader.slice(seg_count_x2);
            _ = try subtable_reader.nextUint16(); // reservedPad
            var start_code_reader = try subtable_reader.slice(seg_count_x2);
            var id_delta_reader = try subtable_reader.slice(seg_count_x2);
            var id_range_offsets_reader = try subtable_reader.slice(seg_count_x2);

            const seg_count = try std.math.divExact(u16, seg_count_x2, 2);
            var end_codes: [seg_count]u16 = undefined;
            var start_codes: [seg_count]u16 = undefined;
            var id_deltas: [seg_count]i16 = undefined;
            var id_range_offsets: [seg_count]u16 = undefined;

            for (0..seg_count) |i| {
                end_codes[i] = try end_code_reader.nextUint16();
                start_codes[i] = try start_code_reader.nextUint16();
                id_deltas[i] = try id_delta_reader.nextInt16();
                id_range_offsets[i] = try id_range_offsets_reader.nextUint16();
            }

            const glyph_id_array_len = try std.math.divExact(u16, subtable_reader.remaining(), 2);
            var glyph_id_array: [glyph_id_array_len]u16 = undefined;
            for (&glyph_id_array) |*glyph_id| glyph_id.* = try subtable_reader.nextUint16();

            return comptime .{ .Format4 = .{
                .end_codes = &end_codes,
                .start_codes = &start_codes,
                .id_deltas = &id_deltas,
                .id_range_offsets_and_glyph_id_array = &(id_range_offsets ++ glyph_id_array),
            } };
        }

        return error.NoSupportedEncoding;
    }
};

const Head = struct {
    font_revision: Fixed,
    flags: Flags,
    units_per_em: u16,
    created: LONGDATETIME,
    modified: LONGDATETIME,
    x_min: i16,
    y_min: i16,
    x_max: i16,
    y_max: i16,
    mac_style: MacStyle,
    lowest_rec_ppem: u16,
    index_to_loc_format: IndexToLocFormat,

    const Flags = packed struct(u16) {
        baseline_at_y_0: bool,
        left_sidebearing_at_x_0: bool,
        instructions_depend_on_point_size: bool,
        force_ppem_to_integer: bool,
        instructions_alter_advance_width: bool,
        _reserved0: u6,
        losslessly_compressed: bool,
        converted: bool,
        optimized_for_cleartype: bool,
        last_resort: bool,
        _reserved1: u1,
    };

    const MacStyle = packed struct(u16) {
        bold: bool,
        italic: bool,
        underline: bool,
        outline: bool,
        shadow: bool,
        condensed: bool,
        extended: bool,
        _reserved: u9,
    };

    const IndexToLocFormat = enum(i16) {
        Offset16 = 0,
        Offset32 = 1,
    };

    fn parse(data: []const u8) !@This() {
        var reader = Reader.init(data);

        const major_version = try reader.nextUint16();
        _ = try reader.nextUint16(); // minorVersion
        if (major_version != 1) return error.UnsupportedTableVersion;
        const font_revision = try reader.nextFixed();
        _ = try reader.nextUint32(); // checksumAdjustment
        _ = try reader.nextUint32(); // magicNumber
        const flags = try reader.nextInt(Flags);
        const units_per_em = try reader.nextUint16();
        const created = try reader.nextLONGDATETIME();
        const modified = try reader.nextLONGDATETIME();
        const x_min = try reader.nextInt16();
        const y_min = try reader.nextInt16();
        const x_max = try reader.nextInt16();
        const y_max = try reader.nextInt16();
        const mac_style = try reader.nextInt(MacStyle);
        const lowest_rec_ppem = try reader.nextUint16();
        _ = try reader.nextInt16(); // fontDirectionHint
        const index_to_loc_format = try reader.nextInt(IndexToLocFormat);
        const glyph_data_format = try reader.nextInt16();
        if (glyph_data_format != 0) return error.UnsupportedGlyphDataFormat;

        return .{
            .font_revision = font_revision,
            .flags = flags,
            .units_per_em = units_per_em,
            .created = created,
            .modified = modified,
            .x_min = x_min,
            .y_min = y_min,
            .x_max = x_max,
            .y_max = y_max,
            .mac_style = mac_style,
            .lowest_rec_ppem = lowest_rec_ppem,
            .index_to_loc_format = index_to_loc_format,
        };
    }
};

const Hhea = struct {
    ascender: FWORD,
    descender: FWORD,
    line_gap: FWORD,
    advance_width_max: UFWORD,
    min_left_side_bearing: FWORD,
    min_right_side_bearing: FWORD,
    x_max_extent: FWORD,
    caret_slope_rise: i16,
    caret_slope_run: i16,
    caret_offset: i16,
    number_of_h_metrics: u16,

    fn parse(data: []const u8) !@This() {
        var reader = Reader.init(data);
        const major_version = try reader.nextUint16();
        if (major_version != 1) return error.UnsupportedTableVersion;
        _ = try reader.nextUint16(); // minorVersion
        const ascender = try reader.nextFWORD();
        const descender = try reader.nextFWORD();
        const line_gap = try reader.nextFWORD();
        const advance_width_max = try reader.nextUFWORD();
        const min_left_side_bearing = try reader.nextFWORD();
        const min_right_side_bearing = try reader.nextFWORD();
        const x_max_extent = try reader.nextFWORD();
        const caret_slope_rise = try reader.nextInt16();
        const caret_slope_run = try reader.nextInt16();
        const caret_offset = try reader.nextInt16();
        _ = try reader.nextInt16(); // reserved
        _ = try reader.nextInt16(); // reserved
        _ = try reader.nextInt16(); // reserved
        _ = try reader.nextInt16(); // reserved
        const metric_data_format = try reader.nextInt16();
        if (metric_data_format != 0) return error.UnsupportedMetricDataFormat;
        const number_of_h_metrics = try reader.nextUint16();
        return .{
            .ascender = ascender,
            .descender = descender,
            .line_gap = line_gap,
            .advance_width_max = advance_width_max,
            .min_left_side_bearing = min_left_side_bearing,
            .min_right_side_bearing = min_right_side_bearing,
            .x_max_extent = x_max_extent,
            .caret_slope_rise = caret_slope_rise,
            .caret_slope_run = caret_slope_run,
            .caret_offset = caret_offset,
            .number_of_h_metrics = number_of_h_metrics,
        };
    }
};

const Maxp = struct {
    num_glyphs: u16,
    max_points: u16,
    max_contours: u16,
    max_composite_points: u16,
    max_composite_contours: u16,
    max_zones: u16,
    max_twilight_points: u16,
    max_storage: u16,
    max_function_defs: u16,
    max_instruction_defs: u16,
    max_stack_elements: u16,
    max_size_of_instructions: u16,
    max_component_elements: u16,
    max_component_depth: u16,

    fn parse(data: []const u8) !@This() {
        var reader = Reader.init(data);

        const version = try reader.nextUint32();
        if (version < 0x00010000 or version >= 0x00020000) return error.UnsupportedTableVersion;

        return .{
            .num_glyphs = try reader.nextUint16(),
            .max_points = try reader.nextUint16(),
            .max_contours = try reader.nextUint16(),
            .max_composite_points = try reader.nextUint16(),
            .max_composite_contours = try reader.nextUint16(),
            .max_zones = try reader.nextUint16(),
            .max_twilight_points = try reader.nextUint16(),
            .max_storage = try reader.nextUint16(),
            .max_function_defs = try reader.nextUint16(),
            .max_instruction_defs = try reader.nextUint16(),
            .max_stack_elements = try reader.nextUint16(),
            .max_size_of_instructions = try reader.nextUint16(),
            .max_component_elements = try reader.nextUint16(),
            .max_component_depth = try reader.nextUint16(),
        };
    }
};

const Vhea = struct {
    vert_typo_ascender: i16,
    vert_typo_descender: i16,
    vert_typo_line_gap: i16,
    advance_height_max: i16,
    min_top_side_bearing: i16,
    min_bottom_side_bearing: i16,
    y_max_extent: i16,
    caret_slope_rise: i16,
    caret_slope_run: i16,
    caret_offset: i16,
    num_of_long_ver_metrics: u16,

    fn parse(data: []const u8) !@This() {
        var reader = Reader.init(data);
        const version = try reader.nextVersion16Dot16();
        if (version < 0x00010000 or version >= 0x00020000) return error.UnsupportedTableVersion;
        const vert_typo_ascender = try reader.nextInt16();
        const vert_typo_descender = try reader.nextInt16();
        const vert_typo_line_gap = try reader.nextInt16();
        const advance_height_max = try reader.nextInt16();
        const min_top_side_bearing = try reader.nextInt16();
        const min_bottom_side_bearing = try reader.nextInt16();
        const y_max_extent = try reader.nextInt16();
        const caret_slope_rise = try reader.nextInt16();
        const caret_slope_run = try reader.nextInt16();
        const caret_offset = try reader.nextInt16();
        _ = try reader.nextInt16(); // reserved
        _ = try reader.nextInt16(); // reserved
        _ = try reader.nextInt16(); // reserved
        _ = try reader.nextInt16(); // reserved
        const metric_data_format = try reader.nextInt16();
        if (metric_data_format != 0) return error.UnsupportedMetricDataFormat;
        const num_of_long_ver_metrics = try reader.nextUint16();
        return .{
            .vert_typo_ascender = vert_typo_ascender,
            .vert_typo_descender = vert_typo_descender,
            .vert_typo_line_gap = vert_typo_line_gap,
            .advance_height_max = advance_height_max,
            .min_top_side_bearing = min_top_side_bearing,
            .min_bottom_side_bearing = min_bottom_side_bearing,
            .y_max_extent = y_max_extent,
            .caret_slope_rise = caret_slope_rise,
            .caret_slope_run = caret_slope_run,
            .caret_offset = caret_offset,
            .num_of_long_ver_metrics = num_of_long_ver_metrics,
        };
    }
};

const Cvt = struct {
    fn parse(comptime data: []const u8) ![]const FWORD {
        var reader = Reader.init(data);
        const n_values = try std.math.divExact(usize, data.len, 2);
        var values: [n_values]FWORD = undefined;
        for (&values) |*v| v.* = try reader.nextFWORD();
        return comptime &values;
    }
};

const Loca = struct {
    fn parse(
        comptime data: []const u8,
        comptime num_glyphs: u16,
        comptime index_to_loc_format: Head.IndexToLocFormat,
    ) ![]const u32 {
        var reader = Reader.init(data);
        var offsets: [@as(usize, num_glyphs) + 1]u32 = undefined;

        switch (index_to_loc_format) {
            .Offset16 => {
                for (&offsets) |*e| e.* = @as(u32, try reader.nextUint16()) * 2;
            },

            .Offset32 => {
                for (&offsets) |*e| e.* = try reader.nextUint32();
            },
        }

        return comptime &offsets;
    }
};

test "parse font" {
    const font_data = @embedFile("Roboto-Regular.ttf");
    const directory = try comptime Directory.extract(font_data);
    const cmap = try comptime Cmap.parse(directory.tableData("cmap").?);
    const cvt = try comptime Cvt.parse(directory.tableData("cvt ").?);
    const head = try comptime Head.parse(directory.tableData("head").?);
    const hhea = try Hhea.parse(directory.tableData("hhea").?);
    const maxp = try comptime Maxp.parse(directory.tableData("maxp").?);
    const loca = try Loca.parse(directory.tableData("loca").?, maxp.num_glyphs, head.index_to_loc_format);
    std.debug.print(
        "\ncmap: {any}\ncvt: {any}\nhead: {any}\nhhea: {any}\nmaxp: {any}\nloca: {any}\n",
        .{ cmap, cvt, head, hhea, maxp, loca },
    );
}
