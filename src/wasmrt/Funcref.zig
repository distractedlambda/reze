const std = @import("std");
const wasmrt = @import("wasmrt.zig");

context: *anyopaque,
vtable: *const VTable,

const function_alignment = blk: {
    const S = struct {
        fn f() void {}
    };

    break :blk @typeInfo(@TypeOf(S.f)).Fn.alignment;
};

const VTable = struct {
    signature: Signature,
    invoke: *align(function_alignment) const anyopaque,
};

pub const Signature = struct {
    params: []const ValType,
    results: []const ValType,

    fn of(comptime F: type) @This() {
        return comptime switch (@typeInfo(F)) {
            .Fn => |info| blk: {
                if (info.calling_convention != .Unspecified)
                    @compileError("calling convention must be Unspecified");

                if (info.alignment != function_alignment)
                    @compileError("alignment must be the default for functions");

                if (info.is_generic)
                    @compileError("function cannot be generic");

                if (info.is_var_args)
                    @compileError("function cannot have varargs");

                if (info.params.len == 0)
                    @compileError("function must have at least a context parameter");

                switch (@typeInfo(info.params[0].type.?)) {
                    .Pointer => |pointer_info| {
                        if (pointer_info.size != .One)
                            @compileError("context parameter must be a pointer to a single value");
                    },

                    else => @compileError("context parameter must be a pointer"),
                }

                var params: [info.params.len - 1]ValType = undefined;
                for (&params, info.params[1..]) |*d, s| d.* = ValType.of(s.type);

                const results = switch (@typeInfo(info.return_type.?)) {
                    .Struct =>

                };
            },

            else => @compileError("expected a function type, but got " ++ @typeName(F)),
        };
    }

    fn check(self: @This(), comptime expected: @This()) !void {
        blk: {
            if (self.params.len != comptime expected.params.len)
                break :blk;

            if (self.results.len != comptime expected.results.len)
                break :blk;

            for (comptime expected.params, self.params) |e, a|
                if (e != a)
                    break :blk;

            for (comptime expected.results, self.results) |e, a|
                if (e != a)
                    break :blk;

            return;
        }

        return error.WrongCallSignature;
    }

    fn InvokeArgsTuple(comptime self: @This()) type {
        return ValType.Tuple(self.params);
    }

    fn InvokeReturn(comptime self: @This()) type {
        return ValType.Return(self.results);
    }

    fn InvokeFnPtr(comptime self: @This()) type {
        return *const @Type(.{ .Fn = .{
            .calling_convention = .Unspecified,
            .alignment = function_alignment,
            .is_generic = false,
            .is_var_args = false,

            .return_type = ValType.Return(self.results),

            .params = blk: {
                var fn_params: [self.params.len + 1]std.builtin.Type.Fn.Param = undefined;

                fn_params[0] = .{
                    .is_generic = false,
                    .is_noalias = false,
                    .type = *anyopaque,
                };

                for (&fn_params[1..], self.params) |*fn_param, param| fn_param.* = .{
                    .is_generic = false,
                    .is_noalias = false,
                    .type = param.Type(),
                };

                break :blk fn_params;
            },
        } });
    }
};

pub const ValType = enum {
    i32,
    i64,
    f32,
    f64,
    v128,
    funcref,
    externref,

    fn of(comptime T: type) @This() {
        return comptime switch (T) {
            i32 => .i32,
            i64 => .i64,
            f32 => .f32,
            f64 => .f64,
            wasmrt.v128 => .v128,
            wasmrt.funcref => .funcref,
            wasmrt.externref => .externref,
            else => unreachable,
        };
    }

    fn Type(comptime self: @This()) type {
        return switch (self) {
            .i32 => i32,
            .i64 => i64,
            .f32 => f32,
            .f64 => f64,
            .v128 => wasmrt.v128,
            .funcref => wasmrt.funcref,
            .externref => wasmrt.externref,
        };
    }

    fn Tuple(comptime val_types: []const @This()) type {
        var types: [val_types.len]type = undefined;
        for (&types, val_types) |*ty, vt| ty.* = vt.Type();
        return std.meta.Tuple(&types);
    }

    fn Return(comptime val_types: []const @This()) type {
        return anyerror!switch (val_types.len) {
            0 => void,
            1 => val_types[0].Type(),
            else => ValType.Tuple(val_types),
        };
    }
};

pub fn invoke(
    self: @This(),
    comptime signature: Signature,
    args: signature.InvokeArgsTuple(),
) signature.InvokeReturn() {
    try self.vtable.signature.check(signature);
    return @call(
        .always_tail,
        @ptrCast(signature.InvokeFnPtr(), self.vtable.invoke),
        .{self.context} ++ args,
    );
}
