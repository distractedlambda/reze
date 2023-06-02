const BufferDecoder = @import("../bytes.zig").BufferDecoder;
const Version16Dot16 = @import("../otf.zig").Version16Dot16;

num_glyphs: u16,
max_points: u16,
max_contours: u16,
max_composite_points: u16,
max_composite_contours: u16,
max_zones: u16,
max_twilight_points: u16,
max_storage: u16,
max_function_defs: u16,
max_stack_elements: u16,
max_size_of_instructions: u16,
max_component_elements: u16,
max_component_depth: u16,

pub fn decode(table_data: []const u8) !@This() {
    var decoder = BufferDecoder(.Big).init(table_data);

    const version = try decoder.next(Version16Dot16);
    if (version != 0x00010000) return error.UnsupportedTableVersion;

    return .{
        .num_glyphs = try decoder.next(u16),
        .max_points = try decoder.next(u16),
        .max_contours = try decoder.next(u16),
        .max_composite_points = try decoder.next(u16),
        .max_composite_contours = try decoder.next(u16),
        .max_zones = try decoder.next(u16),
        .max_twilight_points = try decoder.next(u16),
        .max_storage = try decoder.next(u16),
        .max_function_defs = try decoder.next(u16),
        .max_instruction_defs = try decoder.next(u16),
        .max_stack_elements = try decoder.next(u16),
        .max_size_of_instructions = try decoder.next(u16),
        .max_component_elements = try decoder.next(u16),
        .max_component_depth = try decoder.next(u16),
    };
}
