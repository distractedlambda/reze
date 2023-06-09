const build_options = @import("build_options");

pub const glfw = @import("glfw/glfw.zig");
pub const wasm = @import("wasm/wasm.zig");
pub const Aabb = @import("aabb.zig").Aabb;
pub const Extent = @import("extent.zig").Extent;
pub const Ratio = @import("ratio.zig").Ratio;
pub const ReadOnlyFileMapping = @import("ReadOnlyFileMapping.zig");

test {
    if (build_options.linking_glfw) {
        _ = glfw;
    }

    _ = wasm;
    _ = Aabb;
    _ = Extent;
    _ = Ratio;
    _ = ReadOnlyFileMapping;
}
