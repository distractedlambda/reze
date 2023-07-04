const common = @import("common");
const std = @import("std");

const FixedPoint = common.FixedPoint;

pub const ClipRect = extern struct {
    x1: c_ushort,
    y1: c_ushort,
    x2: c_ushort,
    y2: c_ushort,
};

pub const DrawableInfo = extern struct {
    num_rects: c_uint,
    rects: ?[*]ClipRect,
};

pub const TexRegion = extern struct {
    next: u8,
    prev: u8,
    in_use: u8,
    padding: u8,
    age: c_uint,
};

pub const HwLock = extern struct {
    lock: c_uint align(64),
};

pub const Version = extern struct {
    version_major: c_int,
    version_minor: c_int,
    version_patchlevel: c_int,
    name_len: usize,
    name: ?[*]u8,
    date_len: usize,
    date: ?[*]u8,
    desc_len: usize,
    desc: ?[*]u8,
};

pub const Unique = extern struct {
    unique_len: usize,
    unique: ?[*]u8,
};

pub const List = extern struct {
    count: c_int,
    version: ?[*]Version,
};

pub const Block = opaque {};

pub const Control = extern struct {
    func: enum(c_int) {
        add_command,
        rm_command,
        inst_handler,
        uninst_handler,
        _,
    },
    irq: c_int,
};

pub const MapType = enum(c_int) {
    frame_buffer,
    registers,
    shm,
    agp,
    scatter_gather,
    consistent,
    _,
};

pub const MapFlags = packed struct(c_int) {
    restricted: bool = false,
    read_only: bool = false,
    locked: bool = false,
    kernel: bool = false,
    write_combining: bool = false,
    contains_lock: bool = false,
    removable: bool = false,
    driver: bool = false,
    _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 8) = 0,
};

pub const CtxPrivMap = extern struct {
    ctx_id: c_uint,
    handle: ?*anyopaque,
};

pub const Map = extern struct {
    offset: c_ulong,
    size: c_ulong,
    type: MapType,
    flags: MapFlags,
    handle: ?*anyopaque,
    mtrr: c_int,
};

pub const Client = extern struct {
    idx: c_int,
    auth: c_int,
    pid: c_ulong,
    uid: c_ulong,
    magic: c_ulong,
    iocs: c_ulong,
};

pub const StatType = enum(c_int) {
    lock,
    opens,
    closes,
    ioctls,
    locks,
    unlocks,
    value,
    byte,
    count,
    irq,
    primary,
    secondary,
    dma,
    special,
    missed,
    _,
};

pub const Stats = extern struct {
    count: c_ulong,
    data: [15]extern struct {
        value: c_ulong,
        type: StatType,
    },
};

pub const LockFlags = packed struct(c_int) {
    ready: bool = false,
    quiescent: bool = false,
    flush: bool = false,
    flush_all: bool = false,
    halt_all_queues: bool = false,
    halt_cur_queues: bool = false,
    _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 6) = 0,
};

pub const Lock = extern struct {
    context: c_int,
    flags: LockFlags,
};

pub const DmaFlags = packed struct(c_int) {
    block: bool = false,
    while_locked: bool = false,
    priority: bool = false,
    _bit3: u1 = 0,
    wait: bool = false,
    smaller_ok: bool = false,
    larger_ok: bool = false,
    _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 7) = 0,
};

pub const BufDesc = extern struct {
    count: c_int,
    size: c_int,
    low_mark: c_int,
    high_mark: c_int,
    flags: packed struct(c_int) {
        page_align: bool = false,
        agp_buffer: bool = false,
        sg_buffer: bool = false,
        fb_buffer: bool = false,
        pci_buffer_ro: bool = false,
        _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 6) = 0,
    },
    agp_start: c_ulong,
};

pub const BufInfo = extern struct {
    count: c_int,
    list: ?[*]BufDesc,
};

pub const BufFree = extern struct {
    count: c_int,
    list: ?[*]c_int,
};

pub const BufPub = extern struct {
    idx: c_int,
    total: c_int,
    used: c_int,
    address: usize,
};

pub const BufMap = extern struct {
    count: c_int,
    virtual: ?*anyopaque,
    list: ?[*]BufPub,
};

pub const Dma = extern struct {
    context: c_int,
    send_count: c_int,
    send_indices: ?[*]c_int,
    send_sizes: ?[*]c_int,
    flags: DmaFlags,
    request_count: c_int,
    request_size: c_int,
    request_indices: ?[*]c_int,
    request_sizes: ?[*]c_int,
    granted_count: c_int,
};

pub const CtxFlags = packed struct(c_uint) {
    preserved: bool = false,
    @"2donly": bool = false,
    _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 2) = 0,
};

pub const Ctx = extern struct {
    handle: c_uint,
    flags: CtxFlags,
};

pub const CtxRes = extern struct {
    count: c_int,
    contexts: ?[*]Ctx,
};

pub const Draw = extern struct {
    handle: c_uint,
};

pub const DrawableInfoType = enum(c_int) {
    cliprects,
    _,
};

pub const UpdateDraw = extern struct {
    handle: c_uint,
    type: c_uint,
    num: c_uint,
    data: c_ulonglong,
};

pub const Auth = extern struct {
    magic: c_uint,
};

pub const IrqBusid = extern struct {
    irq: c_int,
    busnum: c_int,
    devnum: c_int,
    funcnum: c_int,
};

pub const VblankSeqType = packed struct(c_int) {
    relative: bool = false,
    _bits_1_25: u25 = 0,
    event: bool = false,
    flip: bool = false,
    nextonmiss: bool = false,
    secondary: bool = false,
    signal: bool = false,
    _reserved: std.meta.Int(.unsigned, @bitSizeOf(c_int) - 31) = 0,
};

pub const WaitVblankRequest = extern struct {
    type: VblankSeqType,
    sequence: c_uint,
    signal: c_ulong,
};

pub const WaitVblankReply = extern struct {
    type: VblankSeqType,
    sequence: c_uint,
    tval_sec: c_long,
    tval_usec: c_long,
};

pub const WaitVblank = extern union {
    WaitVblankRequest: WaitVblankRequest,
    WaitVblankReply: WaitVblankReply,
};

pub const ModesetCtl = extern struct {
    crtc: u32,
    cmd: u32,
};

pub const AgpMode = extern struct {
    mode: c_ulong,
};

pub const AgpBuffer = extern struct {
    size: c_ulong,
    handle: c_ulong,
    type: c_ulong,
    physical: c_ulong,
};

pub const AgpBinding = extern struct {
    handle: c_ulong,
    offset: c_ulong,
};

pub const AgpInfo = extern struct {
    agp_version_major: c_int,
    agp_version_minor: c_int,
    mode: c_ulong,
    aperture_base: c_ulong,
    aperture_size: c_ulong,
    memory_allowed: c_ulong,
    memory_used: c_ulong,
    id_vendor: c_ushort,
    id_device: c_ushort,
};

pub const ScatterGather = extern struct {
    size: c_ulong,
    handle: c_ulong,
};

pub const SetVersion = extern struct {
    drm_di_major: c_int,
    drm_di_minor: c_int,
    drm_dd_major: c_int,
    drm_dd_minor: c_int,
};

pub const GemClose = extern struct {
    handle: u32,
    pad: u32,
};

pub const GemFlink = extern struct {
    handle: u32,
    name: u32,
};

pub const GemOpen = extern struct {
    name: u32,
    handle: u32,
    size: u64,
};

pub const GetCap = extern struct {
    capability: u64,
    value: u64,
};

pub const SetClientCap = extern struct {
    capability: u64,
    value: u64,
};

pub const PrimeHandle = extern struct {
    handle: u32,
    flags: u32,
    fd: i32,
};

pub const SyncobjCreate = extern struct {
    handle: u32,
    flags: u32,
};

pub const SyncobjDestroy = extern struct {
    handle: u32,
    pad: u32,
};

pub const SyncobjHandle = extern struct {
    handle: u32,
    flags: u32,
    fd: i32,
    pad: u32,
};

pub const SyncobjTransfer = extern struct {
    src_handle: u32,
    dst_handle: u32,
    src_point: u64,
    dst_point: u64,
    flags: u32,
    pad: u32,
};

pub const SyncobjWait = extern struct {
    handles: u64,
    timeout_nsec: i64,
    count_handles: u32,
    flags: u32,
    first_signaled: u32,
    pad: u32,
};

pub const SyncobjTimelineWait = extern struct {
    handles: u64,
    points: u64,
    timeout_nsec: i64,
    count_handles: u32,
    flags: u32,
    first_signaled: u32,
    pad: u32,
};

pub const SyncobjArray = extern struct {
    handles: u64,
    count_handles: u32,
    pad: u32,
};

pub const SyncobjTimelineArray = extern struct {
    handles: u64,
    points: u64,
    count_handles: u32,
    flags: u32,
};

pub const CrtcGetSequence = extern struct {
    crtc_id: u32,
    active: u32,
    sequence: u64,
    sequence_ns: i64,
};

pub const CrtcQueueSequence = extern struct {
    crtc_id: u32,
    flags: u32,
    sequence: u64,
    user_data: u64,
};

pub const Event = extern struct {
    type: Type,
    length: u32,

    pub const Type = enum(u32) {
        vblank = 1,
        flip_complete = 2,
        crtc_sequence = 3,
        _,
    };
};

pub const EventVblank = extern struct {
    base: Event,
    user_data: u64,
    tv_sec: u32,
    tv_usec: u32,
    sequence: u32,
    crtc_id: u32,
};

pub const EventCrtcSequence = extern struct {
    base: Event,
    user_data: u64,
    time_ns: i64,
    sequence: u64,
};

pub const ModeModeinfo = extern struct {
    clock: u32,
    hdisplay: u16,
    hsync_start: u16,
    hsync_end: u16,
    htotal: u16,
    hskew: u16,
    vdisplay: u16,
    vsync_start: u16,
    vsync_end: u16,
    vtotal: u16,
    vscan: u16,

    vrefresh: u32,

    flags: Flags,
    type: Type,
    name: [32]u8,

    pub const Flags = packed struct(u32) {
        phsync: bool,
        nhsync: bool,
        pvsync: bool,
        nvsync: bool,
        interlace: bool,
        dblscan: bool,
        csync: bool,
        pcsync: bool,
        ncsync: bool,
        hskew: bool,
        bcast: bool,
        pixmux: bool,
        dblclk: bool,
        clkdiv2: bool,
        @"3d": @"3D",
        picture_aspect: PictureAspect,
        _reserved: u9,

        pub const @"3D" = enum(u5) {
            none,
            frame_packing,
            field_alternative,
            line_alternative,
            side_by_side_full,
            l_depth,
            l_depth_gfx_gfx_depth,
            top_and_bottom,
            side_by_side_half,
            _,
        };

        pub const PictureAspect = enum(u4) {
            none,
            @"4_3",
            @"16_9",
            @"64_27",
            @"256_135",
            _,
        };
    };

    pub const Type = packed struct(u32) {
        builtin: bool,
        clock_c: bool, // should always be combined with builtin?
        crtc_c: bool, // should always be combined with builtin?
        preferred: bool,
        default: bool,
        userdef: bool,
        driver: bool,
        _reserved: u25,
    };
};

pub const ModeCardRes = extern struct {
    fb_id_ptr: u64,
    crtc_id_ptr: u64,
    connector_id_ptr: u64,
    encoder_id_ptr: u64,
    count_fbs: u32,
    count_crtcs: u32,
    count_connectors: u32,
    count_encoders: u32,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
};

pub const ModeCrtc = extern struct {
    set_connectors_ptr: u64,
    count_connectors: u32,

    crtc_id: u32,
    fb_id: u32,

    x: u32,
    y: u32,

    gamma_size: u32,
    mode_valid: u32,
    mode: ModeModeinfo,
};

pub const ModeSetPlane = extern struct {
    plane_id: u32,
    crtc_id: u32,
    fb_id: u32,
    flags: Flags,

    crtc_x: i32,
    crtc_y: i32,
    crtc_w: u32,
    crtc_h: u32,

    src_x: FixedPoint(.unsigned, 16, 16),
    src_y: FixedPoint(.unsigned, 16, 16),
    src_h: FixedPoint(.unsigned, 16, 16),
    src_w: FixedPoint(.unsigned, 16, 16),

    pub const Flags = packed struct(u32) {
        present_top_field: bool,
        present_bottom_field: bool,
        _reserved: u30,
    };
};

pub const ModeGetPlane = extern struct {
    plane_id: u32,

    crtc_id: u32,
    fb_id: u32,

    possible_crtcs: u32,
    gamma_size: u32,

    count_format_types: u32,
    format_type_ptr: u64,
};

pub const ModeGetPlaneRes = extern struct {
    plane_id_ptr: u64,
    count_planes: u32,
};

pub const ModeGetEncoder = extern struct {
    encoder_id: u32,
    encoder_type: EncoderType,

    crtc_id: u32,

    possible_crtcs: u32,
    possible_clones: u32,

    pub const EncoderType = enum(u32) {
        none,
        dac,
        tmds,
        lvds,
        tvdac,
        virtual,
        dsi,
        dpmst,
        dpi,
        _,
    };
};

pub const ModeSubconnector = enum(c_int) {
    automatic = 0,
    vga = 1,
    dvid = 3,
    dvia = 4,
    composite = 5,
    svideo = 6,
    component = 8,
    scart = 9,
    display_port = 10,
    hdmia = 11,
    native = 15,
    wireless = 18,
    _,
};

pub const ModeGetConnector = extern struct {
    encoders_ptr: u64,
    modes_ptr: u64,
    props_ptr: u64,
    prop_values_ptr: u64,

    count_modes: u32,
    count_props: u32,
    count_encoders: u32,

    encoder_id: u32,
    connector_id: u32,
    connector_type: ConnectorType,
    connector_type_id: u32,

    connection: u32,
    mm_width: u32,
    mm_height: u32,
    subpixel: u32,

    pad: u32,

    pub const ConnectorType = enum(u32) {
        unknown,
        vga,
        dvii,
        dvid,
        dvia,
        composite,
        svideo,
        lvds,
        component,
        @"9_pin_din",
        display_port,
        hdmia,
        hdmib,
        tv,
        edp,
        virtual,
        dsi,
        dpi,
        writeback,
        spi,
        usb,
        _,
    };
};

pub const ModePropertyEnum = extern struct {
    value: u64,
    name: [32]u8,
};

pub const ModeGetProperty = extern struct {
    values_ptr: u64,
    enum_blob_ptr: u64,

    prop_id: u32,
    flags: u32,
    name: [32]u8,

    count_values: u32,
    count_enum_blobs: u32, // apparently actually counting enum _values_, not blobs
};

pub const ModeConnectorSetProperty = extern struct {
    value: u64,
    prop_id: u32,
    connector_id: u32,
};

pub const ModeObjGetProperties = extern struct {
    props_ptr: u64,
    prop_values_ptr: u64,
    count_props: u32,
    obj_id: u32,
    obj_type: u32,
};

pub const ModeObjSetProperty = extern struct {
    value: u64,
    prop_id: u32,
    obj_id: u32,
    obj_type: u32,
};

pub const ModeGetBlob = extern struct {
    blob_id: u32,
    length: u32,
    data: u64,
};

pub const ModeFbCmd = extern struct {
    fb_id: u32,
    width: u32,
    height: u32,
    pitch: u32,
    bpp: u32,
    depth: u32,
    handle: u32,
};

pub const ModeFbCmd2 = extern struct {
    fb_id: u32,
    width: u32,
    height: u32,
    pixel_format: u32,
    flags: u32,
    handles: [4]u32,
    pitches: [4]u32,
    offsets: [4]u32,
    modifier: [4]u64,
};

pub const ModeFbDirtyCmd = extern struct {
    fb_id: u32,
    flags: u32,
    color: u32,
    num_clips: u32,
    clips_ptr: u64,
};

pub const ModeModeCmd = extern struct {
    connector_id: u32,
    mode: ModeModeinfo,
};

pub const ModeCursor = extern struct {
    flags: u32,
    crtc_id: u32,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    handle: u32,
};

pub const ModeCursor2 = extern struct {
    flags: u32,
    crtc_id: u32,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    handle: u32,
    hot_x: i32,
    hot_y: i32,
};

pub const ModeCrtcLut = extern struct {
    crtc_id: u32,
    gamma_size: u32,

    red: u64,
    green: u64,
    blue: u64,
};

pub const ColorCtm = extern struct {
    matrix: [9]u64,
};

pub const ColorLut = extern struct {
    red: u16,
    green: u16,
    blue: u16,
    reserved: u16,
};

pub const ModeCrtcPageFlip = extern struct {
    crtc_id: u32,
    fb_id: u32,
    flags: u32,
    reserved: u32,
    user_data: u64,
};

pub const ModeCrtcPageFlipTarget = extern struct {
    crtc_id: u32,
    fb_id: u32,
    flags: u32,
    sequence: u32,
    user_data: u64,
};

pub const ModeCreateDumb = extern struct {
    height: u32,
    width: u32,
    bpp: u32,
    flags: u32,
    handle: u32,
    pitch: u32,
    size: u64,
};

pub const ModeMapDumb = extern struct {
    handle: u32,
    pad: u32,
    offset: u64,
};

pub const ModeDestroyDumb = extern struct {
    handle: u32,
};

pub const ModeAtomic = extern struct {
    flags: u32,
    count_objs: u32,
    objs_ptr: u64,
    count_props_ptr: u64,
    props_ptr: u64,
    prop_values_ptr: u64,
    reserved: u64,
    user_data: u64,
};

pub const FormatModifierBlob = extern struct {
    version: u32,
    flags: u32,
    count_formats: u32,
    formats_offset: u32,
    count_modifiers: u32,
    modifiers_offset: u32,
};

pub const FormatModifier = extern struct {
    formats: u64,
    offset: u32,
    pad: u32,
    modifier: u64,
};

pub const ModeCreateBlob = extern struct {
    data: u64,
    length: u32,
    blob_id: u32,
};

pub const ModeDestroyBlob = extern struct {
    blob_id: u32,
};

pub const ModeCreateLease = extern struct {
    object_ids: u64,
    object_count: u32,
    flags: u32,

    lessee_id: u32,
    fd: u32,
};

pub const ModeListLessees = extern struct {
    count_lessees: u32,
    pad: u32,
    lessees_ptr: u64,
};

pub const ModeGetLease = extern struct {
    count_objects: u32,
    pad: u32,
    objects_ptr: u64,
};

pub const ModeRevokeLease = extern struct {
    lessee_id: u32,
};

pub const ModeRect = extern struct {
    x1: i32,
    y1: i32,
    x2: i32,
    y2: i32,
};

pub const Cap = enum(u64) {
    dumb_buffer = 0x1,
    vblank_high_crtc = 0x2,
    dumb_preferred_depth = 0x3,
    dumb_prefer_shadow = 0x4,
    prime = 0x5,
    timestamp_monotonic = 0x6,
    async_page_flip = 0x7,
    cursor_width = 0x8,
    cursor_height = 0x9,
    addfb2_modifiers = 0x10,
    page_flip_target = 0x11,
    crtc_in_blank_event = 0x12,
    syncobj = 0x13,
    syncobj_timeline = 0x14,
    _,
};

pub const PrimeCap = packed struct(u64) {
    import: bool,
    @"export": bool,
    _reserved: u62,
};
