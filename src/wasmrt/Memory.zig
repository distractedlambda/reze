comptime {
    if (@import("builtin").cpu.arch.endian() != .Little)
        @compileError("TODO support big-endian");
}

const std = @import("std");

allocator: std.mem.Allocator,
min_pages: u16,
max_pages: ?u16,
current_pages: u16,
bytes: [*]align(page_size) u8,

const page_size = 65536;

inline fn pagesToBytes(n_pages: u16) u32 {
    return @as(u32, n_pages) * page_size;
}

pub fn init(allocator: std.mem.Allocator, min_pages: u16, max_pages: ?u16) !@This() {
    const bytes = try allocator.alignedAlloc(u8, page_size, pagesToBytes(min_pages));
    @memset(bytes[0..pagesToBytes(min_pages)], 0);
    return .{
        .allocator = allocator,
        .min_pages = min_pages,
        .max_pages = max_pages,
        .current_pages = min_pages,
        .bytes = bytes,
    };
}

pub fn deinit(self: *@This()) void {
    self.allocator.free(self.bytes[0..pagesToBytes(self.current_pages)]);
    self.* = undefined;
}

pub inline fn @"memory.size"(self: *const @This()) u32 {
    return self.current_pages;
}

pub fn @"memory.grow"(self: *@This(), delta: u32) u32 {
    const err = std.math.maxInt(u32);

    const new_pages = std.math.add(
        u16,
        self.current_pages,
        std.math.cast(u16, delta) catch return err,
    ) catch return err;

    if (self.max_pages) |mp|
        if (self.new_pages > mp)
            return err;

    self.bytes = self.allocator.realloc(
        self.bytes[0..pagesToBytes(self.current_pages)],
        pagesToBytes(new_pages),
    ) catch return err;

    @memset(self.bytes[pagesToBytes(self.current_pages)..pagesToBytes(new_pages)], 0);

    self.current_pages = new_pages;
}

inline fn translateAddress(
    self: *const @This(),
    addr: u32,
    offset: u32,
    comptime access_size: usize,
) ![*]u8 {
    const effective_address = @as(u64, addr) + offset;
    const min_size = effective_address + access_size;
    if (min_size > self.pagesToBytes(self.current_pages)) return error.Trap;
    return self.bytes + effective_address;
}

inline fn load(self: *const @This(), comptime T: type, addr: u32, offset: u32) !T {
    return @ptrCast([*]align(1) const T, try self.translateAddress(addr, offset, @sizeOf(T))).*;
}

inline fn store(self: *const @This(), value: anytype, addr: u32, offset: u32) !void {
    const T = @TypeOf(value);
    @ptrCast([*]align(1) T, try self.translateAddress(addr, offset, @sizeOf(T))).* = value;
}

pub inline fn @"i32.load"(self: *const @This(), addr: u32, offset: u32) !i32 {
    return self.load(i32, addr, offset);
}

pub inline fn @"i64.load"(self: *const @This(), addr: u32, offset: u32) !i64 {
    return self.load(i64, addr, offset);
}

pub inline fn @"f32.load"(self: *const @This(), addr: u32, offset: u32) !f32 {
    return self.load(f32, addr, offset);
}

pub inline fn @"f64.load"(self: *const @This(), addr: u32, offset: u32) !f64 {
    return self.load(f64, addr, offset);
}

pub inline fn @"i32.load8_s"(self: *const @This(), addr: u32, offset: u32) !i32 {
    return self.load(i8, addr, offset);
}

pub inline fn @"i32.load8_u"(self: *const @This(), addr: u32, offset: u32) !i32 {
    return self.load(u8, addr, offset);
}

pub inline fn @"i32.load16_s"(self: *const @This(), addr: u32, offset: u32) !i32 {
    return self.load(i16, addr, offset);
}

pub inline fn @"i32.load16_u"(self: *const @This(), addr: u32, offset: u32) !i32 {
    return self.load(u16, addr, offset);
}
