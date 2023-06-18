const c = @import("c.zig");

pub fn init() !void {
    if (c.FcInit() == c.FcFalse)
        return error.Failure;
}

pub fn reinit() !void {
    if (c.FcInitReinitialize() == c.FcFalse)
        return error.Failure;
}

pub fn bringUpToDate() !void {
    if (c.FcInitBringUptoDate() == c.FcFalse)
        return error.Failure;
}

pub const deinit = c.FcFini;

pub const Pattern = opaque {
    fn fromC(c_ptr: *c.FcPattern) *@This() {
        return @ptrCast(*@This(), c_ptr);
    }

    fn toC(self: *@This()) *c.FcPattern {
        return @ptrCast(*c.FcPattern, self);
    }

    fn toCConst(self: *const @This()) *const c.FcPattern {
        return @ptrCast(*const c.FcPattern, self);
    }

    pub fn create() !*@This() {
        return fromC(try nonnullOrOOM(c.FcPatternCreate()));
    }

    pub fn duplicate(self: *const @This()) !*@This() {
        return fromC(try nonnullOrOOM(c.FcPatternDuplicate(self.toCConst())));
    }

    pub fn reference(self: *@This()) void {
        c.FcPatternReference(self.toC());
    }

    pub fn destroy(self: *@This()) void {
        c.FcPatternDestroy(self.toC());
    }

    pub fn equal(self: *const @This(), other: *const @This()) bool {
        return c.FcPatternEqual(self.toCConst(), other.toCConst()) != c.FcFalse;
    }

    pub fn equalSubset(self: *const @This(), other: *const @This(), subset: *const ObjectSet) bool {
        return c.FcPatternEqualSubset(
            self.toCConst(),
            other.toCConst(),
            subset.toCConst(),
        ) != c.FcFalse;
    }

    pub fn filter(self: *@This(), subset: *const ObjectSet) *@This() {
        return fromC(try nonnullOrOOM(c.FcPatternFilter(self.toC(), subset.toCConst())));
    }

    pub fn hash(self: *const @This()) u32 {
        return c.FcPatternHash(self.toCConst());
    }
};

pub const ObjectSet = opaque {
    fn toCConst(self: *const @This()) *const c.FcObjectSet {
        return @ptrCast(*const c.FcObjectSet, self);
    }
};

pub const Type = enum(c_int) {
    void = c.FcTypeVoid,
    integer = c.FcTypeInteger,
    double = c.FcTypeDouble,
    string = c.FcTypeString,
    bool = c.FcTypeBool,
    matrix = c.FcTypeMatrix,
    char_set = c.FcTypeCharSet,
};

// pub const Value = union(enum) {
//     Void: void,
//     Integer: c_int,
//     Double: f64,
//     String: [*:0]const u8,
//     Bool: bool,
//
//
//
//     fn fromC(c_value: c.FcValue) @This() {
//
//     }
//
// };

fn nonnullOrOOM(ptr: anytype) !@typeInfo(@TypeOf(ptr)).Optional.child {
    return ptr orelse error.OutOfMemory;
}
