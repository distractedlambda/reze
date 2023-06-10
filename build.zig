const std = @import("std");

const Build = std.Build;
const CrossTarget = std.zig.CrossTarget;
const OptimizeMode = std.builtin.OptimizeMode;
const Step = Build.Step;
const Target = std.Target;

const wasm_cpu_model = Target.Cpu.Model{
    .name = "generic",
    .llvm_name = "generic",
    .features = Target.wasm.featureSet(&.{
        .bulk_memory,
        .multivalue,
        .mutable_globals,
        .nontrapping_fptoint,
        .reference_types,
        .sign_ext,
        .simd128,
    }),
};

const wasm_freestanding_target = CrossTarget{
    .cpu_arch = .wasm32,
    .cpu_model = .{ .explicit = &wasm_cpu_model },
    .os_tag = .freestanding,
};

const wasm_wasi_target = CrossTarget{
    .cpu_arch = .wasm32,
    .cpu_model = .{ .explicit = &wasm_cpu_model },
    .os_tag = .wasi,
};

// const Configurator = struct {
//     fn addWasmModule(
//         self: *@This(),
//         name: []const u8,
//         root_source_file: std.Build.FileSource,
//         target: std.zig.CrossTarget,
//         optimize: std.builtin.OptimizeMode,
//     ) *std.Build.Step.Compile {
//         const module = self.build.addSharedLibrary(.{
//             .name = name,
//             .root_source_file = root_source_file,
//             .target = target,
//             .optimize = optimize,
//         });
//
//         module.rdynamic = true;
//
//         return module;
//     }
//
//     fn addFreestandingWasmModule(
//         self: *@This(),
//         name: []const u8,
//         root_source_file: std.Build.FileSource,
//         optimize: std.builtin.OptimizeMode,
//     ) *std.Build.Step.Compile {
//         return self.addWasmModule(name, root_source_file, wasm_freestanding_target, optimize);
//     }
//
//     fn addWasiModule(
//         self: *@This(),
//         name: []const u8,
//         root_source_file: std.Build.FileSource,
//         optimize: std.builtin.OptimizeMode,
//     ) *std.Build.Step.Compile {
//         return self.addWasmModule(name, root_source_file, wasm_wasi_target, optimize);
//     }
//
//     fn configureTestWasmModule(self: *@This(), name: []const u8) void {
//         const root = std.build.FileSource{ .path = self.build.fmt("src/test_modules/{s}.zig", .{name}) };
//         for (std.meta.tags(std.builtin.OptimizeMode)) |mode| {
//             const mode_specific_name = self.build.fmt("{s}-{s}", .{ name, @tagName(mode) });
//             const module = self.addFreestandingWasmModule(mode_specific_name, root, mode);
//             const install_module = self.build.addInstallArtifact(module);
//             install_module.dest_dir = .{ .custom = "test_modules" };
//             self.run_unit_tests.?.step.dependOn(&install_module.step);
//         }
//     }
//
//     fn configureAllTestWasmModules(self: *@This()) void {
//         for (@import("src/test_modules/manifest.zig").module_names) |name| {
//             self.configureTestWasmModule(name);
//         }
//     }
// };

const ThirdPartyLibOption = enum {
    disabled,
    embedded,
    system,
};

const ThirdPartyLibInfo = struct {
    name: []const u8,
    link_name: []const u8,
    configure_embedded: *const fn (*Step.Compile) void,
};

const Configurator = struct {
    build: *Build,
    target: CrossTarget,
    optimize_mode: OptimizeMode,
    x11_lib: ?*Step.Compile = null,
    glfw_lib: ?*Step.Compile = null,
    freetype_lib: ?*Step.Compile = null,

    fn init(b: *Build) @This() {
        return .{
            .build = b,
            .target = b.standardTargetOptions(.{}),
            .optimize_mode = b.standardOptimizeOption(.{}),
        };
    }

    fn createCLib(self: *Configurator, name: []const u8) *Step.Compile {
        return self.build.addStaticLibrary(.{
            .name = name,
            .target = self.target,
            .optimize = self.optimize_mode,
            .link_libc = true,
        });
    }

    fn addX11(self: *Configurator) *Step.Compile {
        if (self.x11_lib) |it| return it;
        const lib = self.createCLib("x11");
        self.x11_lib = lib;

        const config_header = self.build.addConfigHeader(.{
            .style = .{
                .autoconf = .{
                    .path = "third_party/libx11/include/X11/XlibConf.h.in",
                },
            },
            .include_path = "X11/XlibConf.h",
        }, .{
            .XTHREADS = 1,
            .XUSE_MTSAFE_API = 1,
        });

        lib.addConfigHeader(config_header);
        // lib.installConfigHeader(config_header, .{});

        lib.defineCMacro("USE_THREAD_SAFETY_CONSTRUCTOR", "1");
        lib.defineCMacro("HASSETUGID", "1");
        lib.defineCMacro("HASGETRESUID", "1");
        lib.defineCMacro("XTHREADS", "1");
        lib.defineCMacro("X_USE_MTSAFE_API", "1");
        lib.defineCMacro("USE_POLL", "1");
        lib.defineCMacro("XCMS", "1");
        lib.defineCMacro("XLOCALE", "1");
        lib.defineCMacro("XF86BIGFONT", "1");
        lib.defineCMacro("XKB", "1");
        lib.defineCMacro("COMPOSECACHE", "1");

        lib.defineCMacro("_DEFAULT_SOURCE", null);
        lib.defineCMacro("X11_t", null);
        lib.defineCMacro("TRANS_CLIENT", null);

        lib.defineCMacro("XCMSDIR", "\"/usr/local/share/X11\"");

        lib.defineCMacro("HAS_FCHOWN", null);
        lib.defineCMacro("HAS_STICKY_DIR_BIT", null);

        lib.addIncludePath("third_party/libx11/include");
        lib.addIncludePath("third_party/libx11/include/X11");
        lib.addIncludePath("third_party/libx11/src");
        lib.addIncludePath("third_party/libx11/src/xcms");
        lib.addIncludePath("third_party/libx11/src/xkb");
        lib.addIncludePath("third_party/libx11/src/xlibi18n");

        // lib.installHeadersDirectoryOptions(.{
        //     .source_dir = "third_party/libx11/include",
        //     .install_dir = .header,
        //     .install_subdir = "",
        //     .exclude_extensions = &.{ ".am", ".gitignore", ".in" },
        // });

        lib.addIncludePath("third_party/xorgproto/include");

        // lib.installHeadersDirectoryOptions(.{
        //     .source_dir = "third_party/xorgproto/include",
        //     .install_dir = .header,
        //     .install_subdir = "",
        //     .exclude_extensions = &.{".build"},
        // });

        lib.addIncludePath("third_party/libxtrans");

        lib.addCSourceFiles(&.{
            "third_party/libx11/src/AllCells.c",
            "third_party/libx11/src/AllowEv.c",
            "third_party/libx11/src/AllPlanes.c",
            "third_party/libx11/src/AutoRep.c",
            "third_party/libx11/src/Backgnd.c",
            "third_party/libx11/src/BdrWidth.c",
            "third_party/libx11/src/Bell.c",
            "third_party/libx11/src/Border.c",
            "third_party/libx11/src/ChAccCon.c",
            "third_party/libx11/src/ChActPGb.c",
            "third_party/libx11/src/ChClMode.c",
            "third_party/libx11/src/ChCmap.c",
            "third_party/libx11/src/ChGC.c",
            "third_party/libx11/src/ChKeyCon.c",
            "third_party/libx11/src/ChkIfEv.c",
            "third_party/libx11/src/ChkMaskEv.c",
            "third_party/libx11/src/ChkTypEv.c",
            "third_party/libx11/src/ChkTypWEv.c",
            "third_party/libx11/src/ChkWinEv.c",
            "third_party/libx11/src/ChPntCon.c",
            "third_party/libx11/src/ChProp.c",
            "third_party/libx11/src/ChSaveSet.c",
            "third_party/libx11/src/ChWAttrs.c",
            "third_party/libx11/src/ChWindow.c",
            "third_party/libx11/src/CirWin.c",
            "third_party/libx11/src/CirWinDn.c",
            "third_party/libx11/src/CirWinUp.c",
            "third_party/libx11/src/ClDisplay.c",
            "third_party/libx11/src/Clear.c",
            "third_party/libx11/src/ClearArea.c",
            "third_party/libx11/src/ConfWind.c",
            "third_party/libx11/src/Context.c",
            "third_party/libx11/src/ConvSel.c",
            "third_party/libx11/src/CopyArea.c",
            "third_party/libx11/src/CopyCmap.c",
            "third_party/libx11/src/CopyGC.c",
            "third_party/libx11/src/CopyPlane.c",
            "third_party/libx11/src/CrBFData.c",
            "third_party/libx11/src/CrCmap.c",
            "third_party/libx11/src/CrCursor.c",
            "third_party/libx11/src/CrGC.c",
            "third_party/libx11/src/CrGlCur.c",
            "third_party/libx11/src/CrPFBData.c",
            "third_party/libx11/src/CrPixmap.c",
            "third_party/libx11/src/CrWindow.c",
            "third_party/libx11/src/Cursor.c",
            "third_party/libx11/src/DefCursor.c",
            "third_party/libx11/src/DelProp.c",
            "third_party/libx11/src/Depths.c",
            "third_party/libx11/src/DestSubs.c",
            "third_party/libx11/src/DestWind.c",
            "third_party/libx11/src/DisName.c",
            "third_party/libx11/src/DrArc.c",
            "third_party/libx11/src/DrArcs.c",
            "third_party/libx11/src/DrLine.c",
            "third_party/libx11/src/DrLines.c",
            "third_party/libx11/src/DrPoint.c",
            "third_party/libx11/src/DrPoints.c",
            "third_party/libx11/src/DrRect.c",
            "third_party/libx11/src/DrRects.c",
            "third_party/libx11/src/DrSegs.c",
            "third_party/libx11/src/ErrDes.c",
            "third_party/libx11/src/ErrHndlr.c",
            "third_party/libx11/src/evtomask.c",
            "third_party/libx11/src/EvToWire.c",
            "third_party/libx11/src/FetchName.c",
            "third_party/libx11/src/FillArc.c",
            "third_party/libx11/src/FillArcs.c",
            "third_party/libx11/src/FillPoly.c",
            "third_party/libx11/src/FillRct.c",
            "third_party/libx11/src/FillRcts.c",
            "third_party/libx11/src/FilterEv.c",
            "third_party/libx11/src/Flush.c",
            "third_party/libx11/src/Font.c",
            "third_party/libx11/src/FontInfo.c",
            "third_party/libx11/src/FontNames.c",
            "third_party/libx11/src/FreeCmap.c",
            "third_party/libx11/src/FreeCols.c",
            "third_party/libx11/src/FreeCurs.c",
            "third_party/libx11/src/FreeEData.c",
            "third_party/libx11/src/FreeEventData.c",
            "third_party/libx11/src/FreeGC.c",
            "third_party/libx11/src/FreePix.c",
            "third_party/libx11/src/FSSaver.c",
            "third_party/libx11/src/FSWrap.c",
            "third_party/libx11/src/GCMisc.c",
            "third_party/libx11/src/Geom.c",
            "third_party/libx11/src/GetAtomNm.c",
            "third_party/libx11/src/GetColor.c",
            "third_party/libx11/src/GetDflt.c",
            "third_party/libx11/src/GetEventData.c",
            "third_party/libx11/src/GetFPath.c",
            "third_party/libx11/src/GetFProp.c",
            "third_party/libx11/src/GetGCVals.c",
            "third_party/libx11/src/GetGeom.c",
            "third_party/libx11/src/GetHColor.c",
            "third_party/libx11/src/GetHints.c",
            "third_party/libx11/src/GetIFocus.c",
            "third_party/libx11/src/GetImage.c",
            "third_party/libx11/src/GetKCnt.c",
            "third_party/libx11/src/GetMoEv.c",
            "third_party/libx11/src/GetNrmHint.c",
            "third_party/libx11/src/GetPCnt.c",
            "third_party/libx11/src/GetPntMap.c",
            "third_party/libx11/src/GetProp.c",
            "third_party/libx11/src/GetRGBCMap.c",
            "third_party/libx11/src/GetSOwner.c",
            "third_party/libx11/src/GetSSaver.c",
            "third_party/libx11/src/GetStCmap.c",
            "third_party/libx11/src/GetTxtProp.c",
            "third_party/libx11/src/GetWAttrs.c",
            "third_party/libx11/src/GetWMCMapW.c",
            "third_party/libx11/src/GetWMProto.c",
            "third_party/libx11/src/globals.c",
            "third_party/libx11/src/GrButton.c",
            "third_party/libx11/src/GrKey.c",
            "third_party/libx11/src/GrKeybd.c",
            "third_party/libx11/src/GrPointer.c",
            "third_party/libx11/src/GrServer.c",
            "third_party/libx11/src/Host.c",
            "third_party/libx11/src/Iconify.c",
            "third_party/libx11/src/IfEvent.c",
            "third_party/libx11/src/imConv.c",
            "third_party/libx11/src/ImText.c",
            "third_party/libx11/src/ImText16.c",
            "third_party/libx11/src/ImUtil.c",
            "third_party/libx11/src/InitExt.c",
            "third_party/libx11/src/InsCmap.c",
            "third_party/libx11/src/IntAtom.c",
            "third_party/libx11/src/KeyBind.c",
            "third_party/libx11/src/KeysymStr.c",
            "third_party/libx11/src/KillCl.c",
            "third_party/libx11/src/LiHosts.c",
            "third_party/libx11/src/LiICmaps.c",
            "third_party/libx11/src/LiProps.c",
            "third_party/libx11/src/ListExt.c",
            "third_party/libx11/src/LoadFont.c",
            "third_party/libx11/src/LockDis.c",
            "third_party/libx11/src/locking.c",
            "third_party/libx11/src/LookupCol.c",
            "third_party/libx11/src/LowerWin.c",
            "third_party/libx11/src/Macros.c",
            "third_party/libx11/src/MapRaised.c",
            "third_party/libx11/src/MapSubs.c",
            "third_party/libx11/src/MapWindow.c",
            "third_party/libx11/src/MaskEvent.c",
            "third_party/libx11/src/Misc.c",
            "third_party/libx11/src/ModMap.c",
            "third_party/libx11/src/MoveWin.c",
            "third_party/libx11/src/NextEvent.c",
            "third_party/libx11/src/OCWrap.c",
            "third_party/libx11/src/OMWrap.c",
            "third_party/libx11/src/OpenDis.c",
            "third_party/libx11/src/ParseCmd.c",
            "third_party/libx11/src/ParseCol.c",
            "third_party/libx11/src/ParseGeom.c",
            "third_party/libx11/src/PeekEvent.c",
            "third_party/libx11/src/PeekIfEv.c",
            "third_party/libx11/src/Pending.c",
            "third_party/libx11/src/PixFormats.c",
            "third_party/libx11/src/PmapBgnd.c",
            "third_party/libx11/src/PmapBord.c",
            "third_party/libx11/src/PolyReg.c",
            "third_party/libx11/src/PolyTxt.c",
            "third_party/libx11/src/PolyTxt16.c",
            "third_party/libx11/src/PropAlloc.c",
            "third_party/libx11/src/PutBEvent.c",
            "third_party/libx11/src/PutImage.c",
            "third_party/libx11/src/Quarks.c",
            "third_party/libx11/src/QuBest.c",
            "third_party/libx11/src/QuColor.c",
            "third_party/libx11/src/QuColors.c",
            "third_party/libx11/src/QuCurShp.c",
            "third_party/libx11/src/QuExt.c",
            "third_party/libx11/src/QuKeybd.c",
            "third_party/libx11/src/QuPntr.c",
            "third_party/libx11/src/QuStipShp.c",
            "third_party/libx11/src/QuTextE16.c",
            "third_party/libx11/src/QuTextExt.c",
            "third_party/libx11/src/QuTileShp.c",
            "third_party/libx11/src/QuTree.c",
            "third_party/libx11/src/RaiseWin.c",
            "third_party/libx11/src/RdBitF.c",
            "third_party/libx11/src/RecolorC.c",
            "third_party/libx11/src/ReconfWin.c",
            "third_party/libx11/src/ReconfWM.c",
            "third_party/libx11/src/Region.c",
            "third_party/libx11/src/RegstFlt.c",
            "third_party/libx11/src/RepWindow.c",
            "third_party/libx11/src/RestackWs.c",
            "third_party/libx11/src/RotProp.c",
            "third_party/libx11/src/ScrResStr.c",
            "third_party/libx11/src/SelInput.c",
            "third_party/libx11/src/SendEvent.c",
            "third_party/libx11/src/SetBack.c",
            "third_party/libx11/src/SetClMask.c",
            "third_party/libx11/src/SetClOrig.c",
            "third_party/libx11/src/SetCRects.c",
            "third_party/libx11/src/SetDashes.c",
            "third_party/libx11/src/SetFont.c",
            "third_party/libx11/src/SetFore.c",
            "third_party/libx11/src/SetFPath.c",
            "third_party/libx11/src/SetFunc.c",
            "third_party/libx11/src/SetHints.c",
            "third_party/libx11/src/SetIFocus.c",
            "third_party/libx11/src/SetLocale.c",
            "third_party/libx11/src/SetLStyle.c",
            "third_party/libx11/src/SetNrmHint.c",
            "third_party/libx11/src/SetPMask.c",
            "third_party/libx11/src/SetPntMap.c",
            "third_party/libx11/src/SetRGBCMap.c",
            "third_party/libx11/src/SetSOwner.c",
            "third_party/libx11/src/SetSSaver.c",
            "third_party/libx11/src/SetState.c",
            "third_party/libx11/src/SetStCmap.c",
            "third_party/libx11/src/SetStip.c",
            "third_party/libx11/src/SetTile.c",
            "third_party/libx11/src/SetTSOrig.c",
            "third_party/libx11/src/SetTxtProp.c",
            "third_party/libx11/src/SetWMCMapW.c",
            "third_party/libx11/src/SetWMProto.c",
            "third_party/libx11/src/StBytes.c",
            "third_party/libx11/src/StColor.c",
            "third_party/libx11/src/StColors.c",
            "third_party/libx11/src/StName.c",
            "third_party/libx11/src/StNColor.c",
            "third_party/libx11/src/StrKeysym.c",
            "third_party/libx11/src/StrToText.c",
            "third_party/libx11/src/Sync.c",
            "third_party/libx11/src/Synchro.c",
            "third_party/libx11/src/Text.c",
            "third_party/libx11/src/Text16.c",
            "third_party/libx11/src/TextExt.c",
            "third_party/libx11/src/TextExt16.c",
            "third_party/libx11/src/TextToStr.c",
            "third_party/libx11/src/TrCoords.c",
            "third_party/libx11/src/UndefCurs.c",
            "third_party/libx11/src/UngrabBut.c",
            "third_party/libx11/src/UngrabKbd.c",
            "third_party/libx11/src/UngrabKey.c",
            "third_party/libx11/src/UngrabPtr.c",
            "third_party/libx11/src/UngrabSvr.c",
            "third_party/libx11/src/UninsCmap.c",
            "third_party/libx11/src/UnldFont.c",
            "third_party/libx11/src/UnmapSubs.c",
            "third_party/libx11/src/UnmapWin.c",
            "third_party/libx11/src/VisUtil.c",
            "third_party/libx11/src/WarpPtr.c",
            "third_party/libx11/src/Window.c",
            "third_party/libx11/src/WinEvent.c",
            "third_party/libx11/src/Withdraw.c",
            "third_party/libx11/src/WMGeom.c",
            "third_party/libx11/src/WMProps.c",
            "third_party/libx11/src/WrBitF.c",
            "third_party/libx11/src/xcb_disp.c",
            "third_party/libx11/src/xcb_io.c",
            "third_party/libx11/src/xcms/AddDIC.c",
            "third_party/libx11/src/xcms/AddSF.c",
            "third_party/libx11/src/xcms/CCC.c",
            "third_party/libx11/src/xcms/cmsAllCol.c",
            "third_party/libx11/src/xcms/cmsAllNCol.c",
            "third_party/libx11/src/xcms/cmsCmap.c",
            "third_party/libx11/src/xcms/cmsColNm.c",
            "third_party/libx11/src/xcms/cmsGlobls.c",
            "third_party/libx11/src/xcms/cmsInt.c",
            "third_party/libx11/src/xcms/cmsLkCol.c",
            "third_party/libx11/src/xcms/cmsMath.c",
            "third_party/libx11/src/xcms/cmsProp.c",
            "third_party/libx11/src/xcms/cmsTrig.c",
            "third_party/libx11/src/xcms/CvCols.c",
            "third_party/libx11/src/xcms/CvColW.c",
            "third_party/libx11/src/xcms/HVC.c",
            "third_party/libx11/src/xcms/HVCGcC.c",
            "third_party/libx11/src/xcms/HVCGcV.c",
            "third_party/libx11/src/xcms/HVCGcVC.c",
            "third_party/libx11/src/xcms/HVCMnV.c",
            "third_party/libx11/src/xcms/HVCMxC.c",
            "third_party/libx11/src/xcms/HVCMxV.c",
            "third_party/libx11/src/xcms/HVCMxVC.c",
            "third_party/libx11/src/xcms/HVCMxVs.c",
            "third_party/libx11/src/xcms/HVCWpAj.c",
            "third_party/libx11/src/xcms/IdOfPr.c",
            "third_party/libx11/src/xcms/Lab.c",
            "third_party/libx11/src/xcms/LabGcC.c",
            "third_party/libx11/src/xcms/LabGcL.c",
            "third_party/libx11/src/xcms/LabGcLC.c",
            "third_party/libx11/src/xcms/LabMnL.c",
            "third_party/libx11/src/xcms/LabMxC.c",
            "third_party/libx11/src/xcms/LabMxL.c",
            "third_party/libx11/src/xcms/LabMxLC.c",
            "third_party/libx11/src/xcms/LabWpAj.c",
            "third_party/libx11/src/xcms/LRGB.c",
            "third_party/libx11/src/xcms/Luv.c",
            "third_party/libx11/src/xcms/LuvGcC.c",
            "third_party/libx11/src/xcms/LuvGcL.c",
            "third_party/libx11/src/xcms/LuvGcLC.c",
            "third_party/libx11/src/xcms/LuvMnL.c",
            "third_party/libx11/src/xcms/LuvMxC.c",
            "third_party/libx11/src/xcms/LuvMxL.c",
            "third_party/libx11/src/xcms/LuvMxLC.c",
            "third_party/libx11/src/xcms/LuvWpAj.c",
            "third_party/libx11/src/xcms/OfCCC.c",
            "third_party/libx11/src/xcms/PrOfId.c",
            "third_party/libx11/src/xcms/QBlack.c",
            "third_party/libx11/src/xcms/QBlue.c",
            "third_party/libx11/src/xcms/QGreen.c",
            "third_party/libx11/src/xcms/QRed.c",
            "third_party/libx11/src/xcms/QuCol.c",
            "third_party/libx11/src/xcms/QuCols.c",
            "third_party/libx11/src/xcms/QWhite.c",
            "third_party/libx11/src/xcms/SetCCC.c",
            "third_party/libx11/src/xcms/SetGetCols.c",
            "third_party/libx11/src/xcms/StCol.c",
            "third_party/libx11/src/xcms/StCols.c",
            "third_party/libx11/src/xcms/UNDEFINED.c",
            "third_party/libx11/src/xcms/uvY.c",
            "third_party/libx11/src/xcms/XRGB.c",
            "third_party/libx11/src/xcms/xyY.c",
            "third_party/libx11/src/xcms/XYZ.c",
            "third_party/libx11/src/xkb/XKB.c",
            "third_party/libx11/src/xkb/XKBAlloc.c",
            "third_party/libx11/src/xkb/XKBBell.c",
            "third_party/libx11/src/xkb/XKBBind.c",
            "third_party/libx11/src/xkb/XKBCompat.c",
            "third_party/libx11/src/xkb/XKBCtrls.c",
            "third_party/libx11/src/xkb/XKBCvt.c",
            "third_party/libx11/src/xkb/XKBExtDev.c",
            "third_party/libx11/src/xkb/XKBGAlloc.c",
            "third_party/libx11/src/xkb/XKBGeom.c",
            "third_party/libx11/src/xkb/XKBGetByName.c",
            "third_party/libx11/src/xkb/XKBGetMap.c",
            "third_party/libx11/src/xkb/XKBleds.c",
            "third_party/libx11/src/xkb/XKBList.c",
            "third_party/libx11/src/xkb/XKBMAlloc.c",
            "third_party/libx11/src/xkb/XKBMisc.c",
            "third_party/libx11/src/xkb/XKBNames.c",
            "third_party/libx11/src/xkb/XKBRdBuf.c",
            "third_party/libx11/src/xkb/XKBSetGeom.c",
            "third_party/libx11/src/xkb/XKBSetMap.c",
            "third_party/libx11/src/xkb/XKBUse.c",
            "third_party/libx11/src/XlibAsync.c",
            "third_party/libx11/src/xlibi18n/ICWrap.c",
            "third_party/libx11/src/xlibi18n/imKStoUCS.c",
            "third_party/libx11/src/xlibi18n/IMWrap.c",
            "third_party/libx11/src/xlibi18n/lcCharSet.c",
            "third_party/libx11/src/xlibi18n/lcConv.c",
            "third_party/libx11/src/xlibi18n/lcCT.c",
            "third_party/libx11/src/xlibi18n/lcDB.c",
            "third_party/libx11/src/xlibi18n/lcDynamic.c",
            "third_party/libx11/src/xlibi18n/lcFile.c",
            "third_party/libx11/src/xlibi18n/lcGeneric.c",
            "third_party/libx11/src/xlibi18n/lcInit.c",
            "third_party/libx11/src/xlibi18n/lcPrTxt.c",
            "third_party/libx11/src/xlibi18n/lcPublic.c",
            "third_party/libx11/src/xlibi18n/lcPubWrap.c",
            "third_party/libx11/src/xlibi18n/lcRM.c",
            "third_party/libx11/src/xlibi18n/lcStd.c",
            "third_party/libx11/src/xlibi18n/lcTxtPr.c",
            "third_party/libx11/src/xlibi18n/lcUTF8.c",
            "third_party/libx11/src/xlibi18n/lcUtil.c",
            "third_party/libx11/src/xlibi18n/lcWrap.c",
            "third_party/libx11/src/xlibi18n/mbWMProps.c",
            "third_party/libx11/src/xlibi18n/mbWrap.c",
            "third_party/libx11/src/xlibi18n/utf8WMProps.c",
            "third_party/libx11/src/xlibi18n/utf8Wrap.c",
            "third_party/libx11/src/xlibi18n/wcWrap.c",
            "third_party/libx11/src/xlibi18n/XDefaultIMIF.c",
            "third_party/libx11/src/xlibi18n/XDefaultOMIF.c",
            "third_party/libx11/src/xlibi18n/xim_trans.c",
            "third_party/libx11/src/XlibInt.c",
            "third_party/libx11/src/Xrm.c",
        }, &.{});

        return lib;
    }

    fn addGlfw(self: *Configurator) *Step.Compile {
        if (self.glfw_lib) |it| return it;
        const lib = self.createCLib("glfw");
        self.glfw_lib = lib;

        lib.addIncludePath("third_party/glfw/include");

        lib.installHeadersDirectory("third_party/glfw/include", "");

        lib.addCSourceFiles(&.{
            "third_party/glfw/src/context.c",
            "third_party/glfw/src/init.c",
            "third_party/glfw/src/input.c",
            "third_party/glfw/src/monitor.c",
            "third_party/glfw/src/window.c",
            "third_party/glfw/src/vulkan.c",
        }, &.{});

        if (self.target.isWindows()) {
            lib.defineCMacro("_GLFW_WIN32", null);
            lib.linkSystemLibraryName("gdi32");
            lib.addCSourceFiles(&.{
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/wgl_context.c",
                "third_party/glfw/src/win32_init.c",
                "third_party/glfw/src/win32_joystick.c",
                "third_party/glfw/src/win32_monitor.c",
                "third_party/glfw/src/win32_thread.c",
                "third_party/glfw/src/win32_time.c",
                "third_party/glfw/src/win32_window.c",
            }, &.{});
        } else if (self.target.isDarwin()) {
            lib.defineCMacro("_GLFW_COCOA", null);
            lib.linkFramework("Cocoa");
            lib.linkFramework("IOKit");
            lib.linkFramework("CoreFoundation");
            lib.addCSourceFiles(&.{
                "third_party/glfw/src/cocoa_init.m",
                "third_party/glfw/src/cocoa_joystick.m",
                "third_party/glfw/src/cocoa_monitor.m",
                "third_party/glfw/src/cocoa_time.c",
                "third_party/glfw/src/cocoa_window.m",
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/nsgl_context.m",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/posix_thread.c",
            }, &.{});
        } else {
            lib.defineCMacro("_GLFW_X11", null);
            lib.linkLibrary(self.addX11());
            lib.addCSourceFiles(&.{
                "third_party/glfw/src/egl_context.c",
                "third_party/glfw/src/glx_context.c",
                "third_party/glfw/src/osmesa_context.c",
                "third_party/glfw/src/posix_thread.c",
                "third_party/glfw/src/posix_time.c",
                "third_party/glfw/src/x11_init.c",
                "third_party/glfw/src/x11_monitor.c",
                "third_party/glfw/src/x11_window.c",
                "third_party/glfw/src/xkb_unicode.c",
                if (lib.target.isLinux())
                    "third_party/glfw/src/linux_joystick.c"
                else
                    "third_party/glfw/src/null_joystick.c",
            }, &.{});
        }

        return lib;
    }

    fn configureBuild(self: *Configurator) void {
        const unit_tests = self.build.addTest(.{
            .root_source_file = .{ .path = "src/reze/reze.zig" },
            .target = self.target,
            .optimize = self.optimize_mode,
        });

        unit_tests.linkLibrary(self.addGlfw());

        const test_step = self.build.step("test", "Run unit tests");
        test_step.dependOn(&self.build.addRunArtifact(unit_tests).step);
    }
};

pub fn build(b: *Build) void {
    var configurator = Configurator.init(b);
    configurator.configureBuild();
}
