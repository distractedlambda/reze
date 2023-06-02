const opcodes = @import("opcodes.zig");
const std = @import("std");
const wasm = @import("../wasm.zig");

const Decoder = @import("Decoder.zig");
const ModuleSummary = @import("ModuleSummary.zig");

pub fn CodeProcessor(comptime Backend: type) type {
    return struct {
        summary: *const ModuleSummary,
        allocator: std.mem.Allocator,
        locals: std.ArrayListUnmanaged(Local) = .{},
        operand_stack: std.ArrayListUnmanaged(Operand) = .{},
        label_stack: std.ArrayListUnmanaged(Label) = .{},

        const Operand = struct {
            type: wasm.ValType,
            backend: BackendOperand,
        };

        const Local = struct {
            type: wasm.ValType,
            backend: BackendLocal,
        };

        const Label = struct {
            type: wasm.FuncType,
            min_operand_stack_depth: usize,
            target: Target,

            const Target = union(enum) {
                block: BackendLabel,
                loop: BackendLabel,
                @"if": If,
                @"else": BackendLabel,

                const If = struct {
                    @"else": BackendLabel,
                    end: BackendLabel,
                };
            };
        };

        const BackendOperand = getBackendType("Operand");
        const BackendLocal = getBackendType("Local");
        const BackendLabel = getBackendType("Label");
        const BackendLocalVisitor = getBackendVisitorType("visitLocals");
        const BackendInstrVisitor = getBackendVisitorType("visitInstrs");

        fn getBackendType(comptime name: []const u8) type {
            return if (@hasDecl(Backend, name))
                @field(Backend, name)
            else
                void;
        }

        fn getBackendVisitorType(comptime name: []const u8) type {
            return @typeInfo(@typeInfo(@TypeOf(@field(Backend, name))).Fn.return_type.?).ErrorUnion.payload;
        }

        pub fn init(module_summary: *const ModuleSummary, allocator: std.mem.Allocator) @This() {
            return .{ .summary = module_summary, .allocator = allocator };
        }

        pub fn reset(self: *@This()) void {
            self.locals.clearRetainingCapacity();
            self.operand_stack.clearRetainingCapacity();
            self.label_stack.clearRetainingCapacity();
        }

        pub fn deinit(self: *@This()) void {
            self.locals.deinit(self.allocator);
            self.operand_stack.deinit(self.allocator);
            self.label_stack.deinit(self.allocator);
        }

        pub fn process(self: *@This(), backend: *Backend, func: wasm.FuncIdx, code: []const u8) !void {
            var decoder = Decoder.init(code);

            try self.visitLocals(backend, func, &decoder);

            var instr_visitor = try backend.visitInstrs();
            defer instr_visitor.deinit();
            try self.visitInstrs(&instr_visitor, &decoder);
            try instr_visitor.finish();
        }

        fn visitLocals(self: *@This(), backend: *Backend, func: wasm.FuncIdx, decoder: *Decoder) !void {
            var visitor = try backend.visitLocals();
            defer visitor.deinit();

            // Visit local variables for function parameters
            const func_type = self.summary.lookUpType(func);
            try self.locals.ensureUnusedCapacity(self.allocator, func_type.parameters.len);
            for (func_type.parameters) |t| try self.visitLocal(&visitor, func, t);

            // Visit other local variables
            for (0..try decoder.nextInt(u32)) |_| {
                const n_locals = try decoder.nextInt(u32);
                const local_type = try decoder.nextValType();
                try self.locals.ensureUnusedCapacity(self.allocator, n_locals);
                for (0..n_locals) |_| try self.visitLocal(&visitor, func, local_type);
            }

            try visitor.finish();
        }

        fn visitLocal(self: *@This(), visitor: *BackendLocalVisitor, func: wasm.FuncIdx, typ: wasm.ValType) !void {
            const idx = wasm.LocalIdx{
                .value = std.math.cast(u32, self.locals.items.len) orelse
                    return error.TooManyLocals,
            };

            const name = self.summary.local_names.get(.{ func, idx });

            self.locals.appendAssumeCapacity(.{
                .type = typ,
                .backend = try visitor.visitLocal(typ, name),
            });
        }

        fn visitInstrs(self: *@This(), visitor: *BackendInstrVisitor, decoder: *Decoder) !void {
            while (true) switch (try decoder.nextByte()) {
                opcodes.@"unreachable" => {
                    try visitor.visitUnreachable();
                    if (try self.skipUnreachable(visitor, decoder)) return;
                },

                opcodes.nop => {},

                opcodes.block => {
                    const ty = try self.nextBlockType(decoder);
                    const min_depth = try self.checkEntryTypes(ty.parameters);
                    try self.label_stack.append(self.allocator, .{
                        .type = ty,
                        .min_operand_stack_depth = min_depth,
                        .target = .{ .block = try visitor.declareForwardLabel(ty.results) },
                    });
                },

                opcodes.loop => {
                    const ty = try self.nextBlockType(decoder);
                    const min_depth = try self.checkEntryTypes(ty.parameters);
                    try self.label_stack.append(self.allocator, .{
                        .type = ty,
                        .min_operand_stack_depth = min_depth,
                        .target = .{ .loop = blk: {
                            const label_visitor = try visitor.visitBackwardLabel(ty.results);
                            defer label_visitor.deinit();

                            for (self.operand_stack.items[min_depth..]) |*o|
                                o.backend = try label_visitor.visitArg(o.backend);

                            break :blk try label_visitor.finish();
                        } },
                    });
                },

                opcodes.@"if" => {
                    const ty = try self.nextBlockType(decoder);
                    const condition = try self.popOperand(.i32);
                    const min_depth = try self.checkEntryTypes(ty.parameters);
                    const else_target = try visitor.declareForwardLabel(ty.parameters);
                    const end_target = try visitor.declareForwardLabel(ty.results);

                    const inv_condition = try visitor.visitI32Xor(
                        condition,
                        try visitor.visitI32Const(@as(i32, -1)),
                    );

                    try self.label_stack.append(self.allocator, .{
                        .type = ty,
                        .min_operand_stack_depth = min_depth,
                        .target = .{ .@"if" = .{ .@"else" = else_target, .end = end_target } },
                    });

                    var else_arg_visitor = try visitor.visitBrIf(else_target, inv_condition);
                    defer else_arg_visitor.deinit();

                    for (self.operand_stack.items[min_depth..]) |o|
                        try else_arg_visitor.visitArg(o.backend);

                    try else_arg_visitor.finish();
                },

                opcodes.@"else" => {
                    const l = self.label_stack.popOrNull() orelse
                        return error.UnbalancedElse;

                    try self.checkExitTypes(l);

                    switch (l.target) {
                        .@"if" => |target| {
                            var label_visitor = try visitor.visitForwardLabel(target.@"else");
                            // TODO branch to else
                            // TODO branch to end
                        },

                        else => return error.UnbalancedElse,
                    }

                    self.operand_stack.shrinkRetainingCapacity(l.min_operand_stack_depth);
                },

                else => return error.UnsupportedOpcode,
            };
        }

        fn visitElse(self: *@This(), visitor: *BackendInstrVisitor) !void {
            const l = self.label_stack.pop();
            switch (l.backend) {
                .@"if" => |if_backend| self.label_stack.appendAssumeCapacity(.{
                    .type = l.type,
                    .min_operand_stack_depth = l.min_operand_stack_depth,
                    .backend = .{ .@"else" = blk: {
                        const results = self.operand_stack.items[l.min_operand_stack_depth..];

                        if (results.len != l.type.results)
                            return error.BadOperandStack;

                        const results_buffer = try self.scratchAlloc(BackendOperand, results.len);
                        for (results, l.type.results) |res, i| {}

                        errdefer self.allocator.free(results);
                    } },
                }),

                else => return error.UnbalancedElse,
            }
        }

        fn visitEndBlock(
            self: *@This(),
            visitor: *BackendInstrVisitor,
            backend_block: BackendBlock,
        ) !void {
            // TODO
        }

        fn visitEndLoop(
            self: *@This(),
            visitor: *BackendInstrVisitor,
            backend_loop: BackendLoop,
        ) !void {
            // TODO
        }

        fn visitEndIf(
            self: *@This(),
            visitor: *BackendInstrVisitor,
            backend_if: BackendIf,
        ) !void {
            // TODO
        }

        fn visitEndElse(
            self: *@This(),
            visitor: *BackendInstrVisitor,
            backend_else: BackendElse,
        ) !void {
            // TODO
        }

        // returns true if unreachability extends through the rest of the
        // function body, false otherwise
        fn skipUnreachable(self: *@This(), visitor: *BackendInstrVisitor, decoder: *Decoder) !bool {
            if (self.label_stack.items.len == 0)
                // The rest of the function is unreachable, so bail out
                return true;

            var additional_label_depth: usize = 0;

            while (true) switch (try decoder.nextByte()) {
                opcodes.block,
                opcodes.loop,
                opcodes.@"if",
                => {
                    _ = try self.nextBlockType(decoder);
                    additional_label_depth = try std.math.add(usize, additional_label_depth, 1);
                },

                opcodes.@"else" => if (additional_label_depth == 0) {
                    try self.visitElse(visitor);
                    return false;
                },

                opcodes.end => if (additional_label_depth == 0) {
                    const l = self.label_stack.pop();
                    switch (l.backend) {
                        .block => |b| {
                            try self.visitEndBlock(visitor, b);
                            return false;
                        },

                        // Unreachability continues after the end of a loop
                        // construct, so we should keep skipping code (unless
                        // we've popped off the last label, in which case we
                        // need to bail out of the whole function).  We could
                        // extend this logic by also tracking whether a block or
                        // if-else is targeted by a reachable branch
                        // instruction...
                        .loop => |_| if (self.label_stack.items.len == 0)
                            // The rest of the function is unreachable, so
                            // bail out
                            return true,

                        .@"if" => |b| {
                            try self.visitEndIf(visitor, b);
                            return false;
                        },

                        .@"else" => |b| {
                            try self.visitEndElse(visitor, b);
                            return false;
                        },
                    }
                } else {
                    additional_label_depth -= 1;
                },

                opcodes.br_table => {
                    for (0..try decoder.nextInt(u32)) |_| _ = try decoder.nextInt(u32);
                    _ = try decoder.nextInt(u32);
                },

                opcodes.@"ref.null" => {
                    // Using nextRefType() instead of nextByte() to avoid
                    // sudden breakage should multi-byte reference types be
                    // introduced
                    _ = try decoder.nextRefType();
                },

                opcodes.@"select t" => {
                    // Using nextValType() instead of nextByte() to avoid
                    // sudden breakage should multi-byte value types be
                    // introduced
                    for (0..try decoder.nextInt(u32)) |_| _ = try decoder.nextValType();
                },

                opcodes.@"i32.const" => {
                    _ = try decoder.nextInt(i32);
                },

                opcodes.@"i64.const" => {
                    _ = try decoder.nextInt(i64);
                },

                opcodes.@"f32.const" => {
                    _ = try decoder.nextBytes(4);
                },

                opcodes.@"f64.const" => {
                    _ = try decoder.nextBytes(8);
                },

                // No immediates
                opcodes.@"unreachable",
                opcodes.nop,
                opcodes.@"return",
                opcodes.@"ref.is_null",
                opcodes.drop,
                opcodes.select,
                opcodes.@"i32.eqz",
                opcodes.@"i32.eq",
                opcodes.@"i32.ne",
                opcodes.@"i32.lt_s",
                opcodes.@"i32.lt_u",
                opcodes.@"i32.gt_s",
                opcodes.@"i32.gt_u",
                opcodes.@"i32.le_s",
                opcodes.@"i32.le_u",
                opcodes.@"i32.ge_s",
                opcodes.@"i32.ge_u",
                opcodes.@"i64.eqz",
                opcodes.@"i64.eq",
                opcodes.@"i64.ne",
                opcodes.@"i64.lt_s",
                opcodes.@"i64.lt_u",
                opcodes.@"i64.gt_s",
                opcodes.@"i64.gt_u",
                opcodes.@"i64.le_s",
                opcodes.@"i64.le_u",
                opcodes.@"i64.ge_s",
                opcodes.@"i64.ge_u",
                opcodes.@"f32.eq",
                opcodes.@"f32.ne",
                opcodes.@"f32.lt",
                opcodes.@"f32.gt",
                opcodes.@"f32.le",
                opcodes.@"f32.ge",
                opcodes.@"f64.eq",
                opcodes.@"f64.ne",
                opcodes.@"f64.lt",
                opcodes.@"f64.gt",
                opcodes.@"f64.le",
                opcodes.@"f64.ge",
                opcodes.@"i32.clz",
                opcodes.@"i32.ctz",
                opcodes.@"i32.popcnt",
                opcodes.@"i32.add",
                opcodes.@"i32.sub",
                opcodes.@"i32.mul",
                opcodes.@"i32.div_s",
                opcodes.@"i32.div_u",
                opcodes.@"i32.rem_s",
                opcodes.@"i32.rem_u",
                opcodes.@"i32.and",
                opcodes.@"i32.or",
                opcodes.@"i32.xor",
                opcodes.@"i32.shl",
                opcodes.@"i32.shr_s",
                opcodes.@"i32.shr_u",
                opcodes.@"i32.rotl",
                opcodes.@"i32.rotr",
                opcodes.@"i64.clz",
                opcodes.@"i64.ctz",
                opcodes.@"i64.popcnt",
                opcodes.@"i64.add",
                opcodes.@"i64.sub",
                opcodes.@"i64.mul",
                opcodes.@"i64.div_s",
                opcodes.@"i64.div_u",
                opcodes.@"i64.rem_s",
                opcodes.@"i64.rem_u",
                opcodes.@"i64.and",
                opcodes.@"i64.or",
                opcodes.@"i64.xor",
                opcodes.@"i64.shl",
                opcodes.@"i64.shr_s",
                opcodes.@"i64.shr_u",
                opcodes.@"i64.rotl",
                opcodes.@"i64.rotr",
                opcodes.@"f32.abs",
                opcodes.@"f32.neg",
                opcodes.@"f32.ceil",
                opcodes.@"f32.floor",
                opcodes.@"f32.trunc",
                opcodes.@"f32.nearest",
                opcodes.@"f32.sqrt",
                opcodes.@"f32.add",
                opcodes.@"f32.sub",
                opcodes.@"f32.mul",
                opcodes.@"f32.div",
                opcodes.@"f32.min",
                opcodes.@"f32.max",
                opcodes.@"f32.copysign",
                opcodes.@"f64.abs",
                opcodes.@"f64.neg",
                opcodes.@"f64.ceil",
                opcodes.@"f64.floor",
                opcodes.@"f64.trunc",
                opcodes.@"f64.nearest",
                opcodes.@"f64.sqrt",
                opcodes.@"f64.add",
                opcodes.@"f64.sub",
                opcodes.@"f64.mul",
                opcodes.@"f64.div",
                opcodes.@"f64.min",
                opcodes.@"f64.max",
                opcodes.@"f64.copysign",
                opcodes.@"i32.wrap_i64",
                opcodes.@"i32.trunc_f32_s",
                opcodes.@"i32.trunc_f32_u",
                opcodes.@"i32.trunc_f64_s",
                opcodes.@"i32.trunc_f64_u",
                opcodes.@"i64.extend_i32_s",
                opcodes.@"i64.extend_i32_u",
                opcodes.@"i64.trunc_f32_s",
                opcodes.@"i64.trunc_f32_u",
                opcodes.@"i64.trunc_f64_s",
                opcodes.@"i64.trunc_f64_u",
                opcodes.@"f32.convert_i32_s",
                opcodes.@"f32.convert_i32_u",
                opcodes.@"f32.convert_i64_s",
                opcodes.@"f32.convert_i64_u",
                opcodes.@"f32.demote_f64",
                opcodes.@"f64.convert_i32_s",
                opcodes.@"f64.convert_i32_u",
                opcodes.@"f64.convert_i64_s",
                opcodes.@"f64.convert_i64_u",
                opcodes.@"f64.promote_f32",
                opcodes.@"i32.reinterpret_f32",
                opcodes.@"i64.reinterpret_f64",
                opcodes.@"f32.reinterpret_i32",
                opcodes.@"f64.reinterpret_i64",
                opcodes.@"i32.extend8_s",
                opcodes.@"i32.extend16_s",
                opcodes.@"i64.extend8_s",
                opcodes.@"i64.extend16_s",
                opcodes.@"i64.extend32_s",
                => {},

                // 1 u32 immediate
                opcodes.br,
                opcodes.br_if,
                opcodes.call,
                opcodes.@"ref.func",
                opcodes.@"local.get",
                opcodes.@"local.set",
                opcodes.@"local.tee",
                opcodes.@"global.get",
                opcodes.@"global.set",
                opcodes.@"table.get",
                opcodes.@"table.set",
                opcodes.@"memory.size",
                opcodes.@"memory.grow",
                => {
                    _ = try decoder.nextInt(u32);
                },

                // 2 u32 immediates
                opcodes.call_indirect,
                opcodes.@"i32.load",
                opcodes.@"i64.load",
                opcodes.@"f32.load",
                opcodes.@"f64.load",
                opcodes.@"i32.load8_s",
                opcodes.@"i32.load8_u",
                opcodes.@"i32.load16_s",
                opcodes.@"i32.load16_u",
                opcodes.@"i64.load8_s",
                opcodes.@"i64.load8_u",
                opcodes.@"i64.load16_s",
                opcodes.@"i64.load16_u",
                opcodes.@"i64.load32_s",
                opcodes.@"i64.load32_u",
                opcodes.@"i32.store",
                opcodes.@"i64.store",
                opcodes.@"f32.store",
                opcodes.@"f64.store",
                opcodes.@"i32.store8",
                opcodes.@"i32.store16",
                opcodes.@"i64.store8",
                opcodes.@"i64.store16",
                opcodes.@"i64.store32",
                => {
                    _ = try decoder.nextInt(u32);
                    _ = try decoder.nextInt(u32);
                },

                opcodes.general_prefix => switch (try decoder.nextInt(u32)) {
                    // No immediates
                    opcodes.@"i32.trunc_sat_f32_s",
                    opcodes.@"i32.trunc_sat_f32_u",
                    opcodes.@"i32.trunc_sat_f64_s",
                    opcodes.@"i32.trunc_sat_f64_u",
                    opcodes.@"i64.trunc_sat_f32_s",
                    opcodes.@"i64.trunc_sat_f32_u",
                    opcodes.@"i64.trunc_sat_f64_s",
                    opcodes.@"i64.trunc_sat_f64_u",
                    => {},

                    // 1 u32 immediate
                    opcodes.@"data.drop",
                    opcodes.@"memory.fill",
                    opcodes.@"elem.drop",
                    opcodes.@"table.grow",
                    opcodes.@"table.size",
                    opcodes.@"table.fill",
                    => {
                        _ = try decoder.nextInt(u32);
                    },

                    // 2 u32 immediates
                    opcodes.@"memory.init",
                    opcodes.@"memory.copy",
                    opcodes.@"table.init",
                    opcodes.@"table.copy",
                    => {
                        _ = try decoder.nextInt(u32);
                        _ = try decoder.nextInt(u32);
                    },

                    else => return error.UnsupportedOpcode,
                },

                opcodes.simd_prefix => switch (try decoder.nextInt(u32)) {
                    // No immediates
                    opcodes.@"i8x16.swizzle",
                    opcodes.@"i8x16.splat",
                    opcodes.@"i16x8.splat",
                    opcodes.@"i32x4.splat",
                    opcodes.@"i64x2.splat",
                    opcodes.@"f32x4.splat",
                    opcodes.@"f64x2.splat",
                    opcodes.@"i8x16.eq",
                    opcodes.@"i8x16.ne",
                    opcodes.@"i8x16.lt_s",
                    opcodes.@"i8x16.lt_u",
                    opcodes.@"i8x16.gt_s",
                    opcodes.@"i8x16.gt_u",
                    opcodes.@"i8x16.le_s",
                    opcodes.@"i8x16.le_u",
                    opcodes.@"i8x16.ge_s",
                    opcodes.@"i8x16.ge_u",
                    opcodes.@"i16x8.eq",
                    opcodes.@"i16x8.ne",
                    opcodes.@"i16x8.lt_s",
                    opcodes.@"i16x8.lt_u",
                    opcodes.@"i16x8.gt_s",
                    opcodes.@"i16x8.gt_u",
                    opcodes.@"i16x8.le_s",
                    opcodes.@"i16x8.le_u",
                    opcodes.@"i16x8.ge_s",
                    opcodes.@"i16x8.ge_u",
                    opcodes.@"i32x4.eq",
                    opcodes.@"i32x4.ne",
                    opcodes.@"i32x4.lt_s",
                    opcodes.@"i32x4.lt_u",
                    opcodes.@"i32x4.gt_s",
                    opcodes.@"i32x4.gt_u",
                    opcodes.@"i32x4.le_s",
                    opcodes.@"i32x4.le_u",
                    opcodes.@"i32x4.ge_s",
                    opcodes.@"i32x4.ge_u",
                    opcodes.@"f32x4.eq",
                    opcodes.@"f32x4.ne",
                    opcodes.@"f32x4.lt",
                    opcodes.@"f32x4.gt",
                    opcodes.@"f32x4.le",
                    opcodes.@"f32x4.ge",
                    opcodes.@"f64x2.eq",
                    opcodes.@"f64x2.ne",
                    opcodes.@"f64x2.lt",
                    opcodes.@"f64x2.gt",
                    opcodes.@"f64x2.le",
                    opcodes.@"f64x2.ge",
                    opcodes.@"v128.not",
                    opcodes.@"v128.and",
                    opcodes.@"v128.andnot",
                    opcodes.@"v128.or",
                    opcodes.@"v128.xor",
                    opcodes.@"v128.bitselect",
                    opcodes.@"v128.any_true",
                    opcodes.@"v128.load8_lane",
                    opcodes.@"v128.load16_lane",
                    opcodes.@"v128.load32_lane",
                    opcodes.@"v128.load64_lane",
                    opcodes.@"v128.store8_lane",
                    opcodes.@"v128.store16_lane",
                    opcodes.@"v128.store32_lane",
                    opcodes.@"v128.store64_lane",
                    opcodes.@"v128.load32_zero",
                    opcodes.@"v128.load64_zero",
                    opcodes.@"f32x4.demote_f64x2_zero",
                    opcodes.@"f64x2.promote_low_f32x4",
                    opcodes.@"i8x16.abs",
                    opcodes.@"i8x16.neg",
                    opcodes.@"i8x16.popcnt",
                    opcodes.@"i8x16.all_true",
                    opcodes.@"i8x16.bitmask",
                    opcodes.@"i8x16.narrow_i16x8_s",
                    opcodes.@"i8x16.narrow_i16x8_u",
                    opcodes.@"i8x16.shl",
                    opcodes.@"i8x16.shr_s",
                    opcodes.@"i8x16.shr_u",
                    opcodes.@"i8x16.add",
                    opcodes.@"i8x16.add_sat_s",
                    opcodes.@"i8x16.add_sat_u",
                    opcodes.@"i8x16.sub",
                    opcodes.@"i8x16.sub_sat_s",
                    opcodes.@"i8x16.sub_sat_u",
                    opcodes.@"i8x16.min_s",
                    opcodes.@"i8x16.min_u",
                    opcodes.@"i8x16.max_s",
                    opcodes.@"i8x16.max_u",
                    opcodes.@"i8x16.avgr_u",
                    opcodes.@"i16x8.extadd_pairwise_i8x16_s",
                    opcodes.@"i16x8.extadd_pairwise_i8x16_u",
                    opcodes.@"i32x4.extadd_pairwise_i16x8_s",
                    opcodes.@"i32x4.extadd_pairwise_i16x8_u",
                    opcodes.@"i16x8.abs",
                    opcodes.@"i16x8.neg",
                    opcodes.@"i16x8.q15mulr_sat_s",
                    opcodes.@"i16x8.all_true",
                    opcodes.@"i16x8.bitmask",
                    opcodes.@"i16x8.narrow_i32x4_s",
                    opcodes.@"i16x8.narrow_i32x4_u",
                    opcodes.@"i16x8.extend_low_i8x16_s",
                    opcodes.@"i16x8.extend_high_i8x16_s",
                    opcodes.@"i16x8.extend_low_i8x16_u",
                    opcodes.@"i16x8.extend_high_i8x16_u",
                    opcodes.@"i16x8.shl",
                    opcodes.@"i16x8.shr_s",
                    opcodes.@"i16x8.shr_u",
                    opcodes.@"i16x8.add",
                    opcodes.@"i16x8.add_sat_s",
                    opcodes.@"i16x8.add_sat_u",
                    opcodes.@"i16x8.sub",
                    opcodes.@"i16x8.sub_sat_s",
                    opcodes.@"i16x8.sub_sat_u",
                    opcodes.@"i16x8.mul",
                    opcodes.@"i16x8.min_s",
                    opcodes.@"i16x8.min_u",
                    opcodes.@"i16x8.max_s",
                    opcodes.@"i16x8.max_u",
                    opcodes.@"i16x8.avgr_u",
                    opcodes.@"i16x8.extmul_low_i8x16_s",
                    opcodes.@"i16x8.extmul_high_i8x16_s",
                    opcodes.@"i16x8.extmul_low_i8x16_u",
                    opcodes.@"i16x8.extmul_high_i8x16_u",
                    opcodes.@"i32x4.abs",
                    opcodes.@"i32x4.neg",
                    opcodes.@"i32x4.all_true",
                    opcodes.@"i32x4.bitmask",
                    opcodes.@"i32x4.extend_low_i16x8_s",
                    opcodes.@"i32x4.extend_high_i16x8_s",
                    opcodes.@"i32x4.extend_low_i16x8_u",
                    opcodes.@"i32x4.extend_high_i16x8_u",
                    opcodes.@"i32x4.shl",
                    opcodes.@"i32x4.shr_s",
                    opcodes.@"i32x4.shr_u",
                    opcodes.@"i32x4.add",
                    opcodes.@"i32x4.sub",
                    opcodes.@"i32x4.mul",
                    opcodes.@"i32x4.min_s",
                    opcodes.@"i32x4.min_u",
                    opcodes.@"i32x4.max_s",
                    opcodes.@"i32x4.max_u",
                    opcodes.@"i32x4.dot_i16x8_s",
                    opcodes.@"i32x4.extmul_low_i16x8_s",
                    opcodes.@"i32x4.extmul_high_i16x8_s",
                    opcodes.@"i32x4.extmul_low_i16x8_u",
                    opcodes.@"i32x4.extmul_high_i16x8_u",
                    opcodes.@"i64x2.abs",
                    opcodes.@"i64x2.neg",
                    opcodes.@"i64x2.all_true",
                    opcodes.@"i64x2.bitmask",
                    opcodes.@"i64x2.extend_low_i32x4_s",
                    opcodes.@"i64x2.extend_high_i32x4_s",
                    opcodes.@"i64x2.extend_low_i32x4_u",
                    opcodes.@"i64x2.extend_high_i32x4_u",
                    opcodes.@"i64x2.shl",
                    opcodes.@"i64x2.shr_s",
                    opcodes.@"i64x2.shr_u",
                    opcodes.@"i64x2.add",
                    opcodes.@"i64x2.sub",
                    opcodes.@"i64x2.mul",
                    opcodes.@"i64x2.eq",
                    opcodes.@"i64x2.ne",
                    opcodes.@"i64x2.lt_s",
                    opcodes.@"i64x2.gt_s",
                    opcodes.@"i64x2.le_s",
                    opcodes.@"i64x2.ge_s",
                    opcodes.@"i64x2.extmul_low_i32x4_s",
                    opcodes.@"i64x2.extmul_high_i32x4_s",
                    opcodes.@"i64x2.extmul_low_i32x4_u",
                    opcodes.@"i64x2.extmul_high_i32x4_u",
                    opcodes.@"f32x4.ceil",
                    opcodes.@"f32x4.floor",
                    opcodes.@"f32x4.trunc",
                    opcodes.@"f32x4.nearest",
                    opcodes.@"f64x2.ceil",
                    opcodes.@"f64x2.floor",
                    opcodes.@"f64x2.trunc",
                    opcodes.@"f64x2.nearest",
                    opcodes.@"f32x4.abs",
                    opcodes.@"f32x4.neg",
                    opcodes.@"f32x4.sqrt",
                    opcodes.@"f32x4.add",
                    opcodes.@"f32x4.sub",
                    opcodes.@"f32x4.mul",
                    opcodes.@"f32x4.div",
                    opcodes.@"f32x4.min",
                    opcodes.@"f32x4.max",
                    opcodes.@"f32x4.pmin",
                    opcodes.@"f32x4.pmax",
                    opcodes.@"f64x2.abs",
                    opcodes.@"f64x2.neg",
                    opcodes.@"f64x2.sqrt",
                    opcodes.@"f64x2.add",
                    opcodes.@"f64x2.sub",
                    opcodes.@"f64x2.mul",
                    opcodes.@"f64x2.div",
                    opcodes.@"f64x2.min",
                    opcodes.@"f64x2.max",
                    opcodes.@"f64x2.pmin",
                    opcodes.@"f64x2.pmax",
                    opcodes.@"i32x4.trunc_sat_f32x4_s",
                    opcodes.@"i32x4.trunc_sat_f32x4_u",
                    opcodes.@"f32x4.convert_i32x4_s",
                    opcodes.@"f32x4.convert_i32x4_u",
                    opcodes.@"i32x4.trunc_sat_f64x2_s_zero",
                    opcodes.@"i32x4.trunc_sat_f64x2_u_zero",
                    opcodes.@"f64x2.convert_low_i32x4_s",
                    opcodes.@"f64x2.convert_low_i32x4_u",
                    => {},

                    // 1-byte immediate
                    opcodes.@"i8x16.extract_lane_s",
                    opcodes.@"i8x16.extract_lane_u",
                    opcodes.@"i8x16.replace_lane",
                    opcodes.@"i16x8.extract_lane_s",
                    opcodes.@"i16x8.extract_lane_u",
                    opcodes.@"i16x8.replace_lane",
                    opcodes.@"i32x4.extract_lane",
                    opcodes.@"i32x4.replace_lane",
                    opcodes.@"i64x2.extract_lane",
                    opcodes.@"i64x2.replace_lane",
                    opcodes.@"f32x4.extract_lane",
                    opcodes.@"f32x4.replace_lane",
                    opcodes.@"f64x2.extract_lane",
                    opcodes.@"f64x2.replace_lane",
                    => {
                        _ = try decoder.nextByte();
                    },

                    // 16-byte immediate
                    opcodes.@"v128.const",
                    opcodes.@"i8x16.shuffle",
                    => {
                        _ = try decoder.nextBytes(16);
                    },

                    // 2 u32 immediates
                    opcodes.@"v128.load",
                    opcodes.@"v128.load8x8_s",
                    opcodes.@"v128.load8x8_u",
                    opcodes.@"v128.load16x4_s",
                    opcodes.@"v128.load16x4_u",
                    opcodes.@"v128.load32x2_s",
                    opcodes.@"v128.load32x2_u",
                    opcodes.@"v128.load8_splat",
                    opcodes.@"v128.load16_splat",
                    opcodes.@"v128.load32_splat",
                    opcodes.@"v128.load64_splat",
                    opcodes.@"v128.store",
                    opcodes.@"v128.load32_zero",
                    opcodes.@"v128.load64_zero",
                    => {
                        _ = try decoder.nextInt(u32);
                        _ = try decoder.nextInt(u32);
                    },

                    // 2 u32 immediates followed by a 1-byte immediate
                    opcodes.@"v128.load8_lane",
                    opcodes.@"v128.load16_lane",
                    opcodes.@"v128.load32_lane",
                    opcodes.@"v128.load64_lane",
                    opcodes.@"v128.store8_lane",
                    opcodes.@"v128.store16_lane",
                    opcodes.@"v128.store32_lane",
                    opcodes.@"v128.store64_lane",
                    => {
                        _ = try decoder.nextInt(u32);
                        _ = try decoder.nextInt(u32);
                        _ = try decoder.nextByte();
                    },

                    else => return error.UnsupportedOpcode,
                },

                else => return error.UnsupportedOpcode,
            };
        }

        fn nextBlockType(self: *@This(), decoder: *Decoder) !wasm.FuncType {
            return switch (try decoder.peekByte()) {
                0x40 => .{
                    .parameters = &.{},
                    .results = &.{},
                },

                inline 0x6f, 0x70, 0x7b...0x7f => |b| comptime .{
                    .parameters = &.{},
                    .results = &.{@intToEnum(wasm.ValType, b)},
                },

                else => self.summary.lookUp(
                    try self.summary.validateIdx(
                        wasm.TypeIdx{
                            .value = std.math.cast(u32, try decoder.nextInt(i33)) orelse
                                return error.TypeIndexOutOfRange,
                        },
                    ),
                ),
            };
        }

        fn checkEntryTypes(self: *const @This(), expected: []const wasm.ValType) !usize {
            if (expected.len == 0)
                return;

            if (expected.len > self.usableOperandStackDepth())
                return error.OperandStackUnderflow;

            const min_depth = self.operand_stack.items.len - expected.len;

            for (self.operand_stack.items[min_depth..], expected) |a, e|
                if (a.type != e)
                    return error.TypeMismatch;

            return min_depth;
        }

        fn checkExitTypes(self: *const @This(), label: Label) !void {
            const top_operands = self.operand_stack.items[label.min_operand_stack_depth..];

            if (top_operands.len < label.type.results.len)
                return error.OperandStackUnderflow
            else if (top_operands.len > label.type.results.len)
                return error.OperandStackOverflow;

            for (top_operands, label.type.results) |o, t|
                if (o.type != t) return error.TypeMismatch;
        }

        fn usableOperandStackDepth(self: *const @This()) usize {
            return if (self.label_stack.getLastOrNull()) |l|
                self.label_stack.items.len - l.min_operand_stack_depth
            else
                self.label_stack.items.len;
        }

        fn popOperand(self: *@This(), expected_type: wasm.ValType) !BackendOperand {
            if (self.usableOperandStackDepth() == 0)
                return error.OperandStackUnderflow;

            const op = self.operand_stack.pop();

            if (op.type != expected_type)
                return error.TypeMismatch;

            return op.backend;
        }
    };
}

const NullBackend = struct {
    pub const Local = struct {};

    pub const Operand = struct {};

    pub const Label = struct {};

    pub fn visitLocals(_: *@This()) !struct {
        pub fn finish(_: *@This()) !void {}

        pub fn deinit(_: *@This()) void {}

        pub fn visitLocal(_: *@This(), _: wasm.ValType, _: ?wasm.Name) !Local {
            return .{};
        }
    } {
        return .{};
    }

    pub fn visitInstrs(_: *@This()) !struct {
        pub fn finish(_: *@This()) !void {}

        pub fn deinit(_: *@This()) void {}

        pub fn visitUnreachable(_: *@This()) !void {}

        pub fn visitBackwardLabel(_: *@This(), _: []const wasm.ValType) !struct {
            pub fn finish(_: *@This()) !Label {
                return .{};
            }

            pub fn deinit(_: *@This()) void {}

            pub fn visitArg(_: *@This(), _: Operand) !Operand {
                return .{};
            }
        } {
            return .{};
        }

        pub fn declareForwardLabel(_: *@This(), _: []const wasm.ValType) !Label {
            return .{};
        }

        pub fn visitForwardLabel(_: *@This(), _: Label) !struct {
            pub fn finish(_: *@This()) !void {}

            pub fn deinit(_: *@This()) void {}

            pub fn visitArg(_: *@This()) !Operand {
                return .{};
            }
        } {
            return .{};
        }

        pub fn visitBr(_: *@This(), _: Label) !struct {
            pub fn finish(_: *@This()) !void {}

            pub fn deinit(_: *@This()) void {}

            pub fn visitArg(_: *@This(), _: Operand) !void {}
        } {
            return .{};
        }

        pub fn visitBrIf(_: *@This(), _: Label, _: Operand) !struct {
            pub fn finish(_: *@This()) !void {}

            pub fn deinit(_: *@This()) void {}

            pub fn visitArg(_: *@This(), _: Operand) !void {}
        } {
            return .{};
        }

        pub fn visitBrTable(_: *@This(), _: Operand) !struct {
            pub fn finish(_: *@This()) !void {}

            pub fn deinit(_: *@This()) void {}

            pub fn visitArgs(_: *@This()) !struct {
                pub fn finish(_: *@This()) !void {}

                pub fn deinit(_: *@This()) void {}

                pub fn visitArg(_: *@This(), _: Operand) !void {}
            } {
                return .{};
            }

            pub fn visitTargets(_: *@This()) !struct {
                pub fn finish(_: *@This()) !void {}

                pub fn deinit(_: *@This()) void {}

                pub fn visitTarget(_: *@This(), _: Label) !void {}

                pub fn visitDefaultTarget(_: *@This(), _: Label) !void {}
            } {
                return .{};
            }
        } {
            return .{};
        }
    } {
        return .{};
    }
};

test "ref all with null backend" {
    std.testing.refAllDecls(CodeProcessor(NullBackend));
}
