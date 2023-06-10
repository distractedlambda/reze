const std = @import("std");

const c = @import("../c.zig");

const err = @import("err.zig");

const Error = err.Error;
const Face = @import("face.zig").Face;
const Parameter = @import("parameter.zig").Parameter;

pub const Library = opaque {
    fn raw(self: *Library) *c.FT_LibraryRec_ {
        return @ptrCast(*c.FT_LibraryRec_, self);
    }

    pub fn create() Error!*Library {
        var result: c.FT_Library = null;
        try err.check(c.FT_Init_FreeType(&result));
        return @ptrCast(*Library, result);
    }

    pub fn destroy(self: *Library) void {
        err.check(c.FT_Done_FreeType(self.raw())) catch |e|
            std.debug.panic("error destroying FreeType library: {}", .{e});
    }

    pub const OpenFaceOptions = struct {
        source: Source,
        face_index: u16 = 0,
        named_instance_index: u15 = 0,
        driver: ?*c.FT_ModuleRec_ = null,
        params: []const Parameter = &.{},

        pub const Source = union(enum) {
            memory: []const u8,
            path: [*:0]const u8,
            stream: *c.FT_StreamRec_,
        };
    };

    pub fn openFace(self: *Library, options: OpenFaceOptions) Error!*Face {
        var args = std.mem.zeroes(c.FT_Open_Args);

        switch (options.source) {
            .memory => |m| {
                args.flags |= c.FT_OPEN_MEMORY;
                args.memory_base = m.ptr;
                args.memory_size = @intCast(c.FT_Long, m.len);
            },

            .path => |p| {
                args.flags |= c.FT_OPEN_PATHNAME;
                args.pathname = p;
            },

            .stream => |s| {
                args.flags |= c.FT_OPEN_STREAM;
                args.stream = s;
            },
        }

        if (options.driver) |d| {
            args.flags |= c.FT_OPEN_DRIVER;
            options.driver = d;
        }

        if (options.params.len != 0) {
            args.flags |= c.FT_OPEN_PARAMS;
            args.num_params = @intCast(c.FT_Int, options.params.len);
            args.params = @ptrCast([*]c.FT_Parameter, options.params.ptr);
        }

        var result: c.FT_Face = null;

        try err.check(c.FT_Open_Face(
            self.raw(),
            &args,
            options.face_index | (@as(u31, options.named_instance_index) << 16),
            &result,
        ));

        return @ptrCast(*Face, result);
    }
};
