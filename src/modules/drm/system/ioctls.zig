const types = @import("types.zig");

const _ioc_nrbits = 8;
const _ioc_typebits = 8;
const _ioc_sizebits = 14;
const _ioc_dirbits = 2;

const _ioc_nrshift = 0;
const _ioc_typeshift = _ioc_nrshift + _ioc_nrbits;
const _ioc_sizeshift = _ioc_typeshift + _ioc_typebits;
const _ioc_dirshift = _ioc_sizeshift + _ioc_sizebits;

const _ioc_none = 0;
const _ioc_write = 1;
const _ioc_read = 2;

fn _ioc(
    comptime dir: comptime_int,
    comptime typ: comptime_int,
    comptime nr: comptime_int,
    comptime size: comptime_int,
) comptime_int {
    return (dir << _ioc_dirshift) |
        (typ << _ioc_typeshift) |
        (nr << _ioc_nrshift) |
        (size << _ioc_sizeshift);
}

fn _io(comptime typ: comptime_int, comptime nr: comptime_int) comptime_int {
    return _ioc(_ioc_none, typ, nr, 0);
}

fn _ior(comptime typ: comptime_int, comptime nr: comptime_int, comptime size: type) comptime_int {
    return _ioc(_ioc_read, typ, nr, @sizeOf(size));
}

fn _iow(comptime typ: comptime_int, comptime nr: comptime_int, comptime size: type) comptime_int {
    return _ioc(_ioc_write, typ, nr, @sizeOf(size));
}

fn _iowr(comptime typ: comptime_int, comptime nr: comptime_int, comptime size: type) comptime_int {
    return _ioc(_ioc_read | _ioc_write, typ, nr, @sizeOf(size));
}

const ioctl_base = 'd';

fn io(comptime nr: comptime_int) comptime_int {
    return _io(ioctl_base, nr);
}

fn ior(comptime nr: comptime_int, comptime typ: type) comptime_int {
    return _ior(ioctl_base, nr, typ);
}

fn iow(comptime nr: comptime_int, comptime typ: type) comptime_int {
    return _iow(ioctl_base, nr, typ);
}

fn iowr(comptime nr: comptime_int, comptime typ: type) comptime_int {
    return _iowr(ioctl_base, nr, typ);
}

pub const version = _iowr(0x00, types.Version);
pub const get_unique = _iowr(0x01, types.Unique);
pub const get_magic = _ior(0x02, types.Auth);
pub const irq_busid = _iowr(0x03, types.IrqBusid);
pub const get_map = _iowr(0x04, types.Map);
pub const get_client = _iowr(0x05, types.Client);
pub const get_stats = _ior(0x06, types.Stats);
pub const set_version = _iowr(0x07, types.SetVersion);
pub const modeset_ctl = _iow(0x08, types.ModesetCtl);
pub const gem_close = _iow(0x09, types.GemClose);
pub const gem_flink = _iowr(0x0a, types.GemFlink);
pub const gem_open = _iowr(0x0b, types.GemOpen);
pub const get_cap = _iowr(0x0c, types.GetCap);
pub const set_client_cap = _iow(0x0d, types.SetClientCap);

pub const set_unique = _iow(0x10, types.Unique);
pub const auth_magic = _iow(0x11, types.Auth);
pub const block = _iowr(0x12, types.Block);
pub const unblock = _iowr(0x13, types.Block);
pub const control = _iow(0x14, types.Control);
pub const add_map = _iowr(0x15, types.Map);
pub const add_bufs = _iowr(0x16, types.BufDesc);
pub const mark_bufs = _iow(0x17, types.BufDesc);
pub const info_bufs = _iowr(0x18, types.BufInfo);
pub const map_bufs = _iowr(0x19, types.BufMap);
pub const free_bufs = _iow(0x1a, types.BufFree);

pub const rm_map = _iow(0x1b, types.Map);

pub const set_sarea_ctx = _iow(0x1c, types.CtxPrivMap);
pub const get_sarea_ctx = _iowr(0x1d, types.CtxPrivMap);

pub const set_master = _io(0x1e);
pub const drop_master = _io(0x1f);

pub const add_ctx = _iowr(0x20, types.Ctx);
pub const rm_ctx = _iowr(0x21, types.Ctx);
pub const mod_ctx = _iow(0x22, types.Ctx);
pub const get_ctx = _iowr(0x23, types.Ctx);
pub const switch_ctx = _iow(0x24, types.Ctx);
pub const new_ctx = _iow(0x25, types.Ctx);
pub const res_ctx = _iowr(0x26, types.CtxRes);
pub const add_draw = _iowr(0x27, types.Draw);
pub const rm_draw = _iowr(0x28, types.Draw);
pub const dma = _iowr(0x29, types.Dma);
pub const lock = _iow(0x2a, types.Lock);
pub const unlock = _iow(0x2b, types.Lock);
pub const finish = _iow(0x2c, types.Lock);

pub const prime_handle_to_fd = _iowr(0x2d, types.PrimeHandle);
pub const prime_fd_to_handle = _iowr(0x2e, types.PrimeHandle);

pub const agp_acquire = _io(0x30);
pub const agp_release = _io(0x31);
pub const agp_enable = _iow(0x32, types.AgpMode);
pub const agp_info = _ior(0x33, types.AgpInfo);
pub const agp_alloc = _iowr(0x34, types.AgpBuffer);
pub const agp_free = _iow(0x35, types.AgpBuffer);
pub const agp_bind = _iow(0x36, types.AgpBinding);
pub const agp_unbind = _iow(0x37, types.AgpBinding);

pub const sg_alloc = _iowr(0x38, types.ScatterGather);
pub const sg_free = _iow(0x39, types.ScatterGather);

pub const wait_vblank = _iowr(0x3a, types.WaitVblank);

pub const crtc_get_sequence = _iowr(0x3b, types.CrtcGetSequence);
pub const crtc_queue_sequence = _iowr(0x3c, types.CrtcQueueSequence);

pub const update_draw = _iow(0x3f, types.UpdateDraw);

pub const mode_getresources = _iowr(0xA0, types.ModeCardRes);
pub const mode_getcrtc = _iowr(0xA1, types.ModeCrtc);
pub const mode_setcrtc = _iowr(0xA2, types.ModeCrtc);
pub const mode_cursor = _iowr(0xA3, types.ModeCursor);
pub const mode_getgamma = _iowr(0xA4, types.ModeCrtcLut);
pub const mode_setgamma = _iowr(0xA5, types.ModeCrtcLut);
pub const mode_getencoder = _iowr(0xA6, types.ModeGetEncoder);
pub const mode_getconnector = _iowr(0xA7, types.ModeGetConnector);

pub const mode_getproperty = _iowr(0xAA, types.ModeGetProperty);
pub const mode_setproperty = _iowr(0xAB, types.ModeConnectorSetProperty);
pub const mode_getpropblob = _iowr(0xAC, types.ModeGetBlob);
pub const mode_getfb = _iowr(0xAD, types.ModeFbCmd);
pub const mode_addfb = _iowr(0xAE, types.ModeFbCmd);
pub const mode_rmfb = _iowr(0xAF, c_uint);
pub const mode_page_flip = _iowr(0xB0, types.ModeCrtcPageFlip);
pub const mode_dirtyfb = _iowr(0xB1, types.ModeFbDirtyCmd);

pub const mode_create_dumb = _iowr(0xB2, types.ModeCreateDumb);
pub const mode_map_dumb = _iowr(0xB3, types.ModeMapDumb);
pub const mode_destroy_dumb = _iowr(0xB4, types.ModeDestroyDumb);
pub const mode_getplaneresources = _iowr(0xB5, types.ModeGetPlaneRes);
pub const mode_getplane = _iowr(0xB6, types.ModeGetPlane);
pub const mode_setplane = _iowr(0xB7, types.ModeSetPlane);
pub const mode_addfb2 = _iowr(0xB8, types.ModeFbCmd2);
pub const mode_obj_getproperties = _iowr(0xB9, types.ModeObjGetProperties);
pub const mode_obj_setproperty = _iowr(0xBA, types.ModeObjSetProperty);
pub const mode_cursor2 = _iowr(0xBB, types.ModeCursor2);
pub const mode_atomic = _iowr(0xBC, types.ModeAtomic);
pub const mode_createpropblob = _iowr(0xBD, types.ModeCreateBlob);
pub const mode_destroypropblob = _iowr(0xBE, types.ModeDestroyBlob);

pub const syncobj_create = _iowr(0xBF, types.SyncobjCreate);
pub const syncobj_destroy = _iowr(0xC0, types.SyncobjDestroy);
pub const syncobj_handle_to_fd = _iowr(0xC1, types.SyncobjHandle);
pub const syncobj_fd_to_handle = _iowr(0xC2, types.SyncobjHandle);
pub const syncobj_wait = _iowr(0xC3, types.SyncobjWait);
pub const syncobj_reset = _iowr(0xC4, types.SyncobjArray);
pub const syncobj_signal = _iowr(0xC5, types.SyncobjArray);

pub const mode_create_lease = _iowr(0xC6, types.ModeCreateLease);
pub const mode_list_lessees = _iowr(0xC7, types.ModeListLessees);
pub const mode_get_lease = _iowr(0xC8, types.ModeGetLease);
pub const mode_revoke_lease = _iowr(0xC9, types.ModeRevokeLease);

pub const syncobj_timeline_wait = _iowr(0xCA, types.SyncobjTimelineWait);
pub const syncobj_query = _iowr(0xCB, types.SyncobjTimelineArray);
pub const syncobj_transfer = _iowr(0xCC, types.SyncobjTransfer);
pub const syncobj_timeline_signal = _iowr(0xCD, types.SyncobjTimelineArray);

pub const mode_getfb2 = _iowr(0xCE, types.ModeFbCmd2);
