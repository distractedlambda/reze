const c = @import("../c.zig");

const err = @import("err.zig");
const Error = err.Error;

pub const GlyphSlot = opaque {
    fn raw(self: *GlyphSlot) *c.FT_GlyphSlotRec_ {
        return @ptrCast(*c.FT_GlyphSlotRec_, self);
    }

    pub const RenderMode = enum(c_int) {
        normal = c.FT_RENDER_MODE_NORMAL,
        light = c.FT_RENDER_MODE_LIGHT,
        mono = c.FT_RENDER_MODE_MONO,
        lcd = c.FT_RENDER_MODE_LCD,
        lcd_v = c.FT_RENDER_MODE_LCD_V,
        sdf = c.FT_RENDER_MODE_SDF,
    };

    pub fn render(self: *GlyphSlot, mode: RenderMode) Error!void {
        return err.check(c.FT_Render_Glyph(self.raw(), @enumToInt(mode)));
    }
};
