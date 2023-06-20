const std = @import("std");

const c = @import("c.zig");

const common = @import("common");
const pointeeCast = common.pointeeCast;
const CBitFlags = common.CBitFlags;
const CEnum = common.CEnum;

pub const Direction = enum(c.hb_direction_t) {
    invalid = c.HB_DIRECTION_INVALID,
    ltr = c.HB_DIRECTION_LTR,
    rtl = c.HB_DIRECTION_RTL,
    ttb = c.HB_DIRECTION_TTB,
    btt = c.HB_DIRECTION_BTT,
    _,
};

pub const Script = enum(c.hb_script_t) {
    common = c.HB_SCRIPT_COMMON,
    inherited = c.HB_SCRIPT_INHERITED,
    unknown = c.HB_SCRIPT_UNKNOWN,
    arabic = c.HB_SCRIPT_ARABIC,
    armenian = c.HB_SCRIPT_ARMENIAN,
    bengali = c.HB_SCRIPT_BENGALI,
    cyrillic = c.HB_SCRIPT_CYRILLIC,
    devanagari = c.HB_SCRIPT_DEVANAGARI,
    georgian = c.HB_SCRIPT_GEORGIAN,
    greek = c.HB_SCRIPT_GREEK,
    gujarati = c.HB_SCRIPT_GUJARATI,
    gurmukhi = c.HB_SCRIPT_GURMUKHI,
    hangul = c.HB_SCRIPT_HANGUL,
    han = c.HB_SCRIPT_HAN,
    hebrew = c.HB_SCRIPT_HEBREW,
    hiragana = c.HB_SCRIPT_HIRAGANA,
    kannada = c.HB_SCRIPT_KANNADA,
    katakana = c.HB_SCRIPT_KATAKANA,
    lao = c.HB_SCRIPT_LAO,
    latin = c.HB_SCRIPT_LATIN,
    malayalam = c.HB_SCRIPT_MALAYALAM,
    oriya = c.HB_SCRIPT_ORIYA,
    tamil = c.HB_SCRIPT_TAMIL,
    telugu = c.HB_SCRIPT_TELUGU,
    thai = c.HB_SCRIPT_THAI,
    tibetan = c.HB_SCRIPT_TIBETAN,
    bopomofo = c.HB_SCRIPT_BOPOMOFO,
    braille = c.HB_SCRIPT_BRAILLE,
    canadian_syllabics = c.HB_SCRIPT_CANADIAN_SYLLABICS,
    cherokee = c.HB_SCRIPT_CHEROKEE,
    ethiopic = c.HB_SCRIPT_ETHIOPIC,
    khmer = c.HB_SCRIPT_KHMER,
    mongolian = c.HB_SCRIPT_MONGOLIAN,
    myanmar = c.HB_SCRIPT_MYANMAR,
    ogham = c.HB_SCRIPT_OGHAM,
    runic = c.HB_SCRIPT_RUNIC,
    sinhala = c.HB_SCRIPT_SINHALA,
    syriac = c.HB_SCRIPT_SYRIAC,
    thaana = c.HB_SCRIPT_THAANA,
    yi = c.HB_SCRIPT_YI,
    deseret = c.HB_SCRIPT_DESERET,
    gothic = c.HB_SCRIPT_GOTHIC,
    old_italic = c.HB_SCRIPT_OLD_ITALIC,
    buhid = c.HB_SCRIPT_BUHID,
    hanunoo = c.HB_SCRIPT_HANUNOO,
    tagalog = c.HB_SCRIPT_TAGALOG,
    tagbanwa = c.HB_SCRIPT_TAGBANWA,
    cypriot = c.HB_SCRIPT_CYPRIOT,
    limbu = c.HB_SCRIPT_LIMBU,
    linear_b = c.HB_SCRIPT_LINEAR_B,
    osmanya = c.HB_SCRIPT_OSMANYA,
    shavian = c.HB_SCRIPT_SHAVIAN,
    tai_le = c.HB_SCRIPT_TAI_LE,
    ugaritic = c.HB_SCRIPT_UGARITIC,
    buginese = c.HB_SCRIPT_BUGINESE,
    coptic = c.HB_SCRIPT_COPTIC,
    glagolitic = c.HB_SCRIPT_GLAGOLITIC,
    kharoshthi = c.HB_SCRIPT_KHAROSHTHI,
    new_tai_lue = c.HB_SCRIPT_NEW_TAI_LUE,
    old_persian = c.HB_SCRIPT_OLD_PERSIAN,
    syloti_nagri = c.HB_SCRIPT_SYLOTI_NAGRI,
    tifinagh = c.HB_SCRIPT_TIFINAGH,
    balinese = c.HB_SCRIPT_BALINESE,
    cuneiform = c.HB_SCRIPT_CUNEIFORM,
    nko = c.HB_SCRIPT_NKO,
    phags_pa = c.HB_SCRIPT_PHAGS_PA,
    phoenician = c.HB_SCRIPT_PHOENICIAN,
    carian = c.HB_SCRIPT_CARIAN,
    cham = c.HB_SCRIPT_CHAM,
    kayah_li = c.HB_SCRIPT_KAYAH_LI,
    lepcha = c.HB_SCRIPT_LEPCHA,
    lycian = c.HB_SCRIPT_LYCIAN,
    lydian = c.HB_SCRIPT_LYDIAN,
    ol_chiki = c.HB_SCRIPT_OL_CHIKI,
    rejang = c.HB_SCRIPT_REJANG,
    saurashtra = c.HB_SCRIPT_SAURASHTRA,
    sundanese = c.HB_SCRIPT_SUNDANESE,
    vai = c.HB_SCRIPT_VAI,
    avestan = c.HB_SCRIPT_AVESTAN,
    bamum = c.HB_SCRIPT_BAMUM,
    egyptian_hieroglyphs = c.HB_SCRIPT_EGYPTIAN_HIEROGLYPHS,
    imperial_aramaic = c.HB_SCRIPT_IMPERIAL_ARAMAIC,
    inscriptional_pahlavi = c.HB_SCRIPT_INSCRIPTIONAL_PAHLAVI,
    inscriptional_parthian = c.HB_SCRIPT_INSCRIPTIONAL_PARTHIAN,
    javanese = c.HB_SCRIPT_JAVANESE,
    kaithi = c.HB_SCRIPT_KAITHI,
    lisu = c.HB_SCRIPT_LISU,
    meetei_mayek = c.HB_SCRIPT_MEETEI_MAYEK,
    old_south_arabian = c.HB_SCRIPT_OLD_SOUTH_ARABIAN,
    old_turkic = c.HB_SCRIPT_OLD_TURKIC,
    samaritan = c.HB_SCRIPT_SAMARITAN,
    tai_tham = c.HB_SCRIPT_TAI_THAM,
    tai_viet = c.HB_SCRIPT_TAI_VIET,
    batak = c.HB_SCRIPT_BATAK,
    brahmi = c.HB_SCRIPT_BRAHMI,
    mandaic = c.HB_SCRIPT_MANDAIC,
    chakma = c.HB_SCRIPT_CHAKMA,
    meroitic_cursive = c.HB_SCRIPT_MEROITIC_CURSIVE,
    meroitic_hieroglyphs = c.HB_SCRIPT_MEROITIC_HIEROGLYPHS,
    miao = c.HB_SCRIPT_MIAO,
    sharada = c.HB_SCRIPT_SHARADA,
    sora_sompeng = c.HB_SCRIPT_SORA_SOMPENG,
    takri = c.HB_SCRIPT_TAKRI,
    bassa_vah = c.HB_SCRIPT_BASSA_VAH,
    caucasian_albanian = c.HB_SCRIPT_CAUCASIAN_ALBANIAN,
    duployan = c.HB_SCRIPT_DUPLOYAN,
    elbasan = c.HB_SCRIPT_ELBASAN,
    grantha = c.HB_SCRIPT_GRANTHA,
    khojki = c.HB_SCRIPT_KHOJKI,
    khudawadi = c.HB_SCRIPT_KHUDAWADI,
    linear_a = c.HB_SCRIPT_LINEAR_A,
    mahajani = c.HB_SCRIPT_MAHAJANI,
    manichaean = c.HB_SCRIPT_MANICHAEAN,
    mende_kikakui = c.HB_SCRIPT_MENDE_KIKAKUI,
    modi = c.HB_SCRIPT_MODI,
    mro = c.HB_SCRIPT_MRO,
    nabataean = c.HB_SCRIPT_NABATAEAN,
    old_north_arabian = c.HB_SCRIPT_OLD_NORTH_ARABIAN,
    old_permic = c.HB_SCRIPT_OLD_PERMIC,
    pahawh_hmong = c.HB_SCRIPT_PAHAWH_HMONG,
    palmyrene = c.HB_SCRIPT_PALMYRENE,
    pau_cin_hau = c.HB_SCRIPT_PAU_CIN_HAU,
    psalter_pahlavi = c.HB_SCRIPT_PSALTER_PAHLAVI,
    siddham = c.HB_SCRIPT_SIDDHAM,
    TIRHUTA = c.HB_SCRIPT_TIRHUTA,
    warang_citi = c.HB_SCRIPT_WARANG_CITI,
    ahom = c.HB_SCRIPT_AHOM,
    anatolian_hieroglyphs = c.HB_SCRIPT_ANATOLIAN_HIEROGLYPHS,
    hatran = c.HB_SCRIPT_HATRAN,
    multani = c.HB_SCRIPT_MULTANI,
    old_hungarian = c.HB_SCRIPT_OLD_HUNGARIAN,
    signwriting = c.HB_SCRIPT_SIGNWRITING,
    adlam = c.HB_SCRIPT_ADLAM,
    bhaiksuki = c.HB_SCRIPT_BHAIKSUKI,
    marchen = c.HB_SCRIPT_MARCHEN,
    osage = c.HB_SCRIPT_OSAGE,
    tangut = c.HB_SCRIPT_TANGUT,
    newa = c.HB_SCRIPT_NEWA,
    masaram_gondi = c.HB_SCRIPT_MASARAM_GONDI,
    nushu = c.HB_SCRIPT_NUSHU,
    soyombo = c.HB_SCRIPT_SOYOMBO,
    zanabazar_square = c.HB_SCRIPT_ZANABAZAR_SQUARE,
    dogra = c.HB_SCRIPT_DOGRA,
    gunjala_gondi = c.HB_SCRIPT_GUNJALA_GONDI,
    hanifi_rohingya = c.HB_SCRIPT_HANIFI_ROHINGYA,
    makasar = c.HB_SCRIPT_MAKASAR,
    medefaidrin = c.HB_SCRIPT_MEDEFAIDRIN,
    old_sogdian = c.HB_SCRIPT_OLD_SOGDIAN,
    sogdian = c.HB_SCRIPT_SOGDIAN,
    elymaic = c.HB_SCRIPT_ELYMAIC,
    nandinagari = c.HB_SCRIPT_NANDINAGARI,
    nyiakeng_puachue_hmong = c.HB_SCRIPT_NYIAKENG_PUACHUE_HMONG,
    wancho = c.HB_SCRIPT_WANCHO,
    chorasmian = c.HB_SCRIPT_CHORASMIAN,
    dives_akuru = c.HB_SCRIPT_DIVES_AKURU,
    khitan_small_script = c.HB_SCRIPT_KHITAN_SMALL_SCRIPT,
    yezidi = c.HB_SCRIPT_YEZIDI,
    cypro_minoan = c.HB_SCRIPT_CYPRO_MINOAN,
    old_uyghur = c.HB_SCRIPT_OLD_UYGHUR,
    tangsa = c.HB_SCRIPT_TANGSA,
    toto = c.HB_SCRIPT_TOTO,
    vithkuqi = c.HB_SCRIPT_VITHKUQI,
    math = c.HB_SCRIPT_MATH,
    kawi = c.HB_SCRIPT_KAWI,
    nag_mundari = c.HB_SCRIPT_NAG_MUNDARI,
    invalid = c.HB_SCRIPT_INVALID,
    _,
};

pub const DestroyFunc = *const fn (?*anyopaque) callconv(.C) void;

pub const Blob = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.hb_blob_t, self)) {
        return pointeeCast(c.hb_blob_t, self);
    }

    pub const MemoryMode = enum(c.hb_memory_mode_t) {
        duplicate = c.HB_MEMORY_MODE_DUPLICATE,
        readonly = c.HB_MEMORY_MODE_READONLY,
        writable = c.HB_MEMORY_MODE_WRITABLE,
        readonly_may_make_writable = c.HB_MEMORY_MODE_READONLY_MAY_MAKE_WRITABLE,
    };

    pub const CreateOptions = struct {
        data: Data,
        user_data: ?*anyopaque = null,
        destroy: ?DestroyFunc = null,

        pub const Data = union(MemoryMode) {
            duplicate: []const u8,
            readonly: []const u8,
            writable: []u8,
            readonly_may_make_writable: []const u8,

            fn toConstSlice(self: @This()) []const u8 {
                return switch (self) {
                    inline else => |data| data,
                };
            }
        };
    };

    fn checkLen(len: usize) c_uint {
        return std.math.cast(c_uint, len) orelse @panic("maximum blob length exceeded");
    }

    pub fn create(options: CreateOptions) *@This() {
        const data = options.data.toConstSlice();
        return pointeeCast(@This(), c.hb_blob_create(
            data.ptr,
            checkLen(data.len),
            @enumToInt(options.data),
            options.user_data,
            options.destroy,
        ).?);
    }

    pub fn createOrFail(options: CreateOptions) ?*@This() {
        const data = options.data.toConstSlice();
        return pointeeCast(@This(), c.hb_blob_create_or_fail(
            data.ptr,
            checkLen(data.len),
            @enumToInt(options.data),
            options.user_data,
            options.destroy,
        ));
    }

    pub fn createFromFile(file_name: [*:0]const u8) *@This() {
        return pointeeCast(@This(), c.hb_blob_create_from_file(file_name).?);
    }

    pub fn createFromFileOrFail(file_name: [*:0]const u8) ?*@This() {
        return pointeeCast(@This(), c.hb_blob_create_from_file_or_fail(file_name));
    }

    pub fn createSubBlob(self: *@This(), offset: c_uint, length: c_uint) *@This() {
        return pointeeCast(@This(), c.hb_blob_create_sub_blob(self.toC(), offset, length).?);
    }

    pub fn copyWritableOrFail(self: *@This()) ?*@This() {
        return pointeeCast(@This(), c.hb_blob_copy_writable_or_fail(self.toC()));
    }

    pub fn getEmpty() *@This() {
        return pointeeCast(@This(), c.hb_blob_get_empty().?);
    }

    pub fn retain(self: *@This()) void {
        _ = c.hb_blob_reference(self.toC());
    }

    pub fn release(self: *@This()) void {
        c.hb_blob_destroy(self.toC());
    }

    pub fn makeImmutable(self: *@This()) void {
        c.hb_blob_make_immutable(self.toC());
    }

    pub fn isImmutable(self: *@This()) bool {
        return c.hb_blob_is_immutable(self.toC()) != 0;
    }

    pub fn getData(self: *@This()) []const u8 {
        var len: c_uint = undefined;
        const data = c.hb_blob_get_data(self.toC(), &len);
        return if (len == 0) &.{} else data[0..len];
    }

    pub fn getDataWritable(self: *@This()) ?[]u8 {
        var len: c_uint = undefined;
        const data = c.hb_blob_get_data_writable(self.toC(), &len) orelse return null;
        return data[0..len];
    }

    pub fn getLength(self: *@This()) c_uint {
        return c.hb_blob_get_length(self.toC());
    }
};

pub const Buffer = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.hb_buffer_t, self)) {
        return pointeeCast(c.hb_buffer_t, self);
    }

    pub fn create() *@This() {
        return pointeeCast(@This(), c.hb_buffer_create().?);
    }

    pub fn allocationSuccessful(self: *@This()) bool {
        return c.hb_buffer_allocation_successful(self.toC()) != 0;
    }

    pub fn createSimilar(self: *@This()) *@This() {
        return pointeeCast(@This(), c.hb_buffer_create_similar(self.toC()).?);
    }

    pub fn getEmpty() *@This() {
        return pointeeCast(@This(), c.hb_buffer_get_empty().?);
    }

    pub fn retain(self: *@This()) void {
        _ = c.hb_buffer_reference(self.toC());
    }

    pub fn release(self: *@This()) void {
        c.hb_buffer_destroy(self.toC());
    }

    pub fn reset(self: *@This()) void {
        c.hb_buffer_reset(self.toC());
    }

    pub fn clearContents(self: *@This()) void {
        c.hb_buffer_clear_contents(self.toC());
    }

    pub fn preallocate(self: *@This(), size: c_uint) !void {
        if (c.hb_buffer_pre_allocate(self.toC(), size) == 0) {
            return error.OutOfMemory;
        }
    }

    pub fn add(self: *@This(), codepoint: u21, cluster: c_uint) void {
        std.debug.assert(std.unicode.utf8ValidCodepoint(codepoint));
        c.hb_buffer_add(self.toC(), codepoint, cluster);
    }

    fn checkTextLen(len: usize) c_int {
        return std.math.cast(c_int, len) orelse @panic("maximum text length exceeded");
    }

    pub const ItemLength = std.meta.Int(.unsigned, @bitSizeOf(c_int) - 1);

    pub fn addCodepoints(
        self: *@This(),
        text: []const u21,
        item_offset: c_uint,
        item_length: ItemLength,
    ) void {
        c.hb_buffer_add_codepoints(
            self.toC(),
            @ptrCast([*]const u32, text.ptr),
            checkTextLen(text.len),
            item_offset,
            item_length,
        );
    }

    pub fn addUtf32(
        self: *@This(),
        text: []const u32,
        item_offset: c_uint,
        item_length: ItemLength,
    ) void {
        c.hb_buffer_add_utf32(
            self.toC(),
            text.ptr,
            checkTextLen(text.len),
            item_offset,
            item_length,
        );
    }

    pub fn addUtf16(
        self: *@This(),
        text: []const u16,
        item_offset: c_uint,
        item_length: ItemLength,
    ) void {
        c.hb_buffer_add_utf16(
            self.toC(),
            text.ptr,
            checkTextLen(text.len),
            item_offset,
            item_length,
        );
    }

    pub fn addUtf8(
        self: *@This(),
        text: []const u8,
        item_offset: c_uint,
        item_length: ItemLength,
    ) void {
        c.hb_buffer_add_utf8(
            self.toC(),
            text.ptr,
            checkTextLen(text.len),
            item_offset,
            item_length,
        );
    }

    pub fn addLatin1(
        self: *@This(),
        text: []const u8,
        item_offset: c_uint,
        item_length: ItemLength,
    ) void {
        c.hb_buffer_add_latin1(
            self.toC(),
            text.ptr,
            checkTextLen(text.len),
            item_offset,
            item_length,
        );
    }

    pub fn append(self: *@This(), source: *const @This(), start: c_uint, end: ?c_uint) void {
        c.hb_buffer_append(self.toC(), source.toC(), start, end orelse c.HB_FEATURE_GLOBAL_END);
    }

    pub const ContentType = enum(c.hb_buffer_content_type_t) {
        invalid = c.HB_BUFFER_CONTENT_TYPE_INVALID,
        unicode = c.HB_BUFFER_CONTENT_TYPE_UNICODE,
        glyphs = c.HB_BUFFER_CONTENT_TYPE_GLYPHS,
        _,
    };

    pub fn setContentType(self: *@This(), content_type: ContentType) void {
        c.hb_buffer_set_content_type(self.toC(), @enumToInt(content_type));
    }

    pub fn getContentType(self: *const @This()) ContentType {
        return @intToEnum(ContentType, c.hb_buffer_get_content_type(self.toC()));
    }

    pub fn setDirection(self: *@This(), direction: Direction) void {
        c.hb_buffer_set_direction(self.toC(), @enumToInt(direction));
    }

    pub fn getDirection(self: *const @This()) Direction {
        return @intToEnum(Direction, c.hb_buffer_get_direction(self.toC()));
    }

    pub fn setScript(self: *@This(), script: Script) void {
        c.hb_buffer_set_script(self.toC(), @enumToInt(script));
    }

    pub fn getScript(self: *const @This()) Script {
        return @intToEnum(Script, c.hb_buffer_get_script(self.toC()));
    }

    pub fn setLanguage(self: *@This(), language: *const Language) void {
        c.hb_buffer_set_language(self.toC(), language.toC());
    }

    pub fn getLanguage(self: *const @This()) ?*const Language {
        return pointeeCast(Language, c.hb_buffer_get_language(self.toC()));
    }

    pub const Flags = CBitFlags(c.hb_buffer_flags_t, c, .{
        .{ "HB_BUFFER_FLAG_BOT", "bot" },
        .{ "HB_BUFFER_FLAG_EOT", "eot" },
        .{ "HB_BUFFER_FLAG_PRESERVE_DEFAULT_IGNORABLES", "preserve_default_ignorables" },
        .{ "HB_BUFFER_FLAG_REMOVE_DEFAULT_IGNORABLES", "remove_default_ignorables" },
        .{ "HB_BUFFER_FLAG_DO_NOT_INSERT_DOTTED_CIRCLE", "do_not_insert_dotted_circle" },
        .{ "HB_BUFFER_FLAG_VERIFY", "verify" },
        .{ "HB_BUFFER_FLAG_PRODUCE_UNSAFE_TO_CONCAT", "produce_unsafe_to_concat" },
        .{ "HB_BUFFER_FLAG_PRODUCE_SAFE_TO_INSERT_TATWEEL", "produce_safe_to_insert_tatweel" },
    });

    pub fn setFlags(self: *@This(), flags: Flags) void {
        c.hb_buffer_set_flags(self.toC(), @bitCast(c.hb_buffer_flags_t, flags));
    }

    pub fn getFlags(self: *const @This()) Flags {
        return @bitCast(Flags, c.hb_buffer_get_flags(self.toC()));
    }

    pub const ClusterLevel = CEnum(c.hb_buffer_cluster_level_t, c, .{
        .{ "HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES", "monotone_graphemes" },
        .{ "HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS", "monotone_characters" },
        .{ "HB_BUFFER_CLUSTER_LEVEL_CHARACTERS", "characters" },
    });

    pub fn setClusterLevel(self: *@This(), cluster_level: ClusterLevel) void {
        c.hb_buffer_set_cluster_level(self.toC(), @enumToInt(cluster_level));
    }

    pub fn getClusterLevel(self: *const @This()) ClusterLevel {
        return @intToEnum(ClusterLevel, c.hb_buffer_get_cluster_level(self.toC()));
    }

    pub fn setLength(self: *@This(), length: c_uint) !void {
        if (c.hb_buffer_set_length(self.toC(), length) == 0) {
            return error.OutOfMemory;
        }
    }

    pub fn getLength(self: *const @This()) c_uint {
        return c.hb_buffer_get_length(self.toC());
    }

    pub const SegmentProperties = struct {
        direction: Direction,
        script: Script,
        language: ?*const Language,
    };

    pub fn setSegmentProperties(self: *@This(), properties: SegmentProperties) void {
        var c_properties = std.mem.zeroes(c.hb_segment_properties_t);
        c_properties.direction = @enumToInt(properties.direction);
        c_properties.script = @enumToInt(properties.script);
        c_properties.language = Language.toC(properties.language);
        c.hb_buffer_set_segment_properties(self.toC(), &c_properties);
    }

    pub fn getSegmentProperties(self: *const @This()) SegmentProperties {
        var c_properties: c.hb_segment_properties_t = undefined;
        c.hb_buffer_get_segment_properties(self.toC(), &c_properties);
        return .{
            .direction = @intToEnum(Direction, c_properties.direction),
            .script = @intToEnum(Script, c_properties.script),
            .language = pointeeCast(Language, c_properties.language),
        };
    }

    pub fn guessSegmentProperties(self: *@This()) void {
        c.hb_buffer_guess_segment_properties(self.toC());
    }

    pub fn setUnicodeFuncs(self: *@This(), unicode_funcs: *UnicodeFuncs) void {
        c.hb_buffer_set_unicode_funcs(self.toC(), unicode_funcs.toC());
    }

    pub fn getUnicodeFuncs(self: *const @This()) ?*UnicodeFuncs {
        return pointeeCast(UnicodeFuncs, c.hb_buffer_get_unicode_funcs(self.toC()));
    }

    pub fn getGlyphInfos(self: *@This()) []c.hb_glyph_info_t {
        var len: c_uint = undefined;
        const ptr = c.hb_buffer_get_glyph_infos(self.toC(), &len);
        return if (len == 0) &.{} else ptr[0..len];
    }

    pub fn getGlyphPositions(self: *@This()) []c.hb_glyph_position_t {
        var len: c_uint = undefined;
        const ptr = c.hb_buffer_get_glyph_positions(self.toC(), &len);
        return if (len == 0) &.{} else ptr[0..len];
    }

    pub fn hasGlyphPositions(self: *@This()) bool {
        return c.hb_buffer_has_positions(self.toC()) != 0;
    }
};

pub const Language = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.hb_language_impl_t, self)) {
        return pointeeCast(c.hb_language_impl_t, self);
    }
};

pub const UnicodeFuncs = opaque {
    fn toC(self: anytype) @TypeOf(pointeeCast(c.hb_unicode_funcs_t, self)) {
        return pointeeCast(c.hb_unicode_funcs_t, self);
    }
};

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(Blob);
    std.testing.refAllDecls(Buffer);
}
