const std = @import("std");

const F2Dot14 = i16;
const F26Dot6 = i32;

graphics_state: *GraphicsState,

stack_slots: []u32,
stack_depth: usize = 0,

storage_area: []u32,

cvt: []F26Dot6,

px_per_funit: F26Dot6,

functions: [][]const u8,

points_locations: [2][][2]F26Dot6,
points_on_off_curve: [2]std.PackedIntSlice(u1),
points_touched: [2]std.PackedIntSlice(u1),

const GraphicsState = struct {

};

const AA = 0x7f;
const ABS = 0x64;
const ADD = 0x60;
const ALIGNPTS = 0x27;
const ALIGNRP = 0x3c;
const AND = 0x5a;
const CALL = 0x2b;
const CEILING = 0x67;
const CINDEX = 0x25;
const CLEAR = 0x22;
const DEBUG = 0x4f;
const DELTAC1 = 0x73;
const DELTAC2 = 0x74;
const DELTAC3 = 0x75;
const DELTAP1 = 0x5d;
const DELTAP2 = 0x71;
const DELTAP3 = 0x72;
const DEPTH = 0x24;
const DIV = 0x62;
const DUP = 0x20;
const EIF = 0x59;
const ELSE = 0x1b;
const ENDF = 0x2d;
const EQ = 0x54;
const EVEN = 0x57;
const FDEF = 0x2C;
const FLIPOFF = 0x4e;
const FLIPON = 0x4d;
const FLIPPT = 0x80;
const FLIPRGOFF = 0x82;
const FLIPRGON = 0x81;
const FLOOR = 0x66;
const GETINFO = 0x88;
const GETVARIATION = 0x91;
const GFV = 0x0d;
const GPV = 0x0c;
const GT = 0x52;
const GTEQ = 0x53;
const IDEF = 0x89;
const IF = 0x58;
const INSTCTRL = 0x8e;
const IP = 0x39;
const ISECT = 0x0f;
const JMPR = 0x1c;
const JROF = 0x79;
const JROT = 0x78;
const LOOPCALL = 0x2a;
const LT = 0x50;
const LTEQ = 0x51;
const MAX = 0x8B;
const MIN = 0x8c;
const MINDEX = 0x26;
const MPPEM = 0x4b;
const MPS = 0x4c;
const MUL = 0x63;
const NEG = 0x65;
const NEQ = 0x55;
const NOT = 0x5c;
const NPUSHB = 0x40;
const NPUSHW = 0x41;
const ODD = 0x56;
const OR = 0x5b;
const POP = 0x21;
const RCVT = 0x45;
const RDTG = 0x7d;
const ROFF = 0x7a;
const ROLL = 0x8a;
const RS = 0x43;
const RTDG = 0x3d;
const RTG = 0x18;
const RTHG = 0x19;
const RUTG = 0x7c;
const S45ROUND = 0x77;
const SANGW = 0x7e;
const SCANCTRL = 0x85;
const SCANTYPE = 0x8d;
const SCFS = 0x48;
const SCVTCI = 0x1d;
const SDB = 0x5e;
const SDS = 0x5f;
const SFVFS = 0x0b;
const SFVTPV = 0x0e;
const SHPIX = 0x38;
const SLOOP = 0x17;
const SMD = 0x1a;
const SPVFS = 0x0a;
const SROUND = 0x76;
const SRP0 = 0x10;
const SRP1 = 0x11;
const SRP2 = 0x12;
const SSW = 0x1f;
const SSWCI = 0x1e;
const SUB = 0x61;
const SWAP = 0x23;
const SZP0 = 0x13;
const SZP1 = 0x14;
const SZP2 = 0x15;
const SZPS = 0x16;
const UTP = 0x29;
const WCVTF = 0x70;
const WCVTP = 0x44;
const WS = 0x42;

fn GC(a: u1) u8 {
    return 0x46 + a;
}

fn IUP(a: u1) u8 {
    return 0x30 + a;
}

fn MD(a: u1) u8 {
    return 0x49 + a;
}

fn MDAP(a: u1) u8 {
    return 0x2e + a;
}

fn MDRP(abcde: u5) u8 {
    return 0xc0 + abcde;
}

fn MIAP(a: u1) u8 {
    return 0x3e + a;
}

fn MIRP(abcde: u5) u8 {
    return 0xe0 + abcde;
}

fn MSIRP(a: u1) u8 {
    return 0x3a + a;
}

fn NROUND(ab: u2) u8 {
    return 0x6c + ab;
}

fn PUSHB(abc: u3) u8 {
    return 0xb0 + abc;
}

fn PUSHW(abc: u3) u8 {
    return 0xb8 + abc;
}

fn ROUND(ab: u2) u8 {
    return 0x68 + ab;
}

fn SDPVTL(a: u1) u8 {
    return 0x86 + a;
}

fn SFVTCA(a: u1) u8 {
    return 0x04 + a;
}

fn SFVTL(a: u1) u8 {
    return 0x08 + a;
}

fn SHC(a: u1) u8 {
    return 0x34 + a;
}

fn SHP(a: u1) u8 {
    return 0x32 + a;
}

fn SHZ(a: u1) u8 {
    return 0x36 + a;
}

fn SPVTCA(a: u1) u8 {
    return 0x02 + a;
}

fn SPVTL(a: u1) u8 {
    return 0x06 + a;
}

fn SVTCA(a: u1) u8 {
    return 0x00 + a;
}

const InstructionStream = struct {
    instructions: []const u8,
    offset: usize,

    fn init(instructions: []const u8) @This() {
        return .{ .instructions = instructions, .offset = 0 };
    }

    fn nextByte(self: *@This()) ?u8 {
        if (self.offset >= self.instructions.len) return null;
        defer self.offset += 1;
        return self.instructions[self.offset];
    }

    fn nextEmbeddedWord(self: *@This()) i16 {
        const high = self.nextByte().?;
        const low = self.nextByte().?;
        return (@as(i16, high) << 8) | low;
    }

    fn skipThrough(self: *@This(), comptime delimiters: []const u8) void {
        while (true) switch (self.nextByte().?) {
            NPUSHB => {
                const n = self.nextByte();
                self.offset += n;
            },

            NPUSHW => {
                const n = self.nextByte();
                self.offset += @as(usize, n) * 2;
            },

            inline PUSHB(0)...PUSHB(7) => |opcode| {
                self.offset += opcode - PUSHB(0) + 1;
            },

            inline PUSHW(0)...PUSHW(7) => |opcode| {
                self.offset += @as(usize, opcode - PUSHW(0) + 1) * 2;
            },

            else => |byte| inline for (delimiters) |delim| {
                if (byte == delim) break;
            },
        };
    }

    fn jump(self: *@This(), offset: i32) void {
        if (offset < 0) {
            self.offset -= std.math.absCast(offset) + 1;
        } else {
            self.offset += std.math.absCast(offset) - 1;
        }
    }
};

fn getPoint(self: *@This(), index: u32) [2]F26Dot6 {
    _ = self;
    _ = index;
    unreachable;
}

fn stackPushUnsigned(self: *@This(), value: u32) void {
    self.stack[self.stack_depth] = value;
    self.stack_depth += 1;
}

fn stackPushSigned(self: *@This(), value: i32) void {
    self.stackPushUnsigned(@bitCast(u32, value));
}

fn stackPushBool(self: *@This(), value: bool) void {
    self.stackPushUnsigned(@boolToInt(value));
}

fn stackPopUnsigned(self: *@This()) u32 {
    self.stack_depth -= 1;
    return self.stack[self.stack_depth];
}

fn stackPopSigned(self: *@This()) i32 {
    return @bitCast(i32, self.stackPopUnsigned());
}

fn stackPopBool(self: *@This()) bool {
    return self.stackPopUnsigned() != 0;
}

fn stackPopPoint(self: *@This()) [2]F26Dot6 {
    return self.getPoint(self.stackPopUnsigned());
}

fn divideVectorComponentByNorm(component: i32, norm: u32) F2Dot14 {
    return @intCast(F2Dot14, @divFloor((@as(i47, component) << 14) + (norm / 2), norm));
}

fn vectorToDirection(vector: [2]F26Dot6) [2]F2Dot14 {
    // FIXME: reimplement so that this isn't terribly slow and questionably
    // accurate.

    if (vector[0] == 0 and vector[1] == 0) {
        // Nothing particularly reasonable to do here, so just return the x
        // axis.
        return .{ 1 << 14, 0 };
    }

    // Each squared component will be positive, and will therefore fit within a
    // u63; this means that the addition of the two (as a u64) cannot overflow.
    const x_2 = @intCast(u64, std.math.mulWide(vector[0], vector[0]));
    const y_2 = @intCast(u64, std.math.mulWide(vector[1], vector[1]));
    const norm = std.math.sqrt(x_2 + y_2); // FIXME: round result properly?

    return .{
        divideVectorComponentByNorm(vector[0], norm),
        divideVectorComponentByNorm(vector[1], norm),
    };
}

fn lineToDirection(self: *@This()) [2]F2Dot14 {
    const p1 = self.stackPopPoint();
    const p2 = self.stackPopPoint();
    return vectorToDirection(.{ p2[0] -% p1[0], p2[1] -% p1[1] });
}

fn lineToPerpendicularDirection(self: *@This()) [2]F2Dot14 {
    const direction = self.lineToDirection();
    return .{ -direction[1], direction[0] };
}

fn execute(self: *@This(), instructions: []const u8) void {
    var istream = InstructionStream.init(instructions);
    while (istream.nextByte()) |opcode| switch (opcode) {
        GETINFO => {
            const Selector = packed struct(u32) {
                version: bool,
                glyph_rotated: bool,
                glyph_stretched: bool,
                font_variations: bool,
                vertical_phantom_points: bool,
                windows_font_smoothing_grayscale: bool,
                cleartype_enabled: bool,
                cleartype_compatible_widths_enabled: bool,
                cleartype_horizontal_lcd_stripe_orientation: bool,
                cleartype_bgr_lcd_stripe_order: bool,
                cleartype_subpixel_positioned_text_enabled: bool,
                cleartype_symmetric_rendering_enabled: bool,
                cleartype_gray_rendering_enabled: bool,
                _reserved: u19,
            };

            const Result = packed struct(u32) {
                version: u8,
                glyph_rotated: bool,
                glyph_stretched: bool,
                font_variations: bool,
                vertical_phantom_points: bool,
                windows_font_smoothing_grayscale: bool,
                cleartype_enabled: bool,
                cleartype_compatible_widths_enabled: bool,
                cleartype_horizontal_lcd_stripe_orientation: bool,
                cleartype_bgr_lcd_stripe_order: bool,
                cleartype_subpixel_positioned_text_enabled: bool,
                cleartype_symmetric_rendering_enabled: bool,
                cleartype_gray_rendering_enabled: bool,
                _reserved: u12 = 0,
            };

            _ = Selector;
            _ = Result;

            @panic("TODO implement GETINFO");
        },

        SVTCA(0) => {
            self.graphics_state.freedom_vector = .{ 0, 1 << 14 };
            self.graphics_state.projection_vector = self.graphics_state.freedom_vector;
        },

        SVTCA(1) => {
            self.graphics_state.freedom_vector = .{ 1 << 14, 0 };
            self.graphics_state.projection_vector = self.graphics_state.freedom_vector;
        },

        SPVTCA(0) => {
            self.graphics_state.projection_vector = .{ 0, 1 << 14 };
        },

        SPVTCA(1) => {
            self.graphics_state.projection_vector = .{ 1 << 14, 0 };
        },

        SFVTCA(0) => {
            self.graphics_state.freedom_vector = .{ 0, 1 << 14 };
        },

        SFVTCA(1) => {
            self.graphics_state.freedom_vector = .{ 1 << 14, 0 };
        },

        SPVTL(0) => {
            self.graphics_state.projection_vector = self.lineToDirection();
        },

        SPVTL(1) => {
            self.graphics_state.projection_vector = self.lineToPerpendicularDirection();
        },

        SFVTL(0) => {
            self.graphics_state.freedom_vector = self.lineToDirection();
        },

        SFVTL(1) => {
            self.graphics_state.freedom_vector = self.lineToPerpendicularDirection();
        },

        SPVFS => {
            self.graphics_state.projection_vector[1] = @truncate(i16, self.stackPopSigned());
            self.graphics_state.projection_vector[0] = @truncate(i16, self.stackPopSigned());
        },

        SFVFS => {
            self.graphics_state.freedom_vector[1] = @truncate(i16, self.stackPopSigned());
            self.graphics_state.freedom_vector[0] = @truncate(i16, self.stackPopSigned());
        },

        GPV => {
            self.stackPushUnsigned(@bitCast(u16, self.graphics_state.projection_vector[0]));
            self.stackPushUnsigned(@bitCast(u16, self.graphics_state.projection_vector[1]));
        },

        GFV => {
            self.stackPushUnsigned(@bitCast(u16, self.graphics_state.freedom_vector[0]));
            self.stackPushUnsigned(@bitCast(u16, self.graphics_state.freedom_vector[1]));
        },

        SFVTPV => {
            self.graphics_state.freedom_vector = self.graphics_state.projection_vector;
        },

        SZP0 => {
            self.graphics_state.zp.set(0, @intCast(u1, self.stackPopUnsigned()));
        },

        SZP1 => {
            self.graphics_state.zp.set(1, @intCast(u1, self.stackPopUnsigned()));
        },

        SZP2 => {
            self.graphics_state.zp.set(2, @intCast(u1, self.stackPopUnsigned()));
        },

        SZPS => {
            self.graphics_state.zp.setAll(@intCast(u1, self.stackPopUnsigned()));
        },

        inline SRP0...SRP2 => {
            self.graphics_state.rp[opcode - SRP0] = self.stackPopUnsigned();
        },

        SLOOP => {
            self.graphics_state.loop = self.stackPopUnsigned();
        },

        SMD => {
            self.graphics_state.minimum_distance = self.stackPopSigned();
        },

        IF => {
            if (self.stackPopUnsigned() == 0) istream.skipThrough(&.{ ELSE, EIF });
        },

        ELSE => {
            istream.skipThrough(&.{EIF});
        },

        EIF => {
            // Nothing to do
        },

        JMPR => {
            istream.jump(self.stackPopSigned());
        },

        JROF => {
            const condition = self.stackPopUnsigned();
            const offset = self.stackPopSigned();
            if (condition == 0) istream.jump(offset);
        },

        JROT => {
            const condition = self.stackPopUnsigned();
            const offset = self.stackPopSigned();
            if (condition != 0) istream.jump(offset);
        },

        SCVTCI => {
            self.graphics_state.control_value_cut_in = self.stackPopSigned();
        },

        SSWCI => {
            self.graphics_state.single_width_cut_in = self.stackPopSigned();
        },

        DUP => {
            self.stackPushUnsigned(self.stack_slots[self.stack_depth - 1]);
        },

        POP => {
            _ = self.stackPopUnsigned();
        },

        CLEAR => {
            self.stack_depth = 0;
        },

        SWAP => {
            std.mem.swap(&self.stack_slots[self.stack_depth - 1], &self.stack_slots[self.stack_depth - 2]);
        },

        DEPTH => {
            self.stackPushSigned(@intCast(i32, self.stack_depth));
        },

        CINDEX => {
            const k = @intCast(usize, self.stackPopSigned());
            self.stackPushUnsigned(self.stack_slots[self.stack_depth - k]);
        },

        MINDEX => {
            const k = @intCast(usize, self.stackPopUnsigned());
            const kth_element = self.stack_slots[self.stack_depth - k];
            for (self.stack_depth - k..self.stack_depth - 1) |i| self.stack_slots[i] = self.stack_slots[i + 1];
            self.stack_slots[self.stack_depth - 1] = kth_element;
        },

        ROLL => {
            const top_three = self.stack_slots[self.stack_depth - 3][0..3].*;
            self.stack_slots[self.stack_depth - 3] = top_three[1];
            self.stack_slots[self.stack_depth - 2] = top_three[0];
            self.stack_slots[self.stack_depth - 1] = top_three[2];
        },

        FDEF => {
            const f = self.stackPopUnsigned();
            const start = istream.offset;
            istream.skipThrough(ENDF);
            const end = istream.offset;
            self.functions[f] = istream.instructions[start..end];
        },

        CALL => {
            self.execute(self.functions[self.stackPopUnsigned()]);
        },

        LOOPCALL => {
            const f = self.functions[self.stackPopUnsigned()];
            const count = self.stackPopUnsigned();
            for (0..count) |_| self.execute(f);
        },

        inline PUSHB(0)...PUSHB(7) => {
            const n = opcode - PUSHB(0) + 1;
            for (0..n) |_| self.stackPushUnsigned(istream.nextByte().?);
        },

        inline PUSHW(0)...PUSHW(7) => {
            const n = opcode - PUSHW(0) + 1;
            for (0..n) |_| self.stackPushSigned(istream.nextEmbeddedWord());
        },

        NPUSHB => {
            const n = istream.nextByte();
            for (0..n) |_| istream.nextByte();
        },

        NPUSHW => {
            const n = istream.nextByte();
            for (0..n) |_| self.stackPushSigned(istream.nextEmbeddedWord());
        },

        WS => {
            const value = self.stackPopUnsigned();
            const location = self.stackPopUnsigned();
            self.storage_area[location] = value;
        },

        RS => {
            self.stackPushUnsigned(self.storage_area[self.stackPopUnsigned()]);
        },

        WCVTP => {
            const value = self.stackPopSigned();
            const location = self.stackPopUnsigned();
            self.cvt[location].significand = value;
        },

        RCVT => {
            self.stackPushSigned(self.cvt[self.stackPopUnsigned()].significand);
        },

        FLIPON => {
            self.graphics_state.auto_flip = true;
        },

        FLIPOFF => {
            self.graphics_state.auto_flip = false;
        },

        LT => {
            const rhs = self.stackPopUnsigned();
            const lhs = self.stackPopUnsigned();
            self.stackPushBool(lhs < rhs);
        },

        LTEQ => {
            const rhs = self.stackPopUnsigned();
            const lhs = self.stackPopUnsigned();
            self.stackPushBool(lhs <= rhs);
        },

        GT => {
            const rhs = self.stackPopUnsigned();
            const lhs = self.stackPopUnsigned();
            self.stackPushBool(lhs > rhs);
        },

        GTEQ => {
            const rhs = self.stackPopUnsigned();
            const lhs = self.stackPopUnsigned();
            self.stackPushBool(lhs >= rhs);
        },

        EQ => {
            self.stackPushBool(self.stackPopUnsigned() == self.stackPopUnsigned());
        },

        NEQ => {
            self.stackPushBool(self.stackPopUnsigned() != self.stackPopUnsigned());
        },

        AND => {
            const a = self.stackPopBool();
            const b = self.stackPopBool();
            self.stackPushBool(a and b);
        },

        OR => {
            const a = self.stackPopBool();
            const b = self.stackPopBool();
            self.stackPushBool(a or b);
        },

        NOT => {
            self.stackPushBool(!self.stackPopBool());
        },

        ADD => {
            self.stackPushSigned(self.stackPopSigned() +% self.stackPopSigned());
        },

        SUB => {
            const rhs = self.stackPopSigned();
            const lhs = self.stackPopSigned();
            self.stackPushSigned(lhs -% rhs);
        },

        DIV => {
            const rhs = self.stackPopSigned();
            const lhs = self.stackPopSigned();
            self.stackPushSigned(if (rhs == 0) 0 else @truncate(i32, @divTrunc(@as(i38, lhs) << 6, rhs)));
        },

        MUL => {
            self.stackPushSigned(@truncate(i32, (@as(i38, self.stackPopSigned()) *% self.stackPopSigned()) >> 6));
        },

        ABS => {
            const v = self.stackPopSigned();
            self.stackPushSigned(if (v < 0) -%v else v);
        },

        FLOOR => {
            self.stackPushSigned(self.stackPopSigned & ~@as(i32, 0x3f));
        },

        CEILING => {
            const v = self.stackPopSigned();
            self.stackPushSigned(v + ((0x40 - (v & 0x3f)) & 0x3f));
        },

        MIN => {
            self.stackPushUnsigned(@min(self.stackPopUnsigned(), self.stackPopUnsigned()));
        },

        MAX => {
            self.stackPushUnsigned(@max(self.stackPopUnsigned(), self.stackPopUnsigned()));
        },

        WCVTF => {
            const value = self.stackPopSigned();
            const location = self.stackPopUnsigned();
            self.cvt[location] = value *% self.px_per_funit;
        },

        else => {
            std.debug.panic("unknown opcode: {}", .{opcode});
        },
    };
}

test "ref all decls" {
    std.testing.refAllDecls(@This());
}
