const opcodes = @import("opcodes.zig");
const std = @import("std");
const wasm = @import("../wasm.zig");

const Decoder = @import("Decoder.zig");

allocator: std.mem.Allocator,

types: std.ArrayListUnmanaged(wasm.FuncType) = .{},
imported_funcs: std.ArrayListUnmanaged(wasm.ImportedFunc) = .{},
imported_tables: std.ArrayListUnmanaged(wasm.ImportedTable) = .{},
imported_mems: std.ArrayListUnmanaged(wasm.ImportedMem) = .{},
imported_globals: std.ArrayListUnmanaged(wasm.ImportedGlobal) = .{},
funcs: std.ArrayListUnmanaged(wasm.TypeIdx) = .{},
tables: std.ArrayListUnmanaged(wasm.TableType) = .{},
mems: std.ArrayListUnmanaged(wasm.MemType) = .{},
globals: std.ArrayListUnmanaged(wasm.Global) = .{},
exports: std.ArrayListUnmanaged(wasm.Export) = .{},
start: ?wasm.FuncIdx = null,
elems: std.ArrayListUnmanaged(wasm.Elem) = .{},
code: std.ArrayListUnmanaged([]const u8) = .{},
datas: std.ArrayListUnmanaged(wasm.Data) = .{},
module_name: ?[]const u8 = null,
func_names: std.AutoHashMapUnmanaged(wasm.FuncIdx, []const u8) = .{},
local_names: std.AutoHashMapUnmanaged(struct { wasm.FuncIdx, wasm.LocalIdx }, []const u8) = .{},

pub fn init(allocator: std.mem.Allocator, module_data: []const u8) !@This() {
    var directory = @This(){ .allocator = allocator };
    errdefer directory.deinit();
    try directory.processModule(module_data);
    return directory;
}

pub fn deinit(self: *@This()) void {
    for (self.elems.items) |*segment| {
        switch (segment.init) {
            inline else => |vector| self.allocator.free(vector),
        }
    }

    self.types.deinit(self.allocator);
    self.imported_funcs.deinit(self.allocator);
    self.imported_tables.deinit(self.allocator);
    self.imported_mems.deinit(self.allocator);
    self.imported_globals.deinit(self.allocator);
    self.funcs.deinit(self.allocator);
    self.tables.deinit(self.allocator);
    self.mems.deinit(self.allocator);
    self.globals.deinit(self.allocator);
    self.exports.deinit(self.allocator);
    self.elems.deinit(self.allocator);
    self.code.deinit(self.allocator);
    self.datas.deinit(self.allocator);
    self.func_names.deinit(self.allocator);
    self.local_names.deinit(self.allocator);
}

fn processModule(self: *@This(), data: []const u8) !void {
    var decoder = Decoder.init(data);

    if (!std.mem.eql(u8, &.{ 0x00, 0x61, 0x73, 0x6d }, try decoder.nextBytes(4)))
        return error.NotABinaryWasmModule;

    if (!std.mem.eql(u8, &.{ 0x01, 0x00, 0x00, 0x00 }, try decoder.nextBytes(4)))
        return error.UnsupportedBinaryFormatVersion;

    while (!decoder.atEnd()) {
        const section_id = try decoder.nextByte();
        const section_len = try decoder.nextInt(u32);
        const section_data = try decoder.nextBytes(section_len);
        try self.processSection(section_id, section_data);
    }

    if (self.funcs.items.len != self.code.items.len)
        return error.InconsistentFunctionCount;
}

fn processSection(self: *@This(), id: u8, data: []const u8) !void {
    var decoder = Decoder.init(data);
    switch (id) {
        0 => {
            const name = try decoder.nextName();
            if (std.mem.eql(u8, name, "name")) {
                self.processNameSection(decoder.remainder()) catch |err| {
                    std.log.err("error parsing 'name' section: {}", .{err});
                    self.module_name = null;
                    self.func_names.clearAndFree(self.allocator);
                    self.local_names.clearAndFree(self.allocator);
                };
            }
        },

        1 => {
            const len = try decoder.nextInt(u32);
            try self.types.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.types.appendAssumeCapacity(try decoder.nextFuncType());
        },

        2 => {
            const len = try decoder.nextInt(u32);
            for (0..len) |_| {
                const name = wasm.ImportName{
                    .module = try decoder.nextName(),
                    .name = try decoder.nextName(),
                };

                switch (try decoder.nextByte()) {
                    0x00 => try self.imported_funcs.append(self.allocator, .{
                        .name = name,
                        .type = try self.nextIdx(&decoder, wasm.TypeIdx),
                    }),

                    0x01 => try self.imported_tables.append(self.allocator, .{
                        .name = name,
                        .type = try decoder.nextTableType(),
                    }),

                    0x02 => try self.imported_mems.append(self.allocator, .{
                        .name = name,
                        .type = try decoder.nextMemType(),
                    }),

                    0x03 => try self.imported_globals.append(self.allocator, .{
                        .name = name,
                        .type = try decoder.nextGlobalType(),
                    }),

                    else => return error.UnsupportedImport,
                }
            }
        },

        3 => {
            const len = try decoder.nextInt(u32);
            try self.funcs.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.funcs.appendAssumeCapacity(try self.nextIdx(&decoder, wasm.TypeIdx));
        },

        4 => {
            const len = try decoder.nextInt(u32);
            try self.tables.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.tables.appendAssumeCapacity(try decoder.nextTableType());
        },

        5 => {
            const len = try decoder.nextInt(u32);
            try self.mems.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.mems.appendAssumeCapacity(try decoder.nextMemType());
        },

        6 => {
            const len = try decoder.nextInt(u32);
            try self.globals.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.globals.appendAssumeCapacity(try self.nextGlobal(&decoder));
        },

        7 => {
            const len = try decoder.nextInt(u32);
            try self.exports.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.exports.appendAssumeCapacity(try self.nextExport(&decoder));
        },

        8 => {
            self.start = try self.nextIdx(&decoder, wasm.FuncIdx);
        },

        9 => {
            const len = try decoder.nextInt(u32);
            try self.elems.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.elems.appendAssumeCapacity(try self.nextElem(&decoder));
        },

        10 => {
            const len = try decoder.nextInt(u32);
            try self.code.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.code.appendAssumeCapacity(try decoder.nextBytes(try decoder.nextInt(u32)));
        },

        11 => {
            const len = try decoder.nextInt(u32);
            try self.datas.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| self.datas.appendAssumeCapacity(try self.nextData(&decoder));
        },

        12 => {
            // Ignore data count section
        },

        else => return error.UnsupportedSection,
    }
}

fn processNameSection(self: *@This(), data: []const u8) !void {
    var decoder = Decoder.init(data);
    while (!decoder.atEnd()) {
        const subsection_id = try decoder.nextByte();
        const subsection_len = try decoder.nextInt(u32);
        const subsection_data = try decoder.nextBytes(subsection_len);
        try self.processNameSubsection(subsection_id, subsection_data);
    }
}

fn processNameSubsection(self: *@This(), id: u8, data: []const u8) !void {
    var decoder = Decoder.init(data);
    switch (id) {
        0 => {
            self.module_name = try decoder.nextName();
        },

        1 => {
            const len = try decoder.nextInt(u32);
            try self.func_names.ensureUnusedCapacity(self.allocator, len);
            for (0..len) |_| {
                const func = try self.nextIdx(&decoder, wasm.FuncIdx);
                const func_name = try decoder.nextName();
                self.func_names.putAssumeCapacity(func, func_name);
            }
        },

        2 => {
            const outer_len = try decoder.nextInt(u32);
            for (0..outer_len) |_| {
                const func = try self.nextIdx(&decoder, wasm.FuncIdx);
                const inner_len = try decoder.nextInt(u32);
                try self.local_names.ensureUnusedCapacity(self.allocator, inner_len);
                for (0..inner_len) |_| {
                    const local = wasm.LocalIdx{ .value = try decoder.nextInt(u32) };
                    const name = try decoder.nextName();
                    self.local_names.putAssumeCapacity(.{ func, local }, name);
                }
            }
        },

        else => {},
    }
}

pub fn validateIdx(self: *const @This(), idx: anytype) !@TypeOf(idx) {
    switch (@TypeOf(idx)) {
        wasm.TypeIdx => if (idx.value >= self.types.items.len)
            return error.TypeIndexOutOfBounds,

        wasm.FuncIdx => if (idx.value >= self.imported_funcs.items.len and idx.value - self.imported_funcs.items.len >= self.funcs.items.len)
            return error.FunctionIndexOutOfBounds,

        wasm.TableIdx => if (idx.value >= self.imported_tables.items.len and idx.value - self.imported_tables.items.len >= self.tables.items.len)
            return error.TableIndexOutOfBounds,

        wasm.MemIdx => if (idx.value >= self.imported_mems.items.len and idx.value - self.imported_mems.items.len >= self.mems.items.len)
            return error.MemoryIndexOutOfBounds,

        wasm.GlobalIdx => if (idx.value >= self.imported_globals.items.len and idx.value - self.imported_globals.items.len >= self.globals.items.len)
            return error.GlobalIndexOutOfBounds,

        else => @compileError("invalid index type: " ++ @typeName(@TypeOf(idx))),
    }

    return idx;
}

pub fn nextIdx(self: *const @This(), decoder: *Decoder, comptime T: type) !T {
    return try self.validateIdx(T{ .value = try decoder.nextInt(u32) });
}

pub fn isImport(self: *const @This(), idx: anytype) bool {
    const imports_len = switch (@TypeOf(idx)) {
        wasm.FuncIdx => self.imported_funcs.items.len,
        wasm.TableIdx => self.imported_tables.items.len,
        wasm.MemIdx => self.imported_mems.items.len,
        wasm.GlobalIdx => self.imported_globals.items.len,
        else => @compileError("invalid index type: " ++ @typeName(@TypeOf(idx))),
    };

    return idx.value < imports_len;
}

fn nextConstantGlobalGet(self: *const @This(), decoder: *Decoder, expected_type: wasm.ValType) !wasm.GlobalIdx {
    const idx = try self.nextIdx(decoder, wasm.GlobalIdx);

    if (!self.isImport(idx))
        return error.UnsupportedConstantExpression;

    if (self.imported_globals.items[idx.value].type.value_type != expected_type)
        return error.TypeMismatch;

    return idx;
}

fn nextConstantExpr(self: *@This(), decoder: *Decoder, expected_type: wasm.ValType) !wasm.ConstantExpr {
    const value: wasm.ConstantExpr = switch (try decoder.nextByte()) {
        opcodes.@"global.get" => .{ .global_get = try self.nextConstantGlobalGet(decoder, expected_type) },

        opcodes.@"i32.const" => if (expected_type == .i32)
            .{ .i32_const = try decoder.nextInt(i32) }
        else
            return error.TypeMismatch,

        opcodes.@"i64.const" => if (expected_type == .i64)
            .{ .i64_const = try decoder.nextInt(i64) }
        else
            return error.TypeMismatch,

        opcodes.@"f32.const" => if (expected_type == .f32)
            .{ .f32_const = try decoder.nextFixedWidth(u32) }
        else
            return error.TypeMismatch,

        opcodes.@"f64.const" => if (expected_type == .f64)
            .{ .f64_const = try decoder.nextFixedWidth(u64) }
        else
            return error.TypeMismatch,

        opcodes.@"ref.null" => if (expected_type == .funcref or expected_type == .externref)
            .ref_null
        else
            return error.TypeMismatch,

        opcodes.@"ref.func" => if (expected_type == .funcref)
            .{ .ref_func = try self.nextIdx(decoder, wasm.FuncIdx) }
        else
            return error.TypeMismatch,

        else => return error.UnsupportedConstantExpression,
    };

    if (try decoder.nextByte() != opcodes.end)
        return error.UnsupportedConstantExpression;

    return value;
}

fn nextGlobal(self: *@This(), decoder: *Decoder) !wasm.Global {
    const typ = try decoder.nextGlobalType();
    return .{
        .type = typ,
        .initial_value = try self.nextConstantExpr(decoder, typ.value_type),
    };
}

fn nextExport(self: *@This(), decoder: *Decoder) !wasm.Export {
    return .{
        .name = try decoder.nextName(),

        .desc = switch (try decoder.nextByte()) {
            0x00 => .{ .function = try self.nextIdx(decoder, wasm.FuncIdx) },
            0x01 => .{ .table = try self.nextIdx(decoder, wasm.TableIdx) },
            0x02 => .{ .memory = try self.nextIdx(decoder, wasm.MemIdx) },
            0x03 => .{ .global = try self.nextIdx(decoder, wasm.GlobalIdx) },
            else => return error.UnsupportedExport,
        },
    };
}

fn nextI32ConstantExpr(self: *@This(), decoder: *Decoder) !wasm.I32ConstantExpr {
    const value: wasm.I32ConstantExpr = switch (try decoder.nextByte()) {
        opcodes.@"global.get" => .{ .global_get = try self.nextConstantGlobalGet(decoder, .i32) },
        opcodes.@"i32.const" => .{ .i32_const = try decoder.nextInt(i32) },
        else => return error.UnsupportedI32ConstantExpression,
    };

    if (try decoder.nextByte() != opcodes.end)
        return error.UnsupportedI32ConstantExpression;

    return value;
}

fn nextFuncrefConstantExpr(self: *@This(), decoder: *Decoder) !wasm.FuncrefConstantExpr {
    const value: wasm.FuncrefConstantExpr = switch (try decoder.nextByte()) {
        opcodes.@"global.get" => .{ .global_get = try self.nextConstantGlobalGet(decoder, .funcref) },
        opcodes.@"ref.null" => .ref_null,
        opcodes.@"ref.func" => .{ .ref_func = try self.nextIdx(decoder, wasm.FuncIdx) },
        else => return error.UnsupportedFuncrefConstantExpression,
    };

    if (try decoder.nextByte() != opcodes.end)
        return error.UnsupportedFuncrefConstantExpression;

    return value;
}

fn nextExternrefConstantExpr(self: *@This(), decoder: *Decoder) !wasm.ExternrefConstantExpr {
    const value: wasm.ExternrefConstantExpr = switch (try decoder.nextByte()) {
        opcodes.@"global.get" => .{ .global_get = try self.nextConstantGlobalGet(decoder, .externref) },
        opcodes.@"ref.null" => .ref_null,
        else => return error.UnsupportedExternrefConstantExpression,
    };

    if (try decoder.nextByte() != opcodes.end)
        return error.UnsupportedExternrefConstantExpression;

    return value;
}

fn nextIdxVector(self: *@This(), decoder: *Decoder, comptime T: type) ![]const T {
    const len = try decoder.nextInt(u32);
    const indices = try self.allocator.alloc(T, len);
    errdefer self.allocator.free(indices);
    for (indices) |*idx| idx.* = try self.nextIdx(decoder, T);
    return indices;
}

fn nextFuncrefConstantExprVector(self: *@This(), decoder: *Decoder) ![]const wasm.FuncrefConstantExpr {
    const len = try decoder.nextInt(u32);
    const exprs = try self.allocator.alloc(wasm.FuncrefConstantExpr, len);
    errdefer self.allocator.free(exprs);
    for (exprs) |*expr| expr.* = try self.nextFuncrefConstantExpr(decoder);
    return exprs;
}

fn nextExternrefConstantExprVector(self: *@This(), decoder: *Decoder) ![]const wasm.ExternrefConstantExpr {
    const len = try decoder.nextInt(u32);
    const exprs = try self.allocator.alloc(wasm.ExternrefConstantExpr, len);
    errdefer self.allocator.free(exprs);
    for (exprs) |*expr| expr.* = try self.nextExternrefConstantExpr(decoder);
    return exprs;
}

fn nextKindedElemInit(self: *@This(), decoder: *Decoder) !wasm.Elem.Init {
    return switch (try decoder.nextElemKind()) {
        .funcref => .{ .funcrefs = try self.nextIdxVector(decoder, wasm.FuncIdx) },
    };
}

fn nextTypedElemInit(self: *@This(), decoder: *Decoder) !wasm.Elem.Init {
    return switch (try decoder.nextRefType()) {
        .funcref => .{ .funcref_exprs = try self.nextFuncrefConstantExprVector(decoder) },
        .externref => .{ .externref_exprs = try self.nextExternrefConstantExprVector(decoder) },
    };
}

fn nextElem(self: *@This(), decoder: *Decoder) !wasm.Elem {
    return switch (try decoder.nextInt(u32)) {
        0 => .{
            .mode = .{ .active = .{
                .table = try self.validateIdx(wasm.TableIdx{ .value = 0 }),
                .offset = try self.nextI32ConstantExpr(decoder),
            } },

            .init = .{ .funcrefs = try self.nextIdxVector(decoder, wasm.FuncIdx) },
        },

        1 => .{
            .mode = .passive,
            .init = try self.nextKindedElemInit(decoder),
        },

        2 => .{
            .mode = .{ .active = .{
                .table = try self.nextIdx(decoder, wasm.TableIdx),
                .offset = try self.nextI32ConstantExpr(decoder),
            } },

            .init = try self.nextKindedElemInit(decoder),
        },

        3 => .{
            .mode = .declarative,
            .init = try self.nextKindedElemInit(decoder),
        },

        4 => .{
            .mode = .{ .active = .{
                .table = try self.validateIdx(wasm.TableIdx{ .value = 0 }),
                .offset = try self.nextI32ConstantExpr(decoder),
            } },

            .init = .{ .funcref_exprs = try self.nextFuncrefConstantExprVector(decoder) },
        },

        5 => .{
            .mode = .passive,
            .init = try self.nextTypedElemInit(decoder),
        },

        6 => .{
            .mode = .{ .active = .{
                .table = try self.nextIdx(decoder, wasm.TableIdx),
                .offset = try self.nextI32ConstantExpr(decoder),
            } },

            .init = try self.nextTypedElemInit(decoder),
        },

        7 => .{
            .mode = .declarative,
            .init = try self.nextTypedElemInit(decoder),
        },

        else => error.UnsupportedElementSegment,
    };
}

fn nextData(self: *@This(), decoder: *Decoder) !wasm.Data {
    const mode: wasm.Data.Mode = switch (try decoder.nextInt(u32)) {
        0 => .{ .active = .{
            .memory = try self.validateIdx(wasm.MemIdx{ .value = 0 }),
            .offset = try self.nextI32ConstantExpr(decoder),
        } },

        1 => .passive,

        2 => .{ .active = .{
            .memory = try self.nextIdx(decoder, wasm.MemIdx),
            .offset = try self.nextI32ConstantExpr(decoder),
        } },

        else => return error.UnsupportedDataSegment,
    };

    return .{
        .mode = mode,
        .init = try decoder.nextByteVector(),
    };
}

pub fn ImportedOrDeclared(comptime Imported: type, comptime Declared: type) type {
    return union(enum) {
        imported: Imported,
        declared: Declared,
    };
}

pub fn lookUp(self: *const @This(), idx: anytype) switch (@TypeOf(idx)) {
    wasm.TypeIdx => wasm.FuncType,
    wasm.FuncIdx => ImportedOrDeclared(wasm.ImportedFunc, wasm.TypeIdx),
    wasm.TableIdx => ImportedOrDeclared(wasm.ImportedTable, wasm.TableType),
    wasm.MemIdx => ImportedOrDeclared(wasm.ImportedMem, wasm.MemType),
    wasm.GlobalIdx => ImportedOrDeclared(wasm.ImportedGlobal, wasm.GlobalType),
    else => @compileError("invalid index type: " ++ @typeName(@TypeOf(idx))),
} {
    return switch (@TypeOf(idx)) {
        wasm.TypeIdx => self.types.items[idx.value],

        wasm.FuncIdx => if (self.isImport(idx))
            .{ .imported = self.imported_funcs.items[idx.value] }
        else
            .{ .declared = self.funcs.items[idx.value - self.imported_funcs.items.len] },

        wasm.TableIdx => if (self.isImport(idx))
            .{ .imported = self.imported_tables.items[idx.value] }
        else
            .{ .declared = self.tables.items[idx.value - self.imported_tables.items.len] },

        wasm.MemIdx => if (self.isImport(idx))
            .{ .imported = self.imported_mems.items[idx.value] }
        else
            .{ .declared = self.mems.items[idx.value - self.imported_mems.items.len] },

        wasm.GlobalIdx => if (self.isImport(idx))
            .{ .imported = self.imported_globals.items[idx.value] }
        else
            .{ .declared = self.globals.items[idx.value - self.imported_globals.items.len] },

        else => unreachable,
    };
}

pub fn lookUpType(self: *const @This(), idx: anytype) switch (@TypeOf(idx)) {
    wasm.FuncIdx => wasm.FuncType,
    wasm.TableIdx => wasm.TableType,
    wasm.MemIdx => wasm.MemType,
    wasm.GlobalIdx => wasm.GlobalType,
    else => @compileError("invalid index type: " ++ @typeName(@TypeOf(idx))),
} {
    return switch (@TypeOf(idx)) {
        wasm.FuncIdx => self.lookUp(switch (self.lookUp(idx)) {
            .imported => |import| import.type,
            .declared => |type_idx| type_idx,
        }),

        inline wasm.TableIdx, wasm.MemIdx, wasm.GlobalIdx => switch (self.lookUp(idx)) {
            .imported => |import| import.type,
            .declared => |t| t,
        },

        else => unreachable,
    };
}

test "ref all decls" {
    std.testing.refAllDecls(@This());
}

test "summarize test modules" {
    for (@import("../test_modules/manifest.zig").module_names) |name| {
        for (std.meta.tags(std.builtin.OptimizeMode)) |mode| {
            const module_path = try std.fmt.allocPrint(
                std.testing.allocator,
                "test_modules/{s}-{s}.wasm",
                .{ name, @tagName(mode) },
            );
            defer std.testing.allocator.free(module_path);

            const mapping = try @import("../ReadOnlyFileMapping.zig").open(module_path);
            defer mapping.deinit();

            var summary = try init(std.testing.allocator, mapping.contents);
            defer summary.deinit();
        }
    }
}
