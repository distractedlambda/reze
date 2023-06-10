const build_options = @import("build_options");

pub usingnamespace @cImport({
    if (build_options.use_glfw) {
        @cDefine(switch (@import("builtin").os.tag) {
            .ios, .macos, .watchos, .tvos => "GLFW_EXPOSE_NATIVE_COCOA",
            .windows => "GLFW_EXPOSE_NATIVE_WIN32",
            else => "GLFW_EXPOSE_NATIVE_X11",
        }, {});

        @cDefine("GLFW_INCLUDE_NONE", {});
        @cInclude("GLFW/glfw3.h");
        @cInclude("GLFW/glfw3native.h");
    }

    if (build_options.use_freetype) {
        @cInclude("ft2build.h");
        @cInclude("freetype/freetype.h");
    }
});
