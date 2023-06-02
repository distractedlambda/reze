const std = @import("std");

export fn alloc(len: usize, ptr_align: u8) ?[*]u8 {
    return std.heap.wasm_allocator.rawAlloc(len, ptr_align, @returnAddress());
}

export fn resize(buf: [*]u8, buf_len: usize, log2_buf_align: u8, new_len: usize) bool {
    return std.heap.wasm_allocator.rawResize(buf[0..buf_len], log2_buf_align, new_len, @returnAddress());
}

export fn free(buf: [*]u8, buf_len: usize, log2_buf_align: u8) void {
    std.heap.wasm_allocator.rawFree(buf[0..buf_len], log2_buf_align, @returnAddress());
}
