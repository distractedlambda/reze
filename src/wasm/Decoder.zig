const std = @import("std");
const wasm = @import("../wasm.zig");

data: []const u8,

pub fn init(data: []const u8) @This() {
    return .{ .data = data };
}

pub fn atEnd(self: @This()) bool {
    return self.data.len == 0;
}

pub fn nextByte(self: *@This()) !u8 {
    if (self.data.len == 0) return error.UnexpectedEndOfData;
    defer self.data = self.data[1..];
    return self.data[0];
}

pub fn peekByte(self: *@This()) !u8 {
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

pub fn nextByteVector(self: *@This()) !wasm.Name {
    return try self.nextBytes(try self.nextInt(u32));
}

// TODO: validate UTF8?
pub const nextName = nextByteVector;

pub fn nextNumType(self: *@This()) !wasm.NumType {
    return std.meta.intToEnum(wasm.NumType, try self.nextByte()) catch
        error.UnsupportedNumberType;
}

pub fn nextVecType(self: *@This()) !wasm.VecType {
    return std.meta.intToEnum(wasm.VecType, try self.nextByte()) catch
        error.UnsupportedVectorType;
}

pub fn nextRefType(self: *@This()) !wasm.RefType {
    return std.meta.intToEnum(wasm.RefType, try self.nextByte()) catch
        error.UnsupportedReferenceType;
}

pub fn nextValType(self: *@This()) !wasm.ValType {
    return std.meta.intToEnum(wasm.ValType, try self.nextByte()) catch
        error.UnsupportedValueType;
}

pub fn nextResultType(self: *@This()) !wasm.ResultType {
    const len = try self.nextInt(u32);
    const types = try self.nextBytes(len);

    for (types) |t|
        _ = std.meta.intToEnum(wasm.ValType, t) catch
            return error.UnsupportedValueType;

    return std.mem.bytesAsSlice(wasm.ValType, types);
}

pub fn nextFuncType(self: *@This()) !wasm.FuncType {
    if (try self.nextByte() != 0x60)
        return error.UnsupportedFunctionType;

    return .{
        .parameters = try self.nextResultType(),
        .results = try self.nextResultType(),
    };
}

pub fn nextLimits(self: *@This()) !wasm.Limits {
    return switch (try self.nextByte()) {
        0x00 => .{ .min = try self.nextInt(u32) },
        0x01 => .{ .min = try self.nextInt(u32), .max = try self.nextInt(u32) },
        else => error.UnsupportedLimits,
    };
}

pub fn nextMemType(self: *@This()) !wasm.MemType {
    return .{ .limits = try self.nextLimits() };
}

pub fn nextTableType(self: *@This()) !wasm.TableType {
    return .{
        .element_type = try self.nextRefType(),
        .limits = try self.nextLimits(),
    };
}

pub fn nextMut(self: *@This()) !wasm.Mut {
    return std.meta.intToEnum(wasm.Mut, try self.nextByte()) catch
        error.UnsupportedMutability;
}

pub fn nextElemKind(self: *@This()) !wasm.ElemKind {
    return std.meta.intToEnum(wasm.ElemKind, try self.nextByte()) catch
        error.UnsupportedElemKind;
}

pub fn nextGlobalType(self: *@This()) !wasm.GlobalType {
    return .{
        .value_type = try self.nextValType(),
        .mutability = try self.nextMut(),
    };
}

test "ref all decls" {
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
