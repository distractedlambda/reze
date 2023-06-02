const otf = @import("../otf.zig");
const std = @import("std");

const F26Dot6 = otf.F26Dot6;
const F2Dot14 = otf.F2Dot14;

control_value_cut_in: otf.F26Dot6 = 68, // 1.0625 pixels
delta_base: i32 = 9,
delta_shift: i32 = 3,
dual_projection_vector: ?[2]otf.F2Dot14 = null,
freedom_vector: [2]otf.F2Dot14 = .{ 1 << 14, 0 }, // x axis
zp: std.PackedIntArray(u1, 3) = std.PackedIntArray(u1, 3).initAllTo(1),
instruct_control: bool = false,
loop: u32 = 1,
minimum_distance: F26Dot6 = 1 << 6, // 1 pixel
projection_vector: [2]F2Dot14 = .{ 1 << 14, 0 }, // x axis
round_state: i32 = 1,
rp: [3]u32 = .{ 0, 0, 0 },
scan_control: bool = false,
single_width_cut_in: F26Dot6 = 0,
single_width_value: F26Dot6 = 0,
