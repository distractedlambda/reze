const std = @import("std");

const c = @import("../c.zig");
const FixedPoint = @import("../scaled_int.zig").FixedPoint;

const err = @import("err.zig");
const Error = err.Error;

pub const Face = opaque {
    fn rawConst(self: *const Face) *const c.FT_FaceRec_ {
        return @ptrCast(*const c.FT_FaceRec_, self);
    }

    fn raw(self: *Face) *c.FT_FaceRec_ {
        return @ptrCast(*c.FT_FaceRec_, self);
    }

    pub fn destroy(self: *Face) void {
        err.check(c.FT_Done_Face(self.raw())) catch |e|
            std.debug.panic("error destroying FreeType face: {}", .{e});
    }

    pub const SizeRequest = struct {
        type: Type = .nominal,
        width: FixedPoint(.signed, 26, 6),
        height: FixedPoint(.signed, 26, 6),
        dpi_x: c_uint = 0,
        dpi_y: c_uint = 0,

        pub const Type = enum(c_int) {
            nominal = c.FT_SIZE_REQUEST_TYPE_NOMINAL,
            real_dim = c.FT_SIZE_REQUEST_TYPE_REAL_DIM,
            bbox = c.FT_SIZE_REQUEST_TYPE_BBOX,
            cell = c.FT_SIZE_REQUEST_TYPE_CELL,
        };
    };

    pub fn requestSize(self: *Face, request: SizeRequest) Error!void {
        var raw_request = c.FT_Size_RequestRec{
            .type = @enumToInt(request.type),
            .width = request.width.repr,
            .height = request.height.repr,
            .horiResolution = request.dpi_x,
            .vertResolution = request.dpi_y,
        };

        return err.check(c.FT_Request_Size(self.raw(), &raw_request));
    }

    pub const LoadFlags = packed struct(u32) {
        no_scale: bool = false,
        no_hinting: bool = false,
        render: bool = false,
        no_bitmap: bool = false,
        vertical_layout: bool = false,
        force_autohint: bool = false,
        crop_bitmap: bool = false,
        pedantic: bool = false,
        _reserved0: u1 = 0,
        ignore_global_advance_width: bool = false,
        no_recurse: bool = false,
        ignore_transform: bool = false,
        monochrome: bool = false,
        linear_design: bool = false,
        sbits_only: bool = false,
        no_autohint: bool = false,
        target: Target = .normal,
        color: bool = false,
        compute_metrics: bool = false,
        bitmap_metrics_only: bool = false,
        _reserved1: u9 = 0,

        pub const Target = enum(u4) {
            normal = c.FT_RENDER_MODE_NORMAL,
            light = c.FT_RENDER_MODE_LIGHT,
            mono = c.FT_RENDER_MODE_MONO,
            lcd = c.FT_RENDER_MODE_LCD,
            lcd_v = c.FT_RENDER_MODE_LCD_V,
        };
    };

    pub fn loadGlyph(self: *Face, glyph_index: c_uint, flags: LoadFlags) Error!void {
        return err.check(c.FT_Load_Glyph(self.raw(), glyph_index, @bitCast(c.FT_Int32, flags)));
    }

    pub fn getCharIndex(self: *Face, charcode: c_ulong) c_uint {
        return c.FT_Get_Char_index(self.raw(), charcode);
    }

    pub fn loadChar(self: *Face, charcode: c_ulong, flags: LoadFlags) Error!void {
        return err.check(c.FT_Load_Char(self.raw(), charcode, @bitCast(c.FT_Int32, flags)));
    }
};
