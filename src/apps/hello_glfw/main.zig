const glfw = @import("glfw");

pub fn main() anyerror!void {
    try glfw.init(.{});
    defer glfw.terminate();

    const window = try glfw.Window.create(.{
        .width = 800,
        .height = 600,
        .title = "Hello GLFW!",
    });

    while (!try window.shouldClose()) {
        try glfw.pollEvents();
    }
}
