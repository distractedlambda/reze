const otf = @import("../otf.zig");

const BufferDecoder = @import("../bytes.zig").BufferDecoder;
const FWord = otf.FWord;
const UFWord = otf.UFWord;

ascender: FWord,
descender: FWord,
line_gap: FWord,
advance_width_max: UFWord,
min_left_side_bearing: FWord,
min_right_side_bearing: FWord,
x_max_extent: FWord,
caret_slope_rise: i16,
caret_slope_run: i16,
caret_offset: i16,
metric_data_format: MetricDataFormat,
number_of_h_metrics: u16,

pub const MetricDataFormat = enum(i16) {
    current = 0,
    _,
};

pub fn decode(table_data: []const u8) !@This() {
    var decoder = BufferDecoder(.Big).init(table_data);

    const major_version = try decoder.next(u16);
    if (major_version != 1) return error.UnsupportedTableVersion;
    _ = try decoder.next(u16); // minorVersion
    const ascender = try decoder.next(FWord);
    const descender = try decoder.next(FWord);
    const line_gap = try decoder.next(FWord);
    const advance_width_max = try decoder.next(FWord);
    const min_left_side_bearing = try decoder.next(FWord);
    const min_right_side_bearing = try decoder.next(FWord);
    const x_max_extent = try decoder.next(FWord);
    const caret_slope_rise = try decoder.next(i16);
    const caret_slope_run = try decoder.next(i16);
    const caret_offset = try decoder.next(i16);
    _ = try decoder.next(i16); // reserved
    _ = try decoder.next(i16); // reserved
    _ = try decoder.next(i16); // reserved
    _ = try decoder.next(i16); // reserved
    const metric_data_format = try decoder.next(MetricDataFormat);
    const number_of_h_metrics = try decoder.next(u16);

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
        .metric_data_format = metric_data_format,
        .number_of_h_metrics = number_of_h_metrics,
    };
}
