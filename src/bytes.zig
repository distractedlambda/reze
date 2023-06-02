const builtin = @import("builtin");
const std = @import("std");

pub fn BufferDecoder(comptime endian: std.builtin.Endian) type {
    return struct {
        buffer: []const u8,

        pub fn init(buffer: []const u8) @This() {
            return .{ .buffer = buffer };
        }

        pub fn nextBytes(self: *@This(), len: anytype) !@TypeOf(self.buffer[0..len]) {
            if (self.buffer.len < len) return error.OutOfBounds;
            defer self.buffer = self.buffer[len..];
            return self.buffer[0..len];
        }

        pub fn nextChunkedBytes(self: *@This(), comptime chunk_len: comptime_int, num_chunks: usize) []const [chunk_len]u8 {
            const total_len = try std.math.mul(usize, chunk_len, num_chunks);
            const bytes = try self.nextBytes(total_len);
            return @ptrCast([*]const [chunk_len]u8, bytes.ptr)[0..num_chunks];
        }

        pub fn next(self: *@This(), comptime T: type) !T {
            return loadUnpadded(endian, T, try self.nextBytes());
        }

        pub fn nextSlice(self: *@This(), comptime T: type, len: usize) !UnpaddedSlice(endian, T) {
            return .{
                .bytes = try self.nextBytes(try std.math.mul(usize, len, unpaddedSizeOf(T))),
                .len = len,
            };
        }

        pub fn remainder(self: @This()) []const u8 {
            return self.buffer;
        }

        pub fn chunkedRemainder(self: @This(), comptime chunk_len: comptime_int) ![]const [chunk_len]u8 {
            return @ptrCast([*]const [chunk_len]u8, self.buffer.ptr)[0..try std.math.divExact(self.buffer.len, chunk_len)];
        }

        pub fn truncate(self: *@This(), len: usize) !void {
            if (self.buffer.len < len) return error.OutOfBounds;
            self.buffer = self.buffer[0..len];
        }
    };
}

pub fn UnpaddedSlice(comptime endian: std.builtin.Endian, comptime T: type) type {
    return struct {
        bytes: [*]const u8,
        len: usize,

        pub fn get(self: @This(), index: usize) !T {
            return if (index >= self.len)
                return error.OutOfBounds
            else
                loadUnpadded(endian, T, self.bytes[0 .. index * unpaddedSizeOf(T)][0..unpaddedSizeOf(T)]);
        }
    };
}

pub fn unpaddedSizeOf(comptime T: type) comptime_int {
    return @divExact(@bitSizeOf(T), 8);
}

pub fn loadUnpadded(comptime endian: std.builtin.Endian, comptime T: type, bytes: *const [unpaddedSizeOf(T)]u8) switch (@typeInfo(T)) {
    .Enum => std.meta.IntToEnumError!T,
    else => T,
} {
    return switch (@typeInfo(T)) {
        .Int => nativeToEndian(endian, @bitCast(T, bytes.*)),
        .Enum => |info| std.meta.intToEnum(T, loadUnpadded(endian, info.tag_type, bytes)),
        .Struct => |info| @bitCast(T, loadUnpadded(endian, info.backing_integer, bytes)),
        else => @compileError("unsupported type: " ++ @typeName(T)),
    };
}

pub fn nativeToEndian(comptime endian: std.builtin.Endian, value: anytype) @TypeOf(value) {
    return if (endian != builtin.cpu.arch.endian())
        @byteSwap(value)
    else
        value;
}
