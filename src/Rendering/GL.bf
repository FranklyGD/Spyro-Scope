using System;

// This file has been generated using MineGame159's OpenGL Loader Generator
// The generator can be found at: https://github.com/MineGame159/opengl-beef
// Last generated at November 11, 2020 with parameter "glVersion" as "4.6"

namespace OpenGL {
    class GL {
        public function void* GetProcAddressFunc(StringView procname);

        public const uint GL_DEPTH_BUFFER_BIT = 0x00000100;
        public const uint GL_STENCIL_BUFFER_BIT = 0x00000400;
        public const uint GL_COLOR_BUFFER_BIT = 0x00004000;
        public const uint GL_FALSE = 0;
        public const uint GL_TRUE = 1;
        public const uint GL_POINTS = 0x0000;
        public const uint GL_LINES = 0x0001;
        public const uint GL_LINE_LOOP = 0x0002;
        public const uint GL_LINE_STRIP = 0x0003;
        public const uint GL_TRIANGLES = 0x0004;
        public const uint GL_TRIANGLE_STRIP = 0x0005;
        public const uint GL_TRIANGLE_FAN = 0x0006;
        public const uint GL_NEVER = 0x0200;
        public const uint GL_LESS = 0x0201;
        public const uint GL_EQUAL = 0x0202;
        public const uint GL_LEQUAL = 0x0203;
        public const uint GL_GREATER = 0x0204;
        public const uint GL_NOTEQUAL = 0x0205;
        public const uint GL_GEQUAL = 0x0206;
        public const uint GL_ALWAYS = 0x0207;
        public const uint GL_ZERO = 0;
        public const uint GL_ONE = 1;
        public const uint GL_SRC_COLOR = 0x0300;
        public const uint GL_ONE_MINUS_SRC_COLOR = 0x0301;
        public const uint GL_SRC_ALPHA = 0x0302;
        public const uint GL_ONE_MINUS_SRC_ALPHA = 0x0303;
        public const uint GL_DST_ALPHA = 0x0304;
        public const uint GL_ONE_MINUS_DST_ALPHA = 0x0305;
        public const uint GL_DST_COLOR = 0x0306;
        public const uint GL_ONE_MINUS_DST_COLOR = 0x0307;
        public const uint GL_SRC_ALPHA_SATURATE = 0x0308;
        public const uint GL_NONE = 0;
        public const uint GL_FRONT_LEFT = 0x0400;
        public const uint GL_FRONT_RIGHT = 0x0401;
        public const uint GL_BACK_LEFT = 0x0402;
        public const uint GL_BACK_RIGHT = 0x0403;
        public const uint GL_FRONT = 0x0404;
        public const uint GL_BACK = 0x0405;
        public const uint GL_LEFT = 0x0406;
        public const uint GL_RIGHT = 0x0407;
        public const uint GL_FRONT_AND_BACK = 0x0408;
        public const uint GL_NO_ERROR = 0;
        public const uint GL_INVALID_ENUM = 0x0500;
        public const uint GL_INVALID_VALUE = 0x0501;
        public const uint GL_INVALID_OPERATION = 0x0502;
        public const uint GL_OUT_OF_MEMORY = 0x0505;
        public const uint GL_CW = 0x0900;
        public const uint GL_CCW = 0x0901;
        public const uint GL_POINT_SIZE = 0x0B11;
        public const uint GL_POINT_SIZE_RANGE = 0x0B12;
        public const uint GL_POINT_SIZE_GRANULARITY = 0x0B13;
        public const uint GL_LINE_SMOOTH = 0x0B20;
        public const uint GL_LINE_WIDTH = 0x0B21;
        public const uint GL_LINE_WIDTH_RANGE = 0x0B22;
        public const uint GL_LINE_WIDTH_GRANULARITY = 0x0B23;
        public const uint GL_POLYGON_MODE = 0x0B40;
        public const uint GL_POLYGON_SMOOTH = 0x0B41;
        public const uint GL_CULL_FACE = 0x0B44;
        public const uint GL_CULL_FACE_MODE = 0x0B45;
        public const uint GL_FRONT_FACE = 0x0B46;
        public const uint GL_DEPTH_RANGE = 0x0B70;
        public const uint GL_DEPTH_TEST = 0x0B71;
        public const uint GL_DEPTH_WRITEMASK = 0x0B72;
        public const uint GL_DEPTH_CLEAR_VALUE = 0x0B73;
        public const uint GL_DEPTH_FUNC = 0x0B74;
        public const uint GL_STENCIL_TEST = 0x0B90;
        public const uint GL_STENCIL_CLEAR_VALUE = 0x0B91;
        public const uint GL_STENCIL_FUNC = 0x0B92;
        public const uint GL_STENCIL_VALUE_MASK = 0x0B93;
        public const uint GL_STENCIL_FAIL = 0x0B94;
        public const uint GL_STENCIL_PASS_DEPTH_FAIL = 0x0B95;
        public const uint GL_STENCIL_PASS_DEPTH_PASS = 0x0B96;
        public const uint GL_STENCIL_REF = 0x0B97;
        public const uint GL_STENCIL_WRITEMASK = 0x0B98;
        public const uint GL_VIEWPORT = 0x0BA2;
        public const uint GL_DITHER = 0x0BD0;
        public const uint GL_BLEND_DST = 0x0BE0;
        public const uint GL_BLEND_SRC = 0x0BE1;
        public const uint GL_BLEND = 0x0BE2;
        public const uint GL_LOGIC_OP_MODE = 0x0BF0;
        public const uint GL_DRAW_BUFFER = 0x0C01;
        public const uint GL_READ_BUFFER = 0x0C02;
        public const uint GL_SCISSOR_BOX = 0x0C10;
        public const uint GL_SCISSOR_TEST = 0x0C11;
        public const uint GL_COLOR_CLEAR_VALUE = 0x0C22;
        public const uint GL_COLOR_WRITEMASK = 0x0C23;
        public const uint GL_DOUBLEBUFFER = 0x0C32;
        public const uint GL_STEREO = 0x0C33;
        public const uint GL_LINE_SMOOTH_HINT = 0x0C52;
        public const uint GL_POLYGON_SMOOTH_HINT = 0x0C53;
        public const uint GL_UNPACK_SWAP_BYTES = 0x0CF0;
        public const uint GL_UNPACK_LSB_FIRST = 0x0CF1;
        public const uint GL_UNPACK_ROW_LENGTH = 0x0CF2;
        public const uint GL_UNPACK_SKIP_ROWS = 0x0CF3;
        public const uint GL_UNPACK_SKIP_PIXELS = 0x0CF4;
        public const uint GL_UNPACK_ALIGNMENT = 0x0CF5;
        public const uint GL_PACK_SWAP_BYTES = 0x0D00;
        public const uint GL_PACK_LSB_FIRST = 0x0D01;
        public const uint GL_PACK_ROW_LENGTH = 0x0D02;
        public const uint GL_PACK_SKIP_ROWS = 0x0D03;
        public const uint GL_PACK_SKIP_PIXELS = 0x0D04;
        public const uint GL_PACK_ALIGNMENT = 0x0D05;
        public const uint GL_MAX_TEXTURE_SIZE = 0x0D33;
        public const uint GL_MAX_VIEWPORT_DIMS = 0x0D3A;
        public const uint GL_SUBPIXEL_BITS = 0x0D50;
        public const uint GL_TEXTURE_1D = 0x0DE0;
        public const uint GL_TEXTURE_2D = 0x0DE1;
        public const uint GL_TEXTURE_WIDTH = 0x1000;
        public const uint GL_TEXTURE_HEIGHT = 0x1001;
        public const uint GL_TEXTURE_BORDER_COLOR = 0x1004;
        public const uint GL_DONT_CARE = 0x1100;
        public const uint GL_FASTEST = 0x1101;
        public const uint GL_NICEST = 0x1102;
        public const uint GL_BYTE = 0x1400;
        public const uint GL_UNSIGNED_BYTE = 0x1401;
        public const uint GL_SHORT = 0x1402;
        public const uint GL_UNSIGNED_SHORT = 0x1403;
        public const uint GL_INT = 0x1404;
        public const uint GL_UNSIGNED_INT = 0x1405;
        public const uint GL_FLOAT = 0x1406;
        public const uint GL_CLEAR = 0x1500;
        public const uint GL_AND = 0x1501;
        public const uint GL_AND_REVERSE = 0x1502;
        public const uint GL_COPY = 0x1503;
        public const uint GL_AND_INVERTED = 0x1504;
        public const uint GL_NOOP = 0x1505;
        public const uint GL_XOR = 0x1506;
        public const uint GL_OR = 0x1507;
        public const uint GL_NOR = 0x1508;
        public const uint GL_EQUIV = 0x1509;
        public const uint GL_INVERT = 0x150A;
        public const uint GL_OR_REVERSE = 0x150B;
        public const uint GL_COPY_INVERTED = 0x150C;
        public const uint GL_OR_INVERTED = 0x150D;
        public const uint GL_NAND = 0x150E;
        public const uint GL_SET = 0x150F;
        public const uint GL_TEXTURE = 0x1702;
        public const uint GL_COLOR = 0x1800;
        public const uint GL_DEPTH = 0x1801;
        public const uint GL_STENCIL = 0x1802;
        public const uint GL_STENCIL_INDEX = 0x1901;
        public const uint GL_DEPTH_COMPONENT = 0x1902;
        public const uint GL_RED = 0x1903;
        public const uint GL_GREEN = 0x1904;
        public const uint GL_BLUE = 0x1905;
        public const uint GL_ALPHA = 0x1906;
        public const uint GL_RGB = 0x1907;
        public const uint GL_RGBA = 0x1908;
        public const uint GL_POINT = 0x1B00;
        public const uint GL_LINE = 0x1B01;
        public const uint GL_FILL = 0x1B02;
        public const uint GL_KEEP = 0x1E00;
        public const uint GL_REPLACE = 0x1E01;
        public const uint GL_INCR = 0x1E02;
        public const uint GL_DECR = 0x1E03;
        public const uint GL_VENDOR = 0x1F00;
        public const uint GL_RENDERER = 0x1F01;
        public const uint GL_VERSION = 0x1F02;
        public const uint GL_EXTENSIONS = 0x1F03;
        public const uint GL_NEAREST = 0x2600;
        public const uint GL_LINEAR = 0x2601;
        public const uint GL_NEAREST_MIPMAP_NEAREST = 0x2700;
        public const uint GL_LINEAR_MIPMAP_NEAREST = 0x2701;
        public const uint GL_NEAREST_MIPMAP_LINEAR = 0x2702;
        public const uint GL_LINEAR_MIPMAP_LINEAR = 0x2703;
        public const uint GL_TEXTURE_MAG_FILTER = 0x2800;
        public const uint GL_TEXTURE_MIN_FILTER = 0x2801;
        public const uint GL_TEXTURE_WRAP_S = 0x2802;
        public const uint GL_TEXTURE_WRAP_T = 0x2803;
        public const uint GL_REPEAT = 0x2901;
        public const uint GL_COLOR_LOGIC_OP = 0x0BF2;
        public const uint GL_POLYGON_OFFSET_UNITS = 0x2A00;
        public const uint GL_POLYGON_OFFSET_POINT = 0x2A01;
        public const uint GL_POLYGON_OFFSET_LINE = 0x2A02;
        public const uint GL_POLYGON_OFFSET_FILL = 0x8037;
        public const uint GL_POLYGON_OFFSET_FACTOR = 0x8038;
        public const uint GL_TEXTURE_BINDING_1D = 0x8068;
        public const uint GL_TEXTURE_BINDING_2D = 0x8069;
        public const uint GL_TEXTURE_INTERNAL_FORMAT = 0x1003;
        public const uint GL_TEXTURE_RED_SIZE = 0x805C;
        public const uint GL_TEXTURE_GREEN_SIZE = 0x805D;
        public const uint GL_TEXTURE_BLUE_SIZE = 0x805E;
        public const uint GL_TEXTURE_ALPHA_SIZE = 0x805F;
        public const uint GL_DOUBLE = 0x140A;
        public const uint GL_PROXY_TEXTURE_1D = 0x8063;
        public const uint GL_PROXY_TEXTURE_2D = 0x8064;
        public const uint GL_R3_G3_B2 = 0x2A10;
        public const uint GL_RGB4 = 0x804F;
        public const uint GL_RGB5 = 0x8050;
        public const uint GL_RGB8 = 0x8051;
        public const uint GL_RGB10 = 0x8052;
        public const uint GL_RGB12 = 0x8053;
        public const uint GL_RGB16 = 0x8054;
        public const uint GL_RGBA2 = 0x8055;
        public const uint GL_RGBA4 = 0x8056;
        public const uint GL_RGB5_A1 = 0x8057;
        public const uint GL_RGBA8 = 0x8058;
        public const uint GL_RGB10_A2 = 0x8059;
        public const uint GL_RGBA12 = 0x805A;
        public const uint GL_RGBA16 = 0x805B;
        public const uint GL_UNSIGNED_BYTE_3_3_2 = 0x8032;
        public const uint GL_UNSIGNED_SHORT_4_4_4_4 = 0x8033;
        public const uint GL_UNSIGNED_SHORT_5_5_5_1 = 0x8034;
        public const uint GL_UNSIGNED_INT_8_8_8_8 = 0x8035;
        public const uint GL_UNSIGNED_INT_10_10_10_2 = 0x8036;
        public const uint GL_TEXTURE_BINDING_3D = 0x806A;
        public const uint GL_PACK_SKIP_IMAGES = 0x806B;
        public const uint GL_PACK_IMAGE_HEIGHT = 0x806C;
        public const uint GL_UNPACK_SKIP_IMAGES = 0x806D;
        public const uint GL_UNPACK_IMAGE_HEIGHT = 0x806E;
        public const uint GL_TEXTURE_3D = 0x806F;
        public const uint GL_PROXY_TEXTURE_3D = 0x8070;
        public const uint GL_TEXTURE_DEPTH = 0x8071;
        public const uint GL_TEXTURE_WRAP_R = 0x8072;
        public const uint GL_MAX_3D_TEXTURE_SIZE = 0x8073;
        public const uint GL_UNSIGNED_BYTE_2_3_3_REV = 0x8362;
        public const uint GL_UNSIGNED_SHORT_5_6_5 = 0x8363;
        public const uint GL_UNSIGNED_SHORT_5_6_5_REV = 0x8364;
        public const uint GL_UNSIGNED_SHORT_4_4_4_4_REV = 0x8365;
        public const uint GL_UNSIGNED_SHORT_1_5_5_5_REV = 0x8366;
        public const uint GL_UNSIGNED_INT_8_8_8_8_REV = 0x8367;
        public const uint GL_UNSIGNED_INT_2_10_10_10_REV = 0x8368;
        public const uint GL_BGR = 0x80E0;
        public const uint GL_BGRA = 0x80E1;
        public const uint GL_MAX_ELEMENTS_VERTICES = 0x80E8;
        public const uint GL_MAX_ELEMENTS_INDICES = 0x80E9;
        public const uint GL_CLAMP_TO_EDGE = 0x812F;
        public const uint GL_TEXTURE_MIN_LOD = 0x813A;
        public const uint GL_TEXTURE_MAX_LOD = 0x813B;
        public const uint GL_TEXTURE_BASE_LEVEL = 0x813C;
        public const uint GL_TEXTURE_MAX_LEVEL = 0x813D;
        public const uint GL_SMOOTH_POINT_SIZE_RANGE = 0x0B12;
        public const uint GL_SMOOTH_POINT_SIZE_GRANULARITY = 0x0B13;
        public const uint GL_SMOOTH_LINE_WIDTH_RANGE = 0x0B22;
        public const uint GL_SMOOTH_LINE_WIDTH_GRANULARITY = 0x0B23;
        public const uint GL_ALIASED_LINE_WIDTH_RANGE = 0x846E;
        public const uint GL_TEXTURE0 = 0x84C0;
        public const uint GL_TEXTURE1 = 0x84C1;
        public const uint GL_TEXTURE2 = 0x84C2;
        public const uint GL_TEXTURE3 = 0x84C3;
        public const uint GL_TEXTURE4 = 0x84C4;
        public const uint GL_TEXTURE5 = 0x84C5;
        public const uint GL_TEXTURE6 = 0x84C6;
        public const uint GL_TEXTURE7 = 0x84C7;
        public const uint GL_TEXTURE8 = 0x84C8;
        public const uint GL_TEXTURE9 = 0x84C9;
        public const uint GL_TEXTURE10 = 0x84CA;
        public const uint GL_TEXTURE11 = 0x84CB;
        public const uint GL_TEXTURE12 = 0x84CC;
        public const uint GL_TEXTURE13 = 0x84CD;
        public const uint GL_TEXTURE14 = 0x84CE;
        public const uint GL_TEXTURE15 = 0x84CF;
        public const uint GL_TEXTURE16 = 0x84D0;
        public const uint GL_TEXTURE17 = 0x84D1;
        public const uint GL_TEXTURE18 = 0x84D2;
        public const uint GL_TEXTURE19 = 0x84D3;
        public const uint GL_TEXTURE20 = 0x84D4;
        public const uint GL_TEXTURE21 = 0x84D5;
        public const uint GL_TEXTURE22 = 0x84D6;
        public const uint GL_TEXTURE23 = 0x84D7;
        public const uint GL_TEXTURE24 = 0x84D8;
        public const uint GL_TEXTURE25 = 0x84D9;
        public const uint GL_TEXTURE26 = 0x84DA;
        public const uint GL_TEXTURE27 = 0x84DB;
        public const uint GL_TEXTURE28 = 0x84DC;
        public const uint GL_TEXTURE29 = 0x84DD;
        public const uint GL_TEXTURE30 = 0x84DE;
        public const uint GL_TEXTURE31 = 0x84DF;
        public const uint GL_ACTIVE_TEXTURE = 0x84E0;
        public const uint GL_MULTISAMPLE = 0x809D;
        public const uint GL_SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
        public const uint GL_SAMPLE_ALPHA_TO_ONE = 0x809F;
        public const uint GL_SAMPLE_COVERAGE = 0x80A0;
        public const uint GL_SAMPLE_BUFFERS = 0x80A8;
        public const uint GL_SAMPLES = 0x80A9;
        public const uint GL_SAMPLE_COVERAGE_VALUE = 0x80AA;
        public const uint GL_SAMPLE_COVERAGE_INVERT = 0x80AB;
        public const uint GL_TEXTURE_CUBE_MAP = 0x8513;
        public const uint GL_TEXTURE_BINDING_CUBE_MAP = 0x8514;
        public const uint GL_TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;
        public const uint GL_TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;
        public const uint GL_TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;
        public const uint GL_TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;
        public const uint GL_TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;
        public const uint GL_TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;
        public const uint GL_PROXY_TEXTURE_CUBE_MAP = 0x851B;
        public const uint GL_MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;
        public const uint GL_COMPRESSED_RGB = 0x84ED;
        public const uint GL_COMPRESSED_RGBA = 0x84EE;
        public const uint GL_TEXTURE_COMPRESSION_HINT = 0x84EF;
        public const uint GL_TEXTURE_COMPRESSED_IMAGE_SIZE = 0x86A0;
        public const uint GL_TEXTURE_COMPRESSED = 0x86A1;
        public const uint GL_NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2;
        public const uint GL_COMPRESSED_TEXTURE_FORMATS = 0x86A3;
        public const uint GL_CLAMP_TO_BORDER = 0x812D;
        public const uint GL_BLEND_DST_RGB = 0x80C8;
        public const uint GL_BLEND_SRC_RGB = 0x80C9;
        public const uint GL_BLEND_DST_ALPHA = 0x80CA;
        public const uint GL_BLEND_SRC_ALPHA = 0x80CB;
        public const uint GL_POINT_FADE_THRESHOLD_SIZE = 0x8128;
        public const uint GL_DEPTH_COMPONENT16 = 0x81A5;
        public const uint GL_DEPTH_COMPONENT24 = 0x81A6;
        public const uint GL_DEPTH_COMPONENT32 = 0x81A7;
        public const uint GL_MIRRORED_REPEAT = 0x8370;
        public const uint GL_MAX_TEXTURE_LOD_BIAS = 0x84FD;
        public const uint GL_TEXTURE_LOD_BIAS = 0x8501;
        public const uint GL_INCR_WRAP = 0x8507;
        public const uint GL_DECR_WRAP = 0x8508;
        public const uint GL_TEXTURE_DEPTH_SIZE = 0x884A;
        public const uint GL_TEXTURE_COMPARE_MODE = 0x884C;
        public const uint GL_TEXTURE_COMPARE_FUNC = 0x884D;
        public const uint GL_BLEND_COLOR = 0x8005;
        public const uint GL_BLEND_EQUATION = 0x8009;
        public const uint GL_CONSTANT_COLOR = 0x8001;
        public const uint GL_ONE_MINUS_CONSTANT_COLOR = 0x8002;
        public const uint GL_CONSTANT_ALPHA = 0x8003;
        public const uint GL_ONE_MINUS_CONSTANT_ALPHA = 0x8004;
        public const uint GL_FUNC_ADD = 0x8006;
        public const uint GL_FUNC_REVERSE_SUBTRACT = 0x800B;
        public const uint GL_FUNC_SUBTRACT = 0x800A;
        public const uint GL_MIN = 0x8007;
        public const uint GL_MAX = 0x8008;
        public const uint GL_BUFFER_SIZE = 0x8764;
        public const uint GL_BUFFER_USAGE = 0x8765;
        public const uint GL_QUERY_COUNTER_BITS = 0x8864;
        public const uint GL_CURRENT_QUERY = 0x8865;
        public const uint GL_QUERY_RESULT = 0x8866;
        public const uint GL_QUERY_RESULT_AVAILABLE = 0x8867;
        public const uint GL_ARRAY_BUFFER = 0x8892;
        public const uint GL_ELEMENT_ARRAY_BUFFER = 0x8893;
        public const uint GL_ARRAY_BUFFER_BINDING = 0x8894;
        public const uint GL_ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
        public const uint GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
        public const uint GL_READ_ONLY = 0x88B8;
        public const uint GL_WRITE_ONLY = 0x88B9;
        public const uint GL_READ_WRITE = 0x88BA;
        public const uint GL_BUFFER_ACCESS = 0x88BB;
        public const uint GL_BUFFER_MAPPED = 0x88BC;
        public const uint GL_BUFFER_MAP_POINTER = 0x88BD;
        public const uint GL_STREAM_DRAW = 0x88E0;
        public const uint GL_STREAM_READ = 0x88E1;
        public const uint GL_STREAM_COPY = 0x88E2;
        public const uint GL_STATIC_DRAW = 0x88E4;
        public const uint GL_STATIC_READ = 0x88E5;
        public const uint GL_STATIC_COPY = 0x88E6;
        public const uint GL_DYNAMIC_DRAW = 0x88E8;
        public const uint GL_DYNAMIC_READ = 0x88E9;
        public const uint GL_DYNAMIC_COPY = 0x88EA;
        public const uint GL_SAMPLES_PASSED = 0x8914;
        public const uint GL_SRC1_ALPHA = 0x8589;
        public const uint GL_BLEND_EQUATION_RGB = 0x8009;
        public const uint GL_VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
        public const uint GL_VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
        public const uint GL_VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
        public const uint GL_VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
        public const uint GL_CURRENT_VERTEX_ATTRIB = 0x8626;
        public const uint GL_VERTEX_PROGRAM_POINT_SIZE = 0x8642;
        public const uint GL_VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
        public const uint GL_STENCIL_BACK_FUNC = 0x8800;
        public const uint GL_STENCIL_BACK_FAIL = 0x8801;
        public const uint GL_STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;
        public const uint GL_STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;
        public const uint GL_MAX_DRAW_BUFFERS = 0x8824;
        public const uint GL_DRAW_BUFFER0 = 0x8825;
        public const uint GL_DRAW_BUFFER1 = 0x8826;
        public const uint GL_DRAW_BUFFER2 = 0x8827;
        public const uint GL_DRAW_BUFFER3 = 0x8828;
        public const uint GL_DRAW_BUFFER4 = 0x8829;
        public const uint GL_DRAW_BUFFER5 = 0x882A;
        public const uint GL_DRAW_BUFFER6 = 0x882B;
        public const uint GL_DRAW_BUFFER7 = 0x882C;
        public const uint GL_DRAW_BUFFER8 = 0x882D;
        public const uint GL_DRAW_BUFFER9 = 0x882E;
        public const uint GL_DRAW_BUFFER10 = 0x882F;
        public const uint GL_DRAW_BUFFER11 = 0x8830;
        public const uint GL_DRAW_BUFFER12 = 0x8831;
        public const uint GL_DRAW_BUFFER13 = 0x8832;
        public const uint GL_DRAW_BUFFER14 = 0x8833;
        public const uint GL_DRAW_BUFFER15 = 0x8834;
        public const uint GL_BLEND_EQUATION_ALPHA = 0x883D;
        public const uint GL_MAX_VERTEX_ATTRIBS = 0x8869;
        public const uint GL_VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
        public const uint GL_MAX_TEXTURE_IMAGE_UNITS = 0x8872;
        public const uint GL_FRAGMENT_SHADER = 0x8B30;
        public const uint GL_VERTEX_SHADER = 0x8B31;
        public const uint GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;
        public const uint GL_MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;
        public const uint GL_MAX_VARYING_FLOATS = 0x8B4B;
        public const uint GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
        public const uint GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
        public const uint GL_SHADER_TYPE = 0x8B4F;
        public const uint GL_FLOAT_VEC2 = 0x8B50;
        public const uint GL_FLOAT_VEC3 = 0x8B51;
        public const uint GL_FLOAT_VEC4 = 0x8B52;
        public const uint GL_INT_VEC2 = 0x8B53;
        public const uint GL_INT_VEC3 = 0x8B54;
        public const uint GL_INT_VEC4 = 0x8B55;
        public const uint GL_BOOL = 0x8B56;
        public const uint GL_BOOL_VEC2 = 0x8B57;
        public const uint GL_BOOL_VEC3 = 0x8B58;
        public const uint GL_BOOL_VEC4 = 0x8B59;
        public const uint GL_FLOAT_MAT2 = 0x8B5A;
        public const uint GL_FLOAT_MAT3 = 0x8B5B;
        public const uint GL_FLOAT_MAT4 = 0x8B5C;
        public const uint GL_SAMPLER_1D = 0x8B5D;
        public const uint GL_SAMPLER_2D = 0x8B5E;
        public const uint GL_SAMPLER_3D = 0x8B5F;
        public const uint GL_SAMPLER_CUBE = 0x8B60;
        public const uint GL_SAMPLER_1D_SHADOW = 0x8B61;
        public const uint GL_SAMPLER_2D_SHADOW = 0x8B62;
        public const uint GL_DELETE_STATUS = 0x8B80;
        public const uint GL_COMPILE_STATUS = 0x8B81;
        public const uint GL_LINK_STATUS = 0x8B82;
        public const uint GL_VALIDATE_STATUS = 0x8B83;
        public const uint GL_INFO_LOG_LENGTH = 0x8B84;
        public const uint GL_ATTACHED_SHADERS = 0x8B85;
        public const uint GL_ACTIVE_UNIFORMS = 0x8B86;
        public const uint GL_ACTIVE_UNIFORM_MAX_LENGTH = 0x8B87;
        public const uint GL_SHADER_SOURCE_LENGTH = 0x8B88;
        public const uint GL_ACTIVE_ATTRIBUTES = 0x8B89;
        public const uint GL_ACTIVE_ATTRIBUTE_MAX_LENGTH = 0x8B8A;
        public const uint GL_FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;
        public const uint GL_SHADING_LANGUAGE_VERSION = 0x8B8C;
        public const uint GL_CURRENT_PROGRAM = 0x8B8D;
        public const uint GL_POINT_SPRITE_COORD_ORIGIN = 0x8CA0;
        public const uint GL_LOWER_LEFT = 0x8CA1;
        public const uint GL_UPPER_LEFT = 0x8CA2;
        public const uint GL_STENCIL_BACK_REF = 0x8CA3;
        public const uint GL_STENCIL_BACK_VALUE_MASK = 0x8CA4;
        public const uint GL_STENCIL_BACK_WRITEMASK = 0x8CA5;
        public const uint GL_PIXEL_PACK_BUFFER = 0x88EB;
        public const uint GL_PIXEL_UNPACK_BUFFER = 0x88EC;
        public const uint GL_PIXEL_PACK_BUFFER_BINDING = 0x88ED;
        public const uint GL_PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
        public const uint GL_FLOAT_MAT2x3 = 0x8B65;
        public const uint GL_FLOAT_MAT2x4 = 0x8B66;
        public const uint GL_FLOAT_MAT3x2 = 0x8B67;
        public const uint GL_FLOAT_MAT3x4 = 0x8B68;
        public const uint GL_FLOAT_MAT4x2 = 0x8B69;
        public const uint GL_FLOAT_MAT4x3 = 0x8B6A;
        public const uint GL_SRGB = 0x8C40;
        public const uint GL_SRGB8 = 0x8C41;
        public const uint GL_SRGB_ALPHA = 0x8C42;
        public const uint GL_SRGB8_ALPHA8 = 0x8C43;
        public const uint GL_COMPRESSED_SRGB = 0x8C48;
        public const uint GL_COMPRESSED_SRGB_ALPHA = 0x8C49;
        public const uint GL_COMPARE_REF_TO_TEXTURE = 0x884E;
        public const uint GL_CLIP_DISTANCE0 = 0x3000;
        public const uint GL_CLIP_DISTANCE1 = 0x3001;
        public const uint GL_CLIP_DISTANCE2 = 0x3002;
        public const uint GL_CLIP_DISTANCE3 = 0x3003;
        public const uint GL_CLIP_DISTANCE4 = 0x3004;
        public const uint GL_CLIP_DISTANCE5 = 0x3005;
        public const uint GL_CLIP_DISTANCE6 = 0x3006;
        public const uint GL_CLIP_DISTANCE7 = 0x3007;
        public const uint GL_MAX_CLIP_DISTANCES = 0x0D32;
        public const uint GL_MAJOR_VERSION = 0x821B;
        public const uint GL_MINOR_VERSION = 0x821C;
        public const uint GL_NUM_EXTENSIONS = 0x821D;
        public const uint GL_CONTEXT_FLAGS = 0x821E;
        public const uint GL_COMPRESSED_RED = 0x8225;
        public const uint GL_COMPRESSED_RG = 0x8226;
        public const uint GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT = 0x00000001;
        public const uint GL_RGBA32F = 0x8814;
        public const uint GL_RGB32F = 0x8815;
        public const uint GL_RGBA16F = 0x881A;
        public const uint GL_RGB16F = 0x881B;
        public const uint GL_VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;
        public const uint GL_MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;
        public const uint GL_MIN_PROGRAM_TEXEL_OFFSET = 0x8904;
        public const uint GL_MAX_PROGRAM_TEXEL_OFFSET = 0x8905;
        public const uint GL_CLAMP_READ_COLOR = 0x891C;
        public const uint GL_FIXED_ONLY = 0x891D;
        public const uint GL_MAX_VARYING_COMPONENTS = 0x8B4B;
        public const uint GL_TEXTURE_1D_ARRAY = 0x8C18;
        public const uint GL_PROXY_TEXTURE_1D_ARRAY = 0x8C19;
        public const uint GL_TEXTURE_2D_ARRAY = 0x8C1A;
        public const uint GL_PROXY_TEXTURE_2D_ARRAY = 0x8C1B;
        public const uint GL_TEXTURE_BINDING_1D_ARRAY = 0x8C1C;
        public const uint GL_TEXTURE_BINDING_2D_ARRAY = 0x8C1D;
        public const uint GL_R11F_G11F_B10F = 0x8C3A;
        public const uint GL_UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
        public const uint GL_RGB9_E5 = 0x8C3D;
        public const uint GL_UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;
        public const uint GL_TEXTURE_SHARED_SIZE = 0x8C3F;
        public const uint GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH = 0x8C76;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;
        public const uint GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;
        public const uint GL_TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;
        public const uint GL_PRIMITIVES_GENERATED = 0x8C87;
        public const uint GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;
        public const uint GL_RASTERIZER_DISCARD = 0x8C89;
        public const uint GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;
        public const uint GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;
        public const uint GL_INTERLEAVED_ATTRIBS = 0x8C8C;
        public const uint GL_SEPARATE_ATTRIBS = 0x8C8D;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;
        public const uint GL_RGBA32UI = 0x8D70;
        public const uint GL_RGB32UI = 0x8D71;
        public const uint GL_RGBA16UI = 0x8D76;
        public const uint GL_RGB16UI = 0x8D77;
        public const uint GL_RGBA8UI = 0x8D7C;
        public const uint GL_RGB8UI = 0x8D7D;
        public const uint GL_RGBA32I = 0x8D82;
        public const uint GL_RGB32I = 0x8D83;
        public const uint GL_RGBA16I = 0x8D88;
        public const uint GL_RGB16I = 0x8D89;
        public const uint GL_RGBA8I = 0x8D8E;
        public const uint GL_RGB8I = 0x8D8F;
        public const uint GL_RED_INTEGER = 0x8D94;
        public const uint GL_GREEN_INTEGER = 0x8D95;
        public const uint GL_BLUE_INTEGER = 0x8D96;
        public const uint GL_RGB_INTEGER = 0x8D98;
        public const uint GL_RGBA_INTEGER = 0x8D99;
        public const uint GL_BGR_INTEGER = 0x8D9A;
        public const uint GL_BGRA_INTEGER = 0x8D9B;
        public const uint GL_SAMPLER_1D_ARRAY = 0x8DC0;
        public const uint GL_SAMPLER_2D_ARRAY = 0x8DC1;
        public const uint GL_SAMPLER_1D_ARRAY_SHADOW = 0x8DC3;
        public const uint GL_SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;
        public const uint GL_SAMPLER_CUBE_SHADOW = 0x8DC5;
        public const uint GL_UNSIGNED_INT_VEC2 = 0x8DC6;
        public const uint GL_UNSIGNED_INT_VEC3 = 0x8DC7;
        public const uint GL_UNSIGNED_INT_VEC4 = 0x8DC8;
        public const uint GL_INT_SAMPLER_1D = 0x8DC9;
        public const uint GL_INT_SAMPLER_2D = 0x8DCA;
        public const uint GL_INT_SAMPLER_3D = 0x8DCB;
        public const uint GL_INT_SAMPLER_CUBE = 0x8DCC;
        public const uint GL_INT_SAMPLER_1D_ARRAY = 0x8DCE;
        public const uint GL_INT_SAMPLER_2D_ARRAY = 0x8DCF;
        public const uint GL_UNSIGNED_INT_SAMPLER_1D = 0x8DD1;
        public const uint GL_UNSIGNED_INT_SAMPLER_2D = 0x8DD2;
        public const uint GL_UNSIGNED_INT_SAMPLER_3D = 0x8DD3;
        public const uint GL_UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;
        public const uint GL_UNSIGNED_INT_SAMPLER_1D_ARRAY = 0x8DD6;
        public const uint GL_UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;
        public const uint GL_QUERY_WAIT = 0x8E13;
        public const uint GL_QUERY_NO_WAIT = 0x8E14;
        public const uint GL_QUERY_BY_REGION_WAIT = 0x8E15;
        public const uint GL_QUERY_BY_REGION_NO_WAIT = 0x8E16;
        public const uint GL_BUFFER_ACCESS_FLAGS = 0x911F;
        public const uint GL_BUFFER_MAP_LENGTH = 0x9120;
        public const uint GL_BUFFER_MAP_OFFSET = 0x9121;
        public const uint GL_DEPTH_COMPONENT32F = 0x8CAC;
        public const uint GL_DEPTH32F_STENCIL8 = 0x8CAD;
        public const uint GL_FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;
        public const uint GL_INVALID_FRAMEBUFFER_OPERATION = 0x0506;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
        public const uint GL_FRAMEBUFFER_DEFAULT = 0x8218;
        public const uint GL_FRAMEBUFFER_UNDEFINED = 0x8219;
        public const uint GL_DEPTH_STENCIL_ATTACHMENT = 0x821A;
        public const uint GL_MAX_RENDERBUFFER_SIZE = 0x84E8;
        public const uint GL_DEPTH_STENCIL = 0x84F9;
        public const uint GL_UNSIGNED_INT_24_8 = 0x84FA;
        public const uint GL_DEPTH24_STENCIL8 = 0x88F0;
        public const uint GL_TEXTURE_STENCIL_SIZE = 0x88F1;
        public const uint GL_TEXTURE_RED_TYPE = 0x8C10;
        public const uint GL_TEXTURE_GREEN_TYPE = 0x8C11;
        public const uint GL_TEXTURE_BLUE_TYPE = 0x8C12;
        public const uint GL_TEXTURE_ALPHA_TYPE = 0x8C13;
        public const uint GL_TEXTURE_DEPTH_TYPE = 0x8C16;
        public const uint GL_UNSIGNED_NORMALIZED = 0x8C17;
        public const uint GL_FRAMEBUFFER_BINDING = 0x8CA6;
        public const uint GL_DRAW_FRAMEBUFFER_BINDING = 0x8CA6;
        public const uint GL_RENDERBUFFER_BINDING = 0x8CA7;
        public const uint GL_READ_FRAMEBUFFER = 0x8CA8;
        public const uint GL_DRAW_FRAMEBUFFER = 0x8CA9;
        public const uint GL_READ_FRAMEBUFFER_BINDING = 0x8CAA;
        public const uint GL_RENDERBUFFER_SAMPLES = 0x8CAB;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
        public const uint GL_FRAMEBUFFER_COMPLETE = 0x8CD5;
        public const uint GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
        public const uint GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
        public const uint GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB;
        public const uint GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC;
        public const uint GL_FRAMEBUFFER_UNSUPPORTED = 0x8CDD;
        public const uint GL_MAX_COLOR_ATTACHMENTS = 0x8CDF;
        public const uint GL_COLOR_ATTACHMENT0 = 0x8CE0;
        public const uint GL_COLOR_ATTACHMENT1 = 0x8CE1;
        public const uint GL_COLOR_ATTACHMENT2 = 0x8CE2;
        public const uint GL_COLOR_ATTACHMENT3 = 0x8CE3;
        public const uint GL_COLOR_ATTACHMENT4 = 0x8CE4;
        public const uint GL_COLOR_ATTACHMENT5 = 0x8CE5;
        public const uint GL_COLOR_ATTACHMENT6 = 0x8CE6;
        public const uint GL_COLOR_ATTACHMENT7 = 0x8CE7;
        public const uint GL_COLOR_ATTACHMENT8 = 0x8CE8;
        public const uint GL_COLOR_ATTACHMENT9 = 0x8CE9;
        public const uint GL_COLOR_ATTACHMENT10 = 0x8CEA;
        public const uint GL_COLOR_ATTACHMENT11 = 0x8CEB;
        public const uint GL_COLOR_ATTACHMENT12 = 0x8CEC;
        public const uint GL_COLOR_ATTACHMENT13 = 0x8CED;
        public const uint GL_COLOR_ATTACHMENT14 = 0x8CEE;
        public const uint GL_COLOR_ATTACHMENT15 = 0x8CEF;
        public const uint GL_COLOR_ATTACHMENT16 = 0x8CF0;
        public const uint GL_COLOR_ATTACHMENT17 = 0x8CF1;
        public const uint GL_COLOR_ATTACHMENT18 = 0x8CF2;
        public const uint GL_COLOR_ATTACHMENT19 = 0x8CF3;
        public const uint GL_COLOR_ATTACHMENT20 = 0x8CF4;
        public const uint GL_COLOR_ATTACHMENT21 = 0x8CF5;
        public const uint GL_COLOR_ATTACHMENT22 = 0x8CF6;
        public const uint GL_COLOR_ATTACHMENT23 = 0x8CF7;
        public const uint GL_COLOR_ATTACHMENT24 = 0x8CF8;
        public const uint GL_COLOR_ATTACHMENT25 = 0x8CF9;
        public const uint GL_COLOR_ATTACHMENT26 = 0x8CFA;
        public const uint GL_COLOR_ATTACHMENT27 = 0x8CFB;
        public const uint GL_COLOR_ATTACHMENT28 = 0x8CFC;
        public const uint GL_COLOR_ATTACHMENT29 = 0x8CFD;
        public const uint GL_COLOR_ATTACHMENT30 = 0x8CFE;
        public const uint GL_COLOR_ATTACHMENT31 = 0x8CFF;
        public const uint GL_DEPTH_ATTACHMENT = 0x8D00;
        public const uint GL_STENCIL_ATTACHMENT = 0x8D20;
        public const uint GL_FRAMEBUFFER = 0x8D40;
        public const uint GL_RENDERBUFFER = 0x8D41;
        public const uint GL_RENDERBUFFER_WIDTH = 0x8D42;
        public const uint GL_RENDERBUFFER_HEIGHT = 0x8D43;
        public const uint GL_RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
        public const uint GL_STENCIL_INDEX1 = 0x8D46;
        public const uint GL_STENCIL_INDEX4 = 0x8D47;
        public const uint GL_STENCIL_INDEX8 = 0x8D48;
        public const uint GL_STENCIL_INDEX16 = 0x8D49;
        public const uint GL_RENDERBUFFER_RED_SIZE = 0x8D50;
        public const uint GL_RENDERBUFFER_GREEN_SIZE = 0x8D51;
        public const uint GL_RENDERBUFFER_BLUE_SIZE = 0x8D52;
        public const uint GL_RENDERBUFFER_ALPHA_SIZE = 0x8D53;
        public const uint GL_RENDERBUFFER_DEPTH_SIZE = 0x8D54;
        public const uint GL_RENDERBUFFER_STENCIL_SIZE = 0x8D55;
        public const uint GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;
        public const uint GL_MAX_SAMPLES = 0x8D57;
        public const uint GL_FRAMEBUFFER_SRGB = 0x8DB9;
        public const uint GL_HALF_FLOAT = 0x140B;
        public const uint GL_MAP_READ_BIT = 0x0001;
        public const uint GL_MAP_WRITE_BIT = 0x0002;
        public const uint GL_MAP_INVALIDATE_RANGE_BIT = 0x0004;
        public const uint GL_MAP_INVALIDATE_BUFFER_BIT = 0x0008;
        public const uint GL_MAP_FLUSH_EXPLICIT_BIT = 0x0010;
        public const uint GL_MAP_UNSYNCHRONIZED_BIT = 0x0020;
        public const uint GL_COMPRESSED_RED_RGTC1 = 0x8DBB;
        public const uint GL_COMPRESSED_SIGNED_RED_RGTC1 = 0x8DBC;
        public const uint GL_COMPRESSED_RG_RGTC2 = 0x8DBD;
        public const uint GL_COMPRESSED_SIGNED_RG_RGTC2 = 0x8DBE;
        public const uint GL_RG = 0x8227;
        public const uint GL_RG_INTEGER = 0x8228;
        public const uint GL_R8 = 0x8229;
        public const uint GL_R16 = 0x822A;
        public const uint GL_RG8 = 0x822B;
        public const uint GL_RG16 = 0x822C;
        public const uint GL_R16F = 0x822D;
        public const uint GL_R32F = 0x822E;
        public const uint GL_RG16F = 0x822F;
        public const uint GL_RG32F = 0x8230;
        public const uint GL_R8I = 0x8231;
        public const uint GL_R8UI = 0x8232;
        public const uint GL_R16I = 0x8233;
        public const uint GL_R16UI = 0x8234;
        public const uint GL_R32I = 0x8235;
        public const uint GL_R32UI = 0x8236;
        public const uint GL_RG8I = 0x8237;
        public const uint GL_RG8UI = 0x8238;
        public const uint GL_RG16I = 0x8239;
        public const uint GL_RG16UI = 0x823A;
        public const uint GL_RG32I = 0x823B;
        public const uint GL_RG32UI = 0x823C;
        public const uint GL_VERTEX_ARRAY_BINDING = 0x85B5;
        public const uint GL_SAMPLER_2D_RECT = 0x8B63;
        public const uint GL_SAMPLER_2D_RECT_SHADOW = 0x8B64;
        public const uint GL_SAMPLER_BUFFER = 0x8DC2;
        public const uint GL_INT_SAMPLER_2D_RECT = 0x8DCD;
        public const uint GL_INT_SAMPLER_BUFFER = 0x8DD0;
        public const uint GL_UNSIGNED_INT_SAMPLER_2D_RECT = 0x8DD5;
        public const uint GL_UNSIGNED_INT_SAMPLER_BUFFER = 0x8DD8;
        public const uint GL_TEXTURE_BUFFER = 0x8C2A;
        public const uint GL_MAX_TEXTURE_BUFFER_SIZE = 0x8C2B;
        public const uint GL_TEXTURE_BINDING_BUFFER = 0x8C2C;
        public const uint GL_TEXTURE_BUFFER_DATA_STORE_BINDING = 0x8C2D;
        public const uint GL_TEXTURE_RECTANGLE = 0x84F5;
        public const uint GL_TEXTURE_BINDING_RECTANGLE = 0x84F6;
        public const uint GL_PROXY_TEXTURE_RECTANGLE = 0x84F7;
        public const uint GL_MAX_RECTANGLE_TEXTURE_SIZE = 0x84F8;
        public const uint GL_R8_SNORM = 0x8F94;
        public const uint GL_RG8_SNORM = 0x8F95;
        public const uint GL_RGB8_SNORM = 0x8F96;
        public const uint GL_RGBA8_SNORM = 0x8F97;
        public const uint GL_R16_SNORM = 0x8F98;
        public const uint GL_RG16_SNORM = 0x8F99;
        public const uint GL_RGB16_SNORM = 0x8F9A;
        public const uint GL_RGBA16_SNORM = 0x8F9B;
        public const uint GL_SIGNED_NORMALIZED = 0x8F9C;
        public const uint GL_PRIMITIVE_RESTART = 0x8F9D;
        public const uint GL_PRIMITIVE_RESTART_INDEX = 0x8F9E;
        public const uint GL_COPY_READ_BUFFER = 0x8F36;
        public const uint GL_COPY_WRITE_BUFFER = 0x8F37;
        public const uint GL_UNIFORM_BUFFER = 0x8A11;
        public const uint GL_UNIFORM_BUFFER_BINDING = 0x8A28;
        public const uint GL_UNIFORM_BUFFER_START = 0x8A29;
        public const uint GL_UNIFORM_BUFFER_SIZE = 0x8A2A;
        public const uint GL_MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;
        public const uint GL_MAX_GEOMETRY_UNIFORM_BLOCKS = 0x8A2C;
        public const uint GL_MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;
        public const uint GL_MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;
        public const uint GL_MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
        public const uint GL_MAX_UNIFORM_BLOCK_SIZE = 0x8A30;
        public const uint GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;
        public const uint GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS = 0x8A32;
        public const uint GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;
        public const uint GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;
        public const uint GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH = 0x8A35;
        public const uint GL_ACTIVE_UNIFORM_BLOCKS = 0x8A36;
        public const uint GL_UNIFORM_TYPE = 0x8A37;
        public const uint GL_UNIFORM_SIZE = 0x8A38;
        public const uint GL_UNIFORM_NAME_LENGTH = 0x8A39;
        public const uint GL_UNIFORM_BLOCK_INDEX = 0x8A3A;
        public const uint GL_UNIFORM_OFFSET = 0x8A3B;
        public const uint GL_UNIFORM_ARRAY_STRIDE = 0x8A3C;
        public const uint GL_UNIFORM_MATRIX_STRIDE = 0x8A3D;
        public const uint GL_UNIFORM_IS_ROW_MAJOR = 0x8A3E;
        public const uint GL_UNIFORM_BLOCK_BINDING = 0x8A3F;
        public const uint GL_UNIFORM_BLOCK_DATA_SIZE = 0x8A40;
        public const uint GL_UNIFORM_BLOCK_NAME_LENGTH = 0x8A41;
        public const uint GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;
        public const uint GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;
        public const uint GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;
        public const uint GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER = 0x8A45;
        public const uint GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;
        public const uint GL_INVALID_INDEX = 0xFFFFFFFF;
        public const uint GL_CONTEXT_CORE_PROFILE_BIT = 0x00000001;
        public const uint GL_CONTEXT_COMPATIBILITY_PROFILE_BIT = 0x00000002;
        public const uint GL_LINES_ADJACENCY = 0x000A;
        public const uint GL_LINE_STRIP_ADJACENCY = 0x000B;
        public const uint GL_TRIANGLES_ADJACENCY = 0x000C;
        public const uint GL_TRIANGLE_STRIP_ADJACENCY = 0x000D;
        public const uint GL_PROGRAM_POINT_SIZE = 0x8642;
        public const uint GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS = 0x8C29;
        public const uint GL_FRAMEBUFFER_ATTACHMENT_LAYERED = 0x8DA7;
        public const uint GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS = 0x8DA8;
        public const uint GL_GEOMETRY_SHADER = 0x8DD9;
        public const uint GL_GEOMETRY_VERTICES_OUT = 0x8916;
        public const uint GL_GEOMETRY_INPUT_TYPE = 0x8917;
        public const uint GL_GEOMETRY_OUTPUT_TYPE = 0x8918;
        public const uint GL_MAX_GEOMETRY_UNIFORM_COMPONENTS = 0x8DDF;
        public const uint GL_MAX_GEOMETRY_OUTPUT_VERTICES = 0x8DE0;
        public const uint GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS = 0x8DE1;
        public const uint GL_MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;
        public const uint GL_MAX_GEOMETRY_INPUT_COMPONENTS = 0x9123;
        public const uint GL_MAX_GEOMETRY_OUTPUT_COMPONENTS = 0x9124;
        public const uint GL_MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;
        public const uint GL_CONTEXT_PROFILE_MASK = 0x9126;
        public const uint GL_DEPTH_CLAMP = 0x864F;
        public const uint GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION = 0x8E4C;
        public const uint GL_FIRST_VERTEX_CONVENTION = 0x8E4D;
        public const uint GL_LAST_VERTEX_CONVENTION = 0x8E4E;
        public const uint GL_PROVOKING_VERTEX = 0x8E4F;
        public const uint GL_TEXTURE_CUBE_MAP_SEAMLESS = 0x884F;
        public const uint GL_MAX_SERVER_WAIT_TIMEOUT = 0x9111;
        public const uint GL_OBJECT_TYPE = 0x9112;
        public const uint GL_SYNC_CONDITION = 0x9113;
        public const uint GL_SYNC_STATUS = 0x9114;
        public const uint GL_SYNC_FLAGS = 0x9115;
        public const uint GL_SYNC_FENCE = 0x9116;
        public const uint GL_SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
        public const uint GL_UNSIGNALED = 0x9118;
        public const uint GL_SIGNALED = 0x9119;
        public const uint GL_ALREADY_SIGNALED = 0x911A;
        public const uint GL_TIMEOUT_EXPIRED = 0x911B;
        public const uint GL_CONDITION_SATISFIED = 0x911C;
        public const uint GL_WAIT_FAILED = 0x911D;
        public const uint GL_TIMEOUT_IGNORED = 0xFFFFFFFFFFFFFFFF;
        public const uint GL_SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
        public const uint GL_SAMPLE_POSITION = 0x8E50;
        public const uint GL_SAMPLE_MASK = 0x8E51;
        public const uint GL_SAMPLE_MASK_VALUE = 0x8E52;
        public const uint GL_MAX_SAMPLE_MASK_WORDS = 0x8E59;
        public const uint GL_TEXTURE_2D_MULTISAMPLE = 0x9100;
        public const uint GL_PROXY_TEXTURE_2D_MULTISAMPLE = 0x9101;
        public const uint GL_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9102;
        public const uint GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9103;
        public const uint GL_TEXTURE_BINDING_2D_MULTISAMPLE = 0x9104;
        public const uint GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY = 0x9105;
        public const uint GL_TEXTURE_SAMPLES = 0x9106;
        public const uint GL_TEXTURE_FIXED_SAMPLE_LOCATIONS = 0x9107;
        public const uint GL_SAMPLER_2D_MULTISAMPLE = 0x9108;
        public const uint GL_INT_SAMPLER_2D_MULTISAMPLE = 0x9109;
        public const uint GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE = 0x910A;
        public const uint GL_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910B;
        public const uint GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C;
        public const uint GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D;
        public const uint GL_MAX_COLOR_TEXTURE_SAMPLES = 0x910E;
        public const uint GL_MAX_DEPTH_TEXTURE_SAMPLES = 0x910F;
        public const uint GL_MAX_INTEGER_SAMPLES = 0x9110;
        public const uint GL_VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;
        public const uint GL_SRC1_COLOR = 0x88F9;
        public const uint GL_ONE_MINUS_SRC1_COLOR = 0x88FA;
        public const uint GL_ONE_MINUS_SRC1_ALPHA = 0x88FB;
        public const uint GL_MAX_DUAL_SOURCE_DRAW_BUFFERS = 0x88FC;
        public const uint GL_ANY_SAMPLES_PASSED = 0x8C2F;
        public const uint GL_SAMPLER_BINDING = 0x8919;
        public const uint GL_RGB10_A2UI = 0x906F;
        public const uint GL_TEXTURE_SWIZZLE_R = 0x8E42;
        public const uint GL_TEXTURE_SWIZZLE_G = 0x8E43;
        public const uint GL_TEXTURE_SWIZZLE_B = 0x8E44;
        public const uint GL_TEXTURE_SWIZZLE_A = 0x8E45;
        public const uint GL_TEXTURE_SWIZZLE_RGBA = 0x8E46;
        public const uint GL_TIME_ELAPSED = 0x88BF;
        public const uint GL_TIMESTAMP = 0x8E28;
        public const uint GL_INT_2_10_10_10_REV = 0x8D9F;
        public const uint GL_SAMPLE_SHADING = 0x8C36;
        public const uint GL_MIN_SAMPLE_SHADING_VALUE = 0x8C37;
        public const uint GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5E;
        public const uint GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5F;
        public const uint GL_TEXTURE_CUBE_MAP_ARRAY = 0x9009;
        public const uint GL_TEXTURE_BINDING_CUBE_MAP_ARRAY = 0x900A;
        public const uint GL_PROXY_TEXTURE_CUBE_MAP_ARRAY = 0x900B;
        public const uint GL_SAMPLER_CUBE_MAP_ARRAY = 0x900C;
        public const uint GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW = 0x900D;
        public const uint GL_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900E;
        public const uint GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900F;
        public const uint GL_DRAW_INDIRECT_BUFFER = 0x8F3F;
        public const uint GL_DRAW_INDIRECT_BUFFER_BINDING = 0x8F43;
        public const uint GL_GEOMETRY_SHADER_INVOCATIONS = 0x887F;
        public const uint GL_MAX_GEOMETRY_SHADER_INVOCATIONS = 0x8E5A;
        public const uint GL_MIN_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5B;
        public const uint GL_MAX_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5C;
        public const uint GL_FRAGMENT_INTERPOLATION_OFFSET_BITS = 0x8E5D;
        public const uint GL_MAX_VERTEX_STREAMS = 0x8E71;
        public const uint GL_DOUBLE_VEC2 = 0x8FFC;
        public const uint GL_DOUBLE_VEC3 = 0x8FFD;
        public const uint GL_DOUBLE_VEC4 = 0x8FFE;
        public const uint GL_DOUBLE_MAT2 = 0x8F46;
        public const uint GL_DOUBLE_MAT3 = 0x8F47;
        public const uint GL_DOUBLE_MAT4 = 0x8F48;
        public const uint GL_DOUBLE_MAT2x3 = 0x8F49;
        public const uint GL_DOUBLE_MAT2x4 = 0x8F4A;
        public const uint GL_DOUBLE_MAT3x2 = 0x8F4B;
        public const uint GL_DOUBLE_MAT3x4 = 0x8F4C;
        public const uint GL_DOUBLE_MAT4x2 = 0x8F4D;
        public const uint GL_DOUBLE_MAT4x3 = 0x8F4E;
        public const uint GL_ACTIVE_SUBROUTINES = 0x8DE5;
        public const uint GL_ACTIVE_SUBROUTINE_UNIFORMS = 0x8DE6;
        public const uint GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS = 0x8E47;
        public const uint GL_ACTIVE_SUBROUTINE_MAX_LENGTH = 0x8E48;
        public const uint GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH = 0x8E49;
        public const uint GL_MAX_SUBROUTINES = 0x8DE7;
        public const uint GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS = 0x8DE8;
        public const uint GL_NUM_COMPATIBLE_SUBROUTINES = 0x8E4A;
        public const uint GL_COMPATIBLE_SUBROUTINES = 0x8E4B;
        public const uint GL_PATCHES = 0x000E;
        public const uint GL_PATCH_VERTICES = 0x8E72;
        public const uint GL_PATCH_DEFAULT_INNER_LEVEL = 0x8E73;
        public const uint GL_PATCH_DEFAULT_OUTER_LEVEL = 0x8E74;
        public const uint GL_TESS_CONTROL_OUTPUT_VERTICES = 0x8E75;
        public const uint GL_TESS_GEN_MODE = 0x8E76;
        public const uint GL_TESS_GEN_SPACING = 0x8E77;
        public const uint GL_TESS_GEN_VERTEX_ORDER = 0x8E78;
        public const uint GL_TESS_GEN_POINT_MODE = 0x8E79;
        public const uint GL_ISOLINES = 0x8E7A;
        public const uint GL_QUADS = 0x0007;
        public const uint GL_FRACTIONAL_ODD = 0x8E7B;
        public const uint GL_FRACTIONAL_EVEN = 0x8E7C;
        public const uint GL_MAX_PATCH_VERTICES = 0x8E7D;
        public const uint GL_MAX_TESS_GEN_LEVEL = 0x8E7E;
        public const uint GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E7F;
        public const uint GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E80;
        public const uint GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS = 0x8E81;
        public const uint GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS = 0x8E82;
        public const uint GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS = 0x8E83;
        public const uint GL_MAX_TESS_PATCH_COMPONENTS = 0x8E84;
        public const uint GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS = 0x8E85;
        public const uint GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS = 0x8E86;
        public const uint GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS = 0x8E89;
        public const uint GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS = 0x8E8A;
        public const uint GL_MAX_TESS_CONTROL_INPUT_COMPONENTS = 0x886C;
        public const uint GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS = 0x886D;
        public const uint GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E1E;
        public const uint GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E1F;
        public const uint GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER = 0x84F0;
        public const uint GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x84F1;
        public const uint GL_TESS_EVALUATION_SHADER = 0x8E87;
        public const uint GL_TESS_CONTROL_SHADER = 0x8E88;
        public const uint GL_TRANSFORM_FEEDBACK = 0x8E22;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED = 0x8E23;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE = 0x8E24;
        public const uint GL_TRANSFORM_FEEDBACK_BINDING = 0x8E25;
        public const uint GL_MAX_TRANSFORM_FEEDBACK_BUFFERS = 0x8E70;
        public const uint GL_FIXED = 0x140C;
        public const uint GL_IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;
        public const uint GL_IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;
        public const uint GL_LOW_FLOAT = 0x8DF0;
        public const uint GL_MEDIUM_FLOAT = 0x8DF1;
        public const uint GL_HIGH_FLOAT = 0x8DF2;
        public const uint GL_LOW_INT = 0x8DF3;
        public const uint GL_MEDIUM_INT = 0x8DF4;
        public const uint GL_HIGH_INT = 0x8DF5;
        public const uint GL_SHADER_COMPILER = 0x8DFA;
        public const uint GL_SHADER_BINARY_FORMATS = 0x8DF8;
        public const uint GL_NUM_SHADER_BINARY_FORMATS = 0x8DF9;
        public const uint GL_MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
        public const uint GL_MAX_VARYING_VECTORS = 0x8DFC;
        public const uint GL_MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
        public const uint GL_RGB565 = 0x8D62;
        public const uint GL_PROGRAM_BINARY_RETRIEVABLE_HINT = 0x8257;
        public const uint GL_PROGRAM_BINARY_LENGTH = 0x8741;
        public const uint GL_NUM_PROGRAM_BINARY_FORMATS = 0x87FE;
        public const uint GL_PROGRAM_BINARY_FORMATS = 0x87FF;
        public const uint GL_VERTEX_SHADER_BIT = 0x00000001;
        public const uint GL_FRAGMENT_SHADER_BIT = 0x00000002;
        public const uint GL_GEOMETRY_SHADER_BIT = 0x00000004;
        public const uint GL_TESS_CONTROL_SHADER_BIT = 0x00000008;
        public const uint GL_TESS_EVALUATION_SHADER_BIT = 0x00000010;
        public const uint GL_ALL_SHADER_BITS = 0xFFFFFFFF;
        public const uint GL_PROGRAM_SEPARABLE = 0x8258;
        public const uint GL_ACTIVE_PROGRAM = 0x8259;
        public const uint GL_PROGRAM_PIPELINE_BINDING = 0x825A;
        public const uint GL_MAX_VIEWPORTS = 0x825B;
        public const uint GL_VIEWPORT_SUBPIXEL_BITS = 0x825C;
        public const uint GL_VIEWPORT_BOUNDS_RANGE = 0x825D;
        public const uint GL_LAYER_PROVOKING_VERTEX = 0x825E;
        public const uint GL_VIEWPORT_INDEX_PROVOKING_VERTEX = 0x825F;
        public const uint GL_UNDEFINED_VERTEX = 0x8260;
        public const uint GL_COPY_READ_BUFFER_BINDING = 0x8F36;
        public const uint GL_COPY_WRITE_BUFFER_BINDING = 0x8F37;
        public const uint GL_TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;
        public const uint GL_TRANSFORM_FEEDBACK_PAUSED = 0x8E23;
        public const uint GL_UNPACK_COMPRESSED_BLOCK_WIDTH = 0x9127;
        public const uint GL_UNPACK_COMPRESSED_BLOCK_HEIGHT = 0x9128;
        public const uint GL_UNPACK_COMPRESSED_BLOCK_DEPTH = 0x9129;
        public const uint GL_UNPACK_COMPRESSED_BLOCK_SIZE = 0x912A;
        public const uint GL_PACK_COMPRESSED_BLOCK_WIDTH = 0x912B;
        public const uint GL_PACK_COMPRESSED_BLOCK_HEIGHT = 0x912C;
        public const uint GL_PACK_COMPRESSED_BLOCK_DEPTH = 0x912D;
        public const uint GL_PACK_COMPRESSED_BLOCK_SIZE = 0x912E;
        public const uint GL_NUM_SAMPLE_COUNTS = 0x9380;
        public const uint GL_MIN_MAP_BUFFER_ALIGNMENT = 0x90BC;
        public const uint GL_ATOMIC_COUNTER_BUFFER = 0x92C0;
        public const uint GL_ATOMIC_COUNTER_BUFFER_BINDING = 0x92C1;
        public const uint GL_ATOMIC_COUNTER_BUFFER_START = 0x92C2;
        public const uint GL_ATOMIC_COUNTER_BUFFER_SIZE = 0x92C3;
        public const uint GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE = 0x92C4;
        public const uint GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS = 0x92C5;
        public const uint GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES = 0x92C6;
        public const uint GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER = 0x92C7;
        public const uint GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER = 0x92C8;
        public const uint GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x92C9;
        public const uint GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER = 0x92CA;
        public const uint GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER = 0x92CB;
        public const uint GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS = 0x92CC;
        public const uint GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS = 0x92CD;
        public const uint GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS = 0x92CE;
        public const uint GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS = 0x92CF;
        public const uint GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS = 0x92D0;
        public const uint GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS = 0x92D1;
        public const uint GL_MAX_VERTEX_ATOMIC_COUNTERS = 0x92D2;
        public const uint GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS = 0x92D3;
        public const uint GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS = 0x92D4;
        public const uint GL_MAX_GEOMETRY_ATOMIC_COUNTERS = 0x92D5;
        public const uint GL_MAX_FRAGMENT_ATOMIC_COUNTERS = 0x92D6;
        public const uint GL_MAX_COMBINED_ATOMIC_COUNTERS = 0x92D7;
        public const uint GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE = 0x92D8;
        public const uint GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS = 0x92DC;
        public const uint GL_ACTIVE_ATOMIC_COUNTER_BUFFERS = 0x92D9;
        public const uint GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX = 0x92DA;
        public const uint GL_UNSIGNED_INT_ATOMIC_COUNTER = 0x92DB;
        public const uint GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT = 0x00000001;
        public const uint GL_ELEMENT_ARRAY_BARRIER_BIT = 0x00000002;
        public const uint GL_UNIFORM_BARRIER_BIT = 0x00000004;
        public const uint GL_TEXTURE_FETCH_BARRIER_BIT = 0x00000008;
        public const uint GL_SHADER_IMAGE_ACCESS_BARRIER_BIT = 0x00000020;
        public const uint GL_COMMAND_BARRIER_BIT = 0x00000040;
        public const uint GL_PIXEL_BUFFER_BARRIER_BIT = 0x00000080;
        public const uint GL_TEXTURE_UPDATE_BARRIER_BIT = 0x00000100;
        public const uint GL_BUFFER_UPDATE_BARRIER_BIT = 0x00000200;
        public const uint GL_FRAMEBUFFER_BARRIER_BIT = 0x00000400;
        public const uint GL_TRANSFORM_FEEDBACK_BARRIER_BIT = 0x00000800;
        public const uint GL_ATOMIC_COUNTER_BARRIER_BIT = 0x00001000;
        public const uint GL_ALL_BARRIER_BITS = 0xFFFFFFFF;
        public const uint GL_MAX_IMAGE_UNITS = 0x8F38;
        public const uint GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS = 0x8F39;
        public const uint GL_IMAGE_BINDING_NAME = 0x8F3A;
        public const uint GL_IMAGE_BINDING_LEVEL = 0x8F3B;
        public const uint GL_IMAGE_BINDING_LAYERED = 0x8F3C;
        public const uint GL_IMAGE_BINDING_LAYER = 0x8F3D;
        public const uint GL_IMAGE_BINDING_ACCESS = 0x8F3E;
        public const uint GL_IMAGE_1D = 0x904C;
        public const uint GL_IMAGE_2D = 0x904D;
        public const uint GL_IMAGE_3D = 0x904E;
        public const uint GL_IMAGE_2D_RECT = 0x904F;
        public const uint GL_IMAGE_CUBE = 0x9050;
        public const uint GL_IMAGE_BUFFER = 0x9051;
        public const uint GL_IMAGE_1D_ARRAY = 0x9052;
        public const uint GL_IMAGE_2D_ARRAY = 0x9053;
        public const uint GL_IMAGE_CUBE_MAP_ARRAY = 0x9054;
        public const uint GL_IMAGE_2D_MULTISAMPLE = 0x9055;
        public const uint GL_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9056;
        public const uint GL_INT_IMAGE_1D = 0x9057;
        public const uint GL_INT_IMAGE_2D = 0x9058;
        public const uint GL_INT_IMAGE_3D = 0x9059;
        public const uint GL_INT_IMAGE_2D_RECT = 0x905A;
        public const uint GL_INT_IMAGE_CUBE = 0x905B;
        public const uint GL_INT_IMAGE_BUFFER = 0x905C;
        public const uint GL_INT_IMAGE_1D_ARRAY = 0x905D;
        public const uint GL_INT_IMAGE_2D_ARRAY = 0x905E;
        public const uint GL_INT_IMAGE_CUBE_MAP_ARRAY = 0x905F;
        public const uint GL_INT_IMAGE_2D_MULTISAMPLE = 0x9060;
        public const uint GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061;
        public const uint GL_UNSIGNED_INT_IMAGE_1D = 0x9062;
        public const uint GL_UNSIGNED_INT_IMAGE_2D = 0x9063;
        public const uint GL_UNSIGNED_INT_IMAGE_3D = 0x9064;
        public const uint GL_UNSIGNED_INT_IMAGE_2D_RECT = 0x9065;
        public const uint GL_UNSIGNED_INT_IMAGE_CUBE = 0x9066;
        public const uint GL_UNSIGNED_INT_IMAGE_BUFFER = 0x9067;
        public const uint GL_UNSIGNED_INT_IMAGE_1D_ARRAY = 0x9068;
        public const uint GL_UNSIGNED_INT_IMAGE_2D_ARRAY = 0x9069;
        public const uint GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY = 0x906A;
        public const uint GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE = 0x906B;
        public const uint GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C;
        public const uint GL_MAX_IMAGE_SAMPLES = 0x906D;
        public const uint GL_IMAGE_BINDING_FORMAT = 0x906E;
        public const uint GL_IMAGE_FORMAT_COMPATIBILITY_TYPE = 0x90C7;
        public const uint GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE = 0x90C8;
        public const uint GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS = 0x90C9;
        public const uint GL_MAX_VERTEX_IMAGE_UNIFORMS = 0x90CA;
        public const uint GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS = 0x90CB;
        public const uint GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS = 0x90CC;
        public const uint GL_MAX_GEOMETRY_IMAGE_UNIFORMS = 0x90CD;
        public const uint GL_MAX_FRAGMENT_IMAGE_UNIFORMS = 0x90CE;
        public const uint GL_MAX_COMBINED_IMAGE_UNIFORMS = 0x90CF;
        public const uint GL_COMPRESSED_RGBA_BPTC_UNORM = 0x8E8C;
        public const uint GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM = 0x8E8D;
        public const uint GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT = 0x8E8E;
        public const uint GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT = 0x8E8F;
        public const uint GL_TEXTURE_IMMUTABLE_FORMAT = 0x912F;
        public const uint GL_NUM_SHADING_LANGUAGE_VERSIONS = 0x82E9;
        public const uint GL_VERTEX_ATTRIB_ARRAY_LONG = 0x874E;
        public const uint GL_COMPRESSED_RGB8_ETC2 = 0x9274;
        public const uint GL_COMPRESSED_SRGB8_ETC2 = 0x9275;
        public const uint GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;
        public const uint GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
        public const uint GL_COMPRESSED_RGBA8_ETC2_EAC = 0x9278;
        public const uint GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;
        public const uint GL_COMPRESSED_R11_EAC = 0x9270;
        public const uint GL_COMPRESSED_SIGNED_R11_EAC = 0x9271;
        public const uint GL_COMPRESSED_RG11_EAC = 0x9272;
        public const uint GL_COMPRESSED_SIGNED_RG11_EAC = 0x9273;
        public const uint GL_PRIMITIVE_RESTART_FIXED_INDEX = 0x8D69;
        public const uint GL_ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;
        public const uint GL_MAX_ELEMENT_INDEX = 0x8D6B;
        public const uint GL_COMPUTE_SHADER = 0x91B9;
        public const uint GL_MAX_COMPUTE_UNIFORM_BLOCKS = 0x91BB;
        public const uint GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = 0x91BC;
        public const uint GL_MAX_COMPUTE_IMAGE_UNIFORMS = 0x91BD;
        public const uint GL_MAX_COMPUTE_SHARED_MEMORY_SIZE = 0x8262;
        public const uint GL_MAX_COMPUTE_UNIFORM_COMPONENTS = 0x8263;
        public const uint GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = 0x8264;
        public const uint GL_MAX_COMPUTE_ATOMIC_COUNTERS = 0x8265;
        public const uint GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = 0x8266;
        public const uint GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = 0x90EB;
        public const uint GL_MAX_COMPUTE_WORK_GROUP_COUNT = 0x91BE;
        public const uint GL_MAX_COMPUTE_WORK_GROUP_SIZE = 0x91BF;
        public const uint GL_COMPUTE_WORK_GROUP_SIZE = 0x8267;
        public const uint GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER = 0x90EC;
        public const uint GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER = 0x90ED;
        public const uint GL_DISPATCH_INDIRECT_BUFFER = 0x90EE;
        public const uint GL_DISPATCH_INDIRECT_BUFFER_BINDING = 0x90EF;
        public const uint GL_COMPUTE_SHADER_BIT = 0x00000020;
        public const uint GL_DEBUG_OUTPUT_SYNCHRONOUS = 0x8242;
        public const uint GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH = 0x8243;
        public const uint GL_DEBUG_CALLBACK_FUNCTION = 0x8244;
        public const uint GL_DEBUG_CALLBACK_USER_PARAM = 0x8245;
        public const uint GL_DEBUG_SOURCE_API = 0x8246;
        public const uint GL_DEBUG_SOURCE_WINDOW_SYSTEM = 0x8247;
        public const uint GL_DEBUG_SOURCE_SHADER_COMPILER = 0x8248;
        public const uint GL_DEBUG_SOURCE_THIRD_PARTY = 0x8249;
        public const uint GL_DEBUG_SOURCE_APPLICATION = 0x824A;
        public const uint GL_DEBUG_SOURCE_OTHER = 0x824B;
        public const uint GL_DEBUG_TYPE_ERROR = 0x824C;
        public const uint GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR = 0x824D;
        public const uint GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR = 0x824E;
        public const uint GL_DEBUG_TYPE_PORTABILITY = 0x824F;
        public const uint GL_DEBUG_TYPE_PERFORMANCE = 0x8250;
        public const uint GL_DEBUG_TYPE_OTHER = 0x8251;
        public const uint GL_MAX_DEBUG_MESSAGE_LENGTH = 0x9143;
        public const uint GL_MAX_DEBUG_LOGGED_MESSAGES = 0x9144;
        public const uint GL_DEBUG_LOGGED_MESSAGES = 0x9145;
        public const uint GL_DEBUG_SEVERITY_HIGH = 0x9146;
        public const uint GL_DEBUG_SEVERITY_MEDIUM = 0x9147;
        public const uint GL_DEBUG_SEVERITY_LOW = 0x9148;
        public const uint GL_DEBUG_TYPE_MARKER = 0x8268;
        public const uint GL_DEBUG_TYPE_PUSH_GROUP = 0x8269;
        public const uint GL_DEBUG_TYPE_POP_GROUP = 0x826A;
        public const uint GL_DEBUG_SEVERITY_NOTIFICATION = 0x826B;
        public const uint GL_MAX_DEBUG_GROUP_STACK_DEPTH = 0x826C;
        public const uint GL_DEBUG_GROUP_STACK_DEPTH = 0x826D;
        public const uint GL_BUFFER = 0x82E0;
        public const uint GL_SHADER = 0x82E1;
        public const uint GL_PROGRAM = 0x82E2;
        public const uint GL_VERTEX_ARRAY = 0x8074;
        public const uint GL_QUERY = 0x82E3;
        public const uint GL_PROGRAM_PIPELINE = 0x82E4;
        public const uint GL_SAMPLER = 0x82E6;
        public const uint GL_MAX_LABEL_LENGTH = 0x82E8;
        public const uint GL_DEBUG_OUTPUT = 0x92E0;
        public const uint GL_CONTEXT_FLAG_DEBUG_BIT = 0x00000002;
        public const uint GL_MAX_UNIFORM_LOCATIONS = 0x826E;
        public const uint GL_FRAMEBUFFER_DEFAULT_WIDTH = 0x9310;
        public const uint GL_FRAMEBUFFER_DEFAULT_HEIGHT = 0x9311;
        public const uint GL_FRAMEBUFFER_DEFAULT_LAYERS = 0x9312;
        public const uint GL_FRAMEBUFFER_DEFAULT_SAMPLES = 0x9313;
        public const uint GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS = 0x9314;
        public const uint GL_MAX_FRAMEBUFFER_WIDTH = 0x9315;
        public const uint GL_MAX_FRAMEBUFFER_HEIGHT = 0x9316;
        public const uint GL_MAX_FRAMEBUFFER_LAYERS = 0x9317;
        public const uint GL_MAX_FRAMEBUFFER_SAMPLES = 0x9318;
        public const uint GL_INTERNALFORMAT_SUPPORTED = 0x826F;
        public const uint GL_INTERNALFORMAT_PREFERRED = 0x8270;
        public const uint GL_INTERNALFORMAT_RED_SIZE = 0x8271;
        public const uint GL_INTERNALFORMAT_GREEN_SIZE = 0x8272;
        public const uint GL_INTERNALFORMAT_BLUE_SIZE = 0x8273;
        public const uint GL_INTERNALFORMAT_ALPHA_SIZE = 0x8274;
        public const uint GL_INTERNALFORMAT_DEPTH_SIZE = 0x8275;
        public const uint GL_INTERNALFORMAT_STENCIL_SIZE = 0x8276;
        public const uint GL_INTERNALFORMAT_SHARED_SIZE = 0x8277;
        public const uint GL_INTERNALFORMAT_RED_TYPE = 0x8278;
        public const uint GL_INTERNALFORMAT_GREEN_TYPE = 0x8279;
        public const uint GL_INTERNALFORMAT_BLUE_TYPE = 0x827A;
        public const uint GL_INTERNALFORMAT_ALPHA_TYPE = 0x827B;
        public const uint GL_INTERNALFORMAT_DEPTH_TYPE = 0x827C;
        public const uint GL_INTERNALFORMAT_STENCIL_TYPE = 0x827D;
        public const uint GL_MAX_WIDTH = 0x827E;
        public const uint GL_MAX_HEIGHT = 0x827F;
        public const uint GL_MAX_DEPTH = 0x8280;
        public const uint GL_MAX_LAYERS = 0x8281;
        public const uint GL_MAX_COMBINED_DIMENSIONS = 0x8282;
        public const uint GL_COLOR_COMPONENTS = 0x8283;
        public const uint GL_DEPTH_COMPONENTS = 0x8284;
        public const uint GL_STENCIL_COMPONENTS = 0x8285;
        public const uint GL_COLOR_RENDERABLE = 0x8286;
        public const uint GL_DEPTH_RENDERABLE = 0x8287;
        public const uint GL_STENCIL_RENDERABLE = 0x8288;
        public const uint GL_FRAMEBUFFER_RENDERABLE = 0x8289;
        public const uint GL_FRAMEBUFFER_RENDERABLE_LAYERED = 0x828A;
        public const uint GL_FRAMEBUFFER_BLEND = 0x828B;
        public const uint GL_READ_PIXELS = 0x828C;
        public const uint GL_READ_PIXELS_FORMAT = 0x828D;
        public const uint GL_READ_PIXELS_TYPE = 0x828E;
        public const uint GL_TEXTURE_IMAGE_FORMAT = 0x828F;
        public const uint GL_TEXTURE_IMAGE_TYPE = 0x8290;
        public const uint GL_GET_TEXTURE_IMAGE_FORMAT = 0x8291;
        public const uint GL_GET_TEXTURE_IMAGE_TYPE = 0x8292;
        public const uint GL_MIPMAP = 0x8293;
        public const uint GL_MANUAL_GENERATE_MIPMAP = 0x8294;
        public const uint GL_AUTO_GENERATE_MIPMAP = 0x8295;
        public const uint GL_COLOR_ENCODING = 0x8296;
        public const uint GL_SRGB_READ = 0x8297;
        public const uint GL_SRGB_WRITE = 0x8298;
        public const uint GL_FILTER = 0x829A;
        public const uint GL_VERTEX_TEXTURE = 0x829B;
        public const uint GL_TESS_CONTROL_TEXTURE = 0x829C;
        public const uint GL_TESS_EVALUATION_TEXTURE = 0x829D;
        public const uint GL_GEOMETRY_TEXTURE = 0x829E;
        public const uint GL_FRAGMENT_TEXTURE = 0x829F;
        public const uint GL_COMPUTE_TEXTURE = 0x82A0;
        public const uint GL_TEXTURE_SHADOW = 0x82A1;
        public const uint GL_TEXTURE_GATHER = 0x82A2;
        public const uint GL_TEXTURE_GATHER_SHADOW = 0x82A3;
        public const uint GL_SHADER_IMAGE_LOAD = 0x82A4;
        public const uint GL_SHADER_IMAGE_STORE = 0x82A5;
        public const uint GL_SHADER_IMAGE_ATOMIC = 0x82A6;
        public const uint GL_IMAGE_TEXEL_SIZE = 0x82A7;
        public const uint GL_IMAGE_COMPATIBILITY_CLASS = 0x82A8;
        public const uint GL_IMAGE_PIXEL_FORMAT = 0x82A9;
        public const uint GL_IMAGE_PIXEL_TYPE = 0x82AA;
        public const uint GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST = 0x82AC;
        public const uint GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST = 0x82AD;
        public const uint GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE = 0x82AE;
        public const uint GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE = 0x82AF;
        public const uint GL_TEXTURE_COMPRESSED_BLOCK_WIDTH = 0x82B1;
        public const uint GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT = 0x82B2;
        public const uint GL_TEXTURE_COMPRESSED_BLOCK_SIZE = 0x82B3;
        public const uint GL_CLEAR_BUFFER = 0x82B4;
        public const uint GL_TEXTURE_VIEW = 0x82B5;
        public const uint GL_VIEW_COMPATIBILITY_CLASS = 0x82B6;
        public const uint GL_FULL_SUPPORT = 0x82B7;
        public const uint GL_CAVEAT_SUPPORT = 0x82B8;
        public const uint GL_IMAGE_CLASS_4_X_32 = 0x82B9;
        public const uint GL_IMAGE_CLASS_2_X_32 = 0x82BA;
        public const uint GL_IMAGE_CLASS_1_X_32 = 0x82BB;
        public const uint GL_IMAGE_CLASS_4_X_16 = 0x82BC;
        public const uint GL_IMAGE_CLASS_2_X_16 = 0x82BD;
        public const uint GL_IMAGE_CLASS_1_X_16 = 0x82BE;
        public const uint GL_IMAGE_CLASS_4_X_8 = 0x82BF;
        public const uint GL_IMAGE_CLASS_2_X_8 = 0x82C0;
        public const uint GL_IMAGE_CLASS_1_X_8 = 0x82C1;
        public const uint GL_IMAGE_CLASS_11_11_10 = 0x82C2;
        public const uint GL_IMAGE_CLASS_10_10_10_2 = 0x82C3;
        public const uint GL_VIEW_CLASS_128_BITS = 0x82C4;
        public const uint GL_VIEW_CLASS_96_BITS = 0x82C5;
        public const uint GL_VIEW_CLASS_64_BITS = 0x82C6;
        public const uint GL_VIEW_CLASS_48_BITS = 0x82C7;
        public const uint GL_VIEW_CLASS_32_BITS = 0x82C8;
        public const uint GL_VIEW_CLASS_24_BITS = 0x82C9;
        public const uint GL_VIEW_CLASS_16_BITS = 0x82CA;
        public const uint GL_VIEW_CLASS_8_BITS = 0x82CB;
        public const uint GL_VIEW_CLASS_S3TC_DXT1_RGB = 0x82CC;
        public const uint GL_VIEW_CLASS_S3TC_DXT1_RGBA = 0x82CD;
        public const uint GL_VIEW_CLASS_S3TC_DXT3_RGBA = 0x82CE;
        public const uint GL_VIEW_CLASS_S3TC_DXT5_RGBA = 0x82CF;
        public const uint GL_VIEW_CLASS_RGTC1_RED = 0x82D0;
        public const uint GL_VIEW_CLASS_RGTC2_RG = 0x82D1;
        public const uint GL_VIEW_CLASS_BPTC_UNORM = 0x82D2;
        public const uint GL_VIEW_CLASS_BPTC_FLOAT = 0x82D3;
        public const uint GL_UNIFORM = 0x92E1;
        public const uint GL_UNIFORM_BLOCK = 0x92E2;
        public const uint GL_PROGRAM_INPUT = 0x92E3;
        public const uint GL_PROGRAM_OUTPUT = 0x92E4;
        public const uint GL_BUFFER_VARIABLE = 0x92E5;
        public const uint GL_SHADER_STORAGE_BLOCK = 0x92E6;
        public const uint GL_VERTEX_SUBROUTINE = 0x92E8;
        public const uint GL_TESS_CONTROL_SUBROUTINE = 0x92E9;
        public const uint GL_TESS_EVALUATION_SUBROUTINE = 0x92EA;
        public const uint GL_GEOMETRY_SUBROUTINE = 0x92EB;
        public const uint GL_FRAGMENT_SUBROUTINE = 0x92EC;
        public const uint GL_COMPUTE_SUBROUTINE = 0x92ED;
        public const uint GL_VERTEX_SUBROUTINE_UNIFORM = 0x92EE;
        public const uint GL_TESS_CONTROL_SUBROUTINE_UNIFORM = 0x92EF;
        public const uint GL_TESS_EVALUATION_SUBROUTINE_UNIFORM = 0x92F0;
        public const uint GL_GEOMETRY_SUBROUTINE_UNIFORM = 0x92F1;
        public const uint GL_FRAGMENT_SUBROUTINE_UNIFORM = 0x92F2;
        public const uint GL_COMPUTE_SUBROUTINE_UNIFORM = 0x92F3;
        public const uint GL_TRANSFORM_FEEDBACK_VARYING = 0x92F4;
        public const uint GL_ACTIVE_RESOURCES = 0x92F5;
        public const uint GL_MAX_NAME_LENGTH = 0x92F6;
        public const uint GL_MAX_NUM_ACTIVE_VARIABLES = 0x92F7;
        public const uint GL_MAX_NUM_COMPATIBLE_SUBROUTINES = 0x92F8;
        public const uint GL_NAME_LENGTH = 0x92F9;
        public const uint GL_TYPE = 0x92FA;
        public const uint GL_ARRAY_SIZE = 0x92FB;
        public const uint GL_OFFSET = 0x92FC;
        public const uint GL_BLOCK_INDEX = 0x92FD;
        public const uint GL_ARRAY_STRIDE = 0x92FE;
        public const uint GL_MATRIX_STRIDE = 0x92FF;
        public const uint GL_IS_ROW_MAJOR = 0x9300;
        public const uint GL_ATOMIC_COUNTER_BUFFER_INDEX = 0x9301;
        public const uint GL_BUFFER_BINDING = 0x9302;
        public const uint GL_BUFFER_DATA_SIZE = 0x9303;
        public const uint GL_NUM_ACTIVE_VARIABLES = 0x9304;
        public const uint GL_ACTIVE_VARIABLES = 0x9305;
        public const uint GL_REFERENCED_BY_VERTEX_SHADER = 0x9306;
        public const uint GL_REFERENCED_BY_TESS_CONTROL_SHADER = 0x9307;
        public const uint GL_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x9308;
        public const uint GL_REFERENCED_BY_GEOMETRY_SHADER = 0x9309;
        public const uint GL_REFERENCED_BY_FRAGMENT_SHADER = 0x930A;
        public const uint GL_REFERENCED_BY_COMPUTE_SHADER = 0x930B;
        public const uint GL_TOP_LEVEL_ARRAY_SIZE = 0x930C;
        public const uint GL_TOP_LEVEL_ARRAY_STRIDE = 0x930D;
        public const uint GL_LOCATION = 0x930E;
        public const uint GL_LOCATION_INDEX = 0x930F;
        public const uint GL_IS_PER_PATCH = 0x92E7;
        public const uint GL_SHADER_STORAGE_BUFFER = 0x90D2;
        public const uint GL_SHADER_STORAGE_BUFFER_BINDING = 0x90D3;
        public const uint GL_SHADER_STORAGE_BUFFER_START = 0x90D4;
        public const uint GL_SHADER_STORAGE_BUFFER_SIZE = 0x90D5;
        public const uint GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS = 0x90D6;
        public const uint GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS = 0x90D7;
        public const uint GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS = 0x90D8;
        public const uint GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS = 0x90D9;
        public const uint GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS = 0x90DA;
        public const uint GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS = 0x90DB;
        public const uint GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS = 0x90DC;
        public const uint GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS = 0x90DD;
        public const uint GL_MAX_SHADER_STORAGE_BLOCK_SIZE = 0x90DE;
        public const uint GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT = 0x90DF;
        public const uint GL_SHADER_STORAGE_BARRIER_BIT = 0x00002000;
        public const uint GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES = 0x8F39;
        public const uint GL_DEPTH_STENCIL_TEXTURE_MODE = 0x90EA;
        public const uint GL_TEXTURE_BUFFER_OFFSET = 0x919D;
        public const uint GL_TEXTURE_BUFFER_SIZE = 0x919E;
        public const uint GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT = 0x919F;
        public const uint GL_TEXTURE_VIEW_MIN_LEVEL = 0x82DB;
        public const uint GL_TEXTURE_VIEW_NUM_LEVELS = 0x82DC;
        public const uint GL_TEXTURE_VIEW_MIN_LAYER = 0x82DD;
        public const uint GL_TEXTURE_VIEW_NUM_LAYERS = 0x82DE;
        public const uint GL_TEXTURE_IMMUTABLE_LEVELS = 0x82DF;
        public const uint GL_VERTEX_ATTRIB_BINDING = 0x82D4;
        public const uint GL_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D5;
        public const uint GL_VERTEX_BINDING_DIVISOR = 0x82D6;
        public const uint GL_VERTEX_BINDING_OFFSET = 0x82D7;
        public const uint GL_VERTEX_BINDING_STRIDE = 0x82D8;
        public const uint GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D9;
        public const uint GL_MAX_VERTEX_ATTRIB_BINDINGS = 0x82DA;
        public const uint GL_VERTEX_BINDING_BUFFER = 0x8F4F;
        public const uint GL_STACK_UNDERFLOW = 0x0504;
        public const uint GL_STACK_OVERFLOW = 0x0503;
        public const uint GL_MAX_VERTEX_ATTRIB_STRIDE = 0x82E5;
        public const uint GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED = 0x8221;
        public const uint GL_TEXTURE_BUFFER_BINDING = 0x8C2A;
        public const uint GL_MAP_PERSISTENT_BIT = 0x0040;
        public const uint GL_MAP_COHERENT_BIT = 0x0080;
        public const uint GL_DYNAMIC_STORAGE_BIT = 0x0100;
        public const uint GL_CLIENT_STORAGE_BIT = 0x0200;
        public const uint GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT = 0x00004000;
        public const uint GL_BUFFER_IMMUTABLE_STORAGE = 0x821F;
        public const uint GL_BUFFER_STORAGE_FLAGS = 0x8220;
        public const uint GL_CLEAR_TEXTURE = 0x9365;
        public const uint GL_LOCATION_COMPONENT = 0x934A;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_INDEX = 0x934B;
        public const uint GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE = 0x934C;
        public const uint GL_QUERY_BUFFER = 0x9192;
        public const uint GL_QUERY_BUFFER_BARRIER_BIT = 0x00008000;
        public const uint GL_QUERY_BUFFER_BINDING = 0x9193;
        public const uint GL_QUERY_RESULT_NO_WAIT = 0x9194;
        public const uint GL_MIRROR_CLAMP_TO_EDGE = 0x8743;
        public const uint GL_CONTEXT_LOST = 0x0507;
        public const uint GL_NEGATIVE_ONE_TO_ONE = 0x935E;
        public const uint GL_ZERO_TO_ONE = 0x935F;
        public const uint GL_CLIP_ORIGIN = 0x935C;
        public const uint GL_CLIP_DEPTH_MODE = 0x935D;
        public const uint GL_QUERY_WAIT_INVERTED = 0x8E17;
        public const uint GL_QUERY_NO_WAIT_INVERTED = 0x8E18;
        public const uint GL_QUERY_BY_REGION_WAIT_INVERTED = 0x8E19;
        public const uint GL_QUERY_BY_REGION_NO_WAIT_INVERTED = 0x8E1A;
        public const uint GL_MAX_CULL_DISTANCES = 0x82F9;
        public const uint GL_MAX_COMBINED_CLIP_AND_CULL_DISTANCES = 0x82FA;
        public const uint GL_TEXTURE_TARGET = 0x1006;
        public const uint GL_QUERY_TARGET = 0x82EA;
        public const uint GL_GUILTY_CONTEXT_RESET = 0x8253;
        public const uint GL_INNOCENT_CONTEXT_RESET = 0x8254;
        public const uint GL_UNKNOWN_CONTEXT_RESET = 0x8255;
        public const uint GL_RESET_NOTIFICATION_STRATEGY = 0x8256;
        public const uint GL_LOSE_CONTEXT_ON_RESET = 0x8252;
        public const uint GL_NO_RESET_NOTIFICATION = 0x8261;
        public const uint GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT = 0x00000004;
        public const uint GL_CONTEXT_RELEASE_BEHAVIOR = 0x82FB;
        public const uint GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH = 0x82FC;
        public const uint GL_SHADER_BINARY_FORMAT_SPIR_V = 0x9551;
        public const uint GL_SPIR_V_BINARY = 0x9552;
        public const uint GL_PARAMETER_BUFFER = 0x80EE;
        public const uint GL_PARAMETER_BUFFER_BINDING = 0x80EF;
        public const uint GL_CONTEXT_FLAG_NO_ERROR_BIT = 0x00000008;
        public const uint GL_VERTICES_SUBMITTED = 0x82EE;
        public const uint GL_PRIMITIVES_SUBMITTED = 0x82EF;
        public const uint GL_VERTEX_SHADER_INVOCATIONS = 0x82F0;
        public const uint GL_TESS_CONTROL_SHADER_PATCHES = 0x82F1;
        public const uint GL_TESS_EVALUATION_SHADER_INVOCATIONS = 0x82F2;
        public const uint GL_GEOMETRY_SHADER_PRIMITIVES_EMITTED = 0x82F3;
        public const uint GL_FRAGMENT_SHADER_INVOCATIONS = 0x82F4;
        public const uint GL_COMPUTE_SHADER_INVOCATIONS = 0x82F5;
        public const uint GL_CLIPPING_INPUT_PRIMITIVES = 0x82F6;
        public const uint GL_CLIPPING_OUTPUT_PRIMITIVES = 0x82F7;
        public const uint GL_POLYGON_OFFSET_CLAMP = 0x8E1B;
        public const uint GL_SPIR_V_EXTENSIONS = 0x9553;
        public const uint GL_NUM_SPIR_V_EXTENSIONS = 0x9554;
        public const uint GL_TEXTURE_MAX_ANISOTROPY = 0x84FE;
        public const uint GL_MAX_TEXTURE_MAX_ANISOTROPY = 0x84FF;
        public const uint GL_TRANSFORM_FEEDBACK_OVERFLOW = 0x82EC;
        public const uint GL_TRANSFORM_FEEDBACK_STREAM_OVERFLOW = 0x82ED;

        public function void GlCullFace(uint mode);
        public static GlCullFace glCullFace;

        public function void GlFrontFace(uint mode);
        public static GlFrontFace glFrontFace;

        public function void GlHint(uint target, uint mode);
        public static GlHint glHint;

        public function void GlLineWidth(float width);
        public static GlLineWidth glLineWidth;

        public function void GlPointSize(float size);
        public static GlPointSize glPointSize;

        public function void GlPolygonMode(uint face, uint mode);
        public static GlPolygonMode glPolygonMode;

        public function void GlScissor(int x, int y, int width, int height);
        public static GlScissor glScissor;

        public function void GlTexParameterf(uint target, uint pname, float param);
        public static GlTexParameterf glTexParameterf;

        public function void GlTexParameterfv(uint target, uint pname, float* paramss);
        public static GlTexParameterfv glTexParameterfv;

        public function void GlTexParameteri(uint target, uint pname, int param);
        public static GlTexParameteri glTexParameteri;

        public function void GlTexParameteriv(uint target, uint pname, int32* paramss);
        public static GlTexParameteriv glTexParameteriv;

        public function void GlTexImage1D(uint target, int level, int internalformat, int width, int border, uint format, uint type, void* pixels);
        public static GlTexImage1D glTexImage1D;

        public function void GlTexImage2D(uint target, int level, int internalformat, int width, int height, int border, uint format, uint type, void* pixels);
        public static GlTexImage2D glTexImage2D;

        public function void GlDrawBuffer(uint buf);
        public static GlDrawBuffer glDrawBuffer;

        public function void GlClear(uint mask);
        public static GlClear glClear;

        public function void GlClearColor(float red, float green, float blue, float alpha);
        public static GlClearColor glClearColor;

        public function void GlClearStencil(int s);
        public static GlClearStencil glClearStencil;

        public function void GlClearDepth(double depth);
        public static GlClearDepth glClearDepth;

        public function void GlStencilMask(uint mask);
        public static GlStencilMask glStencilMask;

        public function void GlColorMask(uint8 red, uint8 green, uint8 blue, uint8 alpha);
        public static GlColorMask glColorMask;

        public function void GlDepthMask(uint8 flag);
        public static GlDepthMask glDepthMask;

        public function void GlDisable(uint cap);
        public static GlDisable glDisable;

        public function void GlEnable(uint cap);
        public static GlEnable glEnable;

        public function void GlFinish();
        public static GlFinish glFinish;

        public function void GlFlush();
        public static GlFlush glFlush;

        public function void GlBlendFunc(uint sfactor, uint dfactor);
        public static GlBlendFunc glBlendFunc;

        public function void GlLogicOp(uint opcode);
        public static GlLogicOp glLogicOp;

        public function void GlStencilFunc(uint func, int reff, uint mask);
        public static GlStencilFunc glStencilFunc;

        public function void GlStencilOp(uint fail, uint zfail, uint zpass);
        public static GlStencilOp glStencilOp;

        public function void GlDepthFunc(uint func);
        public static GlDepthFunc glDepthFunc;

        public function void GlPixelStoref(uint pname, float param);
        public static GlPixelStoref glPixelStoref;

        public function void GlPixelStorei(uint pname, int param);
        public static GlPixelStorei glPixelStorei;

        public function void GlReadBuffer(uint src);
        public static GlReadBuffer glReadBuffer;

        public function void GlReadPixels(int x, int y, int width, int height, uint format, uint type, void* pixels);
        public static GlReadPixels glReadPixels;

        public function void GlGetBooleanv(uint pname, uint8* data);
        public static GlGetBooleanv glGetBooleanv;

        public function void GlGetDoublev(uint pname, double* data);
        public static GlGetDoublev glGetDoublev;

        public function uint GlGetError();
        public static GlGetError glGetError;

        public function void GlGetFloatv(uint pname, float* data);
        public static GlGetFloatv glGetFloatv;

        public function void GlGetIntegerv(uint pname, int32* data);
        public static GlGetIntegerv glGetIntegerv;

        public function uint8 GlGetString(uint name);
        public static GlGetString glGetString;

        public function void GlGetTexImage(uint target, int level, uint format, uint type, void* pixels);
        public static GlGetTexImage glGetTexImage;

        public function void GlGetTexParameterfv(uint target, uint pname, float* paramss);
        public static GlGetTexParameterfv glGetTexParameterfv;

        public function void GlGetTexParameteriv(uint target, uint pname, int32* paramss);
        public static GlGetTexParameteriv glGetTexParameteriv;

        public function void GlGetTexLevelParameterfv(uint target, int level, uint pname, float* paramss);
        public static GlGetTexLevelParameterfv glGetTexLevelParameterfv;

        public function void GlGetTexLevelParameteriv(uint target, int level, uint pname, int32* paramss);
        public static GlGetTexLevelParameteriv glGetTexLevelParameteriv;

        public function uint8 GlIsEnabled(uint cap);
        public static GlIsEnabled glIsEnabled;

        public function void GlDepthRange(double n, double f);
        public static GlDepthRange glDepthRange;

        public function void GlViewport(int x, int y, int width, int height);
        public static GlViewport glViewport;

        public function void GlDrawArrays(uint mode, int first, int count);
        public static GlDrawArrays glDrawArrays;

        public function void GlDrawElements(uint mode, int count, uint type, void* indices);
        public static GlDrawElements glDrawElements;

        public function void GlPolygonOffset(float factor, float units);
        public static GlPolygonOffset glPolygonOffset;

        public function void GlCopyTexImage1D(uint target, int level, uint internalformat, int x, int y, int width, int border);
        public static GlCopyTexImage1D glCopyTexImage1D;

        public function void GlCopyTexImage2D(uint target, int level, uint internalformat, int x, int y, int width, int height, int border);
        public static GlCopyTexImage2D glCopyTexImage2D;

        public function void GlCopyTexSubImage1D(uint target, int level, int xoffset, int x, int y, int width);
        public static GlCopyTexSubImage1D glCopyTexSubImage1D;

        public function void GlCopyTexSubImage2D(uint target, int level, int xoffset, int yoffset, int x, int y, int width, int height);
        public static GlCopyTexSubImage2D glCopyTexSubImage2D;

        public function void GlTexSubImage1D(uint target, int level, int xoffset, int width, uint format, uint type, void* pixels);
        public static GlTexSubImage1D glTexSubImage1D;

        public function void GlTexSubImage2D(uint target, int level, int xoffset, int yoffset, int width, int height, uint format, uint type, void* pixels);
        public static GlTexSubImage2D glTexSubImage2D;

        public function void GlBindTexture(uint target, uint texture);
        public static GlBindTexture glBindTexture;

        public function void GlDeleteTextures(int n, uint32* textures);
        public static GlDeleteTextures glDeleteTextures;

        public function void GlGenTextures(int n, uint32* textures);
        public static GlGenTextures glGenTextures;

        public function uint8 GlIsTexture(uint texture);
        public static GlIsTexture glIsTexture;

        public function void GlDrawRangeElements(uint mode, uint start, uint end, int count, uint type, void* indices);
        public static GlDrawRangeElements glDrawRangeElements;

        public function void GlTexImage3D(uint target, int level, int internalformat, int width, int height, int depth, int border, uint format, uint type, void* pixels);
        public static GlTexImage3D glTexImage3D;

        public function void GlTexSubImage3D(uint target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, uint format, uint type, void* pixels);
        public static GlTexSubImage3D glTexSubImage3D;

        public function void GlCopyTexSubImage3D(uint target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height);
        public static GlCopyTexSubImage3D glCopyTexSubImage3D;

        public function void GlActiveTexture(uint texture);
        public static GlActiveTexture glActiveTexture;

        public function void GlSampleCoverage(float value, uint8 invert);
        public static GlSampleCoverage glSampleCoverage;

        public function void GlCompressedTexImage3D(uint target, int level, uint internalformat, int width, int height, int depth, int border, int imageSize, void* data);
        public static GlCompressedTexImage3D glCompressedTexImage3D;

        public function void GlCompressedTexImage2D(uint target, int level, uint internalformat, int width, int height, int border, int imageSize, void* data);
        public static GlCompressedTexImage2D glCompressedTexImage2D;

        public function void GlCompressedTexImage1D(uint target, int level, uint internalformat, int width, int border, int imageSize, void* data);
        public static GlCompressedTexImage1D glCompressedTexImage1D;

        public function void GlCompressedTexSubImage3D(uint target, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, uint format, int imageSize, void* data);
        public static GlCompressedTexSubImage3D glCompressedTexSubImage3D;

        public function void GlCompressedTexSubImage2D(uint target, int level, int xoffset, int yoffset, int width, int height, uint format, int imageSize, void* data);
        public static GlCompressedTexSubImage2D glCompressedTexSubImage2D;

        public function void GlCompressedTexSubImage1D(uint target, int level, int xoffset, int width, uint format, int imageSize, void* data);
        public static GlCompressedTexSubImage1D glCompressedTexSubImage1D;

        public function void GlGetCompressedTexImage(uint target, int level, void* img);
        public static GlGetCompressedTexImage glGetCompressedTexImage;

        public function void GlBlendFuncSeparate(uint sfactorRGB, uint dfactorRGB, uint sfactorAlpha, uint dfactorAlpha);
        public static GlBlendFuncSeparate glBlendFuncSeparate;

        public function void GlMultiDrawArrays(uint mode, int32* first, int32* count, int drawcount);
        public static GlMultiDrawArrays glMultiDrawArrays;

        public function void GlMultiDrawElements(uint mode, int32* count, uint type, void *** indices, int drawcount);
        public static GlMultiDrawElements glMultiDrawElements;

        public function void GlPointParameterf(uint pname, float param);
        public static GlPointParameterf glPointParameterf;

        public function void GlPointParameterfv(uint pname, float* paramss);
        public static GlPointParameterfv glPointParameterfv;

        public function void GlPointParameteri(uint pname, int param);
        public static GlPointParameteri glPointParameteri;

        public function void GlPointParameteriv(uint pname, int32* paramss);
        public static GlPointParameteriv glPointParameteriv;

        public function void GlBlendColor(float red, float green, float blue, float alpha);
        public static GlBlendColor glBlendColor;

        public function void GlBlendEquation(uint mode);
        public static GlBlendEquation glBlendEquation;

        public function void GlGenQueries(int n, uint32* ids);
        public static GlGenQueries glGenQueries;

        public function void GlDeleteQueries(int n, uint32* ids);
        public static GlDeleteQueries glDeleteQueries;

        public function uint8 GlIsQuery(uint id);
        public static GlIsQuery glIsQuery;

        public function void GlBeginQuery(uint target, uint id);
        public static GlBeginQuery glBeginQuery;

        public function void GlEndQuery(uint target);
        public static GlEndQuery glEndQuery;

        public function void GlGetQueryiv(uint target, uint pname, int32* paramss);
        public static GlGetQueryiv glGetQueryiv;

        public function void GlGetQueryObjectiv(uint id, uint pname, int32* paramss);
        public static GlGetQueryObjectiv glGetQueryObjectiv;

        public function void GlGetQueryObjectuiv(uint id, uint pname, uint32* paramss);
        public static GlGetQueryObjectuiv glGetQueryObjectuiv;

        public function void GlBindBuffer(uint target, uint buffer);
        public static GlBindBuffer glBindBuffer;

        public function void GlDeleteBuffers(int n, uint32* buffers);
        public static GlDeleteBuffers glDeleteBuffers;

        public function void GlGenBuffers(int n, uint32* buffers);
        public static GlGenBuffers glGenBuffers;

        public function uint8 GlIsBuffer(uint buffer);
        public static GlIsBuffer glIsBuffer;

        public function void GlBufferData(uint target, int size, void* data, uint usage);
        public static GlBufferData glBufferData;

        public function void GlBufferSubData(uint target, int offset, int size, void* data);
        public static GlBufferSubData glBufferSubData;

        public function void GlGetBufferSubData(uint target, int offset, int size, void* data);
        public static GlGetBufferSubData glGetBufferSubData;

        public function void GlMapBuffer(uint target, uint access);
        public static GlMapBuffer glMapBuffer;

        public function uint8 GlUnmapBuffer(uint target);
        public static GlUnmapBuffer glUnmapBuffer;

        public function void GlGetBufferParameteriv(uint target, uint pname, int32* paramss);
        public static GlGetBufferParameteriv glGetBufferParameteriv;

        public function void GlGetBufferPointerv(uint target, uint pname, void *** paramss);
        public static GlGetBufferPointerv glGetBufferPointerv;

        public function void GlBlendEquationSeparate(uint modeRGB, uint modeAlpha);
        public static GlBlendEquationSeparate glBlendEquationSeparate;

        public function void GlDrawBuffers(int n, uint32* bufs);
        public static GlDrawBuffers glDrawBuffers;

        public function void GlStencilOpSeparate(uint face, uint sfail, uint dpfail, uint dppass);
        public static GlStencilOpSeparate glStencilOpSeparate;

        public function void GlStencilFuncSeparate(uint face, uint func, int reff, uint mask);
        public static GlStencilFuncSeparate glStencilFuncSeparate;

        public function void GlStencilMaskSeparate(uint face, uint mask);
        public static GlStencilMaskSeparate glStencilMaskSeparate;

        public function void GlAttachShader(uint program, uint shader);
        public static GlAttachShader glAttachShader;

        public function void GlBindAttribLocation(uint program, uint index, char8* name);
        public static GlBindAttribLocation glBindAttribLocation;

        public function void GlCompileShader(uint shader);
        public static GlCompileShader glCompileShader;

        public function uint GlCreateProgram();
        public static GlCreateProgram glCreateProgram;

        public function uint GlCreateShader(uint type);
        public static GlCreateShader glCreateShader;

        public function void GlDeleteProgram(uint program);
        public static GlDeleteProgram glDeleteProgram;

        public function void GlDeleteShader(uint shader);
        public static GlDeleteShader glDeleteShader;

        public function void GlDetachShader(uint program, uint shader);
        public static GlDetachShader glDetachShader;

        public function void GlDisableVertexAttribArray(uint index);
        public static GlDisableVertexAttribArray glDisableVertexAttribArray;

        public function void GlEnableVertexAttribArray(uint index);
        public static GlEnableVertexAttribArray glEnableVertexAttribArray;

        public function void GlGetActiveAttrib(uint program, uint index, int bufSize, int32* length, int32* size, uint32* type, char8* name);
        public static GlGetActiveAttrib glGetActiveAttrib;

        public function void GlGetActiveUniform(uint program, uint index, int bufSize, int32* length, int32* size, uint32* type, char8* name);
        public static GlGetActiveUniform glGetActiveUniform;

        public function void GlGetAttachedShaders(uint program, int maxCount, int32* count, uint32* shaders);
        public static GlGetAttachedShaders glGetAttachedShaders;

        public function int GlGetAttribLocation(uint program, char8* name);
        public static GlGetAttribLocation glGetAttribLocation;

        public function void GlGetProgramiv(uint program, uint pname, int32* paramss);
        public static GlGetProgramiv glGetProgramiv;

        public function void GlGetProgramInfoLog(uint program, int bufSize, int32* length, char8* infoLog);
        public static GlGetProgramInfoLog glGetProgramInfoLog;

        public function void GlGetShaderiv(uint shader, uint pname, int32* paramss);
        public static GlGetShaderiv glGetShaderiv;

        public function void GlGetShaderInfoLog(uint shader, int bufSize, int32* length, char8* infoLog);
        public static GlGetShaderInfoLog glGetShaderInfoLog;

        public function void GlGetShaderSource(uint shader, int bufSize, int32* length, char8* source);
        public static GlGetShaderSource glGetShaderSource;

        public function int GlGetUniformLocation(uint program, char8* name);
        public static GlGetUniformLocation glGetUniformLocation;

        public function void GlGetUniformfv(uint program, int location, float* paramss);
        public static GlGetUniformfv glGetUniformfv;

        public function void GlGetUniformiv(uint program, int location, int32* paramss);
        public static GlGetUniformiv glGetUniformiv;

        public function void GlGetVertexAttribdv(uint index, uint pname, double* paramss);
        public static GlGetVertexAttribdv glGetVertexAttribdv;

        public function void GlGetVertexAttribfv(uint index, uint pname, float* paramss);
        public static GlGetVertexAttribfv glGetVertexAttribfv;

        public function void GlGetVertexAttribiv(uint index, uint pname, int32* paramss);
        public static GlGetVertexAttribiv glGetVertexAttribiv;

        public function void GlGetVertexAttribPointerv(uint index, uint pname, void *** pointer);
        public static GlGetVertexAttribPointerv glGetVertexAttribPointerv;

        public function uint8 GlIsProgram(uint program);
        public static GlIsProgram glIsProgram;

        public function uint8 GlIsShader(uint shader);
        public static GlIsShader glIsShader;

        public function void GlLinkProgram(uint program);
        public static GlLinkProgram glLinkProgram;

        public function void GlShaderSource(uint shader, int count, char8** string, int32* length);
        public static GlShaderSource glShaderSource;

        public function void GlUseProgram(uint program);
        public static GlUseProgram glUseProgram;

        public function void GlUniform1f(int location, float v0);
        public static GlUniform1f glUniform1f;

        public function void GlUniform2f(int location, float v0, float v1);
        public static GlUniform2f glUniform2f;

        public function void GlUniform3f(int location, float v0, float v1, float v2);
        public static GlUniform3f glUniform3f;

        public function void GlUniform4f(int location, float v0, float v1, float v2, float v3);
        public static GlUniform4f glUniform4f;

        public function void GlUniform1i(int location, int v0);
        public static GlUniform1i glUniform1i;

        public function void GlUniform2i(int location, int v0, int v1);
        public static GlUniform2i glUniform2i;

        public function void GlUniform3i(int location, int v0, int v1, int v2);
        public static GlUniform3i glUniform3i;

        public function void GlUniform4i(int location, int v0, int v1, int v2, int v3);
        public static GlUniform4i glUniform4i;

        public function void GlUniform1fv(int location, int count, float* value);
        public static GlUniform1fv glUniform1fv;

        public function void GlUniform2fv(int location, int count, float* value);
        public static GlUniform2fv glUniform2fv;

        public function void GlUniform3fv(int location, int count, float* value);
        public static GlUniform3fv glUniform3fv;

        public function void GlUniform4fv(int location, int count, float* value);
        public static GlUniform4fv glUniform4fv;

        public function void GlUniform1iv(int location, int count, int32* value);
        public static GlUniform1iv glUniform1iv;

        public function void GlUniform2iv(int location, int count, int32* value);
        public static GlUniform2iv glUniform2iv;

        public function void GlUniform3iv(int location, int count, int32* value);
        public static GlUniform3iv glUniform3iv;

        public function void GlUniform4iv(int location, int count, int32* value);
        public static GlUniform4iv glUniform4iv;

        public function void GlUniformMatrix2fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix2fv glUniformMatrix2fv;

        public function void GlUniformMatrix3fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix3fv glUniformMatrix3fv;

        public function void GlUniformMatrix4fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix4fv glUniformMatrix4fv;

        public function void GlValidateProgram(uint program);
        public static GlValidateProgram glValidateProgram;

        public function void GlVertexAttrib1d(uint index, double x);
        public static GlVertexAttrib1d glVertexAttrib1d;

        public function void GlVertexAttrib1dv(uint index, double* v);
        public static GlVertexAttrib1dv glVertexAttrib1dv;

        public function void GlVertexAttrib1f(uint index, float x);
        public static GlVertexAttrib1f glVertexAttrib1f;

        public function void GlVertexAttrib1fv(uint index, float* v);
        public static GlVertexAttrib1fv glVertexAttrib1fv;

        public function void GlVertexAttrib1s(uint index, int16 x);
        public static GlVertexAttrib1s glVertexAttrib1s;

        public function void GlVertexAttrib1sv(uint index, int16* v);
        public static GlVertexAttrib1sv glVertexAttrib1sv;

        public function void GlVertexAttrib2d(uint index, double x, double y);
        public static GlVertexAttrib2d glVertexAttrib2d;

        public function void GlVertexAttrib2dv(uint index, double* v);
        public static GlVertexAttrib2dv glVertexAttrib2dv;

        public function void GlVertexAttrib2f(uint index, float x, float y);
        public static GlVertexAttrib2f glVertexAttrib2f;

        public function void GlVertexAttrib2fv(uint index, float* v);
        public static GlVertexAttrib2fv glVertexAttrib2fv;

        public function void GlVertexAttrib2s(uint index, int16 x, int16 y);
        public static GlVertexAttrib2s glVertexAttrib2s;

        public function void GlVertexAttrib2sv(uint index, int16* v);
        public static GlVertexAttrib2sv glVertexAttrib2sv;

        public function void GlVertexAttrib3d(uint index, double x, double y, double z);
        public static GlVertexAttrib3d glVertexAttrib3d;

        public function void GlVertexAttrib3dv(uint index, double* v);
        public static GlVertexAttrib3dv glVertexAttrib3dv;

        public function void GlVertexAttrib3f(uint index, float x, float y, float z);
        public static GlVertexAttrib3f glVertexAttrib3f;

        public function void GlVertexAttrib3fv(uint index, float* v);
        public static GlVertexAttrib3fv glVertexAttrib3fv;

        public function void GlVertexAttrib3s(uint index, int16 x, int16 y, int16 z);
        public static GlVertexAttrib3s glVertexAttrib3s;

        public function void GlVertexAttrib3sv(uint index, int16* v);
        public static GlVertexAttrib3sv glVertexAttrib3sv;

        public function void GlVertexAttrib4Nbv(uint index, int8* v);
        public static GlVertexAttrib4Nbv glVertexAttrib4Nbv;

        public function void GlVertexAttrib4Niv(uint index, int32* v);
        public static GlVertexAttrib4Niv glVertexAttrib4Niv;

        public function void GlVertexAttrib4Nsv(uint index, int16* v);
        public static GlVertexAttrib4Nsv glVertexAttrib4Nsv;

        public function void GlVertexAttrib4Nub(uint index, uint8 x, uint8 y, uint8 z, uint8 w);
        public static GlVertexAttrib4Nub glVertexAttrib4Nub;

        public function void GlVertexAttrib4Nubv(uint index, uint8* v);
        public static GlVertexAttrib4Nubv glVertexAttrib4Nubv;

        public function void GlVertexAttrib4Nuiv(uint index, uint32* v);
        public static GlVertexAttrib4Nuiv glVertexAttrib4Nuiv;

        public function void GlVertexAttrib4Nusv(uint index, uint16* v);
        public static GlVertexAttrib4Nusv glVertexAttrib4Nusv;

        public function void GlVertexAttrib4bv(uint index, int8* v);
        public static GlVertexAttrib4bv glVertexAttrib4bv;

        public function void GlVertexAttrib4d(uint index, double x, double y, double z, double w);
        public static GlVertexAttrib4d glVertexAttrib4d;

        public function void GlVertexAttrib4dv(uint index, double* v);
        public static GlVertexAttrib4dv glVertexAttrib4dv;

        public function void GlVertexAttrib4f(uint index, float x, float y, float z, float w);
        public static GlVertexAttrib4f glVertexAttrib4f;

        public function void GlVertexAttrib4fv(uint index, float* v);
        public static GlVertexAttrib4fv glVertexAttrib4fv;

        public function void GlVertexAttrib4iv(uint index, int32* v);
        public static GlVertexAttrib4iv glVertexAttrib4iv;

        public function void GlVertexAttrib4s(uint index, int16 x, int16 y, int16 z, int16 w);
        public static GlVertexAttrib4s glVertexAttrib4s;

        public function void GlVertexAttrib4sv(uint index, int16* v);
        public static GlVertexAttrib4sv glVertexAttrib4sv;

        public function void GlVertexAttrib4ubv(uint index, uint8* v);
        public static GlVertexAttrib4ubv glVertexAttrib4ubv;

        public function void GlVertexAttrib4uiv(uint index, uint32* v);
        public static GlVertexAttrib4uiv glVertexAttrib4uiv;

        public function void GlVertexAttrib4usv(uint index, uint16* v);
        public static GlVertexAttrib4usv glVertexAttrib4usv;

        public function void GlVertexAttribPointer(uint index, int size, uint type, uint8 normalized, int stride, void* pointer);
        public static GlVertexAttribPointer glVertexAttribPointer;

        public function void GlUniformMatrix2x3fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix2x3fv glUniformMatrix2x3fv;

        public function void GlUniformMatrix3x2fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix3x2fv glUniformMatrix3x2fv;

        public function void GlUniformMatrix2x4fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix2x4fv glUniformMatrix2x4fv;

        public function void GlUniformMatrix4x2fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix4x2fv glUniformMatrix4x2fv;

        public function void GlUniformMatrix3x4fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix3x4fv glUniformMatrix3x4fv;

        public function void GlUniformMatrix4x3fv(int location, int count, uint8 transpose, float* value);
        public static GlUniformMatrix4x3fv glUniformMatrix4x3fv;

        public function void GlColorMaski(uint index, uint8 r, uint8 g, uint8 b, uint8 a);
        public static GlColorMaski glColorMaski;

        public function void GlGetBooleani_v(uint target, uint index, uint8* data);
        public static GlGetBooleani_v glGetBooleani_v;

        public function void GlGetIntegeri_v(uint target, uint index, int32* data);
        public static GlGetIntegeri_v glGetIntegeri_v;

        public function void GlEnablei(uint target, uint index);
        public static GlEnablei glEnablei;

        public function void GlDisablei(uint target, uint index);
        public static GlDisablei glDisablei;

        public function uint8 GlIsEnabledi(uint target, uint index);
        public static GlIsEnabledi glIsEnabledi;

        public function void GlBeginTransformFeedback(uint primitiveMode);
        public static GlBeginTransformFeedback glBeginTransformFeedback;

        public function void GlEndTransformFeedback();
        public static GlEndTransformFeedback glEndTransformFeedback;

        public function void GlBindBufferRange(uint target, uint index, uint buffer, int offset, int size);
        public static GlBindBufferRange glBindBufferRange;

        public function void GlBindBufferBase(uint target, uint index, uint buffer);
        public static GlBindBufferBase glBindBufferBase;

        public function void GlTransformFeedbackVaryings(uint program, int count, char8** varyings, uint bufferMode);
        public static GlTransformFeedbackVaryings glTransformFeedbackVaryings;

        public function void GlGetTransformFeedbackVarying(uint program, uint index, int bufSize, int32* length, int32* size, uint32* type, char8* name);
        public static GlGetTransformFeedbackVarying glGetTransformFeedbackVarying;

        public function void GlClampColor(uint target, uint clamp);
        public static GlClampColor glClampColor;

        public function void GlBeginConditionalRender(uint id, uint mode);
        public static GlBeginConditionalRender glBeginConditionalRender;

        public function void GlEndConditionalRender();
        public static GlEndConditionalRender glEndConditionalRender;

        public function void GlVertexAttribIPointer(uint index, int size, uint type, int stride, void* pointer);
        public static GlVertexAttribIPointer glVertexAttribIPointer;

        public function void GlGetVertexAttribIiv(uint index, uint pname, int32* paramss);
        public static GlGetVertexAttribIiv glGetVertexAttribIiv;

        public function void GlGetVertexAttribIuiv(uint index, uint pname, uint32* paramss);
        public static GlGetVertexAttribIuiv glGetVertexAttribIuiv;

        public function void GlVertexAttribI1i(uint index, int x);
        public static GlVertexAttribI1i glVertexAttribI1i;

        public function void GlVertexAttribI2i(uint index, int x, int y);
        public static GlVertexAttribI2i glVertexAttribI2i;

        public function void GlVertexAttribI3i(uint index, int x, int y, int z);
        public static GlVertexAttribI3i glVertexAttribI3i;

        public function void GlVertexAttribI4i(uint index, int x, int y, int z, int w);
        public static GlVertexAttribI4i glVertexAttribI4i;

        public function void GlVertexAttribI1ui(uint index, uint x);
        public static GlVertexAttribI1ui glVertexAttribI1ui;

        public function void GlVertexAttribI2ui(uint index, uint x, uint y);
        public static GlVertexAttribI2ui glVertexAttribI2ui;

        public function void GlVertexAttribI3ui(uint index, uint x, uint y, uint z);
        public static GlVertexAttribI3ui glVertexAttribI3ui;

        public function void GlVertexAttribI4ui(uint index, uint x, uint y, uint z, uint w);
        public static GlVertexAttribI4ui glVertexAttribI4ui;

        public function void GlVertexAttribI1iv(uint index, int32* v);
        public static GlVertexAttribI1iv glVertexAttribI1iv;

        public function void GlVertexAttribI2iv(uint index, int32* v);
        public static GlVertexAttribI2iv glVertexAttribI2iv;

        public function void GlVertexAttribI3iv(uint index, int32* v);
        public static GlVertexAttribI3iv glVertexAttribI3iv;

        public function void GlVertexAttribI4iv(uint index, int32* v);
        public static GlVertexAttribI4iv glVertexAttribI4iv;

        public function void GlVertexAttribI1uiv(uint index, uint32* v);
        public static GlVertexAttribI1uiv glVertexAttribI1uiv;

        public function void GlVertexAttribI2uiv(uint index, uint32* v);
        public static GlVertexAttribI2uiv glVertexAttribI2uiv;

        public function void GlVertexAttribI3uiv(uint index, uint32* v);
        public static GlVertexAttribI3uiv glVertexAttribI3uiv;

        public function void GlVertexAttribI4uiv(uint index, uint32* v);
        public static GlVertexAttribI4uiv glVertexAttribI4uiv;

        public function void GlVertexAttribI4bv(uint index, int8* v);
        public static GlVertexAttribI4bv glVertexAttribI4bv;

        public function void GlVertexAttribI4sv(uint index, int16* v);
        public static GlVertexAttribI4sv glVertexAttribI4sv;

        public function void GlVertexAttribI4ubv(uint index, uint8* v);
        public static GlVertexAttribI4ubv glVertexAttribI4ubv;

        public function void GlVertexAttribI4usv(uint index, uint16* v);
        public static GlVertexAttribI4usv glVertexAttribI4usv;

        public function void GlGetUniformuiv(uint program, int location, uint32* paramss);
        public static GlGetUniformuiv glGetUniformuiv;

        public function void GlBindFragDataLocation(uint program, uint color, char8* name);
        public static GlBindFragDataLocation glBindFragDataLocation;

        public function int GlGetFragDataLocation(uint program, char8* name);
        public static GlGetFragDataLocation glGetFragDataLocation;

        public function void GlUniform1ui(int location, uint v0);
        public static GlUniform1ui glUniform1ui;

        public function void GlUniform2ui(int location, uint v0, uint v1);
        public static GlUniform2ui glUniform2ui;

        public function void GlUniform3ui(int location, uint v0, uint v1, uint v2);
        public static GlUniform3ui glUniform3ui;

        public function void GlUniform4ui(int location, uint v0, uint v1, uint v2, uint v3);
        public static GlUniform4ui glUniform4ui;

        public function void GlUniform1uiv(int location, int count, uint32* value);
        public static GlUniform1uiv glUniform1uiv;

        public function void GlUniform2uiv(int location, int count, uint32* value);
        public static GlUniform2uiv glUniform2uiv;

        public function void GlUniform3uiv(int location, int count, uint32* value);
        public static GlUniform3uiv glUniform3uiv;

        public function void GlUniform4uiv(int location, int count, uint32* value);
        public static GlUniform4uiv glUniform4uiv;

        public function void GlTexParameterIiv(uint target, uint pname, int32* paramss);
        public static GlTexParameterIiv glTexParameterIiv;

        public function void GlTexParameterIuiv(uint target, uint pname, uint32* paramss);
        public static GlTexParameterIuiv glTexParameterIuiv;

        public function void GlGetTexParameterIiv(uint target, uint pname, int32* paramss);
        public static GlGetTexParameterIiv glGetTexParameterIiv;

        public function void GlGetTexParameterIuiv(uint target, uint pname, uint32* paramss);
        public static GlGetTexParameterIuiv glGetTexParameterIuiv;

        public function void GlClearBufferiv(uint buffer, int drawbuffer, int32* value);
        public static GlClearBufferiv glClearBufferiv;

        public function void GlClearBufferuiv(uint buffer, int drawbuffer, uint32* value);
        public static GlClearBufferuiv glClearBufferuiv;

        public function void GlClearBufferfv(uint buffer, int drawbuffer, float* value);
        public static GlClearBufferfv glClearBufferfv;

        public function void GlClearBufferfi(uint buffer, int drawbuffer, float depth, int stencil);
        public static GlClearBufferfi glClearBufferfi;

        public function uint8 GlGetStringi(uint name, uint index);
        public static GlGetStringi glGetStringi;

        public function uint8 GlIsRenderbuffer(uint renderbuffer);
        public static GlIsRenderbuffer glIsRenderbuffer;

        public function void GlBindRenderbuffer(uint target, uint renderbuffer);
        public static GlBindRenderbuffer glBindRenderbuffer;

        public function void GlDeleteRenderbuffers(int n, uint32* renderbuffers);
        public static GlDeleteRenderbuffers glDeleteRenderbuffers;

        public function void GlGenRenderbuffers(int n, uint32* renderbuffers);
        public static GlGenRenderbuffers glGenRenderbuffers;

        public function void GlRenderbufferStorage(uint target, uint internalformat, int width, int height);
        public static GlRenderbufferStorage glRenderbufferStorage;

        public function void GlGetRenderbufferParameteriv(uint target, uint pname, int32* paramss);
        public static GlGetRenderbufferParameteriv glGetRenderbufferParameteriv;

        public function uint8 GlIsFramebuffer(uint framebuffer);
        public static GlIsFramebuffer glIsFramebuffer;

        public function void GlBindFramebuffer(uint target, uint framebuffer);
        public static GlBindFramebuffer glBindFramebuffer;

        public function void GlDeleteFramebuffers(int n, uint32* framebuffers);
        public static GlDeleteFramebuffers glDeleteFramebuffers;

        public function void GlGenFramebuffers(int n, uint32* framebuffers);
        public static GlGenFramebuffers glGenFramebuffers;

        public function uint GlCheckFramebufferStatus(uint target);
        public static GlCheckFramebufferStatus glCheckFramebufferStatus;

        public function void GlFramebufferTexture1D(uint target, uint attachment, uint textarget, uint texture, int level);
        public static GlFramebufferTexture1D glFramebufferTexture1D;

        public function void GlFramebufferTexture2D(uint target, uint attachment, uint textarget, uint texture, int level);
        public static GlFramebufferTexture2D glFramebufferTexture2D;

        public function void GlFramebufferTexture3D(uint target, uint attachment, uint textarget, uint texture, int level, int zoffset);
        public static GlFramebufferTexture3D glFramebufferTexture3D;

        public function void GlFramebufferRenderbuffer(uint target, uint attachment, uint renderbuffertarget, uint renderbuffer);
        public static GlFramebufferRenderbuffer glFramebufferRenderbuffer;

        public function void GlGetFramebufferAttachmentParameteriv(uint target, uint attachment, uint pname, int32* paramss);
        public static GlGetFramebufferAttachmentParameteriv glGetFramebufferAttachmentParameteriv;

        public function void GlGenerateMipmap(uint target);
        public static GlGenerateMipmap glGenerateMipmap;

        public function void GlBlitFramebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, uint mask, uint filter);
        public static GlBlitFramebuffer glBlitFramebuffer;

        public function void GlRenderbufferStorageMultisample(uint target, int samples, uint internalformat, int width, int height);
        public static GlRenderbufferStorageMultisample glRenderbufferStorageMultisample;

        public function void GlFramebufferTextureLayer(uint target, uint attachment, uint texture, int level, int layer);
        public static GlFramebufferTextureLayer glFramebufferTextureLayer;

        public function void GlMapBufferRange(uint target, int offset, int length, uint access);
        public static GlMapBufferRange glMapBufferRange;

        public function void GlFlushMappedBufferRange(uint target, int offset, int length);
        public static GlFlushMappedBufferRange glFlushMappedBufferRange;

        public function void GlBindVertexArray(uint array);
        public static GlBindVertexArray glBindVertexArray;

        public function void GlDeleteVertexArrays(int n, uint32* arrays);
        public static GlDeleteVertexArrays glDeleteVertexArrays;

        public function void GlGenVertexArrays(int n, uint32* arrays);
        public static GlGenVertexArrays glGenVertexArrays;

        public function uint8 GlIsVertexArray(uint array);
        public static GlIsVertexArray glIsVertexArray;

        public function void GlDrawArraysInstanced(uint mode, int first, int count, int instancecount);
        public static GlDrawArraysInstanced glDrawArraysInstanced;

        public function void GlDrawElementsInstanced(uint mode, int count, uint type, void* indices, int instancecount);
        public static GlDrawElementsInstanced glDrawElementsInstanced;

        public function void GlTexBuffer(uint target, uint internalformat, uint buffer);
        public static GlTexBuffer glTexBuffer;

        public function void GlPrimitiveRestartIndex(uint index);
        public static GlPrimitiveRestartIndex glPrimitiveRestartIndex;

        public function void GlCopyBufferSubData(uint readTarget, uint writeTarget, int readOffset, int writeOffset, int size);
        public static GlCopyBufferSubData glCopyBufferSubData;

        public function void GlGetUniformIndices(uint program, int uniformCount, char8** uniformNames, uint32* uniformIndices);
        public static GlGetUniformIndices glGetUniformIndices;

        public function void GlGetActiveUniformsiv(uint program, int uniformCount, uint32* uniformIndices, uint pname, int32* paramss);
        public static GlGetActiveUniformsiv glGetActiveUniformsiv;

        public function void GlGetActiveUniformName(uint program, uint uniformIndex, int bufSize, int32* length, char8* uniformName);
        public static GlGetActiveUniformName glGetActiveUniformName;

        public function uint GlGetUniformBlockIndex(uint program, char8* uniformBlockName);
        public static GlGetUniformBlockIndex glGetUniformBlockIndex;

        public function void GlGetActiveUniformBlockiv(uint program, uint uniformBlockIndex, uint pname, int32* paramss);
        public static GlGetActiveUniformBlockiv glGetActiveUniformBlockiv;

        public function void GlGetActiveUniformBlockName(uint program, uint uniformBlockIndex, int bufSize, int32* length, char8* uniformBlockName);
        public static GlGetActiveUniformBlockName glGetActiveUniformBlockName;

        public function void GlUniformBlockBinding(uint program, uint uniformBlockIndex, uint uniformBlockBinding);
        public static GlUniformBlockBinding glUniformBlockBinding;

        public function void GlDrawElementsBaseVertex(uint mode, int count, uint type, void* indices, int basevertex);
        public static GlDrawElementsBaseVertex glDrawElementsBaseVertex;

        public function void GlDrawRangeElementsBaseVertex(uint mode, uint start, uint end, int count, uint type, void* indices, int basevertex);
        public static GlDrawRangeElementsBaseVertex glDrawRangeElementsBaseVertex;

        public function void GlDrawElementsInstancedBaseVertex(uint mode, int count, uint type, void* indices, int instancecount, int basevertex);
        public static GlDrawElementsInstancedBaseVertex glDrawElementsInstancedBaseVertex;

        public function void GlMultiDrawElementsBaseVertex(uint mode, int32* count, uint type, void *** indices, int drawcount, int32* basevertex);
        public static GlMultiDrawElementsBaseVertex glMultiDrawElementsBaseVertex;

        public function void GlProvokingVertex(uint mode);
        public static GlProvokingVertex glProvokingVertex;

        public function void* GlFenceSync(uint condition, uint flags);
        public static GlFenceSync glFenceSync;

        public function uint8 GlIsSync(void* sync);
        public static GlIsSync glIsSync;

        public function void GlDeleteSync(void* sync);
        public static GlDeleteSync glDeleteSync;

        public function uint GlClientWaitSync(void* sync, uint flags, uint64 timeout);
        public static GlClientWaitSync glClientWaitSync;

        public function void GlWaitSync(void* sync, uint flags, uint64 timeout);
        public static GlWaitSync glWaitSync;

        public function void GlGetInteger64v(uint pname, int64* data);
        public static GlGetInteger64v glGetInteger64v;

        public function void GlGetSynciv(void* sync, uint pname, int count, int32* length, int32* values);
        public static GlGetSynciv glGetSynciv;

        public function void GlGetInteger64i_v(uint target, uint index, int64* data);
        public static GlGetInteger64i_v glGetInteger64i_v;

        public function void GlGetBufferParameteri64v(uint target, uint pname, int64* paramss);
        public static GlGetBufferParameteri64v glGetBufferParameteri64v;

        public function void GlFramebufferTexture(uint target, uint attachment, uint texture, int level);
        public static GlFramebufferTexture glFramebufferTexture;

        public function void GlTexImage2DMultisample(uint target, int samples, uint internalformat, int width, int height, uint8 fixedsamplelocations);
        public static GlTexImage2DMultisample glTexImage2DMultisample;

        public function void GlTexImage3DMultisample(uint target, int samples, uint internalformat, int width, int height, int depth, uint8 fixedsamplelocations);
        public static GlTexImage3DMultisample glTexImage3DMultisample;

        public function void GlGetMultisamplefv(uint pname, uint index, float* val);
        public static GlGetMultisamplefv glGetMultisamplefv;

        public function void GlSampleMaski(uint maskNumber, uint mask);
        public static GlSampleMaski glSampleMaski;

        public function void GlBindFragDataLocationIndexed(uint program, uint colorNumber, uint index, char8* name);
        public static GlBindFragDataLocationIndexed glBindFragDataLocationIndexed;

        public function int GlGetFragDataIndex(uint program, char8* name);
        public static GlGetFragDataIndex glGetFragDataIndex;

        public function void GlGenSamplers(int count, uint32* samplers);
        public static GlGenSamplers glGenSamplers;

        public function void GlDeleteSamplers(int count, uint32* samplers);
        public static GlDeleteSamplers glDeleteSamplers;

        public function uint8 GlIsSampler(uint sampler);
        public static GlIsSampler glIsSampler;

        public function void GlBindSampler(uint unit, uint sampler);
        public static GlBindSampler glBindSampler;

        public function void GlSamplerParameteri(uint sampler, uint pname, int param);
        public static GlSamplerParameteri glSamplerParameteri;

        public function void GlSamplerParameteriv(uint sampler, uint pname, int32* param);
        public static GlSamplerParameteriv glSamplerParameteriv;

        public function void GlSamplerParameterf(uint sampler, uint pname, float param);
        public static GlSamplerParameterf glSamplerParameterf;

        public function void GlSamplerParameterfv(uint sampler, uint pname, float* param);
        public static GlSamplerParameterfv glSamplerParameterfv;

        public function void GlSamplerParameterIiv(uint sampler, uint pname, int32* param);
        public static GlSamplerParameterIiv glSamplerParameterIiv;

        public function void GlSamplerParameterIuiv(uint sampler, uint pname, uint32* param);
        public static GlSamplerParameterIuiv glSamplerParameterIuiv;

        public function void GlGetSamplerParameteriv(uint sampler, uint pname, int32* paramss);
        public static GlGetSamplerParameteriv glGetSamplerParameteriv;

        public function void GlGetSamplerParameterIiv(uint sampler, uint pname, int32* paramss);
        public static GlGetSamplerParameterIiv glGetSamplerParameterIiv;

        public function void GlGetSamplerParameterfv(uint sampler, uint pname, float* paramss);
        public static GlGetSamplerParameterfv glGetSamplerParameterfv;

        public function void GlGetSamplerParameterIuiv(uint sampler, uint pname, uint32* paramss);
        public static GlGetSamplerParameterIuiv glGetSamplerParameterIuiv;

        public function void GlQueryCounter(uint id, uint target);
        public static GlQueryCounter glQueryCounter;

        public function void GlGetQueryObjecti64v(uint id, uint pname, int64* paramss);
        public static GlGetQueryObjecti64v glGetQueryObjecti64v;

        public function void GlGetQueryObjectui64v(uint id, uint pname, uint64* paramss);
        public static GlGetQueryObjectui64v glGetQueryObjectui64v;

        public function void GlVertexAttribDivisor(uint index, uint divisor);
        public static GlVertexAttribDivisor glVertexAttribDivisor;

        public function void GlVertexAttribP1ui(uint index, uint type, uint8 normalized, uint value);
        public static GlVertexAttribP1ui glVertexAttribP1ui;

        public function void GlVertexAttribP1uiv(uint index, uint type, uint8 normalized, uint32* value);
        public static GlVertexAttribP1uiv glVertexAttribP1uiv;

        public function void GlVertexAttribP2ui(uint index, uint type, uint8 normalized, uint value);
        public static GlVertexAttribP2ui glVertexAttribP2ui;

        public function void GlVertexAttribP2uiv(uint index, uint type, uint8 normalized, uint32* value);
        public static GlVertexAttribP2uiv glVertexAttribP2uiv;

        public function void GlVertexAttribP3ui(uint index, uint type, uint8 normalized, uint value);
        public static GlVertexAttribP3ui glVertexAttribP3ui;

        public function void GlVertexAttribP3uiv(uint index, uint type, uint8 normalized, uint32* value);
        public static GlVertexAttribP3uiv glVertexAttribP3uiv;

        public function void GlVertexAttribP4ui(uint index, uint type, uint8 normalized, uint value);
        public static GlVertexAttribP4ui glVertexAttribP4ui;

        public function void GlVertexAttribP4uiv(uint index, uint type, uint8 normalized, uint32* value);
        public static GlVertexAttribP4uiv glVertexAttribP4uiv;

        public function void GlMinSampleShading(float value);
        public static GlMinSampleShading glMinSampleShading;

        public function void GlBlendEquationi(uint buf, uint mode);
        public static GlBlendEquationi glBlendEquationi;

        public function void GlBlendEquationSeparatei(uint buf, uint modeRGB, uint modeAlpha);
        public static GlBlendEquationSeparatei glBlendEquationSeparatei;

        public function void GlBlendFunci(uint buf, uint src, uint dst);
        public static GlBlendFunci glBlendFunci;

        public function void GlBlendFuncSeparatei(uint buf, uint srcRGB, uint dstRGB, uint srcAlpha, uint dstAlpha);
        public static GlBlendFuncSeparatei glBlendFuncSeparatei;

        public function void GlDrawArraysIndirect(uint mode, void* indirect);
        public static GlDrawArraysIndirect glDrawArraysIndirect;

        public function void GlDrawElementsIndirect(uint mode, uint type, void* indirect);
        public static GlDrawElementsIndirect glDrawElementsIndirect;

        public function void GlUniform1d(int location, double x);
        public static GlUniform1d glUniform1d;

        public function void GlUniform2d(int location, double x, double y);
        public static GlUniform2d glUniform2d;

        public function void GlUniform3d(int location, double x, double y, double z);
        public static GlUniform3d glUniform3d;

        public function void GlUniform4d(int location, double x, double y, double z, double w);
        public static GlUniform4d glUniform4d;

        public function void GlUniform1dv(int location, int count, double* value);
        public static GlUniform1dv glUniform1dv;

        public function void GlUniform2dv(int location, int count, double* value);
        public static GlUniform2dv glUniform2dv;

        public function void GlUniform3dv(int location, int count, double* value);
        public static GlUniform3dv glUniform3dv;

        public function void GlUniform4dv(int location, int count, double* value);
        public static GlUniform4dv glUniform4dv;

        public function void GlUniformMatrix2dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix2dv glUniformMatrix2dv;

        public function void GlUniformMatrix3dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix3dv glUniformMatrix3dv;

        public function void GlUniformMatrix4dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix4dv glUniformMatrix4dv;

        public function void GlUniformMatrix2x3dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix2x3dv glUniformMatrix2x3dv;

        public function void GlUniformMatrix2x4dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix2x4dv glUniformMatrix2x4dv;

        public function void GlUniformMatrix3x2dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix3x2dv glUniformMatrix3x2dv;

        public function void GlUniformMatrix3x4dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix3x4dv glUniformMatrix3x4dv;

        public function void GlUniformMatrix4x2dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix4x2dv glUniformMatrix4x2dv;

        public function void GlUniformMatrix4x3dv(int location, int count, uint8 transpose, double* value);
        public static GlUniformMatrix4x3dv glUniformMatrix4x3dv;

        public function void GlGetUniformdv(uint program, int location, double* paramss);
        public static GlGetUniformdv glGetUniformdv;

        public function int GlGetSubroutineUniformLocation(uint program, uint shadertype, char8* name);
        public static GlGetSubroutineUniformLocation glGetSubroutineUniformLocation;

        public function uint GlGetSubroutineIndex(uint program, uint shadertype, char8* name);
        public static GlGetSubroutineIndex glGetSubroutineIndex;

        public function void GlGetActiveSubroutineUniformiv(uint program, uint shadertype, uint index, uint pname, int32* values);
        public static GlGetActiveSubroutineUniformiv glGetActiveSubroutineUniformiv;

        public function void GlGetActiveSubroutineUniformName(uint program, uint shadertype, uint index, int bufSize, int32* length, char8* name);
        public static GlGetActiveSubroutineUniformName glGetActiveSubroutineUniformName;

        public function void GlGetActiveSubroutineName(uint program, uint shadertype, uint index, int bufSize, int32* length, char8* name);
        public static GlGetActiveSubroutineName glGetActiveSubroutineName;

        public function void GlUniformSubroutinesuiv(uint shadertype, int count, uint32* indices);
        public static GlUniformSubroutinesuiv glUniformSubroutinesuiv;

        public function void GlGetUniformSubroutineuiv(uint shadertype, int location, uint32* paramss);
        public static GlGetUniformSubroutineuiv glGetUniformSubroutineuiv;

        public function void GlGetProgramStageiv(uint program, uint shadertype, uint pname, int32* values);
        public static GlGetProgramStageiv glGetProgramStageiv;

        public function void GlPatchParameteri(uint pname, int value);
        public static GlPatchParameteri glPatchParameteri;

        public function void GlPatchParameterfv(uint pname, float* values);
        public static GlPatchParameterfv glPatchParameterfv;

        public function void GlBindTransformFeedback(uint target, uint id);
        public static GlBindTransformFeedback glBindTransformFeedback;

        public function void GlDeleteTransformFeedbacks(int n, uint32* ids);
        public static GlDeleteTransformFeedbacks glDeleteTransformFeedbacks;

        public function void GlGenTransformFeedbacks(int n, uint32* ids);
        public static GlGenTransformFeedbacks glGenTransformFeedbacks;

        public function uint8 GlIsTransformFeedback(uint id);
        public static GlIsTransformFeedback glIsTransformFeedback;

        public function void GlPauseTransformFeedback();
        public static GlPauseTransformFeedback glPauseTransformFeedback;

        public function void GlResumeTransformFeedback();
        public static GlResumeTransformFeedback glResumeTransformFeedback;

        public function void GlDrawTransformFeedback(uint mode, uint id);
        public static GlDrawTransformFeedback glDrawTransformFeedback;

        public function void GlDrawTransformFeedbackStream(uint mode, uint id, uint stream);
        public static GlDrawTransformFeedbackStream glDrawTransformFeedbackStream;

        public function void GlBeginQueryIndexed(uint target, uint index, uint id);
        public static GlBeginQueryIndexed glBeginQueryIndexed;

        public function void GlEndQueryIndexed(uint target, uint index);
        public static GlEndQueryIndexed glEndQueryIndexed;

        public function void GlGetQueryIndexediv(uint target, uint index, uint pname, int32* paramss);
        public static GlGetQueryIndexediv glGetQueryIndexediv;

        public function void GlReleaseShaderCompiler();
        public static GlReleaseShaderCompiler glReleaseShaderCompiler;

        public function void GlShaderBinary(int count, uint32* shaders, uint binaryFormat, void* binary, int length);
        public static GlShaderBinary glShaderBinary;

        public function void GlGetShaderPrecisionFormat(uint shadertype, uint precisiontype, int32* range, int32* precision);
        public static GlGetShaderPrecisionFormat glGetShaderPrecisionFormat;

        public function void GlDepthRangef(float n, float f);
        public static GlDepthRangef glDepthRangef;

        public function void GlClearDepthf(float d);
        public static GlClearDepthf glClearDepthf;

        public function void GlGetProgramBinary(uint program, int bufSize, int32* length, uint32* binaryFormat, void* binary);
        public static GlGetProgramBinary glGetProgramBinary;

        public function void GlProgramBinary(uint program, uint binaryFormat, void* binary, int length);
        public static GlProgramBinary glProgramBinary;

        public function void GlProgramParameteri(uint program, uint pname, int value);
        public static GlProgramParameteri glProgramParameteri;

        public function void GlUseProgramStages(uint pipeline, uint stages, uint program);
        public static GlUseProgramStages glUseProgramStages;

        public function void GlActiveShaderProgram(uint pipeline, uint program);
        public static GlActiveShaderProgram glActiveShaderProgram;

        public function uint GlCreateShaderProgramv(uint type, int count, char8** strings);
        public static GlCreateShaderProgramv glCreateShaderProgramv;

        public function void GlBindProgramPipeline(uint pipeline);
        public static GlBindProgramPipeline glBindProgramPipeline;

        public function void GlDeleteProgramPipelines(int n, uint32* pipelines);
        public static GlDeleteProgramPipelines glDeleteProgramPipelines;

        public function void GlGenProgramPipelines(int n, uint32* pipelines);
        public static GlGenProgramPipelines glGenProgramPipelines;

        public function uint8 GlIsProgramPipeline(uint pipeline);
        public static GlIsProgramPipeline glIsProgramPipeline;

        public function void GlGetProgramPipelineiv(uint pipeline, uint pname, int32* paramss);
        public static GlGetProgramPipelineiv glGetProgramPipelineiv;

        public function void GlProgramUniform1i(uint program, int location, int v0);
        public static GlProgramUniform1i glProgramUniform1i;

        public function void GlProgramUniform1iv(uint program, int location, int count, int32* value);
        public static GlProgramUniform1iv glProgramUniform1iv;

        public function void GlProgramUniform1f(uint program, int location, float v0);
        public static GlProgramUniform1f glProgramUniform1f;

        public function void GlProgramUniform1fv(uint program, int location, int count, float* value);
        public static GlProgramUniform1fv glProgramUniform1fv;

        public function void GlProgramUniform1d(uint program, int location, double v0);
        public static GlProgramUniform1d glProgramUniform1d;

        public function void GlProgramUniform1dv(uint program, int location, int count, double* value);
        public static GlProgramUniform1dv glProgramUniform1dv;

        public function void GlProgramUniform1ui(uint program, int location, uint v0);
        public static GlProgramUniform1ui glProgramUniform1ui;

        public function void GlProgramUniform1uiv(uint program, int location, int count, uint32* value);
        public static GlProgramUniform1uiv glProgramUniform1uiv;

        public function void GlProgramUniform2i(uint program, int location, int v0, int v1);
        public static GlProgramUniform2i glProgramUniform2i;

        public function void GlProgramUniform2iv(uint program, int location, int count, int32* value);
        public static GlProgramUniform2iv glProgramUniform2iv;

        public function void GlProgramUniform2f(uint program, int location, float v0, float v1);
        public static GlProgramUniform2f glProgramUniform2f;

        public function void GlProgramUniform2fv(uint program, int location, int count, float* value);
        public static GlProgramUniform2fv glProgramUniform2fv;

        public function void GlProgramUniform2d(uint program, int location, double v0, double v1);
        public static GlProgramUniform2d glProgramUniform2d;

        public function void GlProgramUniform2dv(uint program, int location, int count, double* value);
        public static GlProgramUniform2dv glProgramUniform2dv;

        public function void GlProgramUniform2ui(uint program, int location, uint v0, uint v1);
        public static GlProgramUniform2ui glProgramUniform2ui;

        public function void GlProgramUniform2uiv(uint program, int location, int count, uint32* value);
        public static GlProgramUniform2uiv glProgramUniform2uiv;

        public function void GlProgramUniform3i(uint program, int location, int v0, int v1, int v2);
        public static GlProgramUniform3i glProgramUniform3i;

        public function void GlProgramUniform3iv(uint program, int location, int count, int32* value);
        public static GlProgramUniform3iv glProgramUniform3iv;

        public function void GlProgramUniform3f(uint program, int location, float v0, float v1, float v2);
        public static GlProgramUniform3f glProgramUniform3f;

        public function void GlProgramUniform3fv(uint program, int location, int count, float* value);
        public static GlProgramUniform3fv glProgramUniform3fv;

        public function void GlProgramUniform3d(uint program, int location, double v0, double v1, double v2);
        public static GlProgramUniform3d glProgramUniform3d;

        public function void GlProgramUniform3dv(uint program, int location, int count, double* value);
        public static GlProgramUniform3dv glProgramUniform3dv;

        public function void GlProgramUniform3ui(uint program, int location, uint v0, uint v1, uint v2);
        public static GlProgramUniform3ui glProgramUniform3ui;

        public function void GlProgramUniform3uiv(uint program, int location, int count, uint32* value);
        public static GlProgramUniform3uiv glProgramUniform3uiv;

        public function void GlProgramUniform4i(uint program, int location, int v0, int v1, int v2, int v3);
        public static GlProgramUniform4i glProgramUniform4i;

        public function void GlProgramUniform4iv(uint program, int location, int count, int32* value);
        public static GlProgramUniform4iv glProgramUniform4iv;

        public function void GlProgramUniform4f(uint program, int location, float v0, float v1, float v2, float v3);
        public static GlProgramUniform4f glProgramUniform4f;

        public function void GlProgramUniform4fv(uint program, int location, int count, float* value);
        public static GlProgramUniform4fv glProgramUniform4fv;

        public function void GlProgramUniform4d(uint program, int location, double v0, double v1, double v2, double v3);
        public static GlProgramUniform4d glProgramUniform4d;

        public function void GlProgramUniform4dv(uint program, int location, int count, double* value);
        public static GlProgramUniform4dv glProgramUniform4dv;

        public function void GlProgramUniform4ui(uint program, int location, uint v0, uint v1, uint v2, uint v3);
        public static GlProgramUniform4ui glProgramUniform4ui;

        public function void GlProgramUniform4uiv(uint program, int location, int count, uint32* value);
        public static GlProgramUniform4uiv glProgramUniform4uiv;

        public function void GlProgramUniformMatrix2fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix2fv glProgramUniformMatrix2fv;

        public function void GlProgramUniformMatrix3fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix3fv glProgramUniformMatrix3fv;

        public function void GlProgramUniformMatrix4fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix4fv glProgramUniformMatrix4fv;

        public function void GlProgramUniformMatrix2dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix2dv glProgramUniformMatrix2dv;

        public function void GlProgramUniformMatrix3dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix3dv glProgramUniformMatrix3dv;

        public function void GlProgramUniformMatrix4dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix4dv glProgramUniformMatrix4dv;

        public function void GlProgramUniformMatrix2x3fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix2x3fv glProgramUniformMatrix2x3fv;

        public function void GlProgramUniformMatrix3x2fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix3x2fv glProgramUniformMatrix3x2fv;

        public function void GlProgramUniformMatrix2x4fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix2x4fv glProgramUniformMatrix2x4fv;

        public function void GlProgramUniformMatrix4x2fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix4x2fv glProgramUniformMatrix4x2fv;

        public function void GlProgramUniformMatrix3x4fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix3x4fv glProgramUniformMatrix3x4fv;

        public function void GlProgramUniformMatrix4x3fv(uint program, int location, int count, uint8 transpose, float* value);
        public static GlProgramUniformMatrix4x3fv glProgramUniformMatrix4x3fv;

        public function void GlProgramUniformMatrix2x3dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix2x3dv glProgramUniformMatrix2x3dv;

        public function void GlProgramUniformMatrix3x2dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix3x2dv glProgramUniformMatrix3x2dv;

        public function void GlProgramUniformMatrix2x4dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix2x4dv glProgramUniformMatrix2x4dv;

        public function void GlProgramUniformMatrix4x2dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix4x2dv glProgramUniformMatrix4x2dv;

        public function void GlProgramUniformMatrix3x4dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix3x4dv glProgramUniformMatrix3x4dv;

        public function void GlProgramUniformMatrix4x3dv(uint program, int location, int count, uint8 transpose, double* value);
        public static GlProgramUniformMatrix4x3dv glProgramUniformMatrix4x3dv;

        public function void GlValidateProgramPipeline(uint pipeline);
        public static GlValidateProgramPipeline glValidateProgramPipeline;

        public function void GlGetProgramPipelineInfoLog(uint pipeline, int bufSize, int32* length, char8* infoLog);
        public static GlGetProgramPipelineInfoLog glGetProgramPipelineInfoLog;

        public function void GlVertexAttribL1d(uint index, double x);
        public static GlVertexAttribL1d glVertexAttribL1d;

        public function void GlVertexAttribL2d(uint index, double x, double y);
        public static GlVertexAttribL2d glVertexAttribL2d;

        public function void GlVertexAttribL3d(uint index, double x, double y, double z);
        public static GlVertexAttribL3d glVertexAttribL3d;

        public function void GlVertexAttribL4d(uint index, double x, double y, double z, double w);
        public static GlVertexAttribL4d glVertexAttribL4d;

        public function void GlVertexAttribL1dv(uint index, double* v);
        public static GlVertexAttribL1dv glVertexAttribL1dv;

        public function void GlVertexAttribL2dv(uint index, double* v);
        public static GlVertexAttribL2dv glVertexAttribL2dv;

        public function void GlVertexAttribL3dv(uint index, double* v);
        public static GlVertexAttribL3dv glVertexAttribL3dv;

        public function void GlVertexAttribL4dv(uint index, double* v);
        public static GlVertexAttribL4dv glVertexAttribL4dv;

        public function void GlVertexAttribLPointer(uint index, int size, uint type, int stride, void* pointer);
        public static GlVertexAttribLPointer glVertexAttribLPointer;

        public function void GlGetVertexAttribLdv(uint index, uint pname, double* paramss);
        public static GlGetVertexAttribLdv glGetVertexAttribLdv;

        public function void GlViewportArrayv(uint first, int count, float* v);
        public static GlViewportArrayv glViewportArrayv;

        public function void GlViewportIndexedf(uint index, float x, float y, float w, float h);
        public static GlViewportIndexedf glViewportIndexedf;

        public function void GlViewportIndexedfv(uint index, float* v);
        public static GlViewportIndexedfv glViewportIndexedfv;

        public function void GlScissorArrayv(uint first, int count, int32* v);
        public static GlScissorArrayv glScissorArrayv;

        public function void GlScissorIndexed(uint index, int left, int bottom, int width, int height);
        public static GlScissorIndexed glScissorIndexed;

        public function void GlScissorIndexedv(uint index, int32* v);
        public static GlScissorIndexedv glScissorIndexedv;

        public function void GlDepthRangeArrayv(uint first, int count, double* v);
        public static GlDepthRangeArrayv glDepthRangeArrayv;

        public function void GlDepthRangeIndexed(uint index, double n, double f);
        public static GlDepthRangeIndexed glDepthRangeIndexed;

        public function void GlGetFloati_v(uint target, uint index, float* data);
        public static GlGetFloati_v glGetFloati_v;

        public function void GlGetDoublei_v(uint target, uint index, double* data);
        public static GlGetDoublei_v glGetDoublei_v;

        public function void GlDrawArraysInstancedBaseInstance(uint mode, int first, int count, int instancecount, uint baseinstance);
        public static GlDrawArraysInstancedBaseInstance glDrawArraysInstancedBaseInstance;

        public function void GlDrawElementsInstancedBaseInstance(uint mode, int count, uint type, void* indices, int instancecount, uint baseinstance);
        public static GlDrawElementsInstancedBaseInstance glDrawElementsInstancedBaseInstance;

        public function void GlDrawElementsInstancedBaseVertexBaseInstance(uint mode, int count, uint type, void* indices, int instancecount, int basevertex, uint baseinstance);
        public static GlDrawElementsInstancedBaseVertexBaseInstance glDrawElementsInstancedBaseVertexBaseInstance;

        public function void GlGetInternalformativ(uint target, uint internalformat, uint pname, int count, int32* paramss);
        public static GlGetInternalformativ glGetInternalformativ;

        public function void GlGetActiveAtomicCounterBufferiv(uint program, uint bufferIndex, uint pname, int32* paramss);
        public static GlGetActiveAtomicCounterBufferiv glGetActiveAtomicCounterBufferiv;

        public function void GlBindImageTexture(uint unit, uint texture, int level, uint8 layered, int layer, uint access, uint format);
        public static GlBindImageTexture glBindImageTexture;

        public function void GlMemoryBarrier(uint barriers);
        public static GlMemoryBarrier glMemoryBarrier;

        public function void GlTexStorage1D(uint target, int levels, uint internalformat, int width);
        public static GlTexStorage1D glTexStorage1D;

        public function void GlTexStorage2D(uint target, int levels, uint internalformat, int width, int height);
        public static GlTexStorage2D glTexStorage2D;

        public function void GlTexStorage3D(uint target, int levels, uint internalformat, int width, int height, int depth);
        public static GlTexStorage3D glTexStorage3D;

        public function void GlDrawTransformFeedbackInstanced(uint mode, uint id, int instancecount);
        public static GlDrawTransformFeedbackInstanced glDrawTransformFeedbackInstanced;

        public function void GlDrawTransformFeedbackStreamInstanced(uint mode, uint id, uint stream, int instancecount);
        public static GlDrawTransformFeedbackStreamInstanced glDrawTransformFeedbackStreamInstanced;

        public function void GlClearBufferData(uint target, uint internalformat, uint format, uint type, void* data);
        public static GlClearBufferData glClearBufferData;

        public function void GlClearBufferSubData(uint target, uint internalformat, int offset, int size, uint format, uint type, void* data);
        public static GlClearBufferSubData glClearBufferSubData;

        public function void GlDispatchCompute(uint num_groups_x, uint num_groups_y, uint num_groups_z);
        public static GlDispatchCompute glDispatchCompute;

        public function void GlDispatchComputeIndirect(int indirect);
        public static GlDispatchComputeIndirect glDispatchComputeIndirect;

        public function void GlCopyImageSubData(uint srcName, uint srcTarget, int srcLevel, int srcX, int srcY, int srcZ, uint dstName, uint dstTarget, int dstLevel, int dstX, int dstY, int dstZ, int srcWidth, int srcHeight, int srcDepth);
        public static GlCopyImageSubData glCopyImageSubData;

        public function void GlFramebufferParameteri(uint target, uint pname, int param);
        public static GlFramebufferParameteri glFramebufferParameteri;

        public function void GlGetFramebufferParameteriv(uint target, uint pname, int32* paramss);
        public static GlGetFramebufferParameteriv glGetFramebufferParameteriv;

        public function void GlGetInternalformati64v(uint target, uint internalformat, uint pname, int count, int64* paramss);
        public static GlGetInternalformati64v glGetInternalformati64v;

        public function void GlInvalidateTexSubImage(uint texture, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth);
        public static GlInvalidateTexSubImage glInvalidateTexSubImage;

        public function void GlInvalidateTexImage(uint texture, int level);
        public static GlInvalidateTexImage glInvalidateTexImage;

        public function void GlInvalidateBufferSubData(uint buffer, int offset, int length);
        public static GlInvalidateBufferSubData glInvalidateBufferSubData;

        public function void GlInvalidateBufferData(uint buffer);
        public static GlInvalidateBufferData glInvalidateBufferData;

        public function void GlInvalidateFramebuffer(uint target, int numAttachments, uint32* attachments);
        public static GlInvalidateFramebuffer glInvalidateFramebuffer;

        public function void GlInvalidateSubFramebuffer(uint target, int numAttachments, uint32* attachments, int x, int y, int width, int height);
        public static GlInvalidateSubFramebuffer glInvalidateSubFramebuffer;

        public function void GlMultiDrawArraysIndirect(uint mode, void* indirect, int drawcount, int stride);
        public static GlMultiDrawArraysIndirect glMultiDrawArraysIndirect;

        public function void GlMultiDrawElementsIndirect(uint mode, uint type, void* indirect, int drawcount, int stride);
        public static GlMultiDrawElementsIndirect glMultiDrawElementsIndirect;

        public function void GlGetProgramInterfaceiv(uint program, uint programInterface, uint pname, int32* paramss);
        public static GlGetProgramInterfaceiv glGetProgramInterfaceiv;

        public function uint GlGetProgramResourceIndex(uint program, uint programInterface, char8* name);
        public static GlGetProgramResourceIndex glGetProgramResourceIndex;

        public function void GlGetProgramResourceName(uint program, uint programInterface, uint index, int bufSize, int32* length, char8* name);
        public static GlGetProgramResourceName glGetProgramResourceName;

        public function void GlGetProgramResourceiv(uint program, uint programInterface, uint index, int propCount, uint32* props, int count, int32* length, int32* paramss);
        public static GlGetProgramResourceiv glGetProgramResourceiv;

        public function int GlGetProgramResourceLocation(uint program, uint programInterface, char8* name);
        public static GlGetProgramResourceLocation glGetProgramResourceLocation;

        public function int GlGetProgramResourceLocationIndex(uint program, uint programInterface, char8* name);
        public static GlGetProgramResourceLocationIndex glGetProgramResourceLocationIndex;

        public function void GlShaderStorageBlockBinding(uint program, uint storageBlockIndex, uint storageBlockBinding);
        public static GlShaderStorageBlockBinding glShaderStorageBlockBinding;

        public function void GlTexBufferRange(uint target, uint internalformat, uint buffer, int offset, int size);
        public static GlTexBufferRange glTexBufferRange;

        public function void GlTexStorage2DMultisample(uint target, int samples, uint internalformat, int width, int height, uint8 fixedsamplelocations);
        public static GlTexStorage2DMultisample glTexStorage2DMultisample;

        public function void GlTexStorage3DMultisample(uint target, int samples, uint internalformat, int width, int height, int depth, uint8 fixedsamplelocations);
        public static GlTexStorage3DMultisample glTexStorage3DMultisample;

        public function void GlTextureView(uint texture, uint target, uint origtexture, uint internalformat, uint minlevel, uint numlevels, uint minlayer, uint numlayers);
        public static GlTextureView glTextureView;

        public function void GlBindVertexBuffer(uint bindingindex, uint buffer, int offset, int stride);
        public static GlBindVertexBuffer glBindVertexBuffer;

        public function void GlVertexAttribFormat(uint attribindex, int size, uint type, uint8 normalized, uint relativeoffset);
        public static GlVertexAttribFormat glVertexAttribFormat;

        public function void GlVertexAttribIFormat(uint attribindex, int size, uint type, uint relativeoffset);
        public static GlVertexAttribIFormat glVertexAttribIFormat;

        public function void GlVertexAttribLFormat(uint attribindex, int size, uint type, uint relativeoffset);
        public static GlVertexAttribLFormat glVertexAttribLFormat;

        public function void GlVertexAttribBinding(uint attribindex, uint bindingindex);
        public static GlVertexAttribBinding glVertexAttribBinding;

        public function void GlVertexBindingDivisor(uint bindingindex, uint divisor);
        public static GlVertexBindingDivisor glVertexBindingDivisor;

        public function void GlDebugMessageControl(uint source, uint type, uint severity, int count, uint32* ids, uint8 enabled);
        public static GlDebugMessageControl glDebugMessageControl;

        public function void GlDebugMessageInsert(uint source, uint type, uint id, uint severity, int length, char8* buf);
        public static GlDebugMessageInsert glDebugMessageInsert;

        public function void GlDebugMessageCallback(function void(uint source, uint type, uint id, uint severity, int length, char8* message, void* userParam) callback, void* userParam);
        public static GlDebugMessageCallback glDebugMessageCallback;

        public function uint GlGetDebugMessageLog(uint count, int bufSize, uint32* sources, uint32* types, uint32* ids, uint32* severities, int32* lengths, char8* messageLog);
        public static GlGetDebugMessageLog glGetDebugMessageLog;

        public function void GlPushDebugGroup(uint source, uint id, int length, char8* message);
        public static GlPushDebugGroup glPushDebugGroup;

        public function void GlPopDebugGroup();
        public static GlPopDebugGroup glPopDebugGroup;

        public function void GlObjectLabel(uint identifier, uint name, int length, char8* label);
        public static GlObjectLabel glObjectLabel;

        public function void GlGetObjectLabel(uint identifier, uint name, int bufSize, int32* length, char8* label);
        public static GlGetObjectLabel glGetObjectLabel;

        public function void GlObjectPtrLabel(void* ptr, int length, char8* label);
        public static GlObjectPtrLabel glObjectPtrLabel;

        public function void GlGetObjectPtrLabel(void* ptr, int bufSize, int32* length, char8* label);
        public static GlGetObjectPtrLabel glGetObjectPtrLabel;

        public function void GlGetPointerv(uint pname, void *** paramss);
        public static GlGetPointerv glGetPointerv;

        public function void GlBufferStorage(uint target, int size, void* data, uint flags);
        public static GlBufferStorage glBufferStorage;

        public function void GlClearTexImage(uint texture, int level, uint format, uint type, void* data);
        public static GlClearTexImage glClearTexImage;

        public function void GlClearTexSubImage(uint texture, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, uint format, uint type, void* data);
        public static GlClearTexSubImage glClearTexSubImage;

        public function void GlBindBuffersBase(uint target, uint first, int count, uint32* buffers);
        public static GlBindBuffersBase glBindBuffersBase;

        public function void GlBindBuffersRange(uint target, uint first, int count, uint32* buffers, int32* offsets, int32* sizes);
        public static GlBindBuffersRange glBindBuffersRange;

        public function void GlBindTextures(uint first, int count, uint32* textures);
        public static GlBindTextures glBindTextures;

        public function void GlBindSamplers(uint first, int count, uint32* samplers);
        public static GlBindSamplers glBindSamplers;

        public function void GlBindImageTextures(uint first, int count, uint32* textures);
        public static GlBindImageTextures glBindImageTextures;

        public function void GlBindVertexBuffers(uint first, int count, uint32* buffers, int32* offsets, int32* strides);
        public static GlBindVertexBuffers glBindVertexBuffers;

        public function void GlClipControl(uint origin, uint depth);
        public static GlClipControl glClipControl;

        public function void GlCreateTransformFeedbacks(int n, uint32* ids);
        public static GlCreateTransformFeedbacks glCreateTransformFeedbacks;

        public function void GlTransformFeedbackBufferBase(uint xfb, uint index, uint buffer);
        public static GlTransformFeedbackBufferBase glTransformFeedbackBufferBase;

        public function void GlTransformFeedbackBufferRange(uint xfb, uint index, uint buffer, int offset, int size);
        public static GlTransformFeedbackBufferRange glTransformFeedbackBufferRange;

        public function void GlGetTransformFeedbackiv(uint xfb, uint pname, int32* param);
        public static GlGetTransformFeedbackiv glGetTransformFeedbackiv;

        public function void GlGetTransformFeedbacki_v(uint xfb, uint pname, uint index, int32* param);
        public static GlGetTransformFeedbacki_v glGetTransformFeedbacki_v;

        public function void GlGetTransformFeedbacki64_v(uint xfb, uint pname, uint index, int64* param);
        public static GlGetTransformFeedbacki64_v glGetTransformFeedbacki64_v;

        public function void GlCreateBuffers(int n, uint32* buffers);
        public static GlCreateBuffers glCreateBuffers;

        public function void GlNamedBufferStorage(uint buffer, int size, void* data, uint flags);
        public static GlNamedBufferStorage glNamedBufferStorage;

        public function void GlNamedBufferData(uint buffer, int size, void* data, uint usage);
        public static GlNamedBufferData glNamedBufferData;

        public function void GlNamedBufferSubData(uint buffer, int offset, int size, void* data);
        public static GlNamedBufferSubData glNamedBufferSubData;

        public function void GlCopyNamedBufferSubData(uint readBuffer, uint writeBuffer, int readOffset, int writeOffset, int size);
        public static GlCopyNamedBufferSubData glCopyNamedBufferSubData;

        public function void GlClearNamedBufferData(uint buffer, uint internalformat, uint format, uint type, void* data);
        public static GlClearNamedBufferData glClearNamedBufferData;

        public function void GlClearNamedBufferSubData(uint buffer, uint internalformat, int offset, int size, uint format, uint type, void* data);
        public static GlClearNamedBufferSubData glClearNamedBufferSubData;

        public function void GlMapNamedBuffer(uint buffer, uint access);
        public static GlMapNamedBuffer glMapNamedBuffer;

        public function void GlMapNamedBufferRange(uint buffer, int offset, int length, uint access);
        public static GlMapNamedBufferRange glMapNamedBufferRange;

        public function uint8 GlUnmapNamedBuffer(uint buffer);
        public static GlUnmapNamedBuffer glUnmapNamedBuffer;

        public function void GlFlushMappedNamedBufferRange(uint buffer, int offset, int length);
        public static GlFlushMappedNamedBufferRange glFlushMappedNamedBufferRange;

        public function void GlGetNamedBufferParameteriv(uint buffer, uint pname, int32* paramss);
        public static GlGetNamedBufferParameteriv glGetNamedBufferParameteriv;

        public function void GlGetNamedBufferParameteri64v(uint buffer, uint pname, int64* paramss);
        public static GlGetNamedBufferParameteri64v glGetNamedBufferParameteri64v;

        public function void GlGetNamedBufferPointerv(uint buffer, uint pname, void *** paramss);
        public static GlGetNamedBufferPointerv glGetNamedBufferPointerv;

        public function void GlGetNamedBufferSubData(uint buffer, int offset, int size, void* data);
        public static GlGetNamedBufferSubData glGetNamedBufferSubData;

        public function void GlCreateFramebuffers(int n, uint32* framebuffers);
        public static GlCreateFramebuffers glCreateFramebuffers;

        public function void GlNamedFramebufferRenderbuffer(uint framebuffer, uint attachment, uint renderbuffertarget, uint renderbuffer);
        public static GlNamedFramebufferRenderbuffer glNamedFramebufferRenderbuffer;

        public function void GlNamedFramebufferParameteri(uint framebuffer, uint pname, int param);
        public static GlNamedFramebufferParameteri glNamedFramebufferParameteri;

        public function void GlNamedFramebufferTexture(uint framebuffer, uint attachment, uint texture, int level);
        public static GlNamedFramebufferTexture glNamedFramebufferTexture;

        public function void GlNamedFramebufferTextureLayer(uint framebuffer, uint attachment, uint texture, int level, int layer);
        public static GlNamedFramebufferTextureLayer glNamedFramebufferTextureLayer;

        public function void GlNamedFramebufferDrawBuffer(uint framebuffer, uint buf);
        public static GlNamedFramebufferDrawBuffer glNamedFramebufferDrawBuffer;

        public function void GlNamedFramebufferDrawBuffers(uint framebuffer, int n, uint32* bufs);
        public static GlNamedFramebufferDrawBuffers glNamedFramebufferDrawBuffers;

        public function void GlNamedFramebufferReadBuffer(uint framebuffer, uint src);
        public static GlNamedFramebufferReadBuffer glNamedFramebufferReadBuffer;

        public function void GlInvalidateNamedFramebufferData(uint framebuffer, int numAttachments, uint32* attachments);
        public static GlInvalidateNamedFramebufferData glInvalidateNamedFramebufferData;

        public function void GlInvalidateNamedFramebufferSubData(uint framebuffer, int numAttachments, uint32* attachments, int x, int y, int width, int height);
        public static GlInvalidateNamedFramebufferSubData glInvalidateNamedFramebufferSubData;

        public function void GlClearNamedFramebufferiv(uint framebuffer, uint buffer, int drawbuffer, int32* value);
        public static GlClearNamedFramebufferiv glClearNamedFramebufferiv;

        public function void GlClearNamedFramebufferuiv(uint framebuffer, uint buffer, int drawbuffer, uint32* value);
        public static GlClearNamedFramebufferuiv glClearNamedFramebufferuiv;

        public function void GlClearNamedFramebufferfv(uint framebuffer, uint buffer, int drawbuffer, float* value);
        public static GlClearNamedFramebufferfv glClearNamedFramebufferfv;

        public function void GlClearNamedFramebufferfi(uint framebuffer, uint buffer, int drawbuffer, float depth, int stencil);
        public static GlClearNamedFramebufferfi glClearNamedFramebufferfi;

        public function void GlBlitNamedFramebuffer(uint readFramebuffer, uint drawFramebuffer, int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1, uint mask, uint filter);
        public static GlBlitNamedFramebuffer glBlitNamedFramebuffer;

        public function uint GlCheckNamedFramebufferStatus(uint framebuffer, uint target);
        public static GlCheckNamedFramebufferStatus glCheckNamedFramebufferStatus;

        public function void GlGetNamedFramebufferParameteriv(uint framebuffer, uint pname, int32* param);
        public static GlGetNamedFramebufferParameteriv glGetNamedFramebufferParameteriv;

        public function void GlGetNamedFramebufferAttachmentParameteriv(uint framebuffer, uint attachment, uint pname, int32* paramss);
        public static GlGetNamedFramebufferAttachmentParameteriv glGetNamedFramebufferAttachmentParameteriv;

        public function void GlCreateRenderbuffers(int n, uint32* renderbuffers);
        public static GlCreateRenderbuffers glCreateRenderbuffers;

        public function void GlNamedRenderbufferStorage(uint renderbuffer, uint internalformat, int width, int height);
        public static GlNamedRenderbufferStorage glNamedRenderbufferStorage;

        public function void GlNamedRenderbufferStorageMultisample(uint renderbuffer, int samples, uint internalformat, int width, int height);
        public static GlNamedRenderbufferStorageMultisample glNamedRenderbufferStorageMultisample;

        public function void GlGetNamedRenderbufferParameteriv(uint renderbuffer, uint pname, int32* paramss);
        public static GlGetNamedRenderbufferParameteriv glGetNamedRenderbufferParameteriv;

        public function void GlCreateTextures(uint target, int n, uint32* textures);
        public static GlCreateTextures glCreateTextures;

        public function void GlTextureBuffer(uint texture, uint internalformat, uint buffer);
        public static GlTextureBuffer glTextureBuffer;

        public function void GlTextureBufferRange(uint texture, uint internalformat, uint buffer, int offset, int size);
        public static GlTextureBufferRange glTextureBufferRange;

        public function void GlTextureStorage1D(uint texture, int levels, uint internalformat, int width);
        public static GlTextureStorage1D glTextureStorage1D;

        public function void GlTextureStorage2D(uint texture, int levels, uint internalformat, int width, int height);
        public static GlTextureStorage2D glTextureStorage2D;

        public function void GlTextureStorage3D(uint texture, int levels, uint internalformat, int width, int height, int depth);
        public static GlTextureStorage3D glTextureStorage3D;

        public function void GlTextureStorage2DMultisample(uint texture, int samples, uint internalformat, int width, int height, uint8 fixedsamplelocations);
        public static GlTextureStorage2DMultisample glTextureStorage2DMultisample;

        public function void GlTextureStorage3DMultisample(uint texture, int samples, uint internalformat, int width, int height, int depth, uint8 fixedsamplelocations);
        public static GlTextureStorage3DMultisample glTextureStorage3DMultisample;

        public function void GlTextureSubImage1D(uint texture, int level, int xoffset, int width, uint format, uint type, void* pixels);
        public static GlTextureSubImage1D glTextureSubImage1D;

        public function void GlTextureSubImage2D(uint texture, int level, int xoffset, int yoffset, int width, int height, uint format, uint type, void* pixels);
        public static GlTextureSubImage2D glTextureSubImage2D;

        public function void GlTextureSubImage3D(uint texture, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, uint format, uint type, void* pixels);
        public static GlTextureSubImage3D glTextureSubImage3D;

        public function void GlCompressedTextureSubImage1D(uint texture, int level, int xoffset, int width, uint format, int imageSize, void* data);
        public static GlCompressedTextureSubImage1D glCompressedTextureSubImage1D;

        public function void GlCompressedTextureSubImage2D(uint texture, int level, int xoffset, int yoffset, int width, int height, uint format, int imageSize, void* data);
        public static GlCompressedTextureSubImage2D glCompressedTextureSubImage2D;

        public function void GlCompressedTextureSubImage3D(uint texture, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, uint format, int imageSize, void* data);
        public static GlCompressedTextureSubImage3D glCompressedTextureSubImage3D;

        public function void GlCopyTextureSubImage1D(uint texture, int level, int xoffset, int x, int y, int width);
        public static GlCopyTextureSubImage1D glCopyTextureSubImage1D;

        public function void GlCopyTextureSubImage2D(uint texture, int level, int xoffset, int yoffset, int x, int y, int width, int height);
        public static GlCopyTextureSubImage2D glCopyTextureSubImage2D;

        public function void GlCopyTextureSubImage3D(uint texture, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width, int height);
        public static GlCopyTextureSubImage3D glCopyTextureSubImage3D;

        public function void GlTextureParameterf(uint texture, uint pname, float param);
        public static GlTextureParameterf glTextureParameterf;

        public function void GlTextureParameterfv(uint texture, uint pname, float* param);
        public static GlTextureParameterfv glTextureParameterfv;

        public function void GlTextureParameteri(uint texture, uint pname, int param);
        public static GlTextureParameteri glTextureParameteri;

        public function void GlTextureParameterIiv(uint texture, uint pname, int32* paramss);
        public static GlTextureParameterIiv glTextureParameterIiv;

        public function void GlTextureParameterIuiv(uint texture, uint pname, uint32* paramss);
        public static GlTextureParameterIuiv glTextureParameterIuiv;

        public function void GlTextureParameteriv(uint texture, uint pname, int32* param);
        public static GlTextureParameteriv glTextureParameteriv;

        public function void GlGenerateTextureMipmap(uint texture);
        public static GlGenerateTextureMipmap glGenerateTextureMipmap;

        public function void GlBindTextureUnit(uint unit, uint texture);
        public static GlBindTextureUnit glBindTextureUnit;

        public function void GlGetTextureImage(uint texture, int level, uint format, uint type, int bufSize, void* pixels);
        public static GlGetTextureImage glGetTextureImage;

        public function void GlGetCompressedTextureImage(uint texture, int level, int bufSize, void* pixels);
        public static GlGetCompressedTextureImage glGetCompressedTextureImage;

        public function void GlGetTextureLevelParameterfv(uint texture, int level, uint pname, float* paramss);
        public static GlGetTextureLevelParameterfv glGetTextureLevelParameterfv;

        public function void GlGetTextureLevelParameteriv(uint texture, int level, uint pname, int32* paramss);
        public static GlGetTextureLevelParameteriv glGetTextureLevelParameteriv;

        public function void GlGetTextureParameterfv(uint texture, uint pname, float* paramss);
        public static GlGetTextureParameterfv glGetTextureParameterfv;

        public function void GlGetTextureParameterIiv(uint texture, uint pname, int32* paramss);
        public static GlGetTextureParameterIiv glGetTextureParameterIiv;

        public function void GlGetTextureParameterIuiv(uint texture, uint pname, uint32* paramss);
        public static GlGetTextureParameterIuiv glGetTextureParameterIuiv;

        public function void GlGetTextureParameteriv(uint texture, uint pname, int32* paramss);
        public static GlGetTextureParameteriv glGetTextureParameteriv;

        public function void GlCreateVertexArrays(int n, uint32* arrays);
        public static GlCreateVertexArrays glCreateVertexArrays;

        public function void GlDisableVertexArrayAttrib(uint vaobj, uint index);
        public static GlDisableVertexArrayAttrib glDisableVertexArrayAttrib;

        public function void GlEnableVertexArrayAttrib(uint vaobj, uint index);
        public static GlEnableVertexArrayAttrib glEnableVertexArrayAttrib;

        public function void GlVertexArrayElementBuffer(uint vaobj, uint buffer);
        public static GlVertexArrayElementBuffer glVertexArrayElementBuffer;

        public function void GlVertexArrayVertexBuffer(uint vaobj, uint bindingindex, uint buffer, int offset, int stride);
        public static GlVertexArrayVertexBuffer glVertexArrayVertexBuffer;

        public function void GlVertexArrayVertexBuffers(uint vaobj, uint first, int count, uint32* buffers, int32* offsets, int32* strides);
        public static GlVertexArrayVertexBuffers glVertexArrayVertexBuffers;

        public function void GlVertexArrayAttribBinding(uint vaobj, uint attribindex, uint bindingindex);
        public static GlVertexArrayAttribBinding glVertexArrayAttribBinding;

        public function void GlVertexArrayAttribFormat(uint vaobj, uint attribindex, int size, uint type, uint8 normalized, uint relativeoffset);
        public static GlVertexArrayAttribFormat glVertexArrayAttribFormat;

        public function void GlVertexArrayAttribIFormat(uint vaobj, uint attribindex, int size, uint type, uint relativeoffset);
        public static GlVertexArrayAttribIFormat glVertexArrayAttribIFormat;

        public function void GlVertexArrayAttribLFormat(uint vaobj, uint attribindex, int size, uint type, uint relativeoffset);
        public static GlVertexArrayAttribLFormat glVertexArrayAttribLFormat;

        public function void GlVertexArrayBindingDivisor(uint vaobj, uint bindingindex, uint divisor);
        public static GlVertexArrayBindingDivisor glVertexArrayBindingDivisor;

        public function void GlGetVertexArrayiv(uint vaobj, uint pname, int32* param);
        public static GlGetVertexArrayiv glGetVertexArrayiv;

        public function void GlGetVertexArrayIndexediv(uint vaobj, uint index, uint pname, int32* param);
        public static GlGetVertexArrayIndexediv glGetVertexArrayIndexediv;

        public function void GlGetVertexArrayIndexed64iv(uint vaobj, uint index, uint pname, int64* param);
        public static GlGetVertexArrayIndexed64iv glGetVertexArrayIndexed64iv;

        public function void GlCreateSamplers(int n, uint32* samplers);
        public static GlCreateSamplers glCreateSamplers;

        public function void GlCreateProgramPipelines(int n, uint32* pipelines);
        public static GlCreateProgramPipelines glCreateProgramPipelines;

        public function void GlCreateQueries(uint target, int n, uint32* ids);
        public static GlCreateQueries glCreateQueries;

        public function void GlGetQueryBufferObjecti64v(uint id, uint buffer, uint pname, int offset);
        public static GlGetQueryBufferObjecti64v glGetQueryBufferObjecti64v;

        public function void GlGetQueryBufferObjectiv(uint id, uint buffer, uint pname, int offset);
        public static GlGetQueryBufferObjectiv glGetQueryBufferObjectiv;

        public function void GlGetQueryBufferObjectui64v(uint id, uint buffer, uint pname, int offset);
        public static GlGetQueryBufferObjectui64v glGetQueryBufferObjectui64v;

        public function void GlGetQueryBufferObjectuiv(uint id, uint buffer, uint pname, int offset);
        public static GlGetQueryBufferObjectuiv glGetQueryBufferObjectuiv;

        public function void GlMemoryBarrierByRegion(uint barriers);
        public static GlMemoryBarrierByRegion glMemoryBarrierByRegion;

        public function void GlGetTextureSubImage(uint texture, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, uint format, uint type, int bufSize, void* pixels);
        public static GlGetTextureSubImage glGetTextureSubImage;

        public function void GlGetCompressedTextureSubImage(uint texture, int level, int xoffset, int yoffset, int zoffset, int width, int height, int depth, int bufSize, void* pixels);
        public static GlGetCompressedTextureSubImage glGetCompressedTextureSubImage;

        public function uint GlGetGraphicsResetStatus();
        public static GlGetGraphicsResetStatus glGetGraphicsResetStatus;

        public function void GlGetnCompressedTexImage(uint target, int lod, int bufSize, void* pixels);
        public static GlGetnCompressedTexImage glGetnCompressedTexImage;

        public function void GlGetnTexImage(uint target, int level, uint format, uint type, int bufSize, void* pixels);
        public static GlGetnTexImage glGetnTexImage;

        public function void GlGetnUniformdv(uint program, int location, int bufSize, double* paramss);
        public static GlGetnUniformdv glGetnUniformdv;

        public function void GlGetnUniformfv(uint program, int location, int bufSize, float* paramss);
        public static GlGetnUniformfv glGetnUniformfv;

        public function void GlGetnUniformiv(uint program, int location, int bufSize, int32* paramss);
        public static GlGetnUniformiv glGetnUniformiv;

        public function void GlGetnUniformuiv(uint program, int location, int bufSize, uint32* paramss);
        public static GlGetnUniformuiv glGetnUniformuiv;

        public function void GlReadnPixels(int x, int y, int width, int height, uint format, uint type, int bufSize, void* data);
        public static GlReadnPixels glReadnPixels;

        public function void GlTextureBarrier();
        public static GlTextureBarrier glTextureBarrier;

        public function void GlSpecializeShader(uint shader, char8* pEntryPoint, uint numSpecializationConstants, uint32* pConstantIndex, uint32* pConstantValue);
        public static GlSpecializeShader glSpecializeShader;

        public function void GlMultiDrawArraysIndirectCount(uint mode, void* indirect, int drawcount, int maxdrawcount, int stride);
        public static GlMultiDrawArraysIndirectCount glMultiDrawArraysIndirectCount;

        public function void GlMultiDrawElementsIndirectCount(uint mode, uint type, void* indirect, int drawcount, int maxdrawcount, int stride);
        public static GlMultiDrawElementsIndirectCount glMultiDrawElementsIndirectCount;

        public function void GlPolygonOffsetClamp(float factor, float units, float clamp);
        public static GlPolygonOffsetClamp glPolygonOffsetClamp;

        public static void Init(GetProcAddressFunc getProcAddress) {
            glCullFace = (GlCullFace) getProcAddress("glCullFace");
            glFrontFace = (GlFrontFace) getProcAddress("glFrontFace");
            glHint = (GlHint) getProcAddress("glHint");
            glLineWidth = (GlLineWidth) getProcAddress("glLineWidth");
            glPointSize = (GlPointSize) getProcAddress("glPointSize");
            glPolygonMode = (GlPolygonMode) getProcAddress("glPolygonMode");
            glScissor = (GlScissor) getProcAddress("glScissor");
            glTexParameterf = (GlTexParameterf) getProcAddress("glTexParameterf");
            glTexParameterfv = (GlTexParameterfv) getProcAddress("glTexParameterfv");
            glTexParameteri = (GlTexParameteri) getProcAddress("glTexParameteri");
            glTexParameteriv = (GlTexParameteriv) getProcAddress("glTexParameteriv");
            glTexImage1D = (GlTexImage1D) getProcAddress("glTexImage1D");
            glTexImage2D = (GlTexImage2D) getProcAddress("glTexImage2D");
            glDrawBuffer = (GlDrawBuffer) getProcAddress("glDrawBuffer");
            glClear = (GlClear) getProcAddress("glClear");
            glClearColor = (GlClearColor) getProcAddress("glClearColor");
            glClearStencil = (GlClearStencil) getProcAddress("glClearStencil");
            glClearDepth = (GlClearDepth) getProcAddress("glClearDepth");
            glStencilMask = (GlStencilMask) getProcAddress("glStencilMask");
            glColorMask = (GlColorMask) getProcAddress("glColorMask");
            glDepthMask = (GlDepthMask) getProcAddress("glDepthMask");
            glDisable = (GlDisable) getProcAddress("glDisable");
            glEnable = (GlEnable) getProcAddress("glEnable");
            glFinish = (GlFinish) getProcAddress("glFinish");
            glFlush = (GlFlush) getProcAddress("glFlush");
            glBlendFunc = (GlBlendFunc) getProcAddress("glBlendFunc");
            glLogicOp = (GlLogicOp) getProcAddress("glLogicOp");
            glStencilFunc = (GlStencilFunc) getProcAddress("glStencilFunc");
            glStencilOp = (GlStencilOp) getProcAddress("glStencilOp");
            glDepthFunc = (GlDepthFunc) getProcAddress("glDepthFunc");
            glPixelStoref = (GlPixelStoref) getProcAddress("glPixelStoref");
            glPixelStorei = (GlPixelStorei) getProcAddress("glPixelStorei");
            glReadBuffer = (GlReadBuffer) getProcAddress("glReadBuffer");
            glReadPixels = (GlReadPixels) getProcAddress("glReadPixels");
            glGetBooleanv = (GlGetBooleanv) getProcAddress("glGetBooleanv");
            glGetDoublev = (GlGetDoublev) getProcAddress("glGetDoublev");
            glGetError = (GlGetError) getProcAddress("glGetError");
            glGetFloatv = (GlGetFloatv) getProcAddress("glGetFloatv");
            glGetIntegerv = (GlGetIntegerv) getProcAddress("glGetIntegerv");
            glGetString = (GlGetString) getProcAddress("glGetString");
            glGetTexImage = (GlGetTexImage) getProcAddress("glGetTexImage");
            glGetTexParameterfv = (GlGetTexParameterfv) getProcAddress("glGetTexParameterfv");
            glGetTexParameteriv = (GlGetTexParameteriv) getProcAddress("glGetTexParameteriv");
            glGetTexLevelParameterfv = (GlGetTexLevelParameterfv) getProcAddress("glGetTexLevelParameterfv");
            glGetTexLevelParameteriv = (GlGetTexLevelParameteriv) getProcAddress("glGetTexLevelParameteriv");
            glIsEnabled = (GlIsEnabled) getProcAddress("glIsEnabled");
            glDepthRange = (GlDepthRange) getProcAddress("glDepthRange");
            glViewport = (GlViewport) getProcAddress("glViewport");
            glDrawArrays = (GlDrawArrays) getProcAddress("glDrawArrays");
            glDrawElements = (GlDrawElements) getProcAddress("glDrawElements");
            glPolygonOffset = (GlPolygonOffset) getProcAddress("glPolygonOffset");
            glCopyTexImage1D = (GlCopyTexImage1D) getProcAddress("glCopyTexImage1D");
            glCopyTexImage2D = (GlCopyTexImage2D) getProcAddress("glCopyTexImage2D");
            glCopyTexSubImage1D = (GlCopyTexSubImage1D) getProcAddress("glCopyTexSubImage1D");
            glCopyTexSubImage2D = (GlCopyTexSubImage2D) getProcAddress("glCopyTexSubImage2D");
            glTexSubImage1D = (GlTexSubImage1D) getProcAddress("glTexSubImage1D");
            glTexSubImage2D = (GlTexSubImage2D) getProcAddress("glTexSubImage2D");
            glBindTexture = (GlBindTexture) getProcAddress("glBindTexture");
            glDeleteTextures = (GlDeleteTextures) getProcAddress("glDeleteTextures");
            glGenTextures = (GlGenTextures) getProcAddress("glGenTextures");
            glIsTexture = (GlIsTexture) getProcAddress("glIsTexture");
            glDrawRangeElements = (GlDrawRangeElements) getProcAddress("glDrawRangeElements");
            glTexImage3D = (GlTexImage3D) getProcAddress("glTexImage3D");
            glTexSubImage3D = (GlTexSubImage3D) getProcAddress("glTexSubImage3D");
            glCopyTexSubImage3D = (GlCopyTexSubImage3D) getProcAddress("glCopyTexSubImage3D");
            glActiveTexture = (GlActiveTexture) getProcAddress("glActiveTexture");
            glSampleCoverage = (GlSampleCoverage) getProcAddress("glSampleCoverage");
            glCompressedTexImage3D = (GlCompressedTexImage3D) getProcAddress("glCompressedTexImage3D");
            glCompressedTexImage2D = (GlCompressedTexImage2D) getProcAddress("glCompressedTexImage2D");
            glCompressedTexImage1D = (GlCompressedTexImage1D) getProcAddress("glCompressedTexImage1D");
            glCompressedTexSubImage3D = (GlCompressedTexSubImage3D) getProcAddress("glCompressedTexSubImage3D");
            glCompressedTexSubImage2D = (GlCompressedTexSubImage2D) getProcAddress("glCompressedTexSubImage2D");
            glCompressedTexSubImage1D = (GlCompressedTexSubImage1D) getProcAddress("glCompressedTexSubImage1D");
            glGetCompressedTexImage = (GlGetCompressedTexImage) getProcAddress("glGetCompressedTexImage");
            glBlendFuncSeparate = (GlBlendFuncSeparate) getProcAddress("glBlendFuncSeparate");
            glMultiDrawArrays = (GlMultiDrawArrays) getProcAddress("glMultiDrawArrays");
            glMultiDrawElements = (GlMultiDrawElements) getProcAddress("glMultiDrawElements");
            glPointParameterf = (GlPointParameterf) getProcAddress("glPointParameterf");
            glPointParameterfv = (GlPointParameterfv) getProcAddress("glPointParameterfv");
            glPointParameteri = (GlPointParameteri) getProcAddress("glPointParameteri");
            glPointParameteriv = (GlPointParameteriv) getProcAddress("glPointParameteriv");
            glBlendColor = (GlBlendColor) getProcAddress("glBlendColor");
            glBlendEquation = (GlBlendEquation) getProcAddress("glBlendEquation");
            glGenQueries = (GlGenQueries) getProcAddress("glGenQueries");
            glDeleteQueries = (GlDeleteQueries) getProcAddress("glDeleteQueries");
            glIsQuery = (GlIsQuery) getProcAddress("glIsQuery");
            glBeginQuery = (GlBeginQuery) getProcAddress("glBeginQuery");
            glEndQuery = (GlEndQuery) getProcAddress("glEndQuery");
            glGetQueryiv = (GlGetQueryiv) getProcAddress("glGetQueryiv");
            glGetQueryObjectiv = (GlGetQueryObjectiv) getProcAddress("glGetQueryObjectiv");
            glGetQueryObjectuiv = (GlGetQueryObjectuiv) getProcAddress("glGetQueryObjectuiv");
            glBindBuffer = (GlBindBuffer) getProcAddress("glBindBuffer");
            glDeleteBuffers = (GlDeleteBuffers) getProcAddress("glDeleteBuffers");
            glGenBuffers = (GlGenBuffers) getProcAddress("glGenBuffers");
            glIsBuffer = (GlIsBuffer) getProcAddress("glIsBuffer");
            glBufferData = (GlBufferData) getProcAddress("glBufferData");
            glBufferSubData = (GlBufferSubData) getProcAddress("glBufferSubData");
            glGetBufferSubData = (GlGetBufferSubData) getProcAddress("glGetBufferSubData");
            glMapBuffer = (GlMapBuffer) getProcAddress("glMapBuffer");
            glUnmapBuffer = (GlUnmapBuffer) getProcAddress("glUnmapBuffer");
            glGetBufferParameteriv = (GlGetBufferParameteriv) getProcAddress("glGetBufferParameteriv");
            glGetBufferPointerv = (GlGetBufferPointerv) getProcAddress("glGetBufferPointerv");
            glBlendEquationSeparate = (GlBlendEquationSeparate) getProcAddress("glBlendEquationSeparate");
            glDrawBuffers = (GlDrawBuffers) getProcAddress("glDrawBuffers");
            glStencilOpSeparate = (GlStencilOpSeparate) getProcAddress("glStencilOpSeparate");
            glStencilFuncSeparate = (GlStencilFuncSeparate) getProcAddress("glStencilFuncSeparate");
            glStencilMaskSeparate = (GlStencilMaskSeparate) getProcAddress("glStencilMaskSeparate");
            glAttachShader = (GlAttachShader) getProcAddress("glAttachShader");
            glBindAttribLocation = (GlBindAttribLocation) getProcAddress("glBindAttribLocation");
            glCompileShader = (GlCompileShader) getProcAddress("glCompileShader");
            glCreateProgram = (GlCreateProgram) getProcAddress("glCreateProgram");
            glCreateShader = (GlCreateShader) getProcAddress("glCreateShader");
            glDeleteProgram = (GlDeleteProgram) getProcAddress("glDeleteProgram");
            glDeleteShader = (GlDeleteShader) getProcAddress("glDeleteShader");
            glDetachShader = (GlDetachShader) getProcAddress("glDetachShader");
            glDisableVertexAttribArray = (GlDisableVertexAttribArray) getProcAddress("glDisableVertexAttribArray");
            glEnableVertexAttribArray = (GlEnableVertexAttribArray) getProcAddress("glEnableVertexAttribArray");
            glGetActiveAttrib = (GlGetActiveAttrib) getProcAddress("glGetActiveAttrib");
            glGetActiveUniform = (GlGetActiveUniform) getProcAddress("glGetActiveUniform");
            glGetAttachedShaders = (GlGetAttachedShaders) getProcAddress("glGetAttachedShaders");
            glGetAttribLocation = (GlGetAttribLocation) getProcAddress("glGetAttribLocation");
            glGetProgramiv = (GlGetProgramiv) getProcAddress("glGetProgramiv");
            glGetProgramInfoLog = (GlGetProgramInfoLog) getProcAddress("glGetProgramInfoLog");
            glGetShaderiv = (GlGetShaderiv) getProcAddress("glGetShaderiv");
            glGetShaderInfoLog = (GlGetShaderInfoLog) getProcAddress("glGetShaderInfoLog");
            glGetShaderSource = (GlGetShaderSource) getProcAddress("glGetShaderSource");
            glGetUniformLocation = (GlGetUniformLocation) getProcAddress("glGetUniformLocation");
            glGetUniformfv = (GlGetUniformfv) getProcAddress("glGetUniformfv");
            glGetUniformiv = (GlGetUniformiv) getProcAddress("glGetUniformiv");
            glGetVertexAttribdv = (GlGetVertexAttribdv) getProcAddress("glGetVertexAttribdv");
            glGetVertexAttribfv = (GlGetVertexAttribfv) getProcAddress("glGetVertexAttribfv");
            glGetVertexAttribiv = (GlGetVertexAttribiv) getProcAddress("glGetVertexAttribiv");
            glGetVertexAttribPointerv = (GlGetVertexAttribPointerv) getProcAddress("glGetVertexAttribPointerv");
            glIsProgram = (GlIsProgram) getProcAddress("glIsProgram");
            glIsShader = (GlIsShader) getProcAddress("glIsShader");
            glLinkProgram = (GlLinkProgram) getProcAddress("glLinkProgram");
            glShaderSource = (GlShaderSource) getProcAddress("glShaderSource");
            glUseProgram = (GlUseProgram) getProcAddress("glUseProgram");
            glUniform1f = (GlUniform1f) getProcAddress("glUniform1f");
            glUniform2f = (GlUniform2f) getProcAddress("glUniform2f");
            glUniform3f = (GlUniform3f) getProcAddress("glUniform3f");
            glUniform4f = (GlUniform4f) getProcAddress("glUniform4f");
            glUniform1i = (GlUniform1i) getProcAddress("glUniform1i");
            glUniform2i = (GlUniform2i) getProcAddress("glUniform2i");
            glUniform3i = (GlUniform3i) getProcAddress("glUniform3i");
            glUniform4i = (GlUniform4i) getProcAddress("glUniform4i");
            glUniform1fv = (GlUniform1fv) getProcAddress("glUniform1fv");
            glUniform2fv = (GlUniform2fv) getProcAddress("glUniform2fv");
            glUniform3fv = (GlUniform3fv) getProcAddress("glUniform3fv");
            glUniform4fv = (GlUniform4fv) getProcAddress("glUniform4fv");
            glUniform1iv = (GlUniform1iv) getProcAddress("glUniform1iv");
            glUniform2iv = (GlUniform2iv) getProcAddress("glUniform2iv");
            glUniform3iv = (GlUniform3iv) getProcAddress("glUniform3iv");
            glUniform4iv = (GlUniform4iv) getProcAddress("glUniform4iv");
            glUniformMatrix2fv = (GlUniformMatrix2fv) getProcAddress("glUniformMatrix2fv");
            glUniformMatrix3fv = (GlUniformMatrix3fv) getProcAddress("glUniformMatrix3fv");
            glUniformMatrix4fv = (GlUniformMatrix4fv) getProcAddress("glUniformMatrix4fv");
            glValidateProgram = (GlValidateProgram) getProcAddress("glValidateProgram");
            glVertexAttrib1d = (GlVertexAttrib1d) getProcAddress("glVertexAttrib1d");
            glVertexAttrib1dv = (GlVertexAttrib1dv) getProcAddress("glVertexAttrib1dv");
            glVertexAttrib1f = (GlVertexAttrib1f) getProcAddress("glVertexAttrib1f");
            glVertexAttrib1fv = (GlVertexAttrib1fv) getProcAddress("glVertexAttrib1fv");
            glVertexAttrib1s = (GlVertexAttrib1s) getProcAddress("glVertexAttrib1s");
            glVertexAttrib1sv = (GlVertexAttrib1sv) getProcAddress("glVertexAttrib1sv");
            glVertexAttrib2d = (GlVertexAttrib2d) getProcAddress("glVertexAttrib2d");
            glVertexAttrib2dv = (GlVertexAttrib2dv) getProcAddress("glVertexAttrib2dv");
            glVertexAttrib2f = (GlVertexAttrib2f) getProcAddress("glVertexAttrib2f");
            glVertexAttrib2fv = (GlVertexAttrib2fv) getProcAddress("glVertexAttrib2fv");
            glVertexAttrib2s = (GlVertexAttrib2s) getProcAddress("glVertexAttrib2s");
            glVertexAttrib2sv = (GlVertexAttrib2sv) getProcAddress("glVertexAttrib2sv");
            glVertexAttrib3d = (GlVertexAttrib3d) getProcAddress("glVertexAttrib3d");
            glVertexAttrib3dv = (GlVertexAttrib3dv) getProcAddress("glVertexAttrib3dv");
            glVertexAttrib3f = (GlVertexAttrib3f) getProcAddress("glVertexAttrib3f");
            glVertexAttrib3fv = (GlVertexAttrib3fv) getProcAddress("glVertexAttrib3fv");
            glVertexAttrib3s = (GlVertexAttrib3s) getProcAddress("glVertexAttrib3s");
            glVertexAttrib3sv = (GlVertexAttrib3sv) getProcAddress("glVertexAttrib3sv");
            glVertexAttrib4Nbv = (GlVertexAttrib4Nbv) getProcAddress("glVertexAttrib4Nbv");
            glVertexAttrib4Niv = (GlVertexAttrib4Niv) getProcAddress("glVertexAttrib4Niv");
            glVertexAttrib4Nsv = (GlVertexAttrib4Nsv) getProcAddress("glVertexAttrib4Nsv");
            glVertexAttrib4Nub = (GlVertexAttrib4Nub) getProcAddress("glVertexAttrib4Nub");
            glVertexAttrib4Nubv = (GlVertexAttrib4Nubv) getProcAddress("glVertexAttrib4Nubv");
            glVertexAttrib4Nuiv = (GlVertexAttrib4Nuiv) getProcAddress("glVertexAttrib4Nuiv");
            glVertexAttrib4Nusv = (GlVertexAttrib4Nusv) getProcAddress("glVertexAttrib4Nusv");
            glVertexAttrib4bv = (GlVertexAttrib4bv) getProcAddress("glVertexAttrib4bv");
            glVertexAttrib4d = (GlVertexAttrib4d) getProcAddress("glVertexAttrib4d");
            glVertexAttrib4dv = (GlVertexAttrib4dv) getProcAddress("glVertexAttrib4dv");
            glVertexAttrib4f = (GlVertexAttrib4f) getProcAddress("glVertexAttrib4f");
            glVertexAttrib4fv = (GlVertexAttrib4fv) getProcAddress("glVertexAttrib4fv");
            glVertexAttrib4iv = (GlVertexAttrib4iv) getProcAddress("glVertexAttrib4iv");
            glVertexAttrib4s = (GlVertexAttrib4s) getProcAddress("glVertexAttrib4s");
            glVertexAttrib4sv = (GlVertexAttrib4sv) getProcAddress("glVertexAttrib4sv");
            glVertexAttrib4ubv = (GlVertexAttrib4ubv) getProcAddress("glVertexAttrib4ubv");
            glVertexAttrib4uiv = (GlVertexAttrib4uiv) getProcAddress("glVertexAttrib4uiv");
            glVertexAttrib4usv = (GlVertexAttrib4usv) getProcAddress("glVertexAttrib4usv");
            glVertexAttribPointer = (GlVertexAttribPointer) getProcAddress("glVertexAttribPointer");
            glUniformMatrix2x3fv = (GlUniformMatrix2x3fv) getProcAddress("glUniformMatrix2x3fv");
            glUniformMatrix3x2fv = (GlUniformMatrix3x2fv) getProcAddress("glUniformMatrix3x2fv");
            glUniformMatrix2x4fv = (GlUniformMatrix2x4fv) getProcAddress("glUniformMatrix2x4fv");
            glUniformMatrix4x2fv = (GlUniformMatrix4x2fv) getProcAddress("glUniformMatrix4x2fv");
            glUniformMatrix3x4fv = (GlUniformMatrix3x4fv) getProcAddress("glUniformMatrix3x4fv");
            glUniformMatrix4x3fv = (GlUniformMatrix4x3fv) getProcAddress("glUniformMatrix4x3fv");
            glColorMaski = (GlColorMaski) getProcAddress("glColorMaski");
            glGetBooleani_v = (GlGetBooleani_v) getProcAddress("glGetBooleani_v");
            glGetIntegeri_v = (GlGetIntegeri_v) getProcAddress("glGetIntegeri_v");
            glEnablei = (GlEnablei) getProcAddress("glEnablei");
            glDisablei = (GlDisablei) getProcAddress("glDisablei");
            glIsEnabledi = (GlIsEnabledi) getProcAddress("glIsEnabledi");
            glBeginTransformFeedback = (GlBeginTransformFeedback) getProcAddress("glBeginTransformFeedback");
            glEndTransformFeedback = (GlEndTransformFeedback) getProcAddress("glEndTransformFeedback");
            glBindBufferRange = (GlBindBufferRange) getProcAddress("glBindBufferRange");
            glBindBufferBase = (GlBindBufferBase) getProcAddress("glBindBufferBase");
            glTransformFeedbackVaryings = (GlTransformFeedbackVaryings) getProcAddress("glTransformFeedbackVaryings");
            glGetTransformFeedbackVarying = (GlGetTransformFeedbackVarying) getProcAddress("glGetTransformFeedbackVarying");
            glClampColor = (GlClampColor) getProcAddress("glClampColor");
            glBeginConditionalRender = (GlBeginConditionalRender) getProcAddress("glBeginConditionalRender");
            glEndConditionalRender = (GlEndConditionalRender) getProcAddress("glEndConditionalRender");
            glVertexAttribIPointer = (GlVertexAttribIPointer) getProcAddress("glVertexAttribIPointer");
            glGetVertexAttribIiv = (GlGetVertexAttribIiv) getProcAddress("glGetVertexAttribIiv");
            glGetVertexAttribIuiv = (GlGetVertexAttribIuiv) getProcAddress("glGetVertexAttribIuiv");
            glVertexAttribI1i = (GlVertexAttribI1i) getProcAddress("glVertexAttribI1i");
            glVertexAttribI2i = (GlVertexAttribI2i) getProcAddress("glVertexAttribI2i");
            glVertexAttribI3i = (GlVertexAttribI3i) getProcAddress("glVertexAttribI3i");
            glVertexAttribI4i = (GlVertexAttribI4i) getProcAddress("glVertexAttribI4i");
            glVertexAttribI1ui = (GlVertexAttribI1ui) getProcAddress("glVertexAttribI1ui");
            glVertexAttribI2ui = (GlVertexAttribI2ui) getProcAddress("glVertexAttribI2ui");
            glVertexAttribI3ui = (GlVertexAttribI3ui) getProcAddress("glVertexAttribI3ui");
            glVertexAttribI4ui = (GlVertexAttribI4ui) getProcAddress("glVertexAttribI4ui");
            glVertexAttribI1iv = (GlVertexAttribI1iv) getProcAddress("glVertexAttribI1iv");
            glVertexAttribI2iv = (GlVertexAttribI2iv) getProcAddress("glVertexAttribI2iv");
            glVertexAttribI3iv = (GlVertexAttribI3iv) getProcAddress("glVertexAttribI3iv");
            glVertexAttribI4iv = (GlVertexAttribI4iv) getProcAddress("glVertexAttribI4iv");
            glVertexAttribI1uiv = (GlVertexAttribI1uiv) getProcAddress("glVertexAttribI1uiv");
            glVertexAttribI2uiv = (GlVertexAttribI2uiv) getProcAddress("glVertexAttribI2uiv");
            glVertexAttribI3uiv = (GlVertexAttribI3uiv) getProcAddress("glVertexAttribI3uiv");
            glVertexAttribI4uiv = (GlVertexAttribI4uiv) getProcAddress("glVertexAttribI4uiv");
            glVertexAttribI4bv = (GlVertexAttribI4bv) getProcAddress("glVertexAttribI4bv");
            glVertexAttribI4sv = (GlVertexAttribI4sv) getProcAddress("glVertexAttribI4sv");
            glVertexAttribI4ubv = (GlVertexAttribI4ubv) getProcAddress("glVertexAttribI4ubv");
            glVertexAttribI4usv = (GlVertexAttribI4usv) getProcAddress("glVertexAttribI4usv");
            glGetUniformuiv = (GlGetUniformuiv) getProcAddress("glGetUniformuiv");
            glBindFragDataLocation = (GlBindFragDataLocation) getProcAddress("glBindFragDataLocation");
            glGetFragDataLocation = (GlGetFragDataLocation) getProcAddress("glGetFragDataLocation");
            glUniform1ui = (GlUniform1ui) getProcAddress("glUniform1ui");
            glUniform2ui = (GlUniform2ui) getProcAddress("glUniform2ui");
            glUniform3ui = (GlUniform3ui) getProcAddress("glUniform3ui");
            glUniform4ui = (GlUniform4ui) getProcAddress("glUniform4ui");
            glUniform1uiv = (GlUniform1uiv) getProcAddress("glUniform1uiv");
            glUniform2uiv = (GlUniform2uiv) getProcAddress("glUniform2uiv");
            glUniform3uiv = (GlUniform3uiv) getProcAddress("glUniform3uiv");
            glUniform4uiv = (GlUniform4uiv) getProcAddress("glUniform4uiv");
            glTexParameterIiv = (GlTexParameterIiv) getProcAddress("glTexParameterIiv");
            glTexParameterIuiv = (GlTexParameterIuiv) getProcAddress("glTexParameterIuiv");
            glGetTexParameterIiv = (GlGetTexParameterIiv) getProcAddress("glGetTexParameterIiv");
            glGetTexParameterIuiv = (GlGetTexParameterIuiv) getProcAddress("glGetTexParameterIuiv");
            glClearBufferiv = (GlClearBufferiv) getProcAddress("glClearBufferiv");
            glClearBufferuiv = (GlClearBufferuiv) getProcAddress("glClearBufferuiv");
            glClearBufferfv = (GlClearBufferfv) getProcAddress("glClearBufferfv");
            glClearBufferfi = (GlClearBufferfi) getProcAddress("glClearBufferfi");
            glGetStringi = (GlGetStringi) getProcAddress("glGetStringi");
            glIsRenderbuffer = (GlIsRenderbuffer) getProcAddress("glIsRenderbuffer");
            glBindRenderbuffer = (GlBindRenderbuffer) getProcAddress("glBindRenderbuffer");
            glDeleteRenderbuffers = (GlDeleteRenderbuffers) getProcAddress("glDeleteRenderbuffers");
            glGenRenderbuffers = (GlGenRenderbuffers) getProcAddress("glGenRenderbuffers");
            glRenderbufferStorage = (GlRenderbufferStorage) getProcAddress("glRenderbufferStorage");
            glGetRenderbufferParameteriv = (GlGetRenderbufferParameteriv) getProcAddress("glGetRenderbufferParameteriv");
            glIsFramebuffer = (GlIsFramebuffer) getProcAddress("glIsFramebuffer");
            glBindFramebuffer = (GlBindFramebuffer) getProcAddress("glBindFramebuffer");
            glDeleteFramebuffers = (GlDeleteFramebuffers) getProcAddress("glDeleteFramebuffers");
            glGenFramebuffers = (GlGenFramebuffers) getProcAddress("glGenFramebuffers");
            glCheckFramebufferStatus = (GlCheckFramebufferStatus) getProcAddress("glCheckFramebufferStatus");
            glFramebufferTexture1D = (GlFramebufferTexture1D) getProcAddress("glFramebufferTexture1D");
            glFramebufferTexture2D = (GlFramebufferTexture2D) getProcAddress("glFramebufferTexture2D");
            glFramebufferTexture3D = (GlFramebufferTexture3D) getProcAddress("glFramebufferTexture3D");
            glFramebufferRenderbuffer = (GlFramebufferRenderbuffer) getProcAddress("glFramebufferRenderbuffer");
            glGetFramebufferAttachmentParameteriv = (GlGetFramebufferAttachmentParameteriv) getProcAddress("glGetFramebufferAttachmentParameteriv");
            glGenerateMipmap = (GlGenerateMipmap) getProcAddress("glGenerateMipmap");
            glBlitFramebuffer = (GlBlitFramebuffer) getProcAddress("glBlitFramebuffer");
            glRenderbufferStorageMultisample = (GlRenderbufferStorageMultisample) getProcAddress("glRenderbufferStorageMultisample");
            glFramebufferTextureLayer = (GlFramebufferTextureLayer) getProcAddress("glFramebufferTextureLayer");
            glMapBufferRange = (GlMapBufferRange) getProcAddress("glMapBufferRange");
            glFlushMappedBufferRange = (GlFlushMappedBufferRange) getProcAddress("glFlushMappedBufferRange");
            glBindVertexArray = (GlBindVertexArray) getProcAddress("glBindVertexArray");
            glDeleteVertexArrays = (GlDeleteVertexArrays) getProcAddress("glDeleteVertexArrays");
            glGenVertexArrays = (GlGenVertexArrays) getProcAddress("glGenVertexArrays");
            glIsVertexArray = (GlIsVertexArray) getProcAddress("glIsVertexArray");
            glDrawArraysInstanced = (GlDrawArraysInstanced) getProcAddress("glDrawArraysInstanced");
            glDrawElementsInstanced = (GlDrawElementsInstanced) getProcAddress("glDrawElementsInstanced");
            glTexBuffer = (GlTexBuffer) getProcAddress("glTexBuffer");
            glPrimitiveRestartIndex = (GlPrimitiveRestartIndex) getProcAddress("glPrimitiveRestartIndex");
            glCopyBufferSubData = (GlCopyBufferSubData) getProcAddress("glCopyBufferSubData");
            glGetUniformIndices = (GlGetUniformIndices) getProcAddress("glGetUniformIndices");
            glGetActiveUniformsiv = (GlGetActiveUniformsiv) getProcAddress("glGetActiveUniformsiv");
            glGetActiveUniformName = (GlGetActiveUniformName) getProcAddress("glGetActiveUniformName");
            glGetUniformBlockIndex = (GlGetUniformBlockIndex) getProcAddress("glGetUniformBlockIndex");
            glGetActiveUniformBlockiv = (GlGetActiveUniformBlockiv) getProcAddress("glGetActiveUniformBlockiv");
            glGetActiveUniformBlockName = (GlGetActiveUniformBlockName) getProcAddress("glGetActiveUniformBlockName");
            glUniformBlockBinding = (GlUniformBlockBinding) getProcAddress("glUniformBlockBinding");
            glDrawElementsBaseVertex = (GlDrawElementsBaseVertex) getProcAddress("glDrawElementsBaseVertex");
            glDrawRangeElementsBaseVertex = (GlDrawRangeElementsBaseVertex) getProcAddress("glDrawRangeElementsBaseVertex");
            glDrawElementsInstancedBaseVertex = (GlDrawElementsInstancedBaseVertex) getProcAddress("glDrawElementsInstancedBaseVertex");
            glMultiDrawElementsBaseVertex = (GlMultiDrawElementsBaseVertex) getProcAddress("glMultiDrawElementsBaseVertex");
            glProvokingVertex = (GlProvokingVertex) getProcAddress("glProvokingVertex");
            glFenceSync = (GlFenceSync) getProcAddress("glFenceSync");
            glIsSync = (GlIsSync) getProcAddress("glIsSync");
            glDeleteSync = (GlDeleteSync) getProcAddress("glDeleteSync");
            glClientWaitSync = (GlClientWaitSync) getProcAddress("glClientWaitSync");
            glWaitSync = (GlWaitSync) getProcAddress("glWaitSync");
            glGetInteger64v = (GlGetInteger64v) getProcAddress("glGetInteger64v");
            glGetSynciv = (GlGetSynciv) getProcAddress("glGetSynciv");
            glGetInteger64i_v = (GlGetInteger64i_v) getProcAddress("glGetInteger64i_v");
            glGetBufferParameteri64v = (GlGetBufferParameteri64v) getProcAddress("glGetBufferParameteri64v");
            glFramebufferTexture = (GlFramebufferTexture) getProcAddress("glFramebufferTexture");
            glTexImage2DMultisample = (GlTexImage2DMultisample) getProcAddress("glTexImage2DMultisample");
            glTexImage3DMultisample = (GlTexImage3DMultisample) getProcAddress("glTexImage3DMultisample");
            glGetMultisamplefv = (GlGetMultisamplefv) getProcAddress("glGetMultisamplefv");
            glSampleMaski = (GlSampleMaski) getProcAddress("glSampleMaski");
            glBindFragDataLocationIndexed = (GlBindFragDataLocationIndexed) getProcAddress("glBindFragDataLocationIndexed");
            glGetFragDataIndex = (GlGetFragDataIndex) getProcAddress("glGetFragDataIndex");
            glGenSamplers = (GlGenSamplers) getProcAddress("glGenSamplers");
            glDeleteSamplers = (GlDeleteSamplers) getProcAddress("glDeleteSamplers");
            glIsSampler = (GlIsSampler) getProcAddress("glIsSampler");
            glBindSampler = (GlBindSampler) getProcAddress("glBindSampler");
            glSamplerParameteri = (GlSamplerParameteri) getProcAddress("glSamplerParameteri");
            glSamplerParameteriv = (GlSamplerParameteriv) getProcAddress("glSamplerParameteriv");
            glSamplerParameterf = (GlSamplerParameterf) getProcAddress("glSamplerParameterf");
            glSamplerParameterfv = (GlSamplerParameterfv) getProcAddress("glSamplerParameterfv");
            glSamplerParameterIiv = (GlSamplerParameterIiv) getProcAddress("glSamplerParameterIiv");
            glSamplerParameterIuiv = (GlSamplerParameterIuiv) getProcAddress("glSamplerParameterIuiv");
            glGetSamplerParameteriv = (GlGetSamplerParameteriv) getProcAddress("glGetSamplerParameteriv");
            glGetSamplerParameterIiv = (GlGetSamplerParameterIiv) getProcAddress("glGetSamplerParameterIiv");
            glGetSamplerParameterfv = (GlGetSamplerParameterfv) getProcAddress("glGetSamplerParameterfv");
            glGetSamplerParameterIuiv = (GlGetSamplerParameterIuiv) getProcAddress("glGetSamplerParameterIuiv");
            glQueryCounter = (GlQueryCounter) getProcAddress("glQueryCounter");
            glGetQueryObjecti64v = (GlGetQueryObjecti64v) getProcAddress("glGetQueryObjecti64v");
            glGetQueryObjectui64v = (GlGetQueryObjectui64v) getProcAddress("glGetQueryObjectui64v");
            glVertexAttribDivisor = (GlVertexAttribDivisor) getProcAddress("glVertexAttribDivisor");
            glVertexAttribP1ui = (GlVertexAttribP1ui) getProcAddress("glVertexAttribP1ui");
            glVertexAttribP1uiv = (GlVertexAttribP1uiv) getProcAddress("glVertexAttribP1uiv");
            glVertexAttribP2ui = (GlVertexAttribP2ui) getProcAddress("glVertexAttribP2ui");
            glVertexAttribP2uiv = (GlVertexAttribP2uiv) getProcAddress("glVertexAttribP2uiv");
            glVertexAttribP3ui = (GlVertexAttribP3ui) getProcAddress("glVertexAttribP3ui");
            glVertexAttribP3uiv = (GlVertexAttribP3uiv) getProcAddress("glVertexAttribP3uiv");
            glVertexAttribP4ui = (GlVertexAttribP4ui) getProcAddress("glVertexAttribP4ui");
            glVertexAttribP4uiv = (GlVertexAttribP4uiv) getProcAddress("glVertexAttribP4uiv");
            glMinSampleShading = (GlMinSampleShading) getProcAddress("glMinSampleShading");
            glBlendEquationi = (GlBlendEquationi) getProcAddress("glBlendEquationi");
            glBlendEquationSeparatei = (GlBlendEquationSeparatei) getProcAddress("glBlendEquationSeparatei");
            glBlendFunci = (GlBlendFunci) getProcAddress("glBlendFunci");
            glBlendFuncSeparatei = (GlBlendFuncSeparatei) getProcAddress("glBlendFuncSeparatei");
            glDrawArraysIndirect = (GlDrawArraysIndirect) getProcAddress("glDrawArraysIndirect");
            glDrawElementsIndirect = (GlDrawElementsIndirect) getProcAddress("glDrawElementsIndirect");
            glUniform1d = (GlUniform1d) getProcAddress("glUniform1d");
            glUniform2d = (GlUniform2d) getProcAddress("glUniform2d");
            glUniform3d = (GlUniform3d) getProcAddress("glUniform3d");
            glUniform4d = (GlUniform4d) getProcAddress("glUniform4d");
            glUniform1dv = (GlUniform1dv) getProcAddress("glUniform1dv");
            glUniform2dv = (GlUniform2dv) getProcAddress("glUniform2dv");
            glUniform3dv = (GlUniform3dv) getProcAddress("glUniform3dv");
            glUniform4dv = (GlUniform4dv) getProcAddress("glUniform4dv");
            glUniformMatrix2dv = (GlUniformMatrix2dv) getProcAddress("glUniformMatrix2dv");
            glUniformMatrix3dv = (GlUniformMatrix3dv) getProcAddress("glUniformMatrix3dv");
            glUniformMatrix4dv = (GlUniformMatrix4dv) getProcAddress("glUniformMatrix4dv");
            glUniformMatrix2x3dv = (GlUniformMatrix2x3dv) getProcAddress("glUniformMatrix2x3dv");
            glUniformMatrix2x4dv = (GlUniformMatrix2x4dv) getProcAddress("glUniformMatrix2x4dv");
            glUniformMatrix3x2dv = (GlUniformMatrix3x2dv) getProcAddress("glUniformMatrix3x2dv");
            glUniformMatrix3x4dv = (GlUniformMatrix3x4dv) getProcAddress("glUniformMatrix3x4dv");
            glUniformMatrix4x2dv = (GlUniformMatrix4x2dv) getProcAddress("glUniformMatrix4x2dv");
            glUniformMatrix4x3dv = (GlUniformMatrix4x3dv) getProcAddress("glUniformMatrix4x3dv");
            glGetUniformdv = (GlGetUniformdv) getProcAddress("glGetUniformdv");
            glGetSubroutineUniformLocation = (GlGetSubroutineUniformLocation) getProcAddress("glGetSubroutineUniformLocation");
            glGetSubroutineIndex = (GlGetSubroutineIndex) getProcAddress("glGetSubroutineIndex");
            glGetActiveSubroutineUniformiv = (GlGetActiveSubroutineUniformiv) getProcAddress("glGetActiveSubroutineUniformiv");
            glGetActiveSubroutineUniformName = (GlGetActiveSubroutineUniformName) getProcAddress("glGetActiveSubroutineUniformName");
            glGetActiveSubroutineName = (GlGetActiveSubroutineName) getProcAddress("glGetActiveSubroutineName");
            glUniformSubroutinesuiv = (GlUniformSubroutinesuiv) getProcAddress("glUniformSubroutinesuiv");
            glGetUniformSubroutineuiv = (GlGetUniformSubroutineuiv) getProcAddress("glGetUniformSubroutineuiv");
            glGetProgramStageiv = (GlGetProgramStageiv) getProcAddress("glGetProgramStageiv");
            glPatchParameteri = (GlPatchParameteri) getProcAddress("glPatchParameteri");
            glPatchParameterfv = (GlPatchParameterfv) getProcAddress("glPatchParameterfv");
            glBindTransformFeedback = (GlBindTransformFeedback) getProcAddress("glBindTransformFeedback");
            glDeleteTransformFeedbacks = (GlDeleteTransformFeedbacks) getProcAddress("glDeleteTransformFeedbacks");
            glGenTransformFeedbacks = (GlGenTransformFeedbacks) getProcAddress("glGenTransformFeedbacks");
            glIsTransformFeedback = (GlIsTransformFeedback) getProcAddress("glIsTransformFeedback");
            glPauseTransformFeedback = (GlPauseTransformFeedback) getProcAddress("glPauseTransformFeedback");
            glResumeTransformFeedback = (GlResumeTransformFeedback) getProcAddress("glResumeTransformFeedback");
            glDrawTransformFeedback = (GlDrawTransformFeedback) getProcAddress("glDrawTransformFeedback");
            glDrawTransformFeedbackStream = (GlDrawTransformFeedbackStream) getProcAddress("glDrawTransformFeedbackStream");
            glBeginQueryIndexed = (GlBeginQueryIndexed) getProcAddress("glBeginQueryIndexed");
            glEndQueryIndexed = (GlEndQueryIndexed) getProcAddress("glEndQueryIndexed");
            glGetQueryIndexediv = (GlGetQueryIndexediv) getProcAddress("glGetQueryIndexediv");
            glReleaseShaderCompiler = (GlReleaseShaderCompiler) getProcAddress("glReleaseShaderCompiler");
            glShaderBinary = (GlShaderBinary) getProcAddress("glShaderBinary");
            glGetShaderPrecisionFormat = (GlGetShaderPrecisionFormat) getProcAddress("glGetShaderPrecisionFormat");
            glDepthRangef = (GlDepthRangef) getProcAddress("glDepthRangef");
            glClearDepthf = (GlClearDepthf) getProcAddress("glClearDepthf");
            glGetProgramBinary = (GlGetProgramBinary) getProcAddress("glGetProgramBinary");
            glProgramBinary = (GlProgramBinary) getProcAddress("glProgramBinary");
            glProgramParameteri = (GlProgramParameteri) getProcAddress("glProgramParameteri");
            glUseProgramStages = (GlUseProgramStages) getProcAddress("glUseProgramStages");
            glActiveShaderProgram = (GlActiveShaderProgram) getProcAddress("glActiveShaderProgram");
            glCreateShaderProgramv = (GlCreateShaderProgramv) getProcAddress("glCreateShaderProgramv");
            glBindProgramPipeline = (GlBindProgramPipeline) getProcAddress("glBindProgramPipeline");
            glDeleteProgramPipelines = (GlDeleteProgramPipelines) getProcAddress("glDeleteProgramPipelines");
            glGenProgramPipelines = (GlGenProgramPipelines) getProcAddress("glGenProgramPipelines");
            glIsProgramPipeline = (GlIsProgramPipeline) getProcAddress("glIsProgramPipeline");
            glGetProgramPipelineiv = (GlGetProgramPipelineiv) getProcAddress("glGetProgramPipelineiv");
            glProgramUniform1i = (GlProgramUniform1i) getProcAddress("glProgramUniform1i");
            glProgramUniform1iv = (GlProgramUniform1iv) getProcAddress("glProgramUniform1iv");
            glProgramUniform1f = (GlProgramUniform1f) getProcAddress("glProgramUniform1f");
            glProgramUniform1fv = (GlProgramUniform1fv) getProcAddress("glProgramUniform1fv");
            glProgramUniform1d = (GlProgramUniform1d) getProcAddress("glProgramUniform1d");
            glProgramUniform1dv = (GlProgramUniform1dv) getProcAddress("glProgramUniform1dv");
            glProgramUniform1ui = (GlProgramUniform1ui) getProcAddress("glProgramUniform1ui");
            glProgramUniform1uiv = (GlProgramUniform1uiv) getProcAddress("glProgramUniform1uiv");
            glProgramUniform2i = (GlProgramUniform2i) getProcAddress("glProgramUniform2i");
            glProgramUniform2iv = (GlProgramUniform2iv) getProcAddress("glProgramUniform2iv");
            glProgramUniform2f = (GlProgramUniform2f) getProcAddress("glProgramUniform2f");
            glProgramUniform2fv = (GlProgramUniform2fv) getProcAddress("glProgramUniform2fv");
            glProgramUniform2d = (GlProgramUniform2d) getProcAddress("glProgramUniform2d");
            glProgramUniform2dv = (GlProgramUniform2dv) getProcAddress("glProgramUniform2dv");
            glProgramUniform2ui = (GlProgramUniform2ui) getProcAddress("glProgramUniform2ui");
            glProgramUniform2uiv = (GlProgramUniform2uiv) getProcAddress("glProgramUniform2uiv");
            glProgramUniform3i = (GlProgramUniform3i) getProcAddress("glProgramUniform3i");
            glProgramUniform3iv = (GlProgramUniform3iv) getProcAddress("glProgramUniform3iv");
            glProgramUniform3f = (GlProgramUniform3f) getProcAddress("glProgramUniform3f");
            glProgramUniform3fv = (GlProgramUniform3fv) getProcAddress("glProgramUniform3fv");
            glProgramUniform3d = (GlProgramUniform3d) getProcAddress("glProgramUniform3d");
            glProgramUniform3dv = (GlProgramUniform3dv) getProcAddress("glProgramUniform3dv");
            glProgramUniform3ui = (GlProgramUniform3ui) getProcAddress("glProgramUniform3ui");
            glProgramUniform3uiv = (GlProgramUniform3uiv) getProcAddress("glProgramUniform3uiv");
            glProgramUniform4i = (GlProgramUniform4i) getProcAddress("glProgramUniform4i");
            glProgramUniform4iv = (GlProgramUniform4iv) getProcAddress("glProgramUniform4iv");
            glProgramUniform4f = (GlProgramUniform4f) getProcAddress("glProgramUniform4f");
            glProgramUniform4fv = (GlProgramUniform4fv) getProcAddress("glProgramUniform4fv");
            glProgramUniform4d = (GlProgramUniform4d) getProcAddress("glProgramUniform4d");
            glProgramUniform4dv = (GlProgramUniform4dv) getProcAddress("glProgramUniform4dv");
            glProgramUniform4ui = (GlProgramUniform4ui) getProcAddress("glProgramUniform4ui");
            glProgramUniform4uiv = (GlProgramUniform4uiv) getProcAddress("glProgramUniform4uiv");
            glProgramUniformMatrix2fv = (GlProgramUniformMatrix2fv) getProcAddress("glProgramUniformMatrix2fv");
            glProgramUniformMatrix3fv = (GlProgramUniformMatrix3fv) getProcAddress("glProgramUniformMatrix3fv");
            glProgramUniformMatrix4fv = (GlProgramUniformMatrix4fv) getProcAddress("glProgramUniformMatrix4fv");
            glProgramUniformMatrix2dv = (GlProgramUniformMatrix2dv) getProcAddress("glProgramUniformMatrix2dv");
            glProgramUniformMatrix3dv = (GlProgramUniformMatrix3dv) getProcAddress("glProgramUniformMatrix3dv");
            glProgramUniformMatrix4dv = (GlProgramUniformMatrix4dv) getProcAddress("glProgramUniformMatrix4dv");
            glProgramUniformMatrix2x3fv = (GlProgramUniformMatrix2x3fv) getProcAddress("glProgramUniformMatrix2x3fv");
            glProgramUniformMatrix3x2fv = (GlProgramUniformMatrix3x2fv) getProcAddress("glProgramUniformMatrix3x2fv");
            glProgramUniformMatrix2x4fv = (GlProgramUniformMatrix2x4fv) getProcAddress("glProgramUniformMatrix2x4fv");
            glProgramUniformMatrix4x2fv = (GlProgramUniformMatrix4x2fv) getProcAddress("glProgramUniformMatrix4x2fv");
            glProgramUniformMatrix3x4fv = (GlProgramUniformMatrix3x4fv) getProcAddress("glProgramUniformMatrix3x4fv");
            glProgramUniformMatrix4x3fv = (GlProgramUniformMatrix4x3fv) getProcAddress("glProgramUniformMatrix4x3fv");
            glProgramUniformMatrix2x3dv = (GlProgramUniformMatrix2x3dv) getProcAddress("glProgramUniformMatrix2x3dv");
            glProgramUniformMatrix3x2dv = (GlProgramUniformMatrix3x2dv) getProcAddress("glProgramUniformMatrix3x2dv");
            glProgramUniformMatrix2x4dv = (GlProgramUniformMatrix2x4dv) getProcAddress("glProgramUniformMatrix2x4dv");
            glProgramUniformMatrix4x2dv = (GlProgramUniformMatrix4x2dv) getProcAddress("glProgramUniformMatrix4x2dv");
            glProgramUniformMatrix3x4dv = (GlProgramUniformMatrix3x4dv) getProcAddress("glProgramUniformMatrix3x4dv");
            glProgramUniformMatrix4x3dv = (GlProgramUniformMatrix4x3dv) getProcAddress("glProgramUniformMatrix4x3dv");
            glValidateProgramPipeline = (GlValidateProgramPipeline) getProcAddress("glValidateProgramPipeline");
            glGetProgramPipelineInfoLog = (GlGetProgramPipelineInfoLog) getProcAddress("glGetProgramPipelineInfoLog");
            glVertexAttribL1d = (GlVertexAttribL1d) getProcAddress("glVertexAttribL1d");
            glVertexAttribL2d = (GlVertexAttribL2d) getProcAddress("glVertexAttribL2d");
            glVertexAttribL3d = (GlVertexAttribL3d) getProcAddress("glVertexAttribL3d");
            glVertexAttribL4d = (GlVertexAttribL4d) getProcAddress("glVertexAttribL4d");
            glVertexAttribL1dv = (GlVertexAttribL1dv) getProcAddress("glVertexAttribL1dv");
            glVertexAttribL2dv = (GlVertexAttribL2dv) getProcAddress("glVertexAttribL2dv");
            glVertexAttribL3dv = (GlVertexAttribL3dv) getProcAddress("glVertexAttribL3dv");
            glVertexAttribL4dv = (GlVertexAttribL4dv) getProcAddress("glVertexAttribL4dv");
            glVertexAttribLPointer = (GlVertexAttribLPointer) getProcAddress("glVertexAttribLPointer");
            glGetVertexAttribLdv = (GlGetVertexAttribLdv) getProcAddress("glGetVertexAttribLdv");
            glViewportArrayv = (GlViewportArrayv) getProcAddress("glViewportArrayv");
            glViewportIndexedf = (GlViewportIndexedf) getProcAddress("glViewportIndexedf");
            glViewportIndexedfv = (GlViewportIndexedfv) getProcAddress("glViewportIndexedfv");
            glScissorArrayv = (GlScissorArrayv) getProcAddress("glScissorArrayv");
            glScissorIndexed = (GlScissorIndexed) getProcAddress("glScissorIndexed");
            glScissorIndexedv = (GlScissorIndexedv) getProcAddress("glScissorIndexedv");
            glDepthRangeArrayv = (GlDepthRangeArrayv) getProcAddress("glDepthRangeArrayv");
            glDepthRangeIndexed = (GlDepthRangeIndexed) getProcAddress("glDepthRangeIndexed");
            glGetFloati_v = (GlGetFloati_v) getProcAddress("glGetFloati_v");
            glGetDoublei_v = (GlGetDoublei_v) getProcAddress("glGetDoublei_v");
            glDrawArraysInstancedBaseInstance = (GlDrawArraysInstancedBaseInstance) getProcAddress("glDrawArraysInstancedBaseInstance");
            glDrawElementsInstancedBaseInstance = (GlDrawElementsInstancedBaseInstance) getProcAddress("glDrawElementsInstancedBaseInstance");
            glDrawElementsInstancedBaseVertexBaseInstance = (GlDrawElementsInstancedBaseVertexBaseInstance) getProcAddress("glDrawElementsInstancedBaseVertexBaseInstance");
            glGetInternalformativ = (GlGetInternalformativ) getProcAddress("glGetInternalformativ");
            glGetActiveAtomicCounterBufferiv = (GlGetActiveAtomicCounterBufferiv) getProcAddress("glGetActiveAtomicCounterBufferiv");
            glBindImageTexture = (GlBindImageTexture) getProcAddress("glBindImageTexture");
            glMemoryBarrier = (GlMemoryBarrier) getProcAddress("glMemoryBarrier");
            glTexStorage1D = (GlTexStorage1D) getProcAddress("glTexStorage1D");
            glTexStorage2D = (GlTexStorage2D) getProcAddress("glTexStorage2D");
            glTexStorage3D = (GlTexStorage3D) getProcAddress("glTexStorage3D");
            glDrawTransformFeedbackInstanced = (GlDrawTransformFeedbackInstanced) getProcAddress("glDrawTransformFeedbackInstanced");
            glDrawTransformFeedbackStreamInstanced = (GlDrawTransformFeedbackStreamInstanced) getProcAddress("glDrawTransformFeedbackStreamInstanced");
            glClearBufferData = (GlClearBufferData) getProcAddress("glClearBufferData");
            glClearBufferSubData = (GlClearBufferSubData) getProcAddress("glClearBufferSubData");
            glDispatchCompute = (GlDispatchCompute) getProcAddress("glDispatchCompute");
            glDispatchComputeIndirect = (GlDispatchComputeIndirect) getProcAddress("glDispatchComputeIndirect");
            glCopyImageSubData = (GlCopyImageSubData) getProcAddress("glCopyImageSubData");
            glFramebufferParameteri = (GlFramebufferParameteri) getProcAddress("glFramebufferParameteri");
            glGetFramebufferParameteriv = (GlGetFramebufferParameteriv) getProcAddress("glGetFramebufferParameteriv");
            glGetInternalformati64v = (GlGetInternalformati64v) getProcAddress("glGetInternalformati64v");
            glInvalidateTexSubImage = (GlInvalidateTexSubImage) getProcAddress("glInvalidateTexSubImage");
            glInvalidateTexImage = (GlInvalidateTexImage) getProcAddress("glInvalidateTexImage");
            glInvalidateBufferSubData = (GlInvalidateBufferSubData) getProcAddress("glInvalidateBufferSubData");
            glInvalidateBufferData = (GlInvalidateBufferData) getProcAddress("glInvalidateBufferData");
            glInvalidateFramebuffer = (GlInvalidateFramebuffer) getProcAddress("glInvalidateFramebuffer");
            glInvalidateSubFramebuffer = (GlInvalidateSubFramebuffer) getProcAddress("glInvalidateSubFramebuffer");
            glMultiDrawArraysIndirect = (GlMultiDrawArraysIndirect) getProcAddress("glMultiDrawArraysIndirect");
            glMultiDrawElementsIndirect = (GlMultiDrawElementsIndirect) getProcAddress("glMultiDrawElementsIndirect");
            glGetProgramInterfaceiv = (GlGetProgramInterfaceiv) getProcAddress("glGetProgramInterfaceiv");
            glGetProgramResourceIndex = (GlGetProgramResourceIndex) getProcAddress("glGetProgramResourceIndex");
            glGetProgramResourceName = (GlGetProgramResourceName) getProcAddress("glGetProgramResourceName");
            glGetProgramResourceiv = (GlGetProgramResourceiv) getProcAddress("glGetProgramResourceiv");
            glGetProgramResourceLocation = (GlGetProgramResourceLocation) getProcAddress("glGetProgramResourceLocation");
            glGetProgramResourceLocationIndex = (GlGetProgramResourceLocationIndex) getProcAddress("glGetProgramResourceLocationIndex");
            glShaderStorageBlockBinding = (GlShaderStorageBlockBinding) getProcAddress("glShaderStorageBlockBinding");
            glTexBufferRange = (GlTexBufferRange) getProcAddress("glTexBufferRange");
            glTexStorage2DMultisample = (GlTexStorage2DMultisample) getProcAddress("glTexStorage2DMultisample");
            glTexStorage3DMultisample = (GlTexStorage3DMultisample) getProcAddress("glTexStorage3DMultisample");
            glTextureView = (GlTextureView) getProcAddress("glTextureView");
            glBindVertexBuffer = (GlBindVertexBuffer) getProcAddress("glBindVertexBuffer");
            glVertexAttribFormat = (GlVertexAttribFormat) getProcAddress("glVertexAttribFormat");
            glVertexAttribIFormat = (GlVertexAttribIFormat) getProcAddress("glVertexAttribIFormat");
            glVertexAttribLFormat = (GlVertexAttribLFormat) getProcAddress("glVertexAttribLFormat");
            glVertexAttribBinding = (GlVertexAttribBinding) getProcAddress("glVertexAttribBinding");
            glVertexBindingDivisor = (GlVertexBindingDivisor) getProcAddress("glVertexBindingDivisor");
            glDebugMessageControl = (GlDebugMessageControl) getProcAddress("glDebugMessageControl");
            glDebugMessageInsert = (GlDebugMessageInsert) getProcAddress("glDebugMessageInsert");
            glDebugMessageCallback = (GlDebugMessageCallback) getProcAddress("glDebugMessageCallback");
            glGetDebugMessageLog = (GlGetDebugMessageLog) getProcAddress("glGetDebugMessageLog");
            glPushDebugGroup = (GlPushDebugGroup) getProcAddress("glPushDebugGroup");
            glPopDebugGroup = (GlPopDebugGroup) getProcAddress("glPopDebugGroup");
            glObjectLabel = (GlObjectLabel) getProcAddress("glObjectLabel");
            glGetObjectLabel = (GlGetObjectLabel) getProcAddress("glGetObjectLabel");
            glObjectPtrLabel = (GlObjectPtrLabel) getProcAddress("glObjectPtrLabel");
            glGetObjectPtrLabel = (GlGetObjectPtrLabel) getProcAddress("glGetObjectPtrLabel");
            glGetPointerv = (GlGetPointerv) getProcAddress("glGetPointerv");
            glBufferStorage = (GlBufferStorage) getProcAddress("glBufferStorage");
            glClearTexImage = (GlClearTexImage) getProcAddress("glClearTexImage");
            glClearTexSubImage = (GlClearTexSubImage) getProcAddress("glClearTexSubImage");
            glBindBuffersBase = (GlBindBuffersBase) getProcAddress("glBindBuffersBase");
            glBindBuffersRange = (GlBindBuffersRange) getProcAddress("glBindBuffersRange");
            glBindTextures = (GlBindTextures) getProcAddress("glBindTextures");
            glBindSamplers = (GlBindSamplers) getProcAddress("glBindSamplers");
            glBindImageTextures = (GlBindImageTextures) getProcAddress("glBindImageTextures");
            glBindVertexBuffers = (GlBindVertexBuffers) getProcAddress("glBindVertexBuffers");
            glClipControl = (GlClipControl) getProcAddress("glClipControl");
            glCreateTransformFeedbacks = (GlCreateTransformFeedbacks) getProcAddress("glCreateTransformFeedbacks");
            glTransformFeedbackBufferBase = (GlTransformFeedbackBufferBase) getProcAddress("glTransformFeedbackBufferBase");
            glTransformFeedbackBufferRange = (GlTransformFeedbackBufferRange) getProcAddress("glTransformFeedbackBufferRange");
            glGetTransformFeedbackiv = (GlGetTransformFeedbackiv) getProcAddress("glGetTransformFeedbackiv");
            glGetTransformFeedbacki_v = (GlGetTransformFeedbacki_v) getProcAddress("glGetTransformFeedbacki_v");
            glGetTransformFeedbacki64_v = (GlGetTransformFeedbacki64_v) getProcAddress("glGetTransformFeedbacki64_v");
            glCreateBuffers = (GlCreateBuffers) getProcAddress("glCreateBuffers");
            glNamedBufferStorage = (GlNamedBufferStorage) getProcAddress("glNamedBufferStorage");
            glNamedBufferData = (GlNamedBufferData) getProcAddress("glNamedBufferData");
            glNamedBufferSubData = (GlNamedBufferSubData) getProcAddress("glNamedBufferSubData");
            glCopyNamedBufferSubData = (GlCopyNamedBufferSubData) getProcAddress("glCopyNamedBufferSubData");
            glClearNamedBufferData = (GlClearNamedBufferData) getProcAddress("glClearNamedBufferData");
            glClearNamedBufferSubData = (GlClearNamedBufferSubData) getProcAddress("glClearNamedBufferSubData");
            glMapNamedBuffer = (GlMapNamedBuffer) getProcAddress("glMapNamedBuffer");
            glMapNamedBufferRange = (GlMapNamedBufferRange) getProcAddress("glMapNamedBufferRange");
            glUnmapNamedBuffer = (GlUnmapNamedBuffer) getProcAddress("glUnmapNamedBuffer");
            glFlushMappedNamedBufferRange = (GlFlushMappedNamedBufferRange) getProcAddress("glFlushMappedNamedBufferRange");
            glGetNamedBufferParameteriv = (GlGetNamedBufferParameteriv) getProcAddress("glGetNamedBufferParameteriv");
            glGetNamedBufferParameteri64v = (GlGetNamedBufferParameteri64v) getProcAddress("glGetNamedBufferParameteri64v");
            glGetNamedBufferPointerv = (GlGetNamedBufferPointerv) getProcAddress("glGetNamedBufferPointerv");
            glGetNamedBufferSubData = (GlGetNamedBufferSubData) getProcAddress("glGetNamedBufferSubData");
            glCreateFramebuffers = (GlCreateFramebuffers) getProcAddress("glCreateFramebuffers");
            glNamedFramebufferRenderbuffer = (GlNamedFramebufferRenderbuffer) getProcAddress("glNamedFramebufferRenderbuffer");
            glNamedFramebufferParameteri = (GlNamedFramebufferParameteri) getProcAddress("glNamedFramebufferParameteri");
            glNamedFramebufferTexture = (GlNamedFramebufferTexture) getProcAddress("glNamedFramebufferTexture");
            glNamedFramebufferTextureLayer = (GlNamedFramebufferTextureLayer) getProcAddress("glNamedFramebufferTextureLayer");
            glNamedFramebufferDrawBuffer = (GlNamedFramebufferDrawBuffer) getProcAddress("glNamedFramebufferDrawBuffer");
            glNamedFramebufferDrawBuffers = (GlNamedFramebufferDrawBuffers) getProcAddress("glNamedFramebufferDrawBuffers");
            glNamedFramebufferReadBuffer = (GlNamedFramebufferReadBuffer) getProcAddress("glNamedFramebufferReadBuffer");
            glInvalidateNamedFramebufferData = (GlInvalidateNamedFramebufferData) getProcAddress("glInvalidateNamedFramebufferData");
            glInvalidateNamedFramebufferSubData = (GlInvalidateNamedFramebufferSubData) getProcAddress("glInvalidateNamedFramebufferSubData");
            glClearNamedFramebufferiv = (GlClearNamedFramebufferiv) getProcAddress("glClearNamedFramebufferiv");
            glClearNamedFramebufferuiv = (GlClearNamedFramebufferuiv) getProcAddress("glClearNamedFramebufferuiv");
            glClearNamedFramebufferfv = (GlClearNamedFramebufferfv) getProcAddress("glClearNamedFramebufferfv");
            glClearNamedFramebufferfi = (GlClearNamedFramebufferfi) getProcAddress("glClearNamedFramebufferfi");
            glBlitNamedFramebuffer = (GlBlitNamedFramebuffer) getProcAddress("glBlitNamedFramebuffer");
            glCheckNamedFramebufferStatus = (GlCheckNamedFramebufferStatus) getProcAddress("glCheckNamedFramebufferStatus");
            glGetNamedFramebufferParameteriv = (GlGetNamedFramebufferParameteriv) getProcAddress("glGetNamedFramebufferParameteriv");
            glGetNamedFramebufferAttachmentParameteriv = (GlGetNamedFramebufferAttachmentParameteriv) getProcAddress("glGetNamedFramebufferAttachmentParameteriv");
            glCreateRenderbuffers = (GlCreateRenderbuffers) getProcAddress("glCreateRenderbuffers");
            glNamedRenderbufferStorage = (GlNamedRenderbufferStorage) getProcAddress("glNamedRenderbufferStorage");
            glNamedRenderbufferStorageMultisample = (GlNamedRenderbufferStorageMultisample) getProcAddress("glNamedRenderbufferStorageMultisample");
            glGetNamedRenderbufferParameteriv = (GlGetNamedRenderbufferParameteriv) getProcAddress("glGetNamedRenderbufferParameteriv");
            glCreateTextures = (GlCreateTextures) getProcAddress("glCreateTextures");
            glTextureBuffer = (GlTextureBuffer) getProcAddress("glTextureBuffer");
            glTextureBufferRange = (GlTextureBufferRange) getProcAddress("glTextureBufferRange");
            glTextureStorage1D = (GlTextureStorage1D) getProcAddress("glTextureStorage1D");
            glTextureStorage2D = (GlTextureStorage2D) getProcAddress("glTextureStorage2D");
            glTextureStorage3D = (GlTextureStorage3D) getProcAddress("glTextureStorage3D");
            glTextureStorage2DMultisample = (GlTextureStorage2DMultisample) getProcAddress("glTextureStorage2DMultisample");
            glTextureStorage3DMultisample = (GlTextureStorage3DMultisample) getProcAddress("glTextureStorage3DMultisample");
            glTextureSubImage1D = (GlTextureSubImage1D) getProcAddress("glTextureSubImage1D");
            glTextureSubImage2D = (GlTextureSubImage2D) getProcAddress("glTextureSubImage2D");
            glTextureSubImage3D = (GlTextureSubImage3D) getProcAddress("glTextureSubImage3D");
            glCompressedTextureSubImage1D = (GlCompressedTextureSubImage1D) getProcAddress("glCompressedTextureSubImage1D");
            glCompressedTextureSubImage2D = (GlCompressedTextureSubImage2D) getProcAddress("glCompressedTextureSubImage2D");
            glCompressedTextureSubImage3D = (GlCompressedTextureSubImage3D) getProcAddress("glCompressedTextureSubImage3D");
            glCopyTextureSubImage1D = (GlCopyTextureSubImage1D) getProcAddress("glCopyTextureSubImage1D");
            glCopyTextureSubImage2D = (GlCopyTextureSubImage2D) getProcAddress("glCopyTextureSubImage2D");
            glCopyTextureSubImage3D = (GlCopyTextureSubImage3D) getProcAddress("glCopyTextureSubImage3D");
            glTextureParameterf = (GlTextureParameterf) getProcAddress("glTextureParameterf");
            glTextureParameterfv = (GlTextureParameterfv) getProcAddress("glTextureParameterfv");
            glTextureParameteri = (GlTextureParameteri) getProcAddress("glTextureParameteri");
            glTextureParameterIiv = (GlTextureParameterIiv) getProcAddress("glTextureParameterIiv");
            glTextureParameterIuiv = (GlTextureParameterIuiv) getProcAddress("glTextureParameterIuiv");
            glTextureParameteriv = (GlTextureParameteriv) getProcAddress("glTextureParameteriv");
            glGenerateTextureMipmap = (GlGenerateTextureMipmap) getProcAddress("glGenerateTextureMipmap");
            glBindTextureUnit = (GlBindTextureUnit) getProcAddress("glBindTextureUnit");
            glGetTextureImage = (GlGetTextureImage) getProcAddress("glGetTextureImage");
            glGetCompressedTextureImage = (GlGetCompressedTextureImage) getProcAddress("glGetCompressedTextureImage");
            glGetTextureLevelParameterfv = (GlGetTextureLevelParameterfv) getProcAddress("glGetTextureLevelParameterfv");
            glGetTextureLevelParameteriv = (GlGetTextureLevelParameteriv) getProcAddress("glGetTextureLevelParameteriv");
            glGetTextureParameterfv = (GlGetTextureParameterfv) getProcAddress("glGetTextureParameterfv");
            glGetTextureParameterIiv = (GlGetTextureParameterIiv) getProcAddress("glGetTextureParameterIiv");
            glGetTextureParameterIuiv = (GlGetTextureParameterIuiv) getProcAddress("glGetTextureParameterIuiv");
            glGetTextureParameteriv = (GlGetTextureParameteriv) getProcAddress("glGetTextureParameteriv");
            glCreateVertexArrays = (GlCreateVertexArrays) getProcAddress("glCreateVertexArrays");
            glDisableVertexArrayAttrib = (GlDisableVertexArrayAttrib) getProcAddress("glDisableVertexArrayAttrib");
            glEnableVertexArrayAttrib = (GlEnableVertexArrayAttrib) getProcAddress("glEnableVertexArrayAttrib");
            glVertexArrayElementBuffer = (GlVertexArrayElementBuffer) getProcAddress("glVertexArrayElementBuffer");
            glVertexArrayVertexBuffer = (GlVertexArrayVertexBuffer) getProcAddress("glVertexArrayVertexBuffer");
            glVertexArrayVertexBuffers = (GlVertexArrayVertexBuffers) getProcAddress("glVertexArrayVertexBuffers");
            glVertexArrayAttribBinding = (GlVertexArrayAttribBinding) getProcAddress("glVertexArrayAttribBinding");
            glVertexArrayAttribFormat = (GlVertexArrayAttribFormat) getProcAddress("glVertexArrayAttribFormat");
            glVertexArrayAttribIFormat = (GlVertexArrayAttribIFormat) getProcAddress("glVertexArrayAttribIFormat");
            glVertexArrayAttribLFormat = (GlVertexArrayAttribLFormat) getProcAddress("glVertexArrayAttribLFormat");
            glVertexArrayBindingDivisor = (GlVertexArrayBindingDivisor) getProcAddress("glVertexArrayBindingDivisor");
            glGetVertexArrayiv = (GlGetVertexArrayiv) getProcAddress("glGetVertexArrayiv");
            glGetVertexArrayIndexediv = (GlGetVertexArrayIndexediv) getProcAddress("glGetVertexArrayIndexediv");
            glGetVertexArrayIndexed64iv = (GlGetVertexArrayIndexed64iv) getProcAddress("glGetVertexArrayIndexed64iv");
            glCreateSamplers = (GlCreateSamplers) getProcAddress("glCreateSamplers");
            glCreateProgramPipelines = (GlCreateProgramPipelines) getProcAddress("glCreateProgramPipelines");
            glCreateQueries = (GlCreateQueries) getProcAddress("glCreateQueries");
            glGetQueryBufferObjecti64v = (GlGetQueryBufferObjecti64v) getProcAddress("glGetQueryBufferObjecti64v");
            glGetQueryBufferObjectiv = (GlGetQueryBufferObjectiv) getProcAddress("glGetQueryBufferObjectiv");
            glGetQueryBufferObjectui64v = (GlGetQueryBufferObjectui64v) getProcAddress("glGetQueryBufferObjectui64v");
            glGetQueryBufferObjectuiv = (GlGetQueryBufferObjectuiv) getProcAddress("glGetQueryBufferObjectuiv");
            glMemoryBarrierByRegion = (GlMemoryBarrierByRegion) getProcAddress("glMemoryBarrierByRegion");
            glGetTextureSubImage = (GlGetTextureSubImage) getProcAddress("glGetTextureSubImage");
            glGetCompressedTextureSubImage = (GlGetCompressedTextureSubImage) getProcAddress("glGetCompressedTextureSubImage");
            glGetGraphicsResetStatus = (GlGetGraphicsResetStatus) getProcAddress("glGetGraphicsResetStatus");
            glGetnCompressedTexImage = (GlGetnCompressedTexImage) getProcAddress("glGetnCompressedTexImage");
            glGetnTexImage = (GlGetnTexImage) getProcAddress("glGetnTexImage");
            glGetnUniformdv = (GlGetnUniformdv) getProcAddress("glGetnUniformdv");
            glGetnUniformfv = (GlGetnUniformfv) getProcAddress("glGetnUniformfv");
            glGetnUniformiv = (GlGetnUniformiv) getProcAddress("glGetnUniformiv");
            glGetnUniformuiv = (GlGetnUniformuiv) getProcAddress("glGetnUniformuiv");
            glReadnPixels = (GlReadnPixels) getProcAddress("glReadnPixels");
            glTextureBarrier = (GlTextureBarrier) getProcAddress("glTextureBarrier");
            glSpecializeShader = (GlSpecializeShader) getProcAddress("glSpecializeShader");
            glMultiDrawArraysIndirectCount = (GlMultiDrawArraysIndirectCount) getProcAddress("glMultiDrawArraysIndirectCount");
            glMultiDrawElementsIndirectCount = (GlMultiDrawElementsIndirectCount) getProcAddress("glMultiDrawElementsIndirectCount");
            glPolygonOffsetClamp = (GlPolygonOffsetClamp) getProcAddress("glPolygonOffsetClamp");
        }
    }
}
