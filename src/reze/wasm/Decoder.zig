const std = @import("std");

const ast = @import("ast.zig");
const opcodes = @import("opcodes.zig");

data: []const u8,

pub fn init(data: []const u8) @This() {
    return .{ .data = data };
}

pub fn atEnd(self: *const @This()) bool {
    return self.data.len == 0;
}

pub fn nextByte(self: *@This()) !u8 {
    if (self.data.len == 0) return error.UnexpectedEndOfData;
    defer self.data = self.data[1..];
    return self.data[0];
}

pub fn peekByte(self: *const @This()) !u8 {
    if (self.data.len == 0) return error.UnexpectedEndOfData;
    return self.data[0];
}

pub fn nextBytes(self: *@This(), len: anytype) !(switch (@typeInfo(@TypeOf(len))) {
    .ComptimeInt => *const [len]u8,

    .Int => |info| if (info.signedness != .unsigned)
        @compileError("signed lengths are not supported")
    else
        []const u8,

    else => @compileError("unsupported len type: " ++ @typeName(@TypeOf(len))),
}) {
    if (self.data.len < len) return error.UnexpectedEndOfData;
    defer self.data = self.data[len..];
    return self.data[0..len];
}

pub fn remainder(self: *@This()) []const u8 {
    defer self.data = self.data[self.data.len..];
    return self.data;
}

pub fn nextInt(self: *@This(), comptime T: type) !T {
    const max_bytes = std.math.divCeil(comptime_int, @bitSizeOf(T), 7) catch unreachable;

    var accum: T = 0;

    inline for (0..max_bytes) |i| {
        const b = try self.nextByte();

        const remaining_bits = @bitSizeOf(T) - i * 7;
        if (comptime remaining_bits < 7) {
            if (b > std.math.maxInt(std.meta.Int(.unsigned, remaining_bits)))
                return error.Overflow;

            return accum | (@as(
                T,
                @bitCast(
                    std.meta.Int(@typeInfo(T).Int.signedness, remaining_bits),
                    @truncate(std.meta.Int(.unsigned, remaining_bits), b),
                ),
            ) << (i * 7));
        }

        if (b <= std.math.maxInt(u7))
            return accum | (@as(
                T,
                @bitCast(
                    std.meta.Int(@typeInfo(T).Int.signedness, 7),
                    @truncate(u7, b),
                ),
            ) << (i * 7))
        else
            accum |= @as(T, @truncate(u7, b)) << (i * 7);
    }

    return error.Overflow;
}

pub fn nextFixedWidth(self: *@This(), comptime T: type) !T {
    return @bitCast(
        T,
        std.mem.readIntLittle(
            std.meta.Int(.unsigned, @bitSizeOf(T)),
            try self.nextBytes(comptime @divExact(@bitSizeOf(T), 8)),
        ),
    );
}

pub fn nextByteVector(self: *@This()) !ast.Name {
    return try self.nextBytes(try self.nextInt(u32));
}

// TODO: validate UTF8?
pub const nextName = nextByteVector;

pub fn nextNumType(self: *@This()) !ast.NumType {
    return std.meta.intToEnum(ast.NumType, try self.nextByte()) catch
        error.UnsupportedNumberType;
}

pub fn nextVecType(self: *@This()) !ast.VecType {
    return std.meta.intToEnum(ast.VecType, try self.nextByte()) catch
        error.UnsupportedVectorType;
}

pub fn nextRefType(self: *@This()) !ast.RefType {
    return std.meta.intToEnum(ast.RefType, try self.nextByte()) catch
        error.UnsupportedReferenceType;
}

pub fn nextValType(self: *@This()) !ast.ValType {
    return std.meta.intToEnum(ast.ValType, try self.nextByte()) catch
        error.UnsupportedValueType;
}

pub fn nextResultType(self: *@This()) !ast.ResultType {
    const len = try self.nextInt(u32);
    const types = try self.nextBytes(len);

    for (types) |t|
        _ = std.meta.intToEnum(ast.ValType, t) catch
            return error.UnsupportedValueType;

    return std.mem.bytesAsSlice(ast.ValType, types);
}

pub fn nextFuncType(self: *@This()) !ast.FuncType {
    if (try self.nextByte() != 0x60)
        return error.UnsupportedFunctionType;

    return .{
        .parameters = try self.nextResultType(),
        .results = try self.nextResultType(),
    };
}

pub fn nextLimits(self: *@This()) !ast.Limits {
    return switch (try self.nextByte()) {
        0x00 => .{ .min = try self.nextInt(u32) },
        0x01 => .{ .min = try self.nextInt(u32), .max = try self.nextInt(u32) },
        else => error.UnsupportedLimits,
    };
}

pub fn nextMemType(self: *@This()) !ast.MemType {
    return .{ .limits = try self.nextLimits() };
}

pub fn nextTableType(self: *@This()) !ast.TableType {
    return .{
        .element_type = try self.nextRefType(),
        .limits = try self.nextLimits(),
    };
}

pub fn nextMut(self: *@This()) !ast.Mut {
    return std.meta.intToEnum(ast.Mut, try self.nextByte()) catch
        error.UnsupportedMutability;
}

pub fn nextElemKind(self: *@This()) !ast.ElemKind {
    return std.meta.intToEnum(ast.ElemKind, try self.nextByte()) catch
        error.UnsupportedElemKind;
}

pub fn nextGlobalType(self: *@This()) !ast.GlobalType {
    return .{
        .value_type = try self.nextValType(),
        .mut = try self.nextMut(),
    };
}

pub fn nextBlockType(self: *@This()) !ast.BlockType {
    return switch (try self.nextInt(i33)) {
        @bitCast(i7, @as(u7, 0x40)) => .{ .immediate = null },
        @bitCast(i7, @as(u7, 0x6f)) => .{ .immediate = .externref },
        @bitCast(i7, @as(u7, 0x70)) => .{ .immediate = .funcref },
        @bitCast(i7, @as(u7, 0x7b)) => .{ .immediate = .v128 },
        @bitCast(i7, @as(u7, 0x7c)) => .{ .immediate = .f64 },
        @bitCast(i7, @as(u7, 0x7d)) => .{ .immediate = .f32 },
        @bitCast(i7, @as(u7, 0x7e)) => .{ .immediate = .i64 },
        @bitCast(i7, @as(u7, 0x7f)) => .{ .immediate = .i32 },
        0...std.math.maxInt(u32) => |idx| .{ .indexed = .{ .value = @intCast(u32, idx) } },
        else => error.UnsupportedBlockType,
    };
}

pub fn nextSectionId(self: *@This()) !ast.SectionId {
    return @intToEnum(ast.SectionId, try self.nextByte());
}

pub fn nextSection(self: *@This()) !ast.Section {
    return .{
        .id = try self.nextSectionId(),
        .contents = try self.nextBytes(try self.nextInt(u32)),
    };
}

pub fn nextInstr(self: *@This(), allocator: std.mem.Allocator) !ast.Instr {
    return switch (try self.nextByte()) {
        opcodes.@"i32.const" => .{ .@"i32.const" = try self.nextInt(i32) },
        opcodes.@"i64.const" => .{ .@"i64.const" = try self.nextInt(i64) },
        opcodes.@"f32.const" => .{ .@"f32.const" = try self.nextFixedWidth(f32) },
        opcodes.@"f64.const" => .{ .@"f64.const" = try self.nextFixedWidth(f64) },

        opcodes.br_table => .{ .br_table = blk: {
            const n_targets = try self.nextInt(u32);
            const targets = try allocator.alloc(ast.LabelIdx, n_targets);
            errdefer allocator.free(targets);
            for (targets) |*t| t.value = try self.nextInt(u32);
            break :blk .{ targets, .{ .value = try self.nextInt(u32) } };
        } },

        inline opcodes.block,
        opcodes.loop,
        opcodes.@"if",
        => |code| @unionInit(
            ast.Instr,
            opcodes.shortOpcodeName(code).?,
            try self.nextBlockType(),
        ),

        inline opcodes.br,
        opcodes.br_if,
        opcodes.call,
        opcodes.@"ref.func",
        opcodes.@"local.get",
        opcodes.@"local.set",
        opcodes.@"local.tee",
        opcodes.@"global.get",
        opcodes.@"global.set",
        opcodes.@"table.get",
        opcodes.@"table.set",
        opcodes.@"memory.size",
        opcodes.@"memory.grow",
        => |code| @unionInit(
            ast.Instr,
            opcodes.shortOpcodeName(code).?,
            .{ .value = try self.nextInt(u32) },
        ),

        inline opcodes.@"unreachable",
        opcodes.nop,
        opcodes.@"else",
        opcodes.end,
        opcodes.@"return",
        opcodes.@"ref.is_null",
        opcodes.drop,
        opcodes.@"i32.eqz",
        opcodes.@"i32.eq",
        opcodes.@"i32.ne",
        opcodes.@"i32.lt_s",
        opcodes.@"i32.lt_u",
        opcodes.@"i32.gt_s",
        opcodes.@"i32.gt_u",
        opcodes.@"i32.le_s",
        opcodes.@"i32.le_u",
        opcodes.@"i32.ge_s",
        opcodes.@"i32.ge_u",
        opcodes.@"i64.eqz",
        opcodes.@"i64.eq",
        opcodes.@"i64.ne",
        opcodes.@"i64.lt_s",
        opcodes.@"i64.lt_u",
        opcodes.@"i64.gt_s",
        opcodes.@"i64.gt_u",
        opcodes.@"i64.le_s",
        opcodes.@"i64.le_u",
        opcodes.@"i64.ge_s",
        opcodes.@"i64.ge_u",
        opcodes.@"f32.eq",
        opcodes.@"f32.ne",
        opcodes.@"f32.lt",
        opcodes.@"f32.gt",
        opcodes.@"f32.le",
        opcodes.@"f32.ge",
        opcodes.@"f64.eq",
        opcodes.@"f64.ne",
        opcodes.@"f64.lt",
        opcodes.@"f64.gt",
        opcodes.@"f64.le",
        opcodes.@"f64.ge",
        opcodes.@"i32.clz",
        opcodes.@"i32.ctz",
        opcodes.@"i32.popcnt",
        opcodes.@"i32.add",
        opcodes.@"i32.sub",
        opcodes.@"i32.mul",
        opcodes.@"i32.div_s",
        opcodes.@"i32.div_u",
        opcodes.@"i32.rem_s",
        opcodes.@"i32.rem_u",
        opcodes.@"i32.and",
        opcodes.@"i32.or",
        opcodes.@"i32.xor",
        opcodes.@"i32.shl",
        opcodes.@"i32.shr_s",
        opcodes.@"i32.shr_u",
        opcodes.@"i32.rotl",
        opcodes.@"i32.rotr",
        opcodes.@"i64.clz",
        opcodes.@"i64.ctz",
        opcodes.@"i64.popcnt",
        opcodes.@"i64.add",
        opcodes.@"i64.sub",
        opcodes.@"i64.mul",
        opcodes.@"i64.div_s",
        opcodes.@"i64.div_u",
        opcodes.@"i64.rem_s",
        opcodes.@"i64.rem_u",
        opcodes.@"i64.and",
        opcodes.@"i64.or",
        opcodes.@"i64.xor",
        opcodes.@"i64.shl",
        opcodes.@"i64.shr_s",
        opcodes.@"i64.shr_u",
        opcodes.@"i64.rotl",
        opcodes.@"i64.rotr",
        opcodes.@"f32.abs",
        opcodes.@"f32.neg",
        opcodes.@"f32.ceil",
        opcodes.@"f32.floor",
        opcodes.@"f32.trunc",
        opcodes.@"f32.nearest",
        opcodes.@"f32.sqrt",
        opcodes.@"f32.add",
        opcodes.@"f32.sub",
        opcodes.@"f32.mul",
        opcodes.@"f32.div",
        opcodes.@"f32.min",
        opcodes.@"f32.max",
        opcodes.@"f32.copysign",
        opcodes.@"f64.abs",
        opcodes.@"f64.neg",
        opcodes.@"f64.ceil",
        opcodes.@"f64.floor",
        opcodes.@"f64.trunc",
        opcodes.@"f64.nearest",
        opcodes.@"f64.sqrt",
        opcodes.@"f64.add",
        opcodes.@"f64.sub",
        opcodes.@"f64.mul",
        opcodes.@"f64.div",
        opcodes.@"f64.min",
        opcodes.@"f64.max",
        opcodes.@"f64.copysign",
        opcodes.@"i32.wrap_i64",
        opcodes.@"i32.trunc_f32_s",
        opcodes.@"i32.trunc_f32_u",
        opcodes.@"i32.trunc_f64_s",
        opcodes.@"i32.trunc_f64_u",
        opcodes.@"i64.extend_i32_s",
        opcodes.@"i64.extend_i32_u",
        opcodes.@"i64.trunc_f32_s",
        opcodes.@"i64.trunc_f32_u",
        opcodes.@"i64.trunc_f64_s",
        opcodes.@"i64.trunc_f64_u",
        opcodes.@"f32.convert_i32_s",
        opcodes.@"f32.convert_i32_u",
        opcodes.@"f32.convert_i64_s",
        opcodes.@"f32.convert_i64_u",
        opcodes.@"f32.demote_f64",
        opcodes.@"f64.convert_i32_s",
        opcodes.@"f64.convert_i32_u",
        opcodes.@"f64.convert_i64_s",
        opcodes.@"f64.convert_i64_u",
        opcodes.@"f64.promote_f32",
        opcodes.@"i32.reinterpret_f32",
        opcodes.@"i64.reinterpret_f64",
        opcodes.@"f32.reinterpret_i32",
        opcodes.@"f64.reinterpret_i64",
        opcodes.@"i32.extend8_s",
        opcodes.@"i32.extend16_s",
        opcodes.@"i64.extend8_s",
        opcodes.@"i64.extend16_s",
        opcodes.@"i64.extend32_s",
        => |code| @unionInit(ast.Instr, opcodes.shortOpcodeName(code).?, {}),

        else => error.UnsupportedOpcode,
    };
}

test {
    std.testing.refAllDecls(@This());
}

test "empty data is atEnd()" {
    try std.testing.expect(init(&.{}).atEnd());
}

test "nextByte() on empty data returns error" {
    var decoder = init(&.{});
    try std.testing.expectError(error.UnexpectedEndOfData, decoder.nextByte());
}

test "one byte is not atEnd()" {
    try std.testing.expect(!init(&.{69}).atEnd());
}

test "nextByte() on one byte" {
    var decoder = init(&.{69});
    try std.testing.expectEqual(@as(u8, 69), try decoder.nextByte());
    try std.testing.expect(decoder.atEnd());
}

test "nextBytes(1) on one byte" {
    var decoder = init(&.{69});
    try std.testing.expectEqualSlices(u8, &.{69}, try decoder.nextBytes(1));
    try std.testing.expect(decoder.atEnd());
}

test "nextBytes(2) on one byte returns error" {
    var decoder = init(&.{69});
    try std.testing.expectError(error.UnexpectedEndOfData, decoder.nextBytes(@as(usize, 2)));
}

test "single-byte u32" {
    var decoder = init(&.{69});
    try std.testing.expectEqual(@as(u32, 69), try decoder.nextInt(u32));
}

test "single-byte positive i32" {
    var decoder = init(&.{42});
    try std.testing.expectEqual(@as(i32, 42), try decoder.nextInt(i32));
}

test "single-byte negative i32" {
    var decoder = init(&.{69});
    try std.testing.expectEqual(@as(i33, @bitCast(i7, @as(u7, 69))), try decoder.nextInt(i32));
}

test "dual-byte u32" {
    var decoder = init(&.{ 0xa4, 0x03 });
    try std.testing.expectEqual(@as(u32, 420), try decoder.nextInt(u32));
    try std.testing.expect(decoder.atEnd());
}

test "this dual-byte u32 could've been a single byte" {
    var decoder = init(&.{ 0xc5, 0x00 });
    try std.testing.expectEqual(@as(u32, 69), try decoder.nextInt(u32));
    try std.testing.expect(decoder.atEnd());
}

test "triple-byte u32" {
    var decoder = init(&.{ 0xd5, 0xc8, 0x02 });
    try std.testing.expectEqual(@as(u32, 42069), try decoder.nextInt(u32));
    try std.testing.expect(decoder.atEnd());
}

test "max u32" {
    var decoder = init(&.{ 0xff, 0xff, 0xff, 0xff, 0x0f });
    try std.testing.expectEqual(@as(u32, std.math.maxInt(u32)), try decoder.nextInt(u32));
    try std.testing.expect(decoder.atEnd());
}

test "u32 overflow" {
    var decoder = init(&.{ 0xff, 0xff, 0xff, 0xff, 0x1f });
    try std.testing.expectError(error.Overflow, decoder.nextInt(u32));
}

test "name" {
    var decoder = init(&[_]u8{0x09} ++ "John Wick");
    try std.testing.expectEqualSlices(u8, "John Wick", try decoder.nextName());
    try std.testing.expect(decoder.atEnd());
}
