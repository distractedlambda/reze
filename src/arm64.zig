const std = @import("std");
const wasm = @import("wasm.zig");

const ir = @import("arm64/ir.zig");

pub const ModuleCompiler = struct {
    allocator: std.mem.Allocator,

    types: std.ArrayListUnmanaged(wasm.FunctionType) = .{},
    imported_functions: std.ArrayListUnmanaged(ImportedFunction) = .{},
    imported_tables: std.ArrayListUnmanaged(ImportedTable) = .{},
    imported_memories: std.ArrayListUnmanaged(ImportedMemory) = .{},
    imported_globals: std.ArrayListUnmanaged(ImportedGlobal) = .{},
    defined_functions: std.ArrayListUnmanaged(DefinedFunction) = .{},
    defined_tables: std.ArrayListUnmanaged(DefinedTable) = .{},
    defined_memories: std.ArrayListUnmanaged(DefinedMemory) = .{},
    defined_globals: std.ArrayListUnmanaged(DefinedGlobal) = .{},
    exports: std.ArrayListUnmanaged(wasm.Export) = .{},
    start: ?wasm.FunctionIndex = null,
    data_count: ?u32 = null,
    store_size: usize = undefined,
    current_function: wasm.FunctionIndex = 0,

    node_arena: std.heap.ArenaAllocator,
    operand_stack: std.ArrayListUnmanaged(Operand) = .{},
    label_stack: std.ArrayListUnmanaged(Label) = .{},
    locals: std.ArrayListUnmanaged(Local) = .{},
    interned_instructions: InternedInstructions = .{},
    env_ptr: *ir.Instruction = undefined,
    current_block: *ir.Block = undefined,

    const InternedInstructions = std.HashMapUnmanaged(
        *ir.Instruction,
        void,
        InternedInstructionsContext,
        std.hash_map.default_max_load_percentage,
    );

    const InternedInstructionsContext = struct {
        pub fn hash(self: @This(), key: *ir.Instruction) u64 {
            _ = self;
            return key.dedupHash();
        }

        pub fn eql(self: @This(), a: *ir.Instruction, b: *ir.Instruction) bool {
            _ = self;
            return a.dedupEql(b);
        }
    };

    const AdaptedInternedInstructionsContext = struct {
        pub fn hash(self: @This(), key: *const ir.Instruction) u64 {
            _ = self;
            return key.dedupHash();
        }

        pub fn eql(self: @This(), a: *const ir.Instruction, b: *ir.Instruction) bool {
            _ = self;
            return a.dedupEql(b);
        }
    };

    fn internInstruction(self: *@This(), instruction: anytype) !*ir.Instruction {
        const result = try self.interned_instructions.getOrPutAdapted(
            self.allocator,
            &instruction.base,
            AdaptedInternedInstructionsContext{},
        );

        if (result.found_existing) {
            return result.key_ptr.*;
        } else {
            const new_instruction = try self.newNode(instruction);
            result.key_ptr.* = &new_instruction.base;
            return &new_instruction.base;
        }
    }

    fn genI32Const(self: *@This(), value: u32) !*ir.Instruction {
        return self.internInstruction(ir.I32Const{ .value = value });
    }

    fn genI64Const(self: *@This(), value: u64) !*ir.Instruction {
        return self.internInstruction(ir.I64Const{ .value = value });
    }

    fn genF32Const(self: *@This(), value: u32) !*ir.Instruction {
        return self.internInstruction(ir.F32Const{ .value = value });
    }

    fn genF64Const(self: *@This(), value: u64) !*ir.Instruction {
        return self.internInstruction(ir.F64Const{ .value = value });
    }

    fn genV128Const(self: *@This(), value: u128) !*ir.Instruction {
        return self.internInstruction(ir.V128Const{ .value = value });
    }

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{
            .allocator = allocator,
            .node_arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn reset(self: *@This()) void {
        self.types.clearRetainingCapacity();
        self.imported_functions.clearRetainingCapacity();
        self.imported_tables.clearRetainingCapacity();
        self.imported_memories.clearRetainingCapacity();
        self.imported_globals.clearRetainingCapacity();
        self.defined_functions.clearRetainingCapacity();
        self.defined_tables.clearRetainingCapacity();
        self.defined_memories.clearRetainingCapacity();
        self.defined_globals.clearRetainingCapacity();
        self.exports.clearRetainingCapacity();
        self.start = null;
        self.data_count = null;
        self.store_size = undefined;
        self.current_function = 0;
    }

    pub fn deinit(self: *@This()) void {
        self.types.deinit(self.allocator);
        self.imported_functions.deinit(self.allocator);
        self.imported_tables.deinit(self.allocator);
        self.imported_memories.deinit(self.allocator);
        self.imported_globals.deinit(self.allocator);
        self.defined_functions.deinit(self.allocator);
        self.defined_tables.deinit(self.allocator);
        self.defined_memories.deinit(self.allocator);
        self.defined_globals.deinit(self.allocator);
        self.exports.deinit(self.allocator);

        self.node_arena.deinit();
        self.operand_stack.deinit(self.allocator);
        self.label_stack.deinit(self.allocator);
        self.locals.deinit(self.allocator);
        self.interned_instructions.deinit(self.allocator);
    }

    pub fn nodeAllocator(self: *@This()) std.mem.Allocator {
        return self.node_arena.allocator();
    }

    pub fn newNode(self: *@This(), node: anytype) !*@TypeOf(node) {
        const memory = try self.nodeAllocator().create(@TypeOf(node));
        memory.* = node;
        return memory;
    }

    pub fn pushOperand(self: *@This(), value: *ir.Instruction, typ: wasm.ValueType) !void {
        try self.operand_stack.append(self.allocator, .{ .value = value, .type = typ });
    }

    pub fn popOperand(self: *@This()) !Operand {
        return self.operand_stack.popOrNull() orelse error.OperandStackUnderflow;
    }

    pub fn visitCustomSection(self: *@This(), name: []const u8, data: []const u8) !void {
        _ = self;
        _ = name;
        _ = data;
    }

    pub fn visitTypeSection(self: *@This(), len: usize) !*@This() {
        try self.types.ensureUnusedCapacity(self.allocator, len);
        return self;
    }

    pub fn visitType(self: *@This(), _: usize, typ: wasm.FunctionType) !void {
        self.types.appendAssumeCapacity(typ);
    }

    pub fn visitImportSection(self: *@This(), _: usize) !*@This() {
        return self;
    }

    pub fn visitImportedFunction(self: *@This(), func: wasm.ImportedFunction) !void {
        try self.imported_functions.append(self.allocator, .{ .wasm = func });
    }

    pub fn visitImportedTable(self: *@This(), table: wasm.ImportedTable) !void {
        try self.imported_tables.append(self.allocator, .{ .wasm = table });
    }

    pub fn visitImportedMemory(self: *@This(), memory: wasm.ImportedMemory) !void {
        try self.imported_memories.append(self.allocator, .{ .wasm = memory });
    }

    pub fn visitImportedGlobal(self: *@This(), global: wasm.ImportedGlobal) !void {
        try self.imported_globals.append(self.allocator, .{ .wasm = global });
    }

    pub fn visitFunctionSection(self: *@This(), len: usize) !*@This() {
        try self.defined_functions.ensureUnusedCapacity(self.allocator, len);
        return self;
    }

    pub fn visitFunction(self: *@This(), _: usize, typ: wasm.TypeIndex) !void {
        self.defined_functions.appendAssumeCapacity(.{ .type = typ });
    }

    pub fn visitTableSection(self: *@This(), len: usize) !*@This() {
        try self.defined_tables.ensureUnusedCapacity(self.allocator, len);
        return self;
    }

    pub fn visitTable(self: *@This(), _: usize, typ: wasm.TableType) !void {
        self.defined_tables.appendAssumeCapacity(.{ .type = typ });
    }

    pub fn visitMemorySection(self: *@This(), len: usize) !*@This() {
        try self.defined_memories.ensureUnusedCapacity(self.allocator, len);
        return self;
    }

    pub fn visitMemory(self: *@This(), _: usize, typ: wasm.MemoryType) !void {
        self.defined_memories.appendAssumeCapacity(.{ .type = typ });
    }

    pub fn visitGlobalSection(self: *@This(), len: usize) !*@This() {
        try self.defined_globals.ensureUnusedCapacity(self.allocator, len);
        return self;
    }

    pub fn visitGlobal(self: *@This(), _: usize, global: wasm.Global) !void {
        self.defined_globals.appendAssumeCapacity(.{ .wasm = global });
    }

    pub fn visitExportSection(self: *@This(), len: usize) !*@This() {
        try self.exports.ensureUnusedCapacity(self.allocator, len);
        return self;
    }

    pub fn visitExport(self: *@This(), _: usize, exp: wasm.Export) !void {
        self.exports.appendAssumeCapacity(exp);
    }

    pub fn visitStartSection(self: *@This(), start: wasm.FunctionIndex) !void {
        self.start = start;
    }

    fn alignOffset(offset: usize, comptime alignment: usize) !usize {
        const misalignment = offset % alignment;
        if (misalignment == 0) return offset;
        return std.math.add(usize, offset, alignment - misalignment);
    }

    pub fn visitBeforeFirstCodeSection(self: *@This()) !void {
        var offset: usize = 0;

        for (self.defined_memories.items) |*memory| {
            offset = try alignOffset(offset, @alignOf(Memory));
            memory.offset = offset;
            offset = try std.math.add(usize, offset, @sizeOf(Memory));
        }

        for (self.imported_memories.items) |*memory| {
            offset = try alignOffset(offset, @alignOf(*Memory));
            memory.ptr_offset = offset;
            offset = try std.math.add(usize, offset, @sizeOf(*Memory));
        }

        for (self.defined_tables.items) |*table| {
            offset = try alignOffset(offset, @alignOf(Table));
            table.offset = offset;
            offset = try std.math.add(usize, offset, @sizeOf(Table));
        }

        for (self.imported_tables.items) |*table| {
            offset = try alignOffset(offset, @alignOf(*Table));
            table.ptr_offset = offset;
            offset = try std.math.add(usize, offset, @sizeOf(*Table));
        }

        for (self.defined_globals.items) |*global| {
            if (global.wasm.type.mutability == .@"const" and global.wasm.initial_value != .global_get)
                // The global will be constant-folded, so don't bother allocating space for it
                continue;

            switch (global.wasm.type.value_type) {
                .i32, .f32, .funcref => {
                    offset = try alignOffset(offset, 4);
                    global.offset = offset;
                    offset = try std.math.add(usize, offset, 4);
                },

                .i64, .f64 => {
                    offset = try alignOffset(offset, 8);
                    global.offset = offset;
                    offset = try std.math.add(usize, offset, 8);
                },

                .v128 => {
                    offset = try alignOffset(offset, 16);
                    global.offset = offset;
                    offset = try std.math.add(usize, offset, 16);
                },

                .externref => @panic("TODO add externref support"),
            }
        }

        for (self.imported_globals.items) |*global| {
            offset = try alignOffset(offset, @alignOf(*anyopaque));
            global.ptr_offset = offset;
            offset = try std.math.add(usize, offset, @sizeOf(*anyopaque));
        }

        for (self.imported_functions.items) |*function| {
            offset = try alignOffset(offset, @alignOf(ImportedFunctionVTable));
            function.vtable_offset = offset;
            offset = try std.math.add(usize, offset, @sizeOf(ImportedFunctionVTable));
        }

        self.store_size = offset;
    }

    pub fn visitCodeSection(self: *@This(), _: usize) !*@This() {
        return self;
    }

    pub fn visitFunctionCode(self: *@This(), _: usize) !*@This() {
        if (self.current_function >= self.defined_functions.items.len)
            return error.UndeclaredFunction;

        _ = self.node_arena.reset(.retain_capacity);

        self.operand_stack.clearRetainingCapacity();
        self.label_stack.clearRetainingCapacity();
        self.locals.clearRetainingCapacity();
        self.interned_instructions.clearRetainingCapacity();

        self.env_ptr = try self.newNode(ir.Instruction.init(.env_ptr));
        self.current_block = try self.newNode(ir.Block{});

        return self;
    }

    pub fn visitLocals(self: *@This(), count: u32, typ: wasm.ValueType) !void {
        const fill = switch (typ) {
            .i32, .funcref => try self.genI32Const(0),
            .i64 => try self.genI64Const(0),
            .f32 => try self.genF32Const(0),
            .f64 => try self.genF64Const(0),
            .v128 => try self.genV128Const(0),
            .externref => @panic("TODO implement externref support"),
        };

        _ = count;
        _ = fill;
    }

    pub fn visitDataCountSection(self: *@This(), count: u32) !void {
        self.data_count = count;
    }

    pub fn visitSelect(self: *@This(), typ: ?wasm.ValueType) !void {
        _ = self;
        _ = typ;
        std.debug.panic("TODO implement select", .{});
    }

    pub fn visitI32Const(self: *@This(), value: i32) !void {
        try self.pushOperand(try self.genI32Const(@bitCast(u32, value)), .i32);
    }

    pub fn visitI64Const(self: *@This(), value: i64) !void {
        try self.pushOperand(try self.genI64Const(@bitCast(u64, value)), .i64);
    }

    pub fn visitF32Const(self: *@This(), value: f32) !void {
        try self.pushOperand(try self.genF32Const(@bitCast(u32, value)), .f32);
    }

    pub fn visitF64Const(self: *@This(), value: f64) !void {
        try self.pushOperand(try self.genF64Const(@bitCast(u64, value)), .f64);
    }

    pub fn visitSimpleInstruction(self: *@This(), opcode: wasm.SimpleInstruction) !void {
        switch (opcode) {
            .@"unreachable" => {
                // self.current_block.append(&(try self.newNode(ir.Udf{ .immediate = 0 })).base);
            },

            .nop => {},

            .drop => {
                _ = try self.popOperand();
            },

            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitBlockTypeInstruction(self: *@This(), opcode: wasm.BlockTypeInstruction, block_type: wasm.BlockType) !void {
        _ = self;
        _ = block_type;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitIndexInstruction(self: *@This(), opcode: wasm.IndexInstruction, index: u32) !void {
        _ = self;
        _ = index;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitMemoryInstruction(self: *@This(), opcode: wasm.MemoryInstruction, mem_arg: wasm.MemoryArgument) !void {
        _ = self;
        _ = mem_arg;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitExtendedInstruction(self: *@This(), opcode: wasm.ExtendedInstruction) !void {
        _ = self;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitExtendedIndexInstruction(self: *@This(), opcode: wasm.ExtendedIndexInstruction, index: u32) !void {
        _ = self;
        _ = index;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitExtendedDualIndexInstruction(self: *@This(), opcode: wasm.ExtendedDualIndexInstruction, index_a: u32, index_b: u32) !void {
        _ = self;
        _ = index_a;
        _ = index_b;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitVectorInstruction(self: *@This(), opcode: wasm.VectorInstruction) !void {
        _ = self;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitVectorMemoryInstruction(self: *@This(), opcode: wasm.VectorMemoryInstruction, mem_arg: wasm.MemoryArgument) !void {
        _ = self;
        _ = mem_arg;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitVectorLaneInstruction(self: *@This(), opcode: wasm.VectorLaneInstruction, lane_idx: wasm.LaneIndex) !void {
        _ = self;
        _ = lane_idx;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }

    pub fn visitVectorMemoryLaneInstruction(self: *@This(), opcode: wasm.VectorMemoryLaneInstruction, mem_arg: wasm.MemoryArgument, lane_idx: wasm.LaneIndex) !void {
        _ = self;
        _ = mem_arg;
        _ = lane_idx;
        switch (opcode) {
            else => std.debug.panic("TODO implement {}", .{opcode}),
        }
    }
};

const ImportedFunction = struct {
    wasm: wasm.ImportedFunction,
    vtable_offset: usize = undefined,
};

const DefinedFunction = struct {
    type: wasm.TypeIndex,
};

const ImportedTable = struct {
    wasm: wasm.ImportedTable,
    ptr_offset: usize = undefined,
};

const DefinedTable = struct {
    type: wasm.TableType,
    offset: usize = undefined,
};

const ImportedMemory = struct {
    wasm: wasm.ImportedMemory,
    ptr_offset: usize = undefined,
};

const DefinedMemory = struct {
    type: wasm.MemoryType,
    offset: usize = undefined,
};

const ImportedGlobal = struct {
    wasm: wasm.ImportedGlobal,
    ptr_offset: usize = undefined,
};

const DefinedGlobal = struct {
    wasm: wasm.Global,
    offset: usize = undefined,
};

const ImportedFunctionVTable = extern struct {
    context: *anyopaque,
    impl: *fn (context: *anyopaque, in: *const anyopaque, out: *anyopaque) callconv(.C) void,
};

const Table = extern struct {
    contents: ?[*]u32,
    size: u32,
};

const Memory = extern struct {
    base: usize,
    size: u32,
};

const Operand = struct {
    value: *ir.Instruction,
    type: wasm.ValueType,
};

const Label = struct {
    block: *ir.Block,
};

const Local = struct {
    value: *ir.Instruction,
    type: wasm.ValueType,
};

pub fn compile(module_data: []const u8, allocator: std.mem.Allocator) !void {
    var compiler = ModuleCompiler.init(allocator);
    try wasm.visitModule(module_data, &compiler);
}

test "ref all" {
    std.testing.refAllDeclsRecursive(@This());
}
