const drm = @import("drm");
const std = @import("std");

pub fn main() anyerror!void {
    const allocator = std.heap.c_allocator;

    const dev_fd = try std.os.open("/dev/dri/card0", std.os.O.RDWR | std.os.O.CLOEXEC, 0);
    defer std.os.close(dev_fd);

    const version = try drm.Version.get(dev_fd, allocator);
    defer version.deinit(allocator);
    std.log.info("Device version: {}.{}.{}", .{version.major, version.minor, version.patch});
    std.log.info("Device name: {s}", .{version.name});
    std.log.info("Device date: {s}", .{version.date});
    std.log.info("Device description: {s}", .{version.desc});
}
