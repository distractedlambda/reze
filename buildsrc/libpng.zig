const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;
const Target = std.Target;

pub const Config = struct {
    target: CrossTarget,
    optimize: OptimizeMode,
    zlib: *Step.Compile,
};

pub fn addLibpng(b: *Build, config: Config) *Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "libpng",
        .target = config.target,
        .optimize = config.optimize,
        .link_libc = true,
    });

    lib.linkLibrary(config.zlib);

    const pnglibconf = b.addConfigHeader(.{
        .style = .{ .cmake = .{ .path = "third_party/libpng/scripts/pnglibconf.h.prebuild" } },
        .include_path = "pnglibconf.h",
    });

    lib.addIncludePath("third_party/libpng");
    lib.addConfigHeader(pnglibconf);

    lib.installHeader("third_party/libpng/png.h", "");
    lib.installHeader("third_party/libpng/pngconf.h", "");
    lib.installConfigHeader(pnglibconf, .{});

    if (hasArmNeon(lib.target_info.target)) {
        lib.defineCMacro("PNG_ARM_NEON_OPT", "2");

        lib.addCSourceFiles(&.{
            "third_party/libpng/arm/arm_init.c",
            "third_party/libpng/arm/filter_neon_intrinsics.c",
            "third_party/libpng/arm/palette_neon_intrinsics.c",
        }, &.{});

        lib.addAssemblyFile("third_party/libpng/arm/filter_neon.S");
    } else if (hasPpcVsx(lib.target_info.target)) {
        lib.defineCMacro("PNG_POWERPC_VSX_OPT", "2");
        lib.addCSourceFiles(&.{
            "third_party/libpng/powerpc/filter_vsx_intrinsics.c",
            "third_party/libpng/powerpc/powerpc_init.c",
        }, &.{});
    } else if (hasX86Sse2(lib.target_info.target)) {
        lib.defineCMacro("PNG_INTEL_SSE_OPT", "1");
        lib.addCSourceFiles(&.{
            "third_party/libpng/intel/filter_sse2_intrinsics.c",
            "third_party/libpng/intel/intel_init.c",
        }, &.{});
    } else if (hasMipselMsa(lib.target_info.target)) {
        lib.defineCMacro("PNG_MIPS_MSA_OPT", "2");
        lib.addCSourceFiles(&.{
            "third_party/libpng/mips/filter_msa_intrinsics.c",
            "third_party/libpng/mips/mips_init.c",
        }, &.{});
    }

    lib.addCSourceFiles(&.{
        "third_party/libpng/png.c",
        "third_party/libpng/pngerror.c",
        "third_party/libpng/pngget.c",
        "third_party/libpng/pngmem.c",
        "third_party/libpng/pngpread.c",
        "third_party/libpng/pngread.c",
        "third_party/libpng/pngrio.c",
        "third_party/libpng/pngrtran.c",
        "third_party/libpng/pngrutil.c",
        "third_party/libpng/pngset.c",
        "third_party/libpng/pngtrans.c",
        "third_party/libpng/pngwio.c",
        "third_party/libpng/pngwrite.c",
        "third_party/libpng/pngwtran.c",
        "third_party/libpng/pngwutil.c",
    }, &.{});
}

fn hasArmNeon(target: Target) bool {
    return switch (target.cpu.arch) {
        .arm, .armeb => Target.arm.featureSetHas(target.cpu.features, .neon),
        .aarch64, .aarch64_be, .aarch64_32 => true,
        else => false,
    };
}

fn hasPpcVsx(target: Target) bool {
    return switch (target.cpu.arch) {
        .powerpc,
        .powerpcle,
        .powerpc64,
        .powerpc64le,
        => Target.powerpc.featureSetHas(target.cpu.features, .vsx),

        else => false,
    };
}

fn hasX86Sse2(target: Target) bool {
    return switch (target.cpu.arch) {
        .x86, .x86_64 => Target.x86.featureSetHas(target.cpu.features, .sse2),
        else => false,
    };
}

fn hasMipselMsa(target: Target) bool {
    return switch (target.cpu.arch) {
        .mipsel, .mips64el => Target.mips.featureSetHas(target.cpu.features, .msa),
        else => false,
    };
}
