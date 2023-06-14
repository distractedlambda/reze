const BOOL = i8;

comptime {
    if (!@import("builtin").target.os.tag.isDarwin())
        @compileError("this interface is only supported on Apple platforms");
}

pub const Class = opaque {
    pub fn id(self: *Class) *Id {
        return @ptrCast(*Id, self);
    }

    extern fn class_getName(*Class) [*:0]const u8;

    pub fn getName(self: *Class) [*:0]const u8 {
        return class_getName(self);
    }

    extern fn class_getSuperclass(*Class) ?*Class;

    pub fn getSuperclass(self: *Class) ?*Class {
        return class_getSuperclass(self);
    }

    extern fn class_isMetaClass(*Class) BOOL;

    pub fn isMetaClass(self: *Class) bool {
        return class_isMetaClass(self) != 0;
    }

    extern fn class_getInstanceSize(*Class) usize;

    pub fn getInstanceSize(self: *Class) usize {
        return class_getInstanceSize(self);
    }
};

pub const Id = opaque {
    extern fn object_getClass(*Id) *Class;

    pub fn getClass(self: *Id) *Class {
        return object_getClass(self);
    }

    extern fn objc_msgSend() void;
};

pub const Selector = opaque {
    extern fn sel_getName(*Selector) [*:0]const u8;

    pub fn getName(self: *Selector) [*:0]const u8 {
        return sel_getName(self);
    }
};

pub fn selector(comptime name: [*:0]const u8) *Selector {
    const static = struct {
        var sel: ?*Selector = null;
    };

    return resolveSelector(name, &static.sel);
}

extern fn sel_registerName([*:0]const u8) *Selector;

fn resolveSelector(name: [*:0]const u8, loc: *?*Selector) *Selector {
    if (@atomicLoad(?*Selector, loc, .Unordered)) |it| return it;
    return resolveSelectorSlow(name, loc);
}

fn resolveSelectorSlow(name: [*:0]const u8, loc: *?*Selector) *Selector {
    const sel = sel_registerName(name);
    @atomicStore(?*Selector, loc, sel, .Unordered);
    return sel;
}
