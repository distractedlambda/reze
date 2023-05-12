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

    fn nextBytes(self: *@This(), comptime len: usize) [len]u8 {
        defer self.source = self.source[len..];
        return self.source[0..len].*;
    }

    fn nextInt(self: *@This(), comptime T: type) T {
        switch (@typeInfo(T)) {
            .Int => {
                const int = @bitCast(T, self.nextBytes(@divExact(@bitSizeOf(T), 8)));
                return if (@import("builtin").cpu.arch.endian() == .Big) int else @byteSwap(int);
            },

            .Enum => |info| {
                return @intToEnum(T, self.nextInt(info.tag_type));
            },

            else => unreachable,
        }
    }

    fn nextUint8(self: *@This()) u8 {
        return self.nextInt(u8);
    }

    fn nextInt8(self: *@This()) i8 {
        return self.nextInt(i8);
    }

    fn nextUint16(self: *@This()) u16 {
        return self.nextInt(u16);
    }

    fn nextInt16(self: *@This()) i16 {
        return self.nextInt(i16);
    }

    fn nextUint24(self: *@This()) u24 {
        return self.nextInt(u24);
    }

    fn nextUint32(self: *@This()) u32 {
        return self.nextInt(u32);
    }

    fn nextInt32(self: *@This()) i32 {
        return self.nextInt(i32);
    }

    const nextFWORD = nextInt16;

    const nextUFWORD = nextUint16;

    const nextF2DOT4 = nextInt16;

    fn nextLONGDATETIME(self: *@This()) LONGDATETIME {
        return self.nextInt(LONGDATETIME);
    }

    fn nextTag(self: *@This()) Tag {
        return self.nextBytes(4);
    }

    fn nextOffset16(self: *@This()) Offset16 {
        const value = self.nextUint16();
        return if (value != 0) value else null;
    }

    fn nextOffset24(self: *@This()) Offset24 {
        const value = self.nextUint24();
        return if (value != 0) value else null;
    }

    fn nextOffset32(self: *@This()) Offset32 {
        const value = self.nextUint32();
        return if (value != 0) value else null;
    }

    const nextVersion16Dot16 = nextUint32;

    fn slice(self: *@This(), len: usize) @This() {
        defer self.source = self.source[len..];
        return .{ .source = self.source[0..len] };
    }

    fn limit(self: *@This(), len: usize) void {
        self.source = self.source[0..len];
    }

    fn remaining(self: @This()) usize {
        return self.source.len;
    }

    fn empty(self: @This()) bool {
        return self.source.len != 0;
    }
};

const Font = struct {
    cmap: Cmap,
    cvt: []const FWORD,
    fpgm: []const u8,
    maxp: Maxp,
    prep: []const u8,

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

        fn parse(comptime data: []const u8) @This() {
            @setEvalBranchQuota(10000);

            var reader = Reader.init(data);

            _ = reader.nextUint16(); // version
            const num_tables = reader.nextUint16();

            var format_4_reader: ?Reader = null;
            var format_12_reader: ?Reader = null;

            for (0..num_tables) |_| {
                const platform_id = reader.nextUint16();
                const encoding_id = reader.nextUint16();
                const subtable_offset = reader.nextUint32();

                if (platform_id != 0) continue;
                if (encoding_id != 3 and encoding_id != 4) continue;

                var subtable_reader = Reader.init(data[subtable_offset..]);

                const format = subtable_reader.nextUint16();

                switch (format) {
                    4 => format_4_reader = subtable_reader,
                    12 => format_12_reader = subtable_reader,
                    else => {},
                }
            }

            if (format_12_reader) |*subtable_reader| {
                _ = subtable_reader.nextUint16(); // reserved
                _ = subtable_reader.nextUint32(); // length
                _ = subtable_reader.nextUint32(); // language
                const num_groups = subtable_reader.nextUint32();

                var parsed_groups: [num_groups]SequentialMapGroup = undefined;

                for (&parsed_groups) |*group| group.* = .{
                    .start_char_code = reader.nextUint32(),
                    .end_char_code = reader.nextUint32(),
                    .start_glyph_id = reader.nextUint32(),
                };

                return comptime .{ .Format12 = &parsed_groups };
            }

            if (format_4_reader) |*subtable_reader| {
                const length = subtable_reader.nextUint16();
                subtable_reader.limit(length - 4);

                _ = subtable_reader.nextUint16(); // language
                const seg_count_x2 = subtable_reader.nextUint16();
                _ = subtable_reader.nextUint16(); // searchRange
                _ = subtable_reader.nextUint16(); // entrySelector
                _ = subtable_reader.nextUint16(); // rangeShift
                var end_code_reader = subtable_reader.slice(seg_count_x2);
                _ = subtable_reader.nextUint16(); // reservedPad
                var start_code_reader = subtable_reader.slice(seg_count_x2);
                var id_delta_reader = subtable_reader.slice(seg_count_x2);
                var id_range_offsets_reader = subtable_reader.slice(seg_count_x2);

                const seg_count = @divExact(seg_count_x2, 2);
                var end_codes: [seg_count]u16 = undefined;
                var start_codes: [seg_count]u16 = undefined;
                var id_deltas: [seg_count]i16 = undefined;
                var id_range_offsets: [seg_count]u16 = undefined;

                for (0..seg_count) |i| {
                    end_codes[i] = end_code_reader.nextUint16();
                    start_codes[i] = start_code_reader.nextUint16();
                    id_deltas[i] = id_delta_reader.nextInt16();
                    id_range_offsets[i] = id_range_offsets_reader.nextUint16();
                }

                var glyph_id_array: [@divExact(subtable_reader.remaining(), 2)]u16 = undefined;
                for (&glyph_id_array) |*glyph_id| glyph_id.* = subtable_reader.nextUint16();

                return comptime .{ .Format4 = .{
                    .end_codes = &end_codes,
                    .start_codes = &start_codes,
                    .id_deltas = &id_deltas,
                    .id_range_offsets_and_glyph_id_array = &(id_range_offsets ++ glyph_id_array),
                } };
            }

            unreachable;
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

        fn parse(data: []const u8) @This() {
            var reader = Reader.init(data);

            const version = reader.nextUint32();

            if (version < 0x00010000) {
                unreachable;
            }

            return .{
                .num_glyphs = reader.nextUint16(),
                .max_points = reader.nextUint16(),
                .max_contours = reader.nextUint16(),
                .max_composite_points = reader.nextUint16(),
                .max_composite_contours = reader.nextUint16(),
                .max_zones = reader.nextUint16(),
                .max_twilight_points = reader.nextUint16(),
                .max_storage = reader.nextUint16(),
                .max_function_defs = reader.nextUint16(),
                .max_instruction_defs = reader.nextUint16(),
                .max_stack_elements = reader.nextUint16(),
                .max_size_of_instructions = reader.nextUint16(),
                .max_component_elements = reader.nextUint16(),
                .max_component_depth = reader.nextUint16(),
            };
        }
    };

    const Directory = struct {
        cmap: ?[]const u8 = null,
        cvt: ?[]const u8 = null,
        fpgm: ?[]const u8 = null,
        maxp: ?[]const u8 = null,
        prep: ?[]const u8 = null,

        fn parse(file_data: []const u8) @This() {
            var result: @This() = .{};
            var reader = Reader.init(file_data);

            _ = reader.nextUint32(); // sfntVersion
            const num_tables = reader.nextUint16();
            _ = reader.nextUint16(); // searchRange
            _ = reader.nextUint16(); // entrySelector
            _ = reader.nextUint16(); // rangeShift

            for (0..num_tables) |_| {
                const tag = reader.nextTag();
                _ = reader.nextUint32(); // checksum
                const offset = reader.nextUint32();
                const length = reader.nextUint32();

                const table_data = file_data[offset..][0..length];

                switch (@bitCast(u32, tag)) {
                    @bitCast(u32, @as([4]u8, "cmap".*)) => result.cmap = table_data,
                    @bitCast(u32, @as([4]u8, "cvt ".*)) => result.cvt = table_data,
                    @bitCast(u32, @as([4]u8, "fpgm".*)) => result.fpgm = table_data,
                    @bitCast(u32, @as([4]u8, "maxp".*)) => result.maxp = table_data,
                    @bitCast(u32, @as([4]u8, "prep".*)) => result.prep = table_data,
                    else => {},
                }
            }

            return result;
        }
    };

    fn parse(comptime file_data: []const u8) @This() {
        const directory = Directory.parse(file_data);
        return comptime .{
            .cmap = Cmap.parse(directory.cmap.?),

            .cvt = blk: {
                if (directory.cvt) |cvt_data| {
                    var reader = Reader.init(cvt_data);
                    var values: [cvt_data.len / 2]FWORD = undefined;
                    for (&values) |*v| v.* = reader.nextFWORD();
                    break :blk &values;
                } else {
                    break :blk &.{};
                }
            },

            .fpgm = directory.fpgm orelse &.{},

            .maxp = Maxp.parse(directory.maxp.?),

            .prep = directory.prep orelse &.{},
        };
    }
};

test "parse and dump test font" {
    const font = comptime Font.parse(@embedFile("Roboto-Regular.ttf"));
    std.debug.print(
        "{s}",
        .{try std.json.stringifyAlloc(std.heap.c_allocator, font, .{ .whitespace = .{} })},
    );
}
