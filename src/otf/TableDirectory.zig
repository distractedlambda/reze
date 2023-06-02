const bytes = @import("../bytes.zig");
const otf = @import("../otf.zig");
const std = @import("std");

const BufferDecoder = bytes.BufferDecoder;
const Tag = otf.Tag;

font_data: []const u8,
table_records: []const [16]u8,

pub fn decode(font_data: []const u8) !@This() {
    var decoder = BufferDecoder(.Big).init(font_data);
    const sfnt_version = try decoder.next(u32);
    if (sfnt_version != 0x00010000) return error.UnsupportedSfntVersion;
    const num_tables = try decoder.next(u16);
    _ = try decoder.next(u16); // searchRange
    _ = try decoder.next(u16); // entrySelector
    _ = try decoder.next(u16); // rangeShift
    return .{
        .font_data = font_data,
        .table_records = try decoder.nextChunkedBytes(16, num_tables),
    };
}

pub const TableRecord = struct {
    tag: Tag,
    data: []const u8,
};

pub const TableIterator = struct {
    font_data: []const u8,
    remaining_records: []const [16]u8,

    pub fn next(self: *@This()) !?TableRecord {
        if (self.remaining_records.len == 0)
            return null;

        const record_data = &self.remaining_records[0];
        const tag = record_data[0..4].*;
        const offset = bytes.loadUnpadded(.Big, u32, record_data[8..12]);
        const length = bytes.loadUnpadded(.Big, u32, record_data[12..16]);

        if (offset > self.font_data.len)
            return error.OutOfBounds;

        if (self.font_data.len - offset < length)
            return error.OutOfBounds;

        self.remaining_records = self.remaining_records[1..];

        return TableRecord{
            .tag = tag,
            .data = self.font_data[offset..][0..length],
        };
    }
};

pub fn tables(self: @This()) TableIterator {
    return .{
        .font_data = self.font_data,
        .remaining_records = self.table_records,
    };
}
