const std = @import("std");

const FixedPoint = @import("scaled_int.zig").FixedPoint;

pub const Tag = [4]u8;
pub const F2Dot14 = FixedPoint(.signed, 2, 14);
pub const F26Dot6 = FixedPoint(.signed, 26, 6);
pub const Fixed = FixedPoint(.signed, 16, 16);
pub const FWord = i16;
pub const UFWord = u16;
pub const LongDateTime = i64;
pub const Version16Dot16 = u32;

pub const GraphicsState = @import("otf/GraphicsState.zig");
pub const Head = @import("otf/head.zig").Head;
pub const Hhea = @import("otf/hhea.zig").Hhea;
pub const Interpreter = @import("otf/Interpreter.zig");
pub const Maxp = @import("otf/maxp.zig").Maxp;
pub const TableDirectory = @import("otf/TableDirectory.zig");

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
        var reader = Reader.init(data);

        const version = reader.nextInt(u16);
        if (version != 0) return error.UnsupportedTableVersion;

        const num_tables = reader.nextInt(u16);

        var format_4_reader: ?Reader = null;
        var format_12_reader: ?Reader = null;

        for (0..num_tables) |_| {
            const platform_id = reader.nextInt(u16);
            const encoding_id = reader.nextInt(u16);
            const subtable_offset = reader.nextInt(u32);

            if (platform_id != 0) continue;
            if (encoding_id != 3 and encoding_id != 4) continue;

            var subtable_reader = Reader.init(data[subtable_offset..]);

            const format = subtable_reader.nextInt(u16);

            switch (format) {
                4 => format_4_reader = subtable_reader,
                12 => format_12_reader = subtable_reader,
                else => {},
            }
        }

        if (format_12_reader) |*subtable_reader| {
            _ = subtable_reader.nextInt(u16); // reserved
            _ = subtable_reader.nextInt(u32); // length
            _ = subtable_reader.nextInt(u32); // language
            const num_groups = subtable_reader.nextInt(u32);

            var parsed_groups: [num_groups]SequentialMapGroup = undefined;

            for (&parsed_groups) |*group| group.* = .{
                .start_char_code = reader.nextInt(u32),
                .end_char_code = reader.nextInt(u32),
                .start_glyph_id = reader.nextInt(u32),
            };

            return comptime .{ .Format12 = &parsed_groups };
        }

        if (format_4_reader) |*subtable_reader| {
            const length = subtable_reader.nextInt(u16);
            subtable_reader.limit(length - 4);

            _ = subtable_reader.nextInt(u16); // language
            const seg_count_x2 = subtable_reader.nextInt(u16);
            _ = subtable_reader.nextInt(u16); // searchRange
            _ = subtable_reader.nextInt(u16); // entrySelector
            _ = subtable_reader.nextInt(u16); // rangeShift
            var end_code_reader = subtable_reader.slice(seg_count_x2);
            _ = subtable_reader.nextInt(u16); // reservedPad
            var start_code_reader = subtable_reader.slice(seg_count_x2);
            var id_delta_reader = subtable_reader.slice(seg_count_x2);
            var id_range_offsets_reader = subtable_reader.slice(seg_count_x2);

            const seg_count = @divExact(seg_count_x2, 2);
            var end_codes: [seg_count]u16 = undefined;
            var start_codes: [seg_count]u16 = undefined;
            var id_deltas: [seg_count]i16 = undefined;
            var id_range_offsets: [seg_count]u16 = undefined;

            for (0..seg_count) |i| {
                end_codes[i] = end_code_reader.nextInt(u16);
                start_codes[i] = start_code_reader.nextInt(u16);
                id_deltas[i] = id_delta_reader.nextInt(i16);
                id_range_offsets[i] = id_range_offsets_reader.nextInt(u16);
            }

            var glyph_id_array: [@divExact(subtable_reader.remaining(), 2)]u16 = undefined;
            for (&glyph_id_array) |*glyph_id| glyph_id.* = subtable_reader.nextInt(u16);

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
        const version = reader.nextVersion16Dot16();
        if (version < 0x00010000 or version >= 0x00020000) return error.UnsupportedTableVersion;
        const vert_typo_ascender = reader.nextInt(i16);
        const vert_typo_descender = reader.nextInt(i16);
        const vert_typo_line_gap = reader.nextInt(i16);
        const advance_height_max = reader.nextInt(i16);
        const min_top_side_bearing = reader.nextInt(i16);
        const min_bottom_side_bearing = reader.nextInt(i16);
        const y_max_extent = reader.nextInt(i16);
        const caret_slope_rise = reader.nextInt(i16);
        const caret_slope_run = reader.nextInt(i16);
        const caret_offset = reader.nextInt(i16);
        _ = reader.nextInt(i16); // reserved
        _ = reader.nextInt(i16); // reserved
        _ = reader.nextInt(i16); // reserved
        _ = reader.nextInt(i16); // reserved
        const metric_data_format = reader.nextInt(i16);
        if (metric_data_format != 0) return error.UnsupportedMetricDataFormat;
        const num_of_long_ver_metrics = reader.nextInt(u16);
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
    fn parse(comptime data: []const u8) []const i16 {
        var reader = Reader.init(data);
        var values: [@divExact(data.len, 2)]i16 = undefined;
        for (&values) |*v| v.* = reader.nextInt(i16);
        return comptime &values;
    }
};

const Loca = struct {
    fn parse(
        comptime data: []const u8,
        comptime num_glyphs: u16,
        comptime index_to_loc_format: Head.IndexToLocFormat,
    ) []const u32 {
        var reader = Reader.init(data);
        var offsets: [@as(usize, num_glyphs) + 1]u32 = undefined;

        switch (index_to_loc_format) {
            .Offset16 => {
                for (&offsets) |*e| e.* = @as(u32, reader.nextInt(u16)) * 2;
            },

            .Offset32 => {
                for (&offsets) |*e| e.* = reader.nextInt(u32);
            },
        }

        return comptime &offsets;
    }
};

const Glyf = struct {
    fn parse(comptime data: []const u8, comptime loca: []const u32, comptime max_composite_components: usize) []const ?Glyph {
        var glyphs: [loca.len - 1]?Glyph = undefined;
        for (&glyphs, 0..) |*glyph, i| glyph.* = Glyph.parse(data[loca[i]..loca[i + 1]], max_composite_components);
        return comptime &glyphs;
    }

    const Glyph = struct {
        x_min: i16,
        y_min: i16,
        x_max: i16,
        y_max: i16,
        instructions: []const u8,
        geometry: Geometry,

        fn parse(comptime data: []const u8, comptime max_composite_components: usize) ?@This() {
            if (data.len == 0) return null;

            var reader = Reader.init(data);
            const number_of_contours = reader.nextInt(i16);
            const x_min = reader.nextInt(i16);
            const y_min = reader.nextInt(i16);
            const x_max = reader.nextInt(i16);
            const y_max = reader.nextInt(i16);
            const geometry_with_instructions = Geometry.parse(reader.source, number_of_contours, max_composite_components);
            return .{
                .x_min = x_min,
                .y_min = y_min,
                .x_max = x_max,
                .y_max = y_max,
                .instructions = geometry_with_instructions.instructions,
                .geometry = geometry_with_instructions.geometry,
            };
        }

        const Geometry = union(enum) {
            Simple: Simple,
            Composite: Composite,

            fn parse(comptime data: []const u8, comptime number_of_contours: i16, comptime max_composite_components: usize) WithInstructions {
                return if (number_of_contours >= 0)
                    Simple.parse(data, number_of_contours)
                else
                    Composite.parse(data, max_composite_components);
            }

            const WithInstructions = struct {
                geometry: Geometry,
                instructions: []const u8,
            };

            const Simple = struct {
                end_point_indices: []const u16,
                points: []const Point,

                const Point = struct {
                    x: i16,
                    y: i16,
                    on_curve: bool,
                };

                const Flags = packed struct(u8) {
                    on_curve_point: bool,
                    x_short_vector: bool,
                    y_short_vector: bool,
                    repeat_flag: bool,
                    x_is_same_or_positive_x_short_vector: bool,
                    y_is_same_or_positive_y_short_vector: bool,
                    overlap_simple: bool,
                    _reserved: u1,
                };

                fn parse(comptime data: []const u8, comptime number_of_contours: usize) WithInstructions {
                    var reader = Reader.init(data);

                    var end_point_indices: [number_of_contours]u16 = undefined;
                    for (&end_point_indices) |*ep| ep.* = reader.nextInt(u16);

                    const num_points = @as(usize, end_point_indices[number_of_contours - 1]) + 1;
                    var points: [num_points]Point = undefined;

                    const instruction_length = reader.nextInt(u16);
                    const instructions = reader.nextSlice(instruction_length);

                    var x_coordinates_size: usize = 0;
                    const flags_size = blk: {
                        var flags_reader = reader;
                        var flags: Flags = undefined;
                        var remaining_repeats: u8 = 0;

                        for (0..num_points) |_| {
                            if (remaining_repeats != 0) {
                                remaining_repeats -= 1;
                            } else {
                                flags = flags_reader.nextInt(Flags);
                            }

                            if (flags.x_short_vector) {
                                x_coordinates_size += 1;
                            } else if (!flags.x_is_same_or_positive_x_short_vector) {
                                x_coordinates_size += 2;
                            }

                            if (flags.repeat_flag) {
                                remaining_repeats = flags_reader.nextInt(u8);
                                flags.repeat_flag = false;
                            }
                        }

                        break :blk reader.remaining() - flags_reader.remaining();
                    };

                    var flags_reader = reader.slice(flags_size);
                    var x_coordinates_reader = reader.slice(x_coordinates_size);
                    var y_coordinates_reader = reader;

                    var flags: Flags = undefined;
                    var remaining_repeats: u8 = 0;
                    var x: i16 = 0;
                    var y: i16 = 0;
                    for (&points) |*point| {
                        if (remaining_repeats != 0) {
                            remaining_repeats -= 1;
                        } else {
                            flags = flags_reader.nextInt(Flags);
                        }

                        if (flags.x_short_vector) {
                            const dx = x_coordinates_reader.nextInt(u8);
                            if (flags.x_is_same_or_positive_x_short_vector) {
                                x += dx;
                            } else {
                                x -= dx;
                            }
                        } else if (!flags.x_is_same_or_positive_x_short_vector) {
                            x += x_coordinates_reader.nextInt(i16);
                        }

                        if (flags.y_short_vector) {
                            const dy = y_coordinates_reader.nextInt(u8);
                            if (flags.y_is_same_or_positive_y_short_vector) {
                                y += dy;
                            } else {
                                y -= dy;
                            }
                        } else if (!flags.y_is_same_or_positive_y_short_vector) {
                            y += y_coordinates_reader.nextInt(i16);
                        }

                        point.x = x;
                        point.y = y;
                        point.on_curve = flags.on_curve_point;

                        if (flags.repeat_flag) {
                            remaining_repeats = flags_reader.nextInt(u8);
                            flags.repeat_flag = false;
                        }
                    }

                    return comptime .{
                        .geometry = .{ .Simple = .{
                            .end_point_indices = &end_point_indices,
                            .points = &points,
                        } },
                        .instructions = instructions,
                    };
                }
            };

            const Composite = struct {
                metrics_source_glyph_index: ?u16,
                components: []const Component,

                const Component = struct {
                    glyph_index: u16,
                    position: Position,
                    rotation_and_scale: [2][2]i16,

                    const Position = union(enum) {
                        Offset: Offset,
                        Anchor: Anchor,

                        const Offset = struct {
                            x: i16,
                            y: i16,
                            coordinate_system: CoordinateSystem,
                            round_to_grid: bool,

                            const CoordinateSystem = enum {
                                parent,
                                child,
                            };
                        };

                        const Anchor = struct {
                            parent_point_index: u16,
                            child_point_index: u16,
                        };
                    };
                };

                const Flags = packed struct(u16) {
                    arg_1_and_2_are_words: bool,
                    args_are_xy_values: bool,
                    round_xy_to_grid: bool,
                    we_have_a_scale: bool,
                    _reserved0: u1,
                    more_components: bool,
                    we_have_an_x_and_y_scale: bool,
                    we_have_a_two_by_two: bool,
                    we_have_instructions: bool,
                    use_my_metrics: bool,
                    overlap_compound: bool,
                    scaled_component_offset: bool,
                    unscaled_component_offset: bool,
                    _reserved1: u3,
                };

                fn parse(comptime data: []const u8, comptime max_components: usize) WithInstructions {
                    var reader = Reader.init(data);
                    var metrics_source_glyph_index: ?u16 = null;
                    var have_instructions = false;
                    var components: [max_components]Component = undefined;

                    const num_components = for (&components, 0..) |*component, i| {
                        const flags = reader.nextInt(Flags);

                        component.glyph_index = reader.nextInt(u16);

                        component.position = blk: {
                            if (flags.args_are_xy_values) {
                                var x: i16 = undefined;
                                var y: i16 = undefined;

                                if (flags.arg_1_and_2_are_words) {
                                    x = reader.nextInt(i16);
                                    y = reader.nextInt(i16);
                                } else {
                                    x = reader.nextInt(i8);
                                    y = reader.nextInt(i8);
                                }

                                break :blk .{ .Offset = .{
                                    .x = x,
                                    .y = y,
                                    .coordinate_system = if (flags.scaled_component_offset) .child else .parent,
                                    .round_to_grid = flags.round_xy_to_grid,
                                } };
                            } else {
                                var parent_point_index: u16 = undefined;
                                var child_point_index: u16 = undefined;

                                if (flags.arg_1_and_2_are_words) {
                                    parent_point_index = reader.nextInt(u16);
                                    child_point_index = reader.nextInt(u16);
                                } else {
                                    parent_point_index = reader.nextInt(u8);
                                    child_point_index = reader.nextInt(u8);
                                }

                                break :blk .{ .Anchor = .{
                                    .parent_point_index = parent_point_index,
                                    .child_point_index = child_point_index,
                                } };
                            }
                        };

                        component.rotation_and_scale = blk: {
                            if (flags.we_have_a_scale) {
                                const scale = reader.nextInt(i16);
                                break :blk .{
                                    .{ scale, 0 },
                                    .{ 0, scale },
                                };
                            }

                            if (flags.we_have_an_x_and_y_scale) {
                                break :blk .{
                                    .{ reader.nextInt(i16), 0 },
                                    .{ 0, reader.nextInt(i16) },
                                };
                            }

                            if (flags.we_have_a_two_by_two) {
                                break :blk .{
                                    .{ reader.nextInt(i16), reader.nextInt(i16) },
                                    .{ reader.nextInt(i16), reader.nextInt(i16) },
                                };
                            }
                        };

                        if (flags.use_my_metrics) {
                            metrics_source_glyph_index = component.glyph_index;
                        }

                        if (flags.we_have_instructions) {
                            have_instructions = true;
                        }

                        if (!flags.more_components) {
                            break i + 1;
                        }
                    };

                    return comptime .{
                        .geometry = .{ .Composite = .{
                            .metrics_source_glyph_index = metrics_source_glyph_index,
                            .components = components[0..num_components],
                        } },
                        .instructions = if (have_instructions) reader.source else &.{},
                    };
                }
            };
        };
    };
};

test "parse font" {
    @setEvalBranchQuota(250000);
    const font_data = @embedFile("Roboto-Regular.ttf");
    const directory = try comptime Directory.extract(font_data);
    const cmap = try comptime Cmap.parse(directory.tableData("cmap").?);
    const cvt = comptime Cvt.parse(directory.tableData("cvt ").?);
    const head = try comptime Head.parse(directory.tableData("head").?);
    const hhea = try Hhea.parse(directory.tableData("hhea").?);
    const maxp = try comptime Maxp.parse(directory.tableData("maxp").?);
    const loca = comptime Loca.parse(directory.tableData("loca").?, maxp.num_glyphs, head.index_to_loc_format);
    const glyf = comptime Glyf.parse(directory.tableData("glyf").?, loca, maxp.max_component_elements);
    std.debug.print(
        "\ncmap: {any}\ncvt: {any}\nhead: {any}\nhhea: {any}\nmaxp: {any}\nloca: {any}\nglyf: {any}\n",
        .{ cmap, cvt, head, hhea, maxp, loca, glyf },
    );
}
