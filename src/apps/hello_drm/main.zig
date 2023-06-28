const drm = @import("drm");
const std = @import("std");

const allocator = std.heap.c_allocator;

pub fn main() anyerror!void {
    var args = std.process.args();
    if (args.next() == null) return error.MissingExecPathArg;
    const dev_path = args.next() orelse return error.MissingDevicePathArg;
    if (args.next() != null) return error.ExtraArgs;

    const dev_fd = try std.os.open(dev_path, std.os.O.RDWR | std.os.O.CLOEXEC, 0);
    defer std.os.close(dev_fd);

    {
        const version = try drm.Version.get(dev_fd, allocator);
        defer version.deinit(allocator);
        std.log.info("Version: {}.{}.{}", .{ version.major, version.minor, version.patch });
        std.log.info("Name: {s}", .{version.name});
        std.log.info("Date: {s}", .{version.date});
        std.log.info("Description: {s}", .{version.desc});
    }

    {
        const bus_id = try drm.getBusId(dev_fd, allocator);
        defer allocator.free(bus_id);
        std.log.info("Bus ID: {s}", .{bus_id});
    }

    const magic = try drm.getMagic(dev_fd);
    std.log.info("Magic: 0x{x}", .{magic});

    {
        const mr = try drm.ModeResources.get(dev_fd, allocator);
        defer mr.deinit(allocator);
    }
}
