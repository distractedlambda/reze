const std = @import("std");

pub fn CEnum(comptime Tag: type, comptime c: type, comptime known_variants: anytype) type {
    var variants: [known_variants.len]std.builtin.Type.EnumField = undefined;
    var n_variants: usize = 0;

    for (known_variants) |kv| {
        if (@hasDecl(c, kv[0])) {
            variants[n_variants] = .{ .name = kv[1], .value = @field(c, kv[0]) };
            n_variants += 1;
        }
    }

    return @Type(.{ .Enum = .{
        .tag_type = Tag,
        .fields = variants[0..n_variants],
        .decls = &.{},
        .is_exhaustive = false,
    } });
}
