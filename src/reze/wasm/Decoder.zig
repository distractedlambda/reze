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

pub fn nextByteVector(self: *@This()) ![]const u8 {
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

pub fn nextMemArg(self: *@This()) !ast.MemArg {
    return .{
        .alignment = try self.nextInt(u32),
        .offset = try self.nextInt(u32),
    };
}

pub fn nextLaneIdx(self: *@This(), comptime T: type) !T {
    return std.math.cast(T, try self.nextByte()) orelse error.LaneIndexOutOfBounds;
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

        opcodes.call_indirect => .{
            .call_indirect = .{
                .{ .value = try self.nextInt(u32) },
                .{ .value = try self.nextInt(u32) },
            },
        },

        opcodes.select => .{
            .select = null,
        },

        opcodes.@"select t" => .{
            .select = switch (try self.nextInt(u32)) {
                0 => null,
                1 => try self.nextValType(),
                else => return error.UnsupportedSelectArity,
            },
        },

        opcodes.@"ref.null" => .{
            .@"ref.null" = try self.nextRefType(),
        },

        inline opcodes.@"i32.load",
        opcodes.@"i64.load",
        opcodes.@"f32.load",
        opcodes.@"f64.load",
        opcodes.@"i32.load8_s",
        opcodes.@"i32.load8_u",
        opcodes.@"i32.load16_s",
        opcodes.@"i32.load16_u",
        opcodes.@"i64.load8_s",
        opcodes.@"i64.load8_u",
        opcodes.@"i64.load16_s",
        opcodes.@"i64.load16_u",
        opcodes.@"i64.load32_s",
        opcodes.@"i64.load32_u",
        opcodes.@"i32.store",
        opcodes.@"i64.store",
        opcodes.@"f32.store",
        opcodes.@"f64.store",
        opcodes.@"i32.store8",
        opcodes.@"i32.store16",
        opcodes.@"i64.store8",
        opcodes.@"i64.store16",
        opcodes.@"i64.store32",
        => |code| @unionInit(
            ast.Instr,
            opcodes.shortOpcodeName(code).?,
            try self.nextMemArg(),
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

        opcodes.long_prefix => switch (try self.nextInt(u32)) {
            inline opcodes.@"i32.trunc_sat_f32_s",
            opcodes.@"i32.trunc_sat_f32_u",
            opcodes.@"i32.trunc_sat_f64_s",
            opcodes.@"i32.trunc_sat_f64_u",
            opcodes.@"i64.trunc_sat_f32_s",
            opcodes.@"i64.trunc_sat_f32_u",
            opcodes.@"i64.trunc_sat_f64_s",
            opcodes.@"i64.trunc_sat_f64_u",
            => |code| @unionInit(ast.Instr, opcodes.longOpcodeName(code).?, {}),

            inline opcodes.@"elem.drop",
            opcodes.@"table.grow",
            opcodes.@"table.size",
            opcodes.@"table.fill",
            opcodes.@"data.drop",
            opcodes.@"memory.fill",
            => |code| @unionInit(
                ast.Instr,
                opcodes.longOpcodeName(code).?,
                .{ .value = try self.nextInt(u32) },
            ),

            inline opcodes.@"memory.init",
            opcodes.@"memory.copy",
            opcodes.@"table.init",
            opcodes.@"table.copy",
            => |code| @unionInit(
                ast.Instr,
                opcodes.longOpcodeName(code).?,
                .{
                    .{ .value = try self.nextInt(u32) },
                    .{ .value = try self.nextInt(u32) },
                },
            ),

            else => error.UnsupportedOpcode,
        },

        opcodes.simd_prefix => switch (try self.nextInt(u32)) {
            opcodes.@"v128.const" => .{
                .@"v128.const" = try self.nextFixedWidth(u128),
            },

            opcodes.@"i8x16.shuffle" => .{ .@"i8x16.shuffle" = blk: {
                var lanes: [16]u4 = undefined;
                for (&lanes) |*l| l.* = try self.nextLaneIdx(u4);
                break :blk lanes;
            } },

            inline opcodes.@"v128.load",
            opcodes.@"v128.load8x8_s",
            opcodes.@"v128.load8x8_u",
            opcodes.@"v128.load16x4_s",
            opcodes.@"v128.load16x4_u",
            opcodes.@"v128.load32x2_s",
            opcodes.@"v128.load32x2_u",
            opcodes.@"v128.load8_splat",
            opcodes.@"v128.load16_splat",
            opcodes.@"v128.load32_splat",
            opcodes.@"v128.load64_splat",
            opcodes.@"v128.store",
            opcodes.@"v128.load32_zero",
            opcodes.@"v128.load64_zero",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                try self.nextMemArg(),
            ),

            inline opcodes.@"i8x16.extract_lane_s",
            opcodes.@"i8x16.extract_lane_u",
            opcodes.@"i8x16.replace_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                try self.nextLaneIdx(u4),
            ),

            inline opcodes.@"i16x8.extract_lane_s",
            opcodes.@"i16x8.extract_lane_u",
            opcodes.@"i16x8.replace_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                try self.nextLaneIdx(u3),
            ),

            inline opcodes.@"i32x4.extract_lane",
            opcodes.@"i32x4.replace_lane",
            opcodes.@"f32x4.extract_lane",
            opcodes.@"f32x4.replace_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                try self.nextLaneIdx(u2),
            ),

            inline opcodes.@"i64x2.extract_lane",
            opcodes.@"i64x2.replace_lane",
            opcodes.@"f64x2.extract_lane",
            opcodes.@"f64x2.replace_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                try self.nextLaneIdx(u1),
            ),

            inline opcodes.@"v128.load8_lane",
            opcodes.@"v128.store8_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                .{
                    try self.nextMemArg(),
                    try self.nextLaneIdx(u4),
                },
            ),

            inline opcodes.@"v128.load16_lane",
            opcodes.@"v128.store16_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                .{
                    try self.nextMemArg(),
                    try self.nextLaneIdx(u3),
                },
            ),

            inline opcodes.@"v128.load32_lane",
            opcodes.@"v128.store32_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                .{
                    try self.nextMemArg(),
                    try self.nextLaneIdx(u2),
                },
            ),

            inline opcodes.@"v128.load64_lane",
            opcodes.@"v128.store64_lane",
            => |code| @unionInit(
                ast.Instr,
                opcodes.simdOpcodeName(code).?,
                .{
                    try self.nextMemArg(),
                    try self.nextLaneIdx(u1),
                },
            ),

            inline opcodes.@"i8x16.swizzle",
            opcodes.@"i8x16.splat",
            opcodes.@"i16x8.splat",
            opcodes.@"i32x4.splat",
            opcodes.@"i64x2.splat",
            opcodes.@"f32x4.splat",
            opcodes.@"f64x2.splat",
            opcodes.@"i8x16.eq",
            opcodes.@"i8x16.ne",
            opcodes.@"i8x16.lt_s",
            opcodes.@"i8x16.lt_u",
            opcodes.@"i8x16.gt_s",
            opcodes.@"i8x16.gt_u",
            opcodes.@"i8x16.le_s",
            opcodes.@"i8x16.le_u",
            opcodes.@"i8x16.ge_s",
            opcodes.@"i8x16.ge_u",
            opcodes.@"i16x8.eq",
            opcodes.@"i16x8.ne",
            opcodes.@"i16x8.lt_s",
            opcodes.@"i16x8.lt_u",
            opcodes.@"i16x8.gt_s",
            opcodes.@"i16x8.gt_u",
            opcodes.@"i16x8.le_s",
            opcodes.@"i16x8.le_u",
            opcodes.@"i16x8.ge_s",
            opcodes.@"i16x8.ge_u",
            opcodes.@"i32x4.eq",
            opcodes.@"i32x4.ne",
            opcodes.@"i32x4.lt_s",
            opcodes.@"i32x4.lt_u",
            opcodes.@"i32x4.gt_s",
            opcodes.@"i32x4.gt_u",
            opcodes.@"i32x4.le_s",
            opcodes.@"i32x4.le_u",
            opcodes.@"i32x4.ge_s",
            opcodes.@"i32x4.ge_u",
            opcodes.@"f32x4.eq",
            opcodes.@"f32x4.ne",
            opcodes.@"f32x4.lt",
            opcodes.@"f32x4.gt",
            opcodes.@"f32x4.le",
            opcodes.@"f32x4.ge",
            opcodes.@"f64x2.eq",
            opcodes.@"f64x2.ne",
            opcodes.@"f64x2.lt",
            opcodes.@"f64x2.gt",
            opcodes.@"f64x2.le",
            opcodes.@"f64x2.ge",
            opcodes.@"v128.not",
            opcodes.@"v128.and",
            opcodes.@"v128.andnot",
            opcodes.@"v128.or",
            opcodes.@"v128.xor",
            opcodes.@"v128.bitselect",
            opcodes.@"v128.any_true",
            opcodes.@"f32x4.demote_f64x2_zero",
            opcodes.@"f64x2.promote_low_f32x4",
            opcodes.@"i8x16.abs",
            opcodes.@"i8x16.neg",
            opcodes.@"i8x16.popcnt",
            opcodes.@"i8x16.all_true",
            opcodes.@"i8x16.bitmask",
            opcodes.@"i8x16.narrow_i16x8_s",
            opcodes.@"i8x16.narrow_i16x8_u",
            opcodes.@"i8x16.shl",
            opcodes.@"i8x16.shr_s",
            opcodes.@"i8x16.shr_u",
            opcodes.@"i8x16.add",
            opcodes.@"i8x16.add_sat_s",
            opcodes.@"i8x16.add_sat_u",
            opcodes.@"i8x16.sub",
            opcodes.@"i8x16.sub_sat_s",
            opcodes.@"i8x16.sub_sat_u",
            opcodes.@"i8x16.min_s",
            opcodes.@"i8x16.min_u",
            opcodes.@"i8x16.max_s",
            opcodes.@"i8x16.max_u",
            opcodes.@"i8x16.avgr_u",
            opcodes.@"i16x8.extadd_pairwise_i8x16_s",
            opcodes.@"i16x8.extadd_pairwise_i8x16_u",
            opcodes.@"i32x4.extadd_pairwise_i16x8_s",
            opcodes.@"i32x4.extadd_pairwise_i16x8_u",
            opcodes.@"i16x8.abs",
            opcodes.@"i16x8.neg",
            opcodes.@"i16x8.q15mulr_sat_s",
            opcodes.@"i16x8.all_true",
            opcodes.@"i16x8.bitmask",
            opcodes.@"i16x8.narrow_i32x4_s",
            opcodes.@"i16x8.narrow_i32x4_u",
            opcodes.@"i16x8.extend_low_i8x16_s",
            opcodes.@"i16x8.extend_high_i8x16_s",
            opcodes.@"i16x8.extend_low_i8x16_u",
            opcodes.@"i16x8.extend_high_i8x16_u",
            opcodes.@"i16x8.shl",
            opcodes.@"i16x8.shr_s",
            opcodes.@"i16x8.shr_u",
            opcodes.@"i16x8.add",
            opcodes.@"i16x8.add_sat_s",
            opcodes.@"i16x8.add_sat_u",
            opcodes.@"i16x8.sub",
            opcodes.@"i16x8.sub_sat_s",
            opcodes.@"i16x8.sub_sat_u",
            opcodes.@"i16x8.mul",
            opcodes.@"i16x8.min_s",
            opcodes.@"i16x8.min_u",
            opcodes.@"i16x8.max_s",
            opcodes.@"i16x8.max_u",
            opcodes.@"i16x8.avgr_u",
            opcodes.@"i16x8.extmul_low_i8x16_s",
            opcodes.@"i16x8.extmul_high_i8x16_s",
            opcodes.@"i16x8.extmul_low_i8x16_u",
            opcodes.@"i16x8.extmul_high_i8x16_u",
            opcodes.@"i32x4.abs",
            opcodes.@"i32x4.neg",
            opcodes.@"i32x4.all_true",
            opcodes.@"i32x4.bitmask",
            opcodes.@"i32x4.extend_low_i16x8_s",
            opcodes.@"i32x4.extend_high_i16x8_s",
            opcodes.@"i32x4.extend_low_i16x8_u",
            opcodes.@"i32x4.extend_high_i16x8_u",
            opcodes.@"i32x4.shl",
            opcodes.@"i32x4.shr_s",
            opcodes.@"i32x4.shr_u",
            opcodes.@"i32x4.add",
            opcodes.@"i32x4.sub",
            opcodes.@"i32x4.mul",
            opcodes.@"i32x4.min_s",
            opcodes.@"i32x4.min_u",
            opcodes.@"i32x4.max_s",
            opcodes.@"i32x4.max_u",
            opcodes.@"i32x4.dot_i16x8_s",
            opcodes.@"i32x4.extmul_low_i16x8_s",
            opcodes.@"i32x4.extmul_high_i16x8_s",
            opcodes.@"i32x4.extmul_low_i16x8_u",
            opcodes.@"i32x4.extmul_high_i16x8_u",
            opcodes.@"i64x2.abs",
            opcodes.@"i64x2.neg",
            opcodes.@"i64x2.all_true",
            opcodes.@"i64x2.bitmask",
            opcodes.@"i64x2.extend_low_i32x4_s",
            opcodes.@"i64x2.extend_high_i32x4_s",
            opcodes.@"i64x2.extend_low_i32x4_u",
            opcodes.@"i64x2.extend_high_i32x4_u",
            opcodes.@"i64x2.shl",
            opcodes.@"i64x2.shr_s",
            opcodes.@"i64x2.shr_u",
            opcodes.@"i64x2.add",
            opcodes.@"i64x2.sub",
            opcodes.@"i64x2.mul",
            opcodes.@"i64x2.eq",
            opcodes.@"i64x2.ne",
            opcodes.@"i64x2.lt_s",
            opcodes.@"i64x2.gt_s",
            opcodes.@"i64x2.le_s",
            opcodes.@"i64x2.ge_s",
            opcodes.@"i64x2.extmul_low_i32x4_s",
            opcodes.@"i64x2.extmul_high_i32x4_s",
            opcodes.@"i64x2.extmul_low_i32x4_u",
            opcodes.@"i64x2.extmul_high_i32x4_u",
            opcodes.@"f32x4.ceil",
            opcodes.@"f32x4.floor",
            opcodes.@"f32x4.trunc",
            opcodes.@"f32x4.nearest",
            opcodes.@"f64x2.ceil",
            opcodes.@"f64x2.floor",
            opcodes.@"f64x2.trunc",
            opcodes.@"f64x2.nearest",
            opcodes.@"f32x4.abs",
            opcodes.@"f32x4.neg",
            opcodes.@"f32x4.sqrt",
            opcodes.@"f32x4.add",
            opcodes.@"f32x4.sub",
            opcodes.@"f32x4.mul",
            opcodes.@"f32x4.div",
            opcodes.@"f32x4.min",
            opcodes.@"f32x4.max",
            opcodes.@"f32x4.pmin",
            opcodes.@"f32x4.pmax",
            opcodes.@"f64x2.abs",
            opcodes.@"f64x2.neg",
            opcodes.@"f64x2.sqrt",
            opcodes.@"f64x2.add",
            opcodes.@"f64x2.sub",
            opcodes.@"f64x2.mul",
            opcodes.@"f64x2.div",
            opcodes.@"f64x2.min",
            opcodes.@"f64x2.max",
            opcodes.@"f64x2.pmin",
            opcodes.@"f64x2.pmax",
            opcodes.@"i32x4.trunc_sat_f32x4_s",
            opcodes.@"i32x4.trunc_sat_f32x4_u",
            opcodes.@"f32x4.convert_i32x4_s",
            opcodes.@"f32x4.convert_i32x4_u",
            opcodes.@"i32x4.trunc_sat_f64x2_s_zero",
            opcodes.@"i32x4.trunc_sat_f64x2_u_zero",
            opcodes.@"f64x2.convert_low_i32x4_s",
            opcodes.@"f64x2.convert_low_i32x4_u",
            => |code| @unionInit(ast.Instr, opcodes.simdOpcodeName(code).?, {}),

            else => error.UnsupportedOpcode,
        },

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
