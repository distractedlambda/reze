const c = @cImport({
    @cInclude("libdrm/drm.h");
});

pub fn main() anyerror!void {
    _ = c;
}
