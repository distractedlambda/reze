const std = @import("std");

pub fn CBitFlags(comptime Bits: type, comptime c: type, comptime known_flags: anytype) type {
    var fields: [@bitSizeOf(Bits)]std.builtin.Type.StructField = undefined;

    for (&fields, 0..) |*field, i| {
        field.* = .{
            .name = std.fmt.comptimePrint("_reserved{}", .{i}),
            .type = bool,
            .default_value = &false,
            .is_comptime = false,
            .alignment = 0,
        };
    }

    for (known_flags) |kf| {
        if (@hasDecl(c, kf[0])) {
            const bit = @field(c, kf[0]);

            if (@popCount(bit) != 1) {
                @compileError(
                    "constant '" ++ @typeName(c) ++ "." ++ kf[0] ++ "' is not a single bit",
                );
            }

            fields[std.math.log2(@as(comptime_int, bit))].name = kf[1];
        }
    }

    return @Type(.{ .Struct = .{
        .layout = .Packed,
        .fields = &fields,
        .decls = &.{},
        .is_tuple = false,
    } });
}
