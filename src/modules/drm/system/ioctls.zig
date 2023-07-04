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

pub const ioctl_version = iowr(0x00, types.Version);
pub const ioctl_get_unique = iowr(0x01, types.Unique);
pub const ioctl_get_magic = ior(0x02, types.Auth);
pub const ioctl_irq_busid = iowr(0x03, types.IrqBusid);
pub const ioctl_get_map = iowr(0x04, types.Map);
pub const ioctl_get_client = iowr(0x05, types.Client);
pub const ioctl_get_stats = ior(0x06, types.Stats);
pub const ioctl_set_version = iowr(0x07, types.SetVersion);
pub const ioctl_modeset_ctl = iow(0x08, types.ModesetCtl);
pub const ioctl_gem_close = iow(0x09, types.GemClose);
pub const ioctl_gem_flink = iowr(0x0a, types.GemFlink);
pub const ioctl_gem_open = iowr(0x0b, types.GemOpen);
pub const ioctl_get_cap = iowr(0x0c, types.GetCap);
pub const ioctl_set_client_cap = iow(0x0d, types.SetClientCap);

pub const ioctl_set_unique = iow(0x10, types.Unique);
pub const ioctl_auth_magic = iow(0x11, types.Auth);
pub const ioctl_block = iowr(0x12, types.Block);
pub const ioctl_unblock = iowr(0x13, types.Block);
pub const ioctl_control = iow(0x14, types.Control);
pub const ioctl_add_map = iowr(0x15, types.Map);
pub const ioctl_add_bufs = iowr(0x16, types.BufDesc);
pub const ioctl_mark_bufs = iow(0x17, types.BufDesc);
pub const ioctl_info_bufs = iowr(0x18, types.BufInfo);
pub const ioctl_map_bufs = iowr(0x19, types.BufMap);
pub const ioctl_free_bufs = iow(0x1a, types.BufFree);

pub const ioctl_rm_map = iow(0x1b, types.Map);

pub const ioctl_set_sarea_ctx = iow(0x1c, types.CtxPrivMap);
pub const ioctl_get_sarea_ctx = iowr(0x1d, types.CtxPrivMap);

pub const ioctl_set_master = io(0x1e);
pub const ioctl_drop_master = io(0x1f);

pub const ioctl_add_ctx = iowr(0x20, types.Ctx);
pub const ioctl_rm_ctx = iowr(0x21, types.Ctx);
pub const ioctl_mod_ctx = iow(0x22, types.Ctx);
pub const ioctl_get_ctx = iowr(0x23, types.Ctx);
pub const ioctl_switch_ctx = iow(0x24, types.Ctx);
pub const ioctl_new_ctx = iow(0x25, types.Ctx);
pub const ioctl_res_ctx = iowr(0x26, types.CtxRes);
pub const ioctl_add_draw = iowr(0x27, types.Draw);
pub const ioctl_rm_draw = iowr(0x28, types.Draw);
pub const ioctl_dma = iowr(0x29, types.Dma);
pub const ioctl_lock = iow(0x2a, types.Lock);
pub const ioctl_unlock = iow(0x2b, types.Lock);
pub const ioctl_finish = iow(0x2c, types.Lock);

pub const ioctl_prime_handle_to_fd = iowr(0x2d, types.PrimeHandle);
pub const ioctl_prime_fd_to_handle = iowr(0x2e, types.PrimeHandle);

pub const ioctl_agp_acquire = io(0x30);
pub const ioctl_agp_release = io(0x31);
pub const ioctl_agp_enable = iow(0x32, types.AgpMode);
pub const ioctl_agp_info = ior(0x33, types.AgpInfo);
pub const ioctl_agp_alloc = iowr(0x34, types.AgpBuffer);
pub const ioctl_agp_free = iow(0x35, types.AgpBuffer);
pub const ioctl_agp_bind = iow(0x36, types.AgpBinding);
pub const ioctl_agp_unbind = iow(0x37, types.AgpBinding);

pub const ioctl_sg_alloc = iowr(0x38, types.ScatterGather);
pub const ioctl_sg_free = iow(0x39, types.ScatterGather);

pub const ioctl_wait_vblank = iowr(0x3a, types.WaitVblank);

pub const ioctl_crtc_get_sequence = iowr(0x3b, types.CrtcGetSequence);
pub const ioctl_crtc_queue_sequence = iowr(0x3c, types.CrtcQueueSequence);

pub const ioctl_update_draw = iow(0x3f, types.UpdateDraw);

pub const ioctl_mode_getresources = iowr(0xA0, types.ModeCardRes);
pub const ioctl_mode_getcrtc = iowr(0xA1, types.ModeCrtc);
pub const ioctl_mode_setcrtc = iowr(0xA2, types.ModeCrtc);
pub const ioctl_mode_cursor = iowr(0xA3, types.ModeCursor);
pub const ioctl_mode_getgamma = iowr(0xA4, types.ModeCrtcLut);
pub const ioctl_mode_setgamma = iowr(0xA5, types.ModeCrtcLut);
pub const ioctl_mode_getencoder = iowr(0xA6, types.ModeGetEncoder);
pub const ioctl_mode_getconnector = iowr(0xA7, types.ModeGetConnector);

pub const ioctl_mode_getproperty = iowr(0xAA, types.ModeGetProperty);
pub const ioctl_mode_setproperty = iowr(0xAB, types.ModeConnectorSetProperty);
pub const ioctl_mode_getpropblob = iowr(0xAC, types.ModeGetBlob);
pub const ioctl_mode_getfb = iowr(0xAD, types.ModeFbCmd);
pub const ioctl_mode_addfb = iowr(0xAE, types.ModeFbCmd);
pub const ioctl_mode_rmfb = iowr(0xAF, c_uint);
pub const ioctl_mode_page_flip = iowr(0xB0, types.ModeCrtcPageFlip);
pub const ioctl_mode_dirtyfb = iowr(0xB1, types.ModeFbDirtyCmd);

pub const ioctl_mode_create_dumb = iowr(0xB2, types.ModeCreateDumb);
pub const ioctl_mode_map_dumb = iowr(0xB3, types.ModeMapDumb);
pub const ioctl_mode_destroy_dumb = iowr(0xB4, types.ModeDestroyDumb);
pub const ioctl_mode_getplaneresources = iowr(0xB5, types.ModeGetPlaneRes);
pub const ioctl_mode_getplane = iowr(0xB6, types.ModeGetPlane);
pub const ioctl_mode_setplane = iowr(0xB7, types.ModeSetPlane);
pub const ioctl_mode_addfb2 = iowr(0xB8, types.ModeFbCmd2);
pub const ioctl_mode_obj_getproperties = iowr(0xB9, types.ModeObjGetProperties);
pub const ioctl_mode_obj_setproperty = iowr(0xBA, types.ModeObjSetProperty);
pub const ioctl_mode_cursor2 = iowr(0xBB, types.ModeCursor2);
pub const ioctl_mode_atomic = iowr(0xBC, types.ModeAtomic);
pub const ioctl_mode_createpropblob = iowr(0xBD, types.ModeCreateBlob);
pub const ioctl_mode_destroypropblob = iowr(0xBE, types.ModeDestroyBlob);

pub const ioctl_syncobj_create = iowr(0xBF, types.SyncobjCreate);
pub const ioctl_syncobj_destroy = iowr(0xC0, types.SyncobjDestroy);
pub const ioctl_syncobj_handle_to_fd = iowr(0xC1, types.SyncobjHandle);
pub const ioctl_syncobj_fd_to_handle = iowr(0xC2, types.SyncobjHandle);
pub const ioctl_syncobj_wait = iowr(0xC3, types.SyncobjWait);
pub const ioctl_syncobj_reset = iowr(0xC4, types.SyncobjArray);
pub const ioctl_syncobj_signal = iowr(0xC5, types.SyncobjArray);

pub const ioctl_mode_create_lease = iowr(0xC6, types.ModeCreateLease);
pub const ioctl_mode_list_lessees = iowr(0xC7, types.ModeListLessees);
pub const ioctl_mode_get_lease = iowr(0xC8, types.ModeGetLease);
pub const ioctl_mode_revoke_lease = iowr(0xC9, types.ModeRevokeLease);

pub const ioctl_syncobj_timeline_wait = iowr(0xCA, types.SyncobjTimelineWait);
pub const ioctl_syncobj_query = iowr(0xCB, types.SyncobjTimelineArray);
pub const ioctl_syncobj_transfer = iowr(0xCC, types.SyncobjTransfer);
pub const ioctl_syncobj_timeline_signal = iowr(0xCD, types.SyncobjTimelineArray);

pub const ioctl_mode_getfb2 = iowr(0xCE, types.ModeFbCmd2);
