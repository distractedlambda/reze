const std = @import("std");
const wasm = @import("../wasm.zig");

pub const Opcode = enum {
    udf,
    env_ptr,

    br,
    br_if,
    br_table,
    ret,
    call,
    call_indirect,
    global_get,
    global_set,
    table_get,
    table_set,
    table_size,
    memory_size,

    // pure ops
    // -- constants
    i32_const,
    i64_const,
    f32_const,
    f64_const,
    v128_const,

    // -- arguments
    function_arg,
    block_arg,

    // -- pure unary ops
    // ---- pure unary ops (i32 result)
    i32_eqz,
    i64_eqz,
    i32_clz,
    i32_ctz,
    i32_popcnt,
    i32_wrap_i64,
    i32_reinterpret_f32,
    i32_extend8_s,
    i32_extend16_s,
    ref_is_null,
    i32_trunc_sat_f32_s,
    i32_trunc_sat_f32_u,
    i32_trunc_sat_f64_s,
    i32_trunc_sat_f64_u,
    v128_any_true,
    i8x16_all_true,
    i8x16_bitmask,
    i16x8_all_true,
    i16x8_bitmask,
    i32x4_all_true,
    i32x4_bitmask,
    i64x2_all_true,
    i64x2_bitmask,

    // ---- pure unary ops (i64 result)
    i64_clz,
    i64_ctz,
    i64_popcnt,
    i64_extend_i32_s,
    i64_extend_i32_u,
    i64_reinterpret_f64,
    i64_extend8_s,
    i64_extend16_s,
    i64_extend32_s,
    i64_trunc_sat_f32_s,
    i64_trunc_sat_f32_u,
    i64_trunc_sat_f64_s,
    i64_trunc_sat_f64_u,

    // ---- pure unary ops (f32 result)
    f32_abs,
    f32_neg,
    f32_ceil,
    f32_floor,
    f32_trunc,
    f32_nearest,
    f32_sqrt,
    f32_convert_i32_s,
    f32_convert_i32_u,
    f32_convert_i64_s,
    f32_convert_i64_u,
    f32_demote_f64,
    f32_reinterpret_i32,

    // ---- pure unary ops (f64 result)
    f64_abs,
    f64_neg,
    f64_ceil,
    f64_floor,
    f64_trunc,
    f64_nearest,
    f64_sqrt,
    f64_convert_i32_s,
    f64_convert_i32_u,
    f64_convert_i64_s,
    f64_convert_i64_u,
    f64_promote_f32,
    f64_reinterpret_i64,

    // ---- pure unary ops (v128 result)
    i8x16_splat,
    i16x8_splat,
    i32x4_splat,
    i64x2_splat,
    f32x4_splat,
    f64x2_splat,
    v128_not,
    f32x4_demote_f64x2_zero,
    f64x2_promote_low_f32x4,
    i8x16_abs,
    i8x16_neg,
    i8x16_popcnt,
    i8x16_narrow_i16x8_s,
    i8x16_narrow_i16x8_u,
    f32x4_ceil,
    f32x4_floor,
    f32x4_trunc,
    f32x4_nearest,
    f64x2_ceil,
    f64x2_floor,
    f64x2_trunc,
    i16x8_abs,
    i16x8_neg,
    i16x8_narrow_i32x4_s,
    i16x8_narrow_i32x4_u,
    i16x8_extend_low_i8x16_s,
    i16x8_extend_high_i8x16_s,
    i16x8_extend_low_i8x16_u,
    i16x8_extend_high_i8x16_u,
    f64x2_nearest,
    i32x4_abs,
    i32x4_neg,
    i32x4_extend_low_i16x8_s,
    i32x4_extend_high_i16x8_s,
    i32x4_extend_low_i16x8_u,
    i32x4_extend_high_i16x8_u,
    i64x2_abs,
    i64x2_neg,
    i64x2_extend_low_i32x4_s,
    i64x2_extend_high_i32x4_s,
    i64x2_extend_low_i32x4_u,
    i64x2_extend_high_i32x4_u,
    f32x4_abs,
    f32x4_neg,
    f32x4_sqrt,
    f64x2_abs,
    f64x2_neg,
    f64x2_sqrt,
    i32x4_trunc_sat_f32x4_s,
    i32x4_trunc_sat_f32x4_u,
    f32x4_convert_i32x4_s,
    f32x4_convert_i32x4_u,
    i32x4_trunc_sat_f64x2_s_zero,
    i32x4_trunc_sat_f64x2_u_zero,
    f64x2_convert_low_i32x4_s,
    f64x2_convert_low_i32x4_u,

    // -- pure binary ops
    // ---- pure binary ops (i32 result)
    i32_eq,
    i32_ne,
    i32_lt_s,
    i32_lt_u,
    i32_gt_s,
    i32_gt_u,
    i32_le_s,
    i32_le_u,
    i32_ge_s,
    i32_ge_u,
    i64_eq,
    i64_ne,
    i64_lt_s,
    i64_lt_u,
    i64_gt_s,
    i64_gt_u,
    i64_le_s,
    i64_le_u,
    i64_ge_s,
    i64_ge_u,
    f32_eq,
    f32_ne,
    f32_lt,
    f32_gt,
    f32_le,
    f32_ge,
    f64_eq,
    f64_ne,
    f64_lt,
    f64_gt,
    f64_le,
    f64_ge,
    i32_add,
    i32_sub,
    i32_mul,
    i32_and,
    i32_or,
    i32_xor,
    i32_shl,
    i32_shr_s,
    i32_shr_u,
    i32_rotl,
    i32_rotr,

    // ---- pure binary ops (i64 result)
    i64_add,
    i64_sub,
    i64_mul,
    i64_and,
    i64_or,
    i64_xor,
    i64_shl,
    i64_shr_s,
    i64_shr_u,
    i64_rotl,
    i64_rotr,

    // ---- pure binary ops (f32 result)
    f32_add,
    f32_sub,
    f32_mul,
    f32_div,
    f32_min,
    f32_max,
    f32_copysign,

    // ---- pure binary ops (f64 result)
    f64_add,
    f64_sub,
    f64_mul,
    f64_div,
    f64_min,
    f64_max,
    f64_copysign,

    // ---- pure binary ops (v128 result)
    i8x16_eq,
    i8x16_ne,
    i8x16_lt_s,
    i8x16_lt_u,
    i8x16_gt_s,
    i8x16_gt_u,
    i8x16_le_s,
    i8x16_le_u,
    i8x16_ge_s,
    i8x16_ge_u,
    i16x8_eq,
    i16x8_ne,
    i16x8_lt_s,
    i16x8_lt_u,
    i16x8_gt_s,
    i16x8_gt_u,
    i16x8_le_s,
    i16x8_le_u,
    i16x8_ge_s,
    i16x8_ge_u,
    i32x4_eq,
    i32x4_ne,
    i32x4_lt_s,
    i32x4_lt_u,
    i32x4_gt_s,
    i32x4_gt_u,
    i32x4_le_s,
    i32x4_le_u,
    i32x4_ge_s,
    i32x4_ge_u,
    f32x4_eq,
    f32x4_ne,
    f32x4_lt,
    f32x4_gt,
    f32x4_le,
    f32x4_ge,
    f64x2_eq,
    f64x2_ne,
    f64x2_lt,
    f64x2_gt,
    f64x2_le,
    f64x2_ge,
    v128_and,
    v128_andnot,
    v128_or,
    v128_xor,
    i8x16_shl,
    i8x16_shr_s,
    i8x16_shr_u,
    i8x16_add,
    i8x16_add_sat_s,
    i8x16_add_sat_u,
    i8x16_sub,
    i8x16_sub_sat_s,
    i8x16_sub_sat_u,
    i8x16_min_s,
    i8x16_min_u,
    i8x16_max_s,
    i8x16_max_u,
    i8x16_avgr_u,
    i16x8_extadd_pairwise_i8x16_s,
    i16x8_extadd_pairwise_i8x16_u,
    i32x4_extadd_pairwise_i16x8_s,
    i32x4_extadd_pairwise_i16x8_u,
    i16x8_q15mulr_sat_s,
    i16x8_shl,
    i16x8_shr_s,
    i16x8_shr_u,
    i16x8_add,
    i16x8_add_sat_s,
    i16x8_add_sat_u,
    i16x8_sub,
    i16x8_sub_sat_s,
    i16x8_sub_sat_u,
    i16x8_mul,
    i16x8_min_s,
    i16x8_min_u,
    i16x8_max_s,
    i16x8_max_u,
    i16x8_avgr_u,
    i16x8_extmul_low_i8x16_s,
    i16x8_extmul_high_i8x16_s,
    i16x8_extmul_low_i8x16_u,
    i16x8_extmul_high_i8x16_u,
    i32x4_shl,
    i32x4_shr_s,
    i32x4_shr_u,
    i32x4_add,
    i32x4_sub,
    i32x4_mul,
    i32x4_min_s,
    i32x4_min_u,
    i32x4_max_s,
    i32x4_max_u,
    i32x4_dot_i16x8_s,
    i32x4_extmul_low_i16x8_s,
    i32x4_extmul_high_i16x8_s,
    i32x4_extmul_low_i16x8_u,
    i32x4_extmul_high_i16x8_u,
    i64x2_shl,
    i64x2_shr_s,
    i64x2_shr_u,
    i64x2_add,
    i64x2_sub,
    i64x2_mul,
    i64x2_eq,
    i64x2_ne,
    i64x2_lt_s,
    i64x2_gt_s,
    i64x2_le_s,
    i64x2_ge_s,
    i64x2_extmul_low_i32x4_s,
    i64x2_extmul_high_i32x4_s,
    i64x2_extmul_low_i32x4_u,
    i64x2_extmul_high_i32x4_u,
    f32x4_add,
    f32x4_sub,
    f32x4_mul,
    f32x4_div,
    f32x4_min,
    f32x4_max,
    f32x4_pmin,
    f32x4_pmax,
    f64x2_add,
    f64x2_sub,
    f64x2_mul,
    f64x2_div,
    f64x2_min,
    f64x2_max,
    f64x2_pmin,
    f64x2_pmax,

    i32_load,
    i64_load,
    f32_load,
    f64_load,
    i32_load8_s,
    i32_load8_u,
    i32_load16_s,
    i32_load16_u,
    i64_load8_s,
    i64_load8_u,
    i64_load16_s,
    i64_load16_u,
    i64_load32_s,
    i64_load32_u,

    i32_store,
    i64_store,
    f32_store,
    f64_store,
    i32_store8,
    i32_store16,
    i64_store8,
    i64_store16,
    i64_store32,

    v128_load,
    v128_load_8x8_s,
    v128_load_8x8_u,
    v128_load_16x4_s,
    v128_load_16x4_u,
    v128_load_32x2_s,
    v128_load_32x2_u,
    v128_load8_splat,
    v128_load16_splat,
    v128_load32_splat,
    v128_load64_splat,
    v128_load32_zero,
    v128_load64_zero,

    v128_store,
};

pub const Instruction = struct {
    opcode: Opcode,

    pub fn init(opcode: Opcode) @This() {
        return .{ .opcode = opcode };
    }

    pub fn dedupHash(self: *const @This()) u64 {
        var hasher = std.hash.Wyhash.init(0);
        std.hash.autoHash(&hasher, self.opcode);

        switch (@enumToInt(self.opcode)) {
            @enumToInt(Opcode.i32_const) => {
                std.hash.autoHash(&hasher, @fieldParentPtr(I32Const, "base", self).value);
            },

            @enumToInt(Opcode.i64_const) => {
                std.hash.autoHash(&hasher, @fieldParentPtr(I64Const, "base", self).value);
            },

            @enumToInt(Opcode.f32_const) => {
                std.hash.autoHash(&hasher, @fieldParentPtr(F32Const, "base", self).value);
            },

            @enumToInt(Opcode.f64_const) => {
                std.hash.autoHash(&hasher, @fieldParentPtr(F64Const, "base", self).value);
            },

            @enumToInt(Opcode.v128_const) => {
                std.hash.autoHash(&hasher, @fieldParentPtr(V128Const, "base", self).value);
            },

            else => @panic("unsupported opcode"),
        }

        return hasher.final();
    }

    pub fn dedupEql(self: *const @This(), other: *const @This()) bool {
        if (self.opcode != other.opcode) return false;
        switch (@enumToInt(self.opcode)) {
            @enumToInt(Opcode.i32_const) => {
                return @fieldParentPtr(I32Const, "base", self).value == @fieldParentPtr(I32Const, "base", other).value;
            },

            @enumToInt(Opcode.i64_const) => {
                return @fieldParentPtr(I64Const, "base", self).value == @fieldParentPtr(I64Const, "base", other).value;
            },

            @enumToInt(Opcode.f32_const) => {
                return @fieldParentPtr(F32Const, "base", self).value == @fieldParentPtr(F32Const, "base", other).value;
            },

            @enumToInt(Opcode.f64_const) => {
                return @fieldParentPtr(F64Const, "base", self).value == @fieldParentPtr(F64Const, "base", other).value;
            },

            @enumToInt(Opcode.v128_const) => {
                return @fieldParentPtr(V128Const, "base", self).value == @fieldParentPtr(V128Const, "base", other).value;
            },

            else => @panic("unsupported opcode"),
        }
    }
};

pub const Block = struct {
    head: ?*Instruction = null,
    tail: ?*Instruction = null,
};

pub const SequencedInstruction = struct {
    base: Instruction,
    prior: ?*Instruction = null,
    next: ?*Instruction = null,

    pub fn init(opcode: Opcode) @This() {
        return .{ .base = Instruction.init(opcode) };
    }
};

pub const Br = struct {
    base: Instruction = Instruction.init(.br),
    target: *Block,
    arguments: []*Instruction,
};

pub const BrIf = struct {
    base: Instruction = Instruction.init(.br_if),
    condition: *Instruction,
    target: *Block,
    arguments: []*Instruction,
};

pub const BrTable = struct {
    base: Instruction = Instruction.init(.br_table),
    index: *Instruction,
    cases: []*Block,
    default: *Block,
};

pub const Ret = struct {
    base: Instruction = Instruction.init(.ret),
    values: []*Instruction,
};

pub const Call = struct {
    base: SequencedInstruction = SequencedInstruction.init(.call),
    callee: wasm.FunctionIndex,
    arguments: []*Instruction,
};

pub const CallIndirect = struct {
    base: SequencedInstruction = SequencedInstruction.init(.call_indirect),
    callee_type: wasm.TypeIndex,
    table: wasm.TableIndex,
    index: *Instruction,
    arguments: []*Instruction,
};

pub const GlobalGet = struct {
    base: SequencedInstruction = SequencedInstruction.init(.global_get),
    global: wasm.GlobalIndex,
};

pub const GlobalSet = struct {
    base: SequencedInstruction = SequencedInstruction.init(.global_set),
    global: wasm.GlobalIndex,
    value: *Instruction,
};

pub const TableGet = struct {
    base: SequencedInstruction = SequencedInstruction.init(.table_get),
    table: wasm.TableIndex,
    index: *Instruction,
};

pub const TableSet = struct {
    base: SequencedInstruction = SequencedInstruction.init(.table_set),
    table: wasm.TableIndex,
    index: *Instruction,
    value: *Instruction,
};

pub const TableSize = struct {
    base: SequencedInstruction = SequencedInstruction.init(.table_size),
    table: wasm.TableIndex,
};

pub const Load = struct {
    base: SequencedInstruction,
    address: *Instruction,

    pub fn init(opcode: Opcode, address: *Instruction) @This() {
        return .{
            .base = SequencedInstruction.init(opcode),
            .address = address,
        };
    }
};

pub const Store = struct {
    base: SequencedInstruction,
    address: *Instruction,
    value: *Instruction,

    pub fn init(opcode: Opcode, address: *Instruction, value: *Instruction) @This() {
        return .{
            .base = SequencedInstruction.init(opcode),
            .address = address,
            .value = value,
        };
    }
};

pub const I32Const = struct {
    base: Instruction = Instruction.init(.i32_const),
    value: u32,
};

pub const I64Const = struct {
    base: Instruction = Instruction.init(.i64_const),
    value: u64,
};

pub const F32Const = struct {
    base: Instruction = Instruction.init(.f32_const),
    value: u32,
};

pub const F64Const = struct {
    base: Instruction = Instruction.init(.f64_const),
    value: u64,
};

pub const V128Const = struct {
    base: Instruction = Instruction.init(.v128_const),
    value: u128,
};

pub const Udf = struct {
    base: SequencedInstruction = SequencedInstruction.init(.udf),
    immediate: u16,
};

pub const PureUnaryOp = struct {
    base: Instruction,
    operand: *Instruction,

    pub fn init(opcode: Opcode, operand: *Instruction) @This() {
        return .{ .base = Instruction.init(opcode), .operand = operand };
    }
};

pub const PureBinaryOp = struct {
    base: Instruction,
    lhs: *Instruction,
    rhs: *Instruction,

    pub fn init(opcode: Opcode, lhs: *Instruction, rhs: *Instruction) @This() {
        return .{ .base = Instruction.init(opcode), .lhs = lhs, .rhs = rhs };
    }
};

pub const FunctionArg = struct {
    base: Instruction = Instruction.init(.function_arg),
    index: u32,
};

pub const BlockArg = struct {
    base: Instruction = Instruction.init(.block_arg),
    block: *Block,
    index: u32,
};

test "ref all" {
    std.testing.refAllDeclsRecursive(@This());
}
