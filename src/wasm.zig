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

pub const SectionId = enum(u8) {
    custom = 0,
    type = 1,
    import = 2,
    function = 3,
    table = 4,
    memory = 5,
    global = 6,
    @"export" = 7,
    start = 8,
    element = 9,
    code = 10,
    data = 11,
    data_count = 12,
    _,
};

pub const Section = struct {
    id: SectionId,
    contents: []const u8,
};

pub const BlockType = union(enum) {
    immediate: ?ValType,
    indexed: TypeIdx,
};

pub const Instr = union(enum) {
    @"unreachable": void,
    nop: void,
    block: BlockType,
    loop: BlockType,
    @"if": BlockType,
    @"else": void,
    end: void,
    br: LabelIdx,
    br_if: LabelIdx,
    br_table: struct { []const LabelIdx, LabelIdx },
    @"return": void,
    call: FuncIdx,
    call_indirect: struct { FuncIdx, TableIdx },
    drop: void,
    select: ?ValType,
    @"local.get": LocalIdx,
    @"local.set": LocalIdx,
    @"local.tee": LocalIdx,
    @"global.get": GlobalIdx,
    @"global.set": GlobalIdx,
    @"table.get": TableIdx,
    @"table.set": TableIdx,
    @"i32.load": MemArg,
    @"i64.load": MemArg,
    @"f32.load": MemArg,
    @"f64.load": MemArg,
    @"i32.load8_s": MemArg,
    @"i32.load8_u": MemArg,
    @"i32.load16_s": MemArg,
    @"i32.load16_u": MemArg,
    @"i64.load8_s": MemArg,
    @"i64.load8_u": MemArg,
    @"i64.load16_s": MemArg,
    @"i64.load16_u": MemArg,
    @"i64.load32_s": MemArg,
    @"i64.load32_u": MemArg,
    @"i32.store": MemArg,
    @"i64.store": MemArg,
    @"f32.store": MemArg,
    @"f64.store": MemArg,
    @"i32.store8": MemArg,
    @"i32.store16": MemArg,
    @"i64.store8": MemArg,
    @"i64.store16": MemArg,
    @"i64.store32": MemArg,
    @"memory.size": MemIdx,
    @"memory.grow": MemIdx,
    @"i32.const": i32,
    @"i64.const": i64,
    @"f32.const": f32,
    @"f64.const": f64,
    @"i32.eqz": void,
    @"i32.eq": void,
    @"i32.ne": void,
    @"i32.lt_s": void,
    @"i32.lt_u": void,
    @"i32.gt_s": void,
    @"i32.gt_u": void,
    @"i32.le_s": void,
    @"i32.le_u": void,
    @"i32.ge_s": void,
    @"i32.ge_u": void,
    @"i64.eqz": void,
    @"i64.eq": void,
    @"i64.ne": void,
    @"i64.lt_s": void,
    @"i64.lt_u": void,
    @"i64.gt_s": void,
    @"i64.gt_u": void,
    @"i64.le_s": void,
    @"i64.le_u": void,
    @"i64.ge_s": void,
    @"i64.ge_u": void,
    @"f32.eq": void,
    @"f32.ne": void,
    @"f32.lt": void,
    @"f32.gt": void,
    @"f32.le": void,
    @"f32.ge": void,
    @"f64.eq": void,
    @"f64.ne": void,
    @"f64.lt": void,
    @"f64.gt": void,
    @"f64.le": void,
    @"f64.ge": void,
    @"i32.clz": void,
    @"i32.ctz": void,
    @"i32.popcnt": void,
    @"i32.add": void,
    @"i32.sub": void,
    @"i32.mul": void,
    @"i32.div_s": void,
    @"i32.div_u": void,
    @"i32.rem_s": void,
    @"i32.rem_u": void,
    @"i32.and": void,
    @"i32.or": void,
    @"i32.xor": void,
    @"i32.shl": void,
    @"i32.shr_s": void,
    @"i32.shr_u": void,
    @"i32.rotl": void,
    @"i32.rotr": void,
    @"i64.clz": void,
    @"i64.ctz": void,
    @"i64.popcnt": void,
    @"i64.add": void,
    @"i64.sub": void,
    @"i64.mul": void,
    @"i64.div_s": void,
    @"i64.div_u": void,
    @"i64.rem_s": void,
    @"i64.rem_u": void,
    @"i64.and": void,
    @"i64.or": void,
    @"i64.xor": void,
    @"i64.shl": void,
    @"i64.shr_s": void,
    @"i64.shr_u": void,
    @"i64.rotl": void,
    @"i64.rotr": void,
    @"f32.abs": void,
    @"f32.neg": void,
    @"f32.ceil": void,
    @"f32.floor": void,
    @"f32.trunc": void,
    @"f32.nearest": void,
    @"f32.sqrt": void,
    @"f32.add": void,
    @"f32.sub": void,
    @"f32.mul": void,
    @"f32.div": void,
    @"f32.min": void,
    @"f32.max": void,
    @"f32.copysign": void,
    @"f64.abs": void,
    @"f64.neg": void,
    @"f64.ceil": void,
    @"f64.floor": void,
    @"f64.trunc": void,
    @"f64.nearest": void,
    @"f64.sqrt": void,
    @"f64.add": void,
    @"f64.sub": void,
    @"f64.mul": void,
    @"f64.div": void,
    @"f64.min": void,
    @"f64.max": void,
    @"f64.copysign": void,
    @"i32.wrap_i64": void,
    @"i32.trunc_f32_s": void,
    @"i32.trunc_f32_u": void,
    @"i32.trunc_f64_s": void,
    @"i32.trunc_f64_u": void,
    @"i64.extend_i32_s": void,
    @"i64.extend_i32_u": void,
    @"i64.trunc_f32_s": void,
    @"i64.trunc_f32_u": void,
    @"i64.trunc_f64_s": void,
    @"i64.trunc_f64_u": void,
    @"f32.convert_i32_s": void,
    @"f32.convert_i32_u": void,
    @"f32.convert_i64_s": void,
    @"f32.convert_i64_u": void,
    @"f32.demote_f64": void,
    @"f64.convert_i32_s": void,
    @"f64.convert_i32_u": void,
    @"f64.convert_i64_s": void,
    @"f64.convert_i64_u": void,
    @"f64.promote_f32": void,
    @"i32.reinterpret_f32": void,
    @"i64.reinterpret_f64": void,
    @"f32.reinterpret_i32": void,
    @"f64.reinterpret_i64": void,
    @"i32.extend8_s": void,
    @"i32.extend16_s": void,
    @"i64.extend8_s": void,
    @"i64.extend16_s": void,
    @"i64.extend32_s": void,
    @"ref.null": RefType,
    @"ref.is_null": void,
    @"ref.func": FuncIdx,
    @"i32.trunc_sat_f32_s": void,
    @"i32.trunc_sat_f32_u": void,
    @"i32.trunc_sat_f64_s": void,
    @"i32.trunc_sat_f64_u": void,
    @"i64.trunc_sat_f32_s": void,
    @"i64.trunc_sat_f32_u": void,
    @"i64.trunc_sat_f64_s": void,
    @"i64.trunc_sat_f64_u": void,
    @"memory.init": struct { DataIdx, MemIdx },
    @"data.drop": DataIdx,
    @"memory.copy": struct { MemIdx, MemIdx },
    @"memory.fill": MemIdx,
    @"table.init": struct { ElemIdx, TableIdx },
    @"elem.drop": struct { ElemIdx },
    @"table.copy": struct { TableIdx, TableIdx },
    @"table.grow": struct { TableIdx },
    @"table.size": struct { TableIdx },
    @"table.fill": struct { TableIdx },
    @"v128.load": MemArg,
    @"v128.load8x8_s": MemArg,
    @"v128.load8x8_u": MemArg,
    @"v128.load16x4_s": MemArg,
    @"v128.load16x4_u": MemArg,
    @"v128.load32x2_s": MemArg,
    @"v128.load32x2_u": MemArg,
    @"v128.load8_splat": MemArg,
    @"v128.load16_splat": MemArg,
    @"v128.load32_splat": MemArg,
    @"v128.load64_splat": MemArg,
    @"v128.store": MemArg,
    @"v128.const": u128,
    @"i8x16.shuffle": void,
    @"i8x16.swizzle": void,
    @"i8x16.splat": void,
    @"i16x8.splat": void,
    @"i32x4.splat": void,
    @"i64x2.splat": void,
    @"f32x4.splat": void,
    @"f64x2.splat": void,
    @"i8x16.extract_lane_s": LaneIdx,
    @"i8x16.extract_lane_u": LaneIdx,
    @"i8x16.replace_lane": LaneIdx,
    @"i16x8.extract_lane_s": LaneIdx,
    @"i16x8.extract_lane_u": LaneIdx,
    @"i16x8.replace_lane": LaneIdx,
    @"i32x4.extract_lane": LaneIdx,
    @"i32x4.replace_lane": LaneIdx,
    @"i64x2.extract_lane": LaneIdx,
    @"i64x2.replace_lane": LaneIdx,
    @"f32x4.extract_lane": LaneIdx,
    @"f32x4.replace_lane": LaneIdx,
    @"f64x2.extract_lane": LaneIdx,
    @"f64x2.replace_lane": LaneIdx,
    @"i8x16.eq": void,
    @"i8x16.ne": void,
    @"i8x16.lt_s": void,
    @"i8x16.lt_u": void,
    @"i8x16.gt_s": void,
    @"i8x16.gt_u": void,
    @"i8x16.le_s": void,
    @"i8x16.le_u": void,
    @"i8x16.ge_s": void,
    @"i8x16.ge_u": void,
    @"i16x8.eq": void,
    @"i16x8.ne": void,
    @"i16x8.lt_s": void,
    @"i16x8.lt_u": void,
    @"i16x8.gt_s": void,
    @"i16x8.gt_u": void,
    @"i16x8.le_s": void,
    @"i16x8.le_u": void,
    @"i16x8.ge_s": void,
    @"i16x8.ge_u": void,
    @"i32x4.eq": void,
    @"i32x4.ne": void,
    @"i32x4.lt_s": void,
    @"i32x4.lt_u": void,
    @"i32x4.gt_s": void,
    @"i32x4.gt_u": void,
    @"i32x4.le_s": void,
    @"i32x4.le_u": void,
    @"i32x4.ge_s": void,
    @"i32x4.ge_u": void,
    @"f32x4.eq": void,
    @"f32x4.ne": void,
    @"f32x4.lt": void,
    @"f32x4.gt": void,
    @"f32x4.le": void,
    @"f32x4.ge": void,
    @"f64x2.eq": void,
    @"f64x2.ne": void,
    @"f64x2.lt": void,
    @"f64x2.gt": void,
    @"f64x2.le": void,
    @"f64x2.ge": void,
    @"v128.not": void,
    @"v128.and": void,
    @"v128.andnot": void,
    @"v128.or": void,
    @"v128.xor": void,
    @"v128.bitselect": void,
    @"v128.any_true": void,
    @"v128.load8_lane": struct { MemArg, LaneIdx },
    @"v128.load16_lane": struct { MemArg, LaneIdx },
    @"v128.load32_lane": struct { MemArg, LaneIdx },
    @"v128.load64_lane": struct { MemArg, LaneIdx },
    @"v128.store8_lane": struct { MemArg, LaneIdx },
    @"v128.store16_lane": struct { MemArg, LaneIdx },
    @"v128.store32_lane": struct { MemArg, LaneIdx },
    @"v128.store64_lane": struct { MemArg, LaneIdx },
    @"v128.load32_zero": MemArg,
    @"v128.load64_zero": MemArg,
    @"f32x4.demote_f64x2_zero": void,
    @"f64x2.promote_low_f32x4": void,
    @"i8x16.abs": void,
    @"i8x16.neg": void,
    @"i8x16.popcnt": void,
    @"i8x16.all_true": void,
    @"i8x16.bitmask": void,
    @"i8x16.narrow_i16x8_s": void,
    @"i8x16.narrow_i16x8_u": void,
    @"i8x16.shl": void,
    @"i8x16.shr_s": void,
    @"i8x16.shr_u": void,
    @"i8x16.add": void,
    @"i8x16.add_sat_s": void,
    @"i8x16.add_sat_u": void,
    @"i8x16.sub": void,
    @"i8x16.sub_sat_s": void,
    @"i8x16.sub_sat_u": void,
    @"i8x16.min_s": void,
    @"i8x16.min_u": void,
    @"i8x16.max_s": void,
    @"i8x16.max_u": void,
    @"i8x16.avgr_u": void,
    @"i16x8.extadd_pairwise_i8x16_s": void,
    @"i16x8.extadd_pairwise_i8x16_u": void,
    @"i32x4.extadd_pairwise_i16x8_s": void,
    @"i32x4.extadd_pairwise_i16x8_u": void,
    @"i16x8.abs": void,
    @"i16x8.neg": void,
    @"i16x8.q15mulr_sat_s": void,
    @"i16x8.all_true": void,
    @"i16x8.bitmask": void,
    @"i16x8.narrow_i32x4_s": void,
    @"i16x8.narrow_i32x4_u": void,
    @"i16x8.extend_low_i8x16_s": void,
    @"i16x8.extend_high_i8x16_s": void,
    @"i16x8.extend_low_i8x16_u": void,
    @"i16x8.extend_high_i8x16_u": void,
    @"i16x8.shl": void,
    @"i16x8.shr_s": void,
    @"i16x8.shr_u": void,
    @"i16x8.add": void,
    @"i16x8.add_sat_s": void,
    @"i16x8.add_sat_u": void,
    @"i16x8.sub": void,
    @"i16x8.sub_sat_s": void,
    @"i16x8.sub_sat_u": void,
    @"i16x8.mul": void,
    @"i16x8.min_s": void,
    @"i16x8.min_u": void,
    @"i16x8.max_s": void,
    @"i16x8.max_u": void,
    @"i16x8.avgr_u": void,
    @"i16x8.extmul_low_i8x16_s": void,
    @"i16x8.extmul_high_i8x16_s": void,
    @"i16x8.extmul_low_i8x16_u": void,
    @"i16x8.extmul_high_i8x16_u": void,
    @"i32x4.abs": void,
    @"i32x4.neg": void,
    @"i32x4.all_true": void,
    @"i32x4.bitmask": void,
    @"i32x4.extend_low_i16x8_s": void,
    @"i32x4.extend_high_i16x8_s": void,
    @"i32x4.extend_low_i16x8_u": void,
    @"i32x4.extend_high_i16x8_u": void,
    @"i32x4.shl": void,
    @"i32x4.shr_s": void,
    @"i32x4.shr_u": void,
    @"i32x4.add": void,
    @"i32x4.sub": void,
    @"i32x4.mul": void,
    @"i32x4.min_s": void,
    @"i32x4.min_u": void,
    @"i32x4.max_s": void,
    @"i32x4.max_u": void,
    @"i32x4.dot_i16x8_s": void,
    @"i32x4.extmul_low_i16x8_s": void,
    @"i32x4.extmul_high_i16x8_s": void,
    @"i32x4.extmul_low_i16x8_u": void,
    @"i32x4.extmul_high_i16x8_u": void,
    @"i64x2.abs": void,
    @"i64x2.neg": void,
    @"i64x2.all_true": void,
    @"i64x2.bitmask": void,
    @"i64x2.extend_low_i32x4_s": void,
    @"i64x2.extend_high_i32x4_s": void,
    @"i64x2.extend_low_i32x4_u": void,
    @"i64x2.extend_high_i32x4_u": void,
    @"i64x2.shl": void,
    @"i64x2.shr_s": void,
    @"i64x2.shr_u": void,
    @"i64x2.add": void,
    @"i64x2.sub": void,
    @"i64x2.mul": void,
    @"i64x2.eq": void,
    @"i64x2.ne": void,
    @"i64x2.lt_s": void,
    @"i64x2.gt_s": void,
    @"i64x2.le_s": void,
    @"i64x2.ge_s": void,
    @"i64x2.extmul_low_i32x4_s": void,
    @"i64x2.extmul_high_i32x4_s": void,
    @"i64x2.extmul_low_i32x4_u": void,
    @"i64x2.extmul_high_i32x4_u": void,
    @"f32x4.ceil": void,
    @"f32x4.floor": void,
    @"f32x4.trunc": void,
    @"f32x4.nearest": void,
    @"f64x2.ceil": void,
    @"f64x2.floor": void,
    @"f64x2.trunc": void,
    @"f64x2.nearest": void,
    @"f32x4.abs": void,
    @"f32x4.neg": void,
    @"f32x4.sqrt": void,
    @"f32x4.add": void,
    @"f32x4.sub": void,
    @"f32x4.mul": void,
    @"f32x4.div": void,
    @"f32x4.min": void,
    @"f32x4.max": void,
    @"f32x4.pmin": void,
    @"f32x4.pmax": void,
    @"f64x2.abs": void,
    @"f64x2.neg": void,
    @"f64x2.sqrt": void,
    @"f64x2.add": void,
    @"f64x2.sub": void,
    @"f64x2.mul": void,
    @"f64x2.div": void,
    @"f64x2.min": void,
    @"f64x2.max": void,
    @"f64x2.pmin": void,
    @"f64x2.pmax": void,
    @"i32x4.trunc_sat_f32x4_s": void,
    @"i32x4.trunc_sat_f32x4_u": void,
    @"f32x4.convert_i32x4_s": void,
    @"f32x4.convert_i32x4_u": void,
    @"i32x4.trunc_sat_f64x2_s_zero": void,
    @"i32x4.trunc_sat_f64x2_u_zero": void,
    @"f64x2.convert_low_i32x4_s": void,
    @"f64x2.convert_low_i32x4_u": void,
};

test {
    _ = @import("wasm/Decoder.zig");
}

test "ref all decls" {
    @import("std").testing.refAllDecls(@This());
}
