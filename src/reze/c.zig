const buildconfig = @import("buildconfig");

pub usingnamespace @cImport({
    if (buildconfig.linking_glfw) {
        @cDefine("GLFW_INCLUDE_NONE", {});

        @cDefine("GLFW_NATIVE_INCLUDE_NONE", {});

        @cDefine(switch (@import("builtin").os.tag) {
            .ios, .macos, .watchos, .tvos => "GLFW_EXPOSE_NATIVE_COCOA",
            .windows => "GLFW_EXPOSE_NATIVE_WIN32",
            else => "GLFW_EXPOSE_NATIVE_X11",
        }, {});

        @cInclude("GLFW/glfw3.h");
        @cInclude("GLFW/glfw3native.h");
    }

    if (buildconfig.linking_freetype) {
        // TODO
    }

    if (buildconfig.linking_fontconfig) {
        // TODO
    }
});
