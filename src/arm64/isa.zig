const std = @import("std");

const Sf = enum(u1) {
    W,
    X,
};

const PcRelative = packed struct(u32) {
    rd: u5,
    immhi: u19,
    _fixed: u5 = 0b10000,
    immlo: u2,
    op: enum(u1) { adr, adrp },
};

const AddSubImmediate = packed struct(u32) {
    rd: u5,
    rn: u5,
    imm12: u12,
    sh: bool,
    _fixed: u6 = 0b100010,
    S: bool,
    op: enum(u1) { add, sub },
    sf: Sf,
};

const LogicalImmediate = packed struct(u32) {
    rd: u5,
    rn: u5,
    imms: u6,
    immr: u6,
    N: u1,
    _fixed: u6 = 0b100100,
    opc: u2,
    sf: Sf,
};

const MoveWideImmediate = packed struct(u32) {
    rd: u5,
    imm16: u16,
    hw: u2,
    _fixed: u6 = 0b100101,
    opc: u2,
    sf: Sf,
};

const Bitfield = packed struct(u32) {
    rd: u5,
    rn: u5,
    imms: u6,
    immr: u6,
    N: u1,
    _fixed: u6 = 0b100110,
    opc: u2,
    sf: Sf,
};

const Extract = packed struct(u32) {
    ed: u5,
    rn: u5,
    imms: u6,
    rm: u5,
    o0: u1,
    N: u1,
    _fixed: u6 = 0b100111,
    op21: u2,
    sf: Sf,
};

const ConditionalBranchImmediate = packed struct(u32) {
    cond: u4,
    o0: u1,
    imm19: u19,
    o1: u1,
    _fixed: u7 = 0b0101010,
};

const ExceptionGeneration = packed struct(u32) {
    LL: u2,
    op2: u3,
    imm16: u16,
    opc: u3,
    _fixed: u8 = 0b11010100,
};

const UnconditionalBranchRegister = packed struct(u32) {
    op4: u4,
    rn: u5,
    op3: u6,
    op2: u5,
    opc: u4,
    _fixed: u7 = 0b1101011,
};

const UnconditionalBranchImmediate = packed struct(u32) {
    imm26: u26,
    _fixed: u5 = 0b00101,
    op: enum(u1) { b, bl },
};

const CompareAndBranchImmediate = packed struct(u32) {
    rt: u5,
    imm19: u19,
    op: enum(u1) { cbz, cbnz },
    _fixed: u6 = 0b011010,
    sf: Sf,
};

const TestAndBranchImmediate = packed struct(u32) {
    rt: u5,
    imm14: u14,
    b40: u5,
    op: enum(u1) { tbz, tbnz },
    _fixed: u6 = 0b011011,
    b5: u1,
};

const LoadRegisterLiteral = packed struct(u32) {
    rt: u5,
    imm19: u19,
    _fixed0: u2 = 0b00,
    V: bool,
    _fixed1: u3 = 0b011,
    opc: u2,
};

const LoadStoreRegisterPair = packed struct(u32) {
    rt: u5,
    rn: u5,
    rt2: u5,
    imm7: u7,
    L: bool,
    kind: Kind,
    V: bool,
    _fixed1: u3 = 0b101,
    opc: u2,

    const Kind = enum(u3) {
        post_indexed = 0b001,
        offset = 0b010,
        pre_indexed = 0b011,
    };
};

test "ref all" {
    std.testing.refAllDeclsRecursive(@This());
}
