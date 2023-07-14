const builtin = @import("builtin");
const std = @import("std");

const Endian = std.builtin.Endian;

pub const BufferDecoder = struct {
    buffer: []const u8,

    pub fn init(buffer: []const u8) BufferDecoder {
        return .{ .buffer = buffer };
    }

    fn checkRemaining(self: @This(), count: usize) !void {
        if (self.buffer.len < count) return error.EndOfBuffer;
    }

    pub fn nextBytes(self: *@This(), count: anytype) !@TypeOf(self.buffer[0..count]) {
        try self.checkRemaining(count);
        defer self.buffer = self.buffer[count..];
        return self.buffer[0..count];
    }

    pub fn next(self: *@This(), comptime endian: Endian, comptime T: type) !T {
        return switch (@typeInfo(T)) {
            .Int => |info| blk: {
                const n_bytes: comptime_int = @divExact(info.bits, 8);
                const raw: T = @bitCast((try self.next(n_bytes)).*);
                break :blk if (builtin.cpu.arch.endian == endian)
                    raw
                else
                    @byteSwap(raw);
            },

            .Enum => |info| blk: {
                const tag = try self.next(endian, info.tag_type);
                break :blk if (info.is_exhaustive)
                    std.meta.intToEnum(T, tag)
                else
                    @enumFromInt(tag);
            },

            .Struct => |info| @bitCast(try self.next(endian, info.backing_integer.?)),

            .Float => |info| @bitCast(try self.next(endian, std.meta.Int(.unsigned, info.bits))),

            else => @compileError("unsupported type: " ++ @typeName(T)),
        };
    }

    pub fn skip(self: *@This(), count: usize) void {
        try self.checkRemaining(count);
        self.buffer = self.buffer[count..];
    }
};
