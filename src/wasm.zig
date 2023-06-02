pub const ModuleSummary = @import("wasm/ModuleSummary.zig");

pub const TypeIdx = packed struct(u32) {
    value: u32,
};

pub const FuncIdx = packed struct(u32) {
    value: u32,
};

pub const TableIdx = packed struct(u32) {
    value: u32,
};

pub const MemIdx = packed struct(u32) {
    value: u32,
};

pub const GlobalIdx = packed struct(u32) {
    value: u32,
};

pub const ElemIdx = packed struct(u32) {
    value: u32,
};

pub const DataIdx = packed struct(u32) {
    value: u32,
};

pub const LocalIdx = packed struct(u32) {
    value: u32,
};

pub const LabelIdx = packed struct(u32) {
    value: u32,
};

pub const LaneIdx = u8;

pub const SimpleInstruction = enum(u8) {
    @"unreachable" = 0x00,
    nop,
    @"else" = 0x05,
    end = 0x0b,
    @"return" = 0x0f,
    drop = 0x1a,
    i32_eqz = 0x45,
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
    i64_eqz,
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
    i32_clz,
    i32_ctz,
    i32_popcnt,
    i32_add,
    i32_sub,
    i32_mul,
    i32_div_s,
    i32_div_u,
    i32_rem_s,
    i32_rem_u,
    i32_and,
    i32_or,
    i32_xor,
    i32_shl,
    i32_shr_s,
    i32_shr_u,
    i32_rotl,
    i32_rotr,
    i64_clz,
    i64_ctz,
    i64_popcnt,
    i64_add,
    i64_sub,
    i64_mul,
    i64_div_s,
    i64_div_u,
    i64_rem_s,
    i64_rem_u,
    i64_and,
    i64_or,
    i64_xor,
    i64_shl,
    i64_shr_s,
    i64_shr_u,
    i64_rotl,
    i64_rotr,
    f32_abs,
    f32_neg,
    f32_ceil,
    f32_floor,
    f32_trunc,
    f32_nearest,
    f32_sqrt,
    f32_add,
    f32_sub,
    f32_mul,
    f32_div,
    f32_min,
    f32_max,
    f32_copysign,
    f64_abs,
    f64_neg,
    f64_ceil,
    f64_floor,
    f64_trunc,
    f64_nearest,
    f64_sqrt,
    f64_add,
    f64_sub,
    f64_mul,
    f64_div,
    f64_min,
    f64_max,
    f64_copysign,
    i32_wrap_i64,
    i32_trunc_f32_s,
    i32_trunc_f32_u,
    i32_trunc_f64_s,
    i32_trunc_f64_u,
    i64_extend_i32_s,
    i64_extend_i32_u,
    i64_trunc_f32_s,
    i64_trunc_f32_u,
    i64_trunc_f64_s,
    i64_trunc_f64_u,
    f32_convert_i32_s,
    f32_convert_i32_u,
    f32_convert_i64_s,
    f32_convert_i64_u,
    f32_demote_f64,
    f64_convert_i32_s,
    f64_convert_i32_u,
    f64_convert_i64_s,
    f64_convert_i64_u,
    f64_promote_f32,
    i32_reinterpret_f32,
    i64_reinterpret_f64,
    f32_reinterpret_i32,
    f64_reinterpret_i64,
    i32_extend8_s,
    i32_extend16_s,
    i64_extend8_s,
    i64_extend16_s,
    i64_extend32_s,
    ref_is_null = 0xd1,
};

pub const BlockTypeInstruction = enum(u8) {
    block = 0x02,
    loop,
    @"if",
};

pub const IndexInstruction = enum(u8) {
    br = 0x0c,
    br_if,
    call = 0x10,
    local_get = 0x20,
    local_set,
    local_tee,
    global_get,
    global_set,
    table_get,
    table_set,
    memory_size = 0x3f,
    memory_grow,
    ref_func = 0xd2,
};

pub const MemoryInstruction = enum(u8) {
    i32_load = 0x28,
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
};

pub const ExtendedInstruction = enum(u32) {
    i32_trunc_sat_f32_s = 0,
    i32_trunc_sat_f32_u,
    i32_trunc_sat_f64_s,
    i32_trunc_sat_f64_u,
    i64_trunc_sat_f32_s,
    i64_trunc_sat_f32_u,
    i64_trunc_sat_f64_s,
    i64_trunc_sat_f64_u,
};

pub const ExtendedIndexInstruction = enum(u32) {
    data_drop = 9,
    memory_fill = 11,
    elem_drop = 13,
    table_grow = 15,
    table_size,
    table_fill,
};

pub const ExtendedDualIndexInstruction = enum(u32) {
    memory_init = 8,
    memory_copy = 10,
    table_init = 12,
    table_copy = 14,
};

pub const VectorInstruction = enum(u32) {
    i8x16_swizzle = 14,
    i8x16_splat,
    i16x8_splat,
    i32x4_splat,
    i64x2_splat,
    f32x4_splat,
    f64x2_splat,
    i8x16_eq = 35,
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
    v128_not,
    v128_and,
    v128_andnot,
    v128_or,
    v128_xor,
    v128_bitselect,
    v128_any_true,
    f32x4_demote_f64x2_zero = 94,
    f64x2_promote_low_f32x4,
    i8x16_abs,
    i8x16_neg,
    i8x16_popcnt,
    i8x16_all_true,
    i8x16_bitmask,
    i8x16_narrow_i16x8_s,
    i8x16_narrow_i16x8_u,
    f32x4_ceil,
    f32x4_floor,
    f32x4_trunc,
    f32x4_nearest,
    i8x16_shl,
    i8x16_shr_s,
    i8x16_shr_u,
    i8x16_add,
    i8x16_add_sat_s,
    i8x16_add_sat_u,
    i8x16_sub,
    i8x16_sub_sat_s,
    i8x16_sub_sat_u,
    f64x2_ceil,
    f64x2_floor,
    i8x16_min_s,
    i8x16_min_u,
    i8x16_max_s,
    i8x16_max_u,
    f64x2_trunc,
    i8x16_avgr_u,
    i16x8_extadd_pairwise_i8x16_s,
    i16x8_extadd_pairwise_i8x16_u,
    i32x4_extadd_pairwise_i16x8_s,
    i32x4_extadd_pairwise_i16x8_u,
    i16x8_abs,
    i16x8_neg,
    i16x8_q15mulr_sat_s,
    i16x8_all_true,
    i16x8_bitmask,
    i16x8_narrow_i32x4_s,
    i16x8_narrow_i32x4_u,
    i16x8_extend_low_i8x16_s,
    i16x8_extend_high_i8x16_s,
    i16x8_extend_low_i8x16_u,
    i16x8_extend_high_i8x16_u,
    i16x8_shl,
    i16x8_shr_s,
    i16x8_shr_u,
    i16x8_add,
    i16x8_add_sat_s,
    i16x8_add_sat_u,
    i16x8_sub,
    i16x8_sub_sat_s,
    i16x8_sub_sat_u,
    f64x2_nearest,
    i16x8_mul,
    i16x8_min_s,
    i16x8_min_u,
    i16x8_max_s,
    i16x8_max_u,
    i16x8_avgr_u = 155,
    i16x8_extmul_low_i8x16_s,
    i16x8_extmul_high_i8x16_s,
    i16x8_extmul_low_i8x16_u,
    i16x8_extmul_high_i8x16_u,
    i32x4_abs,
    i32x4_neg,
    i32x4_all_true = 163,
    i32x4_bitmask,
    i32x4_extend_low_i16x8_s = 167,
    i32x4_extend_high_i16x8_s,
    i32x4_extend_low_i16x8_u,
    i32x4_extend_high_i16x8_u,
    i32x4_shl,
    i32x4_shr_s,
    i32x4_shr_u,
    i32x4_add,
    i32x4_sub = 177,
    i32x4_mul = 181,
    i32x4_min_s,
    i32x4_min_u,
    i32x4_max_s,
    i32x4_max_u,
    i32x4_dot_i16x8_s,
    i32x4_extmul_low_i16x8_s = 188,
    i32x4_extmul_high_i16x8_s,
    i32x4_extmul_low_i16x8_u,
    i32x4_extmul_high_i16x8_u,
    i64x2_abs,
    i64x2_neg,
    i64x2_all_true = 195,
    i64x2_bitmask,
    i64x2_extend_low_i32x4_s = 199,
    i64x2_extend_high_i32x4_s,
    i64x2_extend_low_i32x4_u,
    i64x2_extend_high_i32x4_u,
    i64x2_shl,
    i64x2_shr_s,
    i64x2_shr_u,
    i64x2_add,
    i64x2_sub = 209,
    i64x2_mul = 213,
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
    f32x4_abs,
    f32x4_neg,
    f32x4_sqrt,
    f32x4_add,
    f32x4_sub,
    f32x4_mul,
    f32x4_div,
    f32x4_min,
    f32x4_max,
    f32x4_pmin,
    f32x4_pmax,
    f64x2_abs,
    f64x2_neg,
    f64x2_sqrt = 239,
    f64x2_add,
    f64x2_sub,
    f64x2_mul,
    f64x2_div,
    f64x2_min,
    f64x2_max,
    f64x2_pmin,
    f64x2_pmax,
    i32x4_trunc_sat_f32x4_s,
    i32x4_trunc_sat_f32x4_u,
    f32x4_convert_i32x4_s,
    f32x4_convert_i32x4_u,
    i32x4_trunc_sat_f64x2_s_zero,
    i32x4_trunc_sat_f64x2_u_zero,
    f64x2_convert_low_i32x4_s,
    f64x2_convert_low_i32x4_u,
};

pub const Vector16ByteImmediateInstruction = enum(u32) {
    v128_const = 12,
    i8x16_shuffle,
};

pub const VectorMemoryInstruction = enum(u32) {
    v128_load = 0,
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
    v128_store,
    v128_load32_zero = 92,
    v128_load64_zero,
};

pub const VectorLaneInstruction = enum(u32) {
    i8x16_extract_lane_s = 21,
    i8x16_extract_lane_u,
    i8x16_replace_lane,
    i16x8_extract_lane_s,
    i16x8_extract_lane_u,
    i16x8_replace_lane,
    i32x4_extract_lane,
    i32x4_replace_lane,
    i64x2_extract_lane,
    i64x2_replace_lane,
    f32x4_extract_lane,
    f32x4_replace_lane,
    f64x2_extract_lane,
    f64x2_replace_lane,
};

pub const VectorMemoryLaneInstruction = enum(u32) {
    v128_load8_lane = 84,
    v128_load16_lane,
    v128_load32_lane,
    v128_load64_lane,
    v128_store8_lane,
    v128_store16_lane,
    v128_store32_lane,
    v128_store64_lane,
};

pub const NumType = enum(u8) {
    i32 = 0x7f,
    i64 = 0x7e,
    f32 = 0x7d,
    f64 = 0x7c,
};

pub const VecType = enum(u8) {
    v128 = 0x7b,
};

pub const RefType = enum(u8) {
    funcref = 0x70,
    externref = 0x6f,
};

pub const ValType = enum(u8) {
    i32 = 0x7f,
    i64 = 0x7e,
    f32 = 0x7d,
    f64 = 0x7c,
    v128 = 0x7b,
    funcref = 0x70,
    externref = 0x6f,
};

pub const ResultType = []const ValType;

pub const FuncType = struct {
    parameters: ResultType,
    results: ResultType,
};

pub const Limits = struct {
    min: u32,
    max: ?u32 = null,
};

pub const MemType = struct {
    limits: Limits,
};

pub const TableType = struct {
    element_type: RefType,
    limits: Limits,
};

pub const Mut = enum(u8) {
    @"const" = 0x00,
    @"var" = 0x01,
};

pub const GlobalType = struct {
    value_type: ValType,
    mutability: Mut,
};

pub const MemArg = struct {
    alignment: u32,
    offset: u32,
};

pub const Name = []const u8;

pub const ImportName = struct {
    module: []const u8,
    name: []const u8,
};

fn Imported(comptime Type: type) type {
    return struct {
        name: ImportName,
        type: Type,
    };
}

pub const ImportedFunc = Imported(TypeIdx);

pub const ImportedTable = Imported(TableType);

pub const ImportedMem = Imported(MemType);

pub const ImportedGlobal = Imported(GlobalType);

pub const ConstantExpr = union(enum) {
    i32_const: i32,
    i64_const: i64,
    f32_const: u32,
    f64_const: u64,
    ref_null: void,
    ref_func: FuncIdx,
    global_get: GlobalIdx,
};

pub const I32ConstantExpr = union(enum) {
    i32_const: i32,
    global_get: GlobalIdx,
};

pub const FuncrefConstantExpr = union(enum) {
    ref_null: void,
    ref_func: FuncIdx,
    global_get: GlobalIdx,
};

pub const ExternrefConstantExpr = union(enum) {
    ref_null: void,
    global_get: GlobalIdx,
};

pub const BlockType = union(enum) {
    immediate: ?ValType,
    indexed: FuncIdx,
};

pub const Global = struct {
    type: GlobalType,
    initial_value: ConstantExpr,
};

pub const ExportDesc = union(enum) {
    function: FuncIdx,
    table: TableIdx,
    memory: MemIdx,
    global: GlobalIdx,
};

pub const Export = struct {
    name: Name,
    desc: ExportDesc,
};

pub const ElemKind = enum(u8) {
    funcref = 0x00,
};

pub const Elem = struct {
    mode: Mode,
    init: Init,

    pub const Mode = union(enum) {
        active: Active,
        passive: void,
        declarative: void,

        pub const Active = struct {
            table: TableIdx,
            offset: I32ConstantExpr,
        };
    };

    pub const Init = union(enum) {
        funcrefs: []const FuncIdx,
        funcref_exprs: []const FuncrefConstantExpr,
        externref_exprs: []const ExternrefConstantExpr,
    };
};

pub const Data = struct {
    mode: Mode,
    init: []const u8,

    pub const Mode = union(enum) {
        active: Active,
        passive: void,

        pub const Active = struct {
            memory: MemIdx,
            offset: I32ConstantExpr,
        };
    };
};

test {
    _ = @import("wasm/code_processor.zig");
    _ = @import("wasm/Decoder.zig");
    _ = @import("wasm/ModuleSummary.zig");
    _ = @import("wasm/opcodes.zig");
}

test "ref all decls" {
    @import("std").testing.refAllDecls(@This());
}
