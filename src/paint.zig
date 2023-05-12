const std = @import("std");

const Rgb = struct {
    r: u8,
    g: u8,
    b: u8,
};

const Rgba = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const RgbaPremultiplied = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

const Painter = struct {
    pixels: [*]u32,
    row_stride: usize,
};

const gamma_expand_8_to_16_lut = blk: {
    @setEvalBranchQuota(10000);

    var lut: [256]u16 = undefined;

    for (&lut, 0..) |*e, i| {
        e.* = @round(trueGammaExpand(@as(comptime_float, i) / @as(comptime_float, std.math.maxInt(u8))) * std.math.maxInt(u16));
    }

    break :blk lut;
};

fn trueGammaCompress(c: f64) f64 {
    if (c <= 0.0031308) {
        return 12.92 * c;
    } else {
        return 1.055 * std.math.pow(f64, c, 1 / 2.4) - 0.055;
    }
}

fn trueGammaExpand(c: f64) f64 {
    if (c <= 0.04045) {
        return c / 12.92;
    } else {
        return std.math.pow(f64, (c + 0.055) / 1.055, 2.4);
    }
}

test "generate LUTs" {
    _ = gamma_expand_8_to_16_lut;
}
