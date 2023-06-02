const bytes = @import("../bytes.zig");
const std = @import("std");

const BufferDecoder = bytes.BufferDecoder;
const UnpaddedSlice = bytes.UnpaddedSlice;

table_data: []const u8,
encoding_records: []const [8]u8,

pub fn decode(table_data: []const u8) !@This() {
    var decoder = BufferDecoder(.Big).init(table_data);

    const version = try decoder.next(u16);
    if (version != 0) return error.UnsupportedTableVersion;
    const num_tables = try decoder.next(u16);

    return .{
        .table_data = table_data,
        .encoding_records = try decoder.nextChunkedBytes(8, num_tables),
    };
}

pub const PlatformId = enum(u16) {
    unicode = 0,
    macintosh = 1,
    iso = 2,
    windows = 3,
    custom = 4,
    _,
};

pub const UnicodeEncodingId = enum(u16) {
    unicode_1_0 = 0,
    unicode_1_1 = 1,
    iso_iec_10646 = 2,
    unicode_2_0_bmp_only = 3,
    unicode_2_0_full_repertoire = 4,
    unicode_variation_sequences = 5,
    unicode_full_repertoire = 6,
    _,
};

pub const IsoEncodingId = enum(u16) {
    ascii_7bit = 0,
    iso_10646 = 1,
    iso_8859_1 = 2,
    _,
};

pub const WindowsEncodingId = enum(u16) {
    symbol = 0,
    unicode_bmp = 1,
    shift_jis = 2,
    prc = 3,
    big_5 = 4,
    wansung = 5,
    johab = 6,
    unicode_full_repertoire = 10,
    _,
};

pub const EncodingRecord = struct {
    platform_id: PlatformId,
    encoding_id: u16,
    subtable_data: []const u8,

    pub fn decodeSubtable(self: @This()) !Subtable {
        return Subtable.decode(self.subtable_data);
    }
};

pub const EncodingIterator = struct {
    table_data: []const u8,
    remaining_records: []const [8]u8,

    pub fn next(self: *@This()) !?EncodingRecord {
        if (self.remaining_records.len == 0)
            return null;

        const record_data = &self.remaining_records[0];
        const platform_id = bytes.loadUnpadded(.Big, PlatformId, record_data[0..2]);
        const encoding_id = bytes.loadUnpadded(.Big, u16, record_data[2..4]);
        const subtable_offset = bytes.loadUnpadded(.Big, u32, record_data[4..8]);

        if (subtable_offset > self.table_data.len)
            return error.OutOfBounds;

        self.remaining_records = self.remaining_records[1..];

        return .{
            .platform_id = platform_id,
            .encoding_id = encoding_id,
            .subtable_data = self.table_data[subtable_offset..],
        };
    }
};

pub fn encodings(self: @This()) EncodingIterator {
    return .{
        .table_data = self.table_data,
        .remaining_records = self.encoding_records,
    };
}

pub const Subtable = union(enum) {
    Format0: Format0,
    Format4: Format4,
    Format6: Format6,
    Format12: Format12Or13,
    Format13: Format12Or13,

    pub const Format0 = struct {
        language: u16,
        glyph_id_array: *const [256]u8,

        fn decode(format_data: []const u8) !@This() {
            var decoder = BufferDecoder(.Big).init(format_data);

            const length = try decoder.next(u16);
            try decoder.truncate(try std.math.sub(u16, length, 4));

            return .{
                .language = try decoder.next(u16),
                .glyph_id_array = try decoder.nextBytes(256),
            };
        }

        pub fn resolveGlyph(self: @This(), char_code: u32) ?u32 {
            return if (char_code < 256)
                self.glyph_id_array[@truncate(u8, char_code)]
            else
                null;
        }

        pub fn resolveGlyphSpecialized(comptime self: @This(), char_code: u32) ?u32 {
            return switch (char_code) {
                inline 0...255 => |i| self.glyph_id_array[i],
                else => null,
            };
        }
    };

    pub const Format4 = struct {
        language: u16,
        segment_count: u15,
        end_codes: [*]const [2]u8,
        start_codes: [*]const [2]u8,
        id_deltas: [*]const [2]u8,
        id_range_offsets_and_glyph_id_array: []const [2]u8,

        fn decode(format_data: []const u8) !@This() {
            var decoder = BufferDecoder(.Big).init(format_data);

            const length = try decoder.next(u16);
            try decoder.truncate(try std.math.sub(u16, length, 4));
            const language = try decoder.next(u16);
            const seg_count_x2 = try decoder.next(u16);
            const seg_count = @intCast(u15, try std.math.divExact(u16, seg_count_x2, 2));
            _ = try decoder.next(u16); // searchRange
            _ = try decoder.next(u16); // entrySelector
            _ = try decoder.next(u16); // rangeShift
            const end_codes = try decoder.nextChunkedBytes(2, seg_count);
            _ = try decoder.next(u16); // reservedPad
            const start_codes = try decoder.nextChunkedBytes(2, seg_count);
            const id_deltas = try decoder.nextChunkedBytes(2, seg_count);
            const id_range_offsets_and_glyph_id_array = try decoder.chunkedRemainder(2);

            return .{
                .language = language,
                .segment_count = seg_count,
                .end_codes = end_codes.ptr,
                .start_codes = start_codes.ptr,
                .id_deltas = id_deltas.ptr,
                .id_range_offsets_and_glyph_id_array = id_range_offsets_and_glyph_id_array.ptr,
            };
        }

        pub fn resolveGlyph(self: @This(), char_code: u32) !?u32 {

        }
    };

    pub const Format6 = struct {
        language: u16,
        first_code: u16,
        glyph_id_array: []const [2]u8,

        fn decode(format_data: []const u8) !@This() {
            var decoder = BufferDecoder(.Big).init(format_data);

            const length = try decoder.next(u16);
            try decoder.truncate(try std.math.sub(u16, length, 4));
            const language = try decoder.next(u16);
            const first_code = try decoder.next(u16);
            const entry_count = try decoder.next(u16);
            const glyph_id_array = try decoder.nextChunkedBytes(2, entry_count);

            return .{
                .language = language,
                .first_code = first_code,
                .glyph_id_array = glyph_id_array,
            };
        }
    };

    pub const Format12Or13 = struct {
        language: u32,
        groups: []const [12]u8,

        fn decode(format_data: []const u8) !@This() {
            var decoder = BufferDecoder(.Big).init(format_data);

            _ = try decoder.next(u16); // reserved
            const length = try decoder.next(u32);
            try decoder.truncate(try std.math.sub(u32, length, 8));
            const language = try decoder.next(u32);
            const num_groups = try decoder.next(u32);
            const groups = try decoder.nextChunkedBytes(12, num_groups);

            return .{
                .language = language,
                .groups = groups,
            };
        }
    };

    fn decode(subtable_data: []const u8) !@This() {
        var decoder = BufferDecoder(.Big).init(subtable_data);

        const format = decoder.next(u16);
        const format_data = decoder.remainder();

        return switch (format) {
            0 => .{ .Format0 = try Format0.decode(format_data) },
            4 => .{ .Format4 = try Format4.decode(format_data) },
            6 => .{ .Format6 = try Format6.decode(format_data) },
            12 => .{ .Format12 = try Format12Or13.decode(format_data) },
            13 => .{ .Format13 = try Format12Or13.decode(format_data) },
            else => error.UnsupportedEncodingFormat,
        };
    }

    pub fn resolveGlyph(self: @This(), char_code: u32) !?u32 {
        return switch (self) {
            .Format0 => |format| format.resolveGlyph(char_code),
            .Format4 => |format| format.resolveGlyph(char_code),
            .Format6 => |format| format.resolveGlyph(char_code),
            .Format12 => |format| format.resolveFormat12Glyph(char_code),
            .Format13 => |format| format.resolveFormat13Glyph(char_code),
        };
    }

    pub fn resolveGlyphSpecialized(comptime self: @This(), char_code: u32) !?u32 {
        return switch (self) {
            .Format0 => |format| format.resolveGlyphSpecialized(char_code),
            .Format4 => |format| format.resolveGlyphSpecialized(char_code),
            .Format6 => |format| format.resolveGlyphSpecialized(char_code),
            .Format12 => |format| format.resolveFormat12GlyphSpecialized(char_code),
            .Format13 => |format| format.resolveFormat13GlyphSpecialized(char_code),
        };
    }
};
