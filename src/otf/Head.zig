const otf = @import("../otf.zig");

const BufferDecoder = @import("../bytes.zig").BufferDecoder;
const Fixed = otf.Fixed;
const LongDateTime = otf.LongDateTime;

font_revision: Fixed,
flags: Flags,
units_per_em: u16,
created: LongDateTime,
modified: LongDateTime,
x_min: i16,
y_min: i16,
x_max: i16,
y_max: i16,
mac_style: MacStyle,
lowest_rec_ppem: u16,
index_to_loc_format: IndexToLocFormat,
glyph_data_format: GlyphDataFormat,

pub const Flags = packed struct(u16) {
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

pub const MacStyle = packed struct(u16) {
    bold: bool,
    italic: bool,
    underline: bool,
    outline: bool,
    shadow: bool,
    condensed: bool,
    extended: bool,
    _reserved: u9,
};

pub const IndexToLocFormat = enum(i16) {
    Offset16 = 0,
    Offset32 = 1,
    _,
};

pub const GlyphDataFormat = enum(i16) {
    current = 0,
    _,
};

pub fn decode(table_data: []const u8) !@This() {
    var decoder = BufferDecoder(.Big).init(table_data);

    const major_version = try decoder.next(u16);
    if (major_version != 0) return error.UnsupportedTableVersion;
    _ = try decoder.next(u16); // minorVersion
    const font_revision = try decoder.next(Fixed);
    _ = try decoder.next(u32); // checksumAdjustment
    _ = try decoder.next(u32); // magicNumber
    const flags = try decoder.next(Flags);
    const units_per_em = try decoder.next(u16);
    const created = try decoder.next(LongDateTime);
    const modified = try decoder.next(LongDateTime);
    const x_min = try decoder.next(i16);
    const y_min = try decoder.next(i16);
    const x_max = try decoder.next(i16);
    const y_max = try decoder.next(i16);
    const mac_style = try decoder.next(u16);
    const lowest_rec_ppem = try decoder.next(u16);
    _ = try decoder.next(i16); // fontDirectionHint
    const index_to_loc_format = try decoder.next(IndexToLocFormat);
    const glyph_data_format = try decoder.next(GlyphDataFormat);

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
        .glyph_data_format = glyph_data_format,
    };
}
