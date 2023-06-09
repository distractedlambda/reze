pub const ast = @import("ast.zig");
pub const opcodes = @import("opcodes.zig");
pub const runtime = @import("runtime/runtime.zig");
pub const Decoder = @import("Decoder.zig");

test {
    _ = ast;
    _ = opcodes;
    _ = runtime;
    _ = Decoder;
}
