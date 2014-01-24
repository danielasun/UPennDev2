/*
 * DXLPRO54.h
 *
 *  Created on: 2013. 1. 14.
 *      Author: hjsong
 */

#ifndef PRO54_H_
#define PRO54_H_

#include "dxl_info.h"

namespace Thor
{

class PRO54 :public DXLInfo
{

public:
	const double MIN_ANGLE;
	const double MAX_ANGLE;
	const double MIN_RAD;
	const double MAX_RAD;
	const int CENTER_VALUE;

	enum
	{
		P_MODEL_NUMBER_L						=	0,
		P_MODEL_NUMBER_H						=	1,
		P_MODEL_INFORMATION_LL					=	2,
		P_MODEL_INFORMATION_LH					=	3,
		P_MODEL_INFORMATION_HL					=	4,
		P_MODEL_INFORMATION_HH					=	5,
		P_VERSION_OF_FIRMWARE					=	6,
		P_ID									=	7,
		P_BAUD_RATE								=	8,
		P_RETURN_DELAY_TIME						=	9,
		P_INVERTER_MODE							=	10,
		P_OPERATING_MODE						=	11,
		P_DIRECTION_SETTING						=	12,
		P_HOMING_OFFSET_LL						=	13,
		P_HOMING_OFFSET_LH						=	14,
		P_HOMING_OFFSET_HL						=	15,
		P_HOMING_OFFSET_HH						=	16,
		P_MOVING_THRESHOLD_LL					=	17,
		P_MOVING_THRESHOLD_LH					=	18,
		P_MOVING_THRESHOLD_HL					=	19,
		P_MOVING_THRESHOLD_HH					=	20,
		P_TEMPERATURE_LIMIT						=	21,
		P_MAX_VOLTAGE_LIMIT_L					=	22,
		P_MAX_VOLTAGE_LIMIT_H					=	23,
		P_MIN_VOLTAGE_LIMIT_L					=	24,
		P_MIN_VOLTAGE_LIMIT_H					=	25,
		P_ACCELATION_LIMIT_LL					=	26,
		P_ACCELATION_LIMIT_LH					=	27,
		P_ACCELATION_LIMIT_HL					=	28,
		P_ACCELATION_LIMIT_HH					=	29,
		P_TORQUE_LIMIT_L						=	30,
		P_TORQUE_LIMIT_H						=	31,
		P_VELOCITY_LIMIT_LL						=	32,
		P_VELOCITY_LIMIT_LH						=	33,
		P_VELOCITY_LIMIT_HL						=	34,
		P_VELOCITY_LIMIT_HH						=	35,
		P_PLUS_POSITION_LIMIT_LL				=	36,
		P_PLUS_POSITION_LIMIT_LH				=	37,
		P_PLUS_POSITION_LIMIT_HL				=	38,
		P_PLUS_POSITION_LIMIT_HH				=	39,
		P_MINUS_POSITION_LIMIT_LL				=	40,
		P_MINUS_POSITION_LIMIT_LH				=	41,
		P_MINUS_POSITION_LIMIT_HL				=	42,
		P_MINUS_POSITION_LIMIT_HH				=	43,
		P_EXTERNAL_PORT_MODE_1					=	44,
		P_EXTERNAL_PORT_MODE_2					=	45,
		P_EXTERNAL_PORT_MODE_3					=	46,
		P_EXTERNAL_PORT_MODE_4					=	47,
		P_SHUTDOWN								=	48,
		P_INDIRECT_ADDRESS_0_L					=	49,
		P_INDIRECT_ADDRESS_0_H					=	50,
		P_INDIRECT_ADDRESS_1_L					=	51,
		P_INDIRECT_ADDRESS_1_H					=	52,
		P_INDIRECT_ADDRESS_2_L					=	53,
		P_INDIRECT_ADDRESS_2_H					=	54,
		P_INDIRECT_ADDRESS_3_L					=	55,
		P_INDIRECT_ADDRESS_3_H					=	56,
		P_INDIRECT_ADDRESS_4_L					=	57,
		P_INDIRECT_ADDRESS_4_H					=	58,
		P_INDIRECT_ADDRESS_5_L					=	59,
		P_INDIRECT_ADDRESS_5_H					=	60,
		P_INDIRECT_ADDRESS_6_L					=	61,
		P_INDIRECT_ADDRESS_6_H					=	62,
		P_INDIRECT_ADDRESS_7_L					=	63,
		P_INDIRECT_ADDRESS_7_H					=	64,
		P_INDIRECT_ADDRESS_8_L					=	65,
		P_INDIRECT_ADDRESS_8_H					=	66,
		P_INDIRECT_ADDRESS_9_L					=	67,
		P_INDIRECT_ADDRESS_9_H					=	68,
		P_INDIRECT_ADDRESS_10_L					=	69,
		P_INDIRECT_ADDRESS_10_H					=	70,
		P_INDIRECT_ADDRESS_11_L					=	71,
		P_INDIRECT_ADDRESS_11_H					=	72,
		P_INDIRECT_ADDRESS_12_L					=	73,
		P_INDIRECT_ADDRESS_12_H					=	74,
		P_INDIRECT_ADDRESS_13_L					=	75,
		P_INDIRECT_ADDRESS_13_H					=	76,
		P_INDIRECT_ADDRESS_14_L					=	77,
		P_INDIRECT_ADDRESS_14_H					=	78,
		P_INDIRECT_ADDRESS_15_L					=	79,
		P_INDIRECT_ADDRESS_15_H					=	80,
		P_INDIRECT_ADDRESS_16_L					=	81,
		P_INDIRECT_ADDRESS_16_H					=	82,
		P_INDIRECT_ADDRESS_17_L					=	83,
		P_INDIRECT_ADDRESS_17_H					=	84,
		P_INDIRECT_ADDRESS_18_L					=	85,
		P_INDIRECT_ADDRESS_18_H					=	86,
		P_INDIRECT_ADDRESS_19_L					=	87,
		P_INDIRECT_ADDRESS_19_H					=	88,
		P_INDIRECT_ADDRESS_20_L					=	89,
		P_INDIRECT_ADDRESS_20_H					=	90,
		P_INDIRECT_ADDRESS_21_L					=	91,
		P_INDIRECT_ADDRESS_21_H					=	92,
		P_INDIRECT_ADDRESS_22_L					=	93,
		P_INDIRECT_ADDRESS_22_H					=	94,
		P_INDIRECT_ADDRESS_23_L					=	95,
		P_INDIRECT_ADDRESS_23_H					=	96,
		P_INDIRECT_ADDRESS_24_L					=	97,
		P_INDIRECT_ADDRESS_24_H					=	98,
		P_INDIRECT_ADDRESS_25_L					=	99,
		P_INDIRECT_ADDRESS_25_H					=	100,
		P_INDIRECT_ADDRESS_26_L					=	101,
		P_INDIRECT_ADDRESS_26_H					=	102,
		P_INDIRECT_ADDRESS_27_L					=	103,
		P_INDIRECT_ADDRESS_27_H					=	104,
		P_INDIRECT_ADDRESS_28_L					=	105,
		P_INDIRECT_ADDRESS_28_H					=	106,
		P_INDIRECT_ADDRESS_29_L					=	107,
		P_INDIRECT_ADDRESS_29_H					=	108,
		P_INDIRECT_ADDRESS_30_L					=	109,
		P_INDIRECT_ADDRESS_30_H					=	110,
		P_INDIRECT_ADDRESS_31_L					=	111,
		P_INDIRECT_ADDRESS_31_H					=	112,
		P_INDIRECT_ADDRESS_32_L					=	113,
		P_INDIRECT_ADDRESS_32_H					=	114,
		P_INDIRECT_ADDRESS_33_L					=	115,
		P_INDIRECT_ADDRESS_33_H					=	116,
		P_INDIRECT_ADDRESS_34_L					=	117,
		P_INDIRECT_ADDRESS_34_H					=	118,
		P_INDIRECT_ADDRESS_35_L					=	119,
		P_INDIRECT_ADDRESS_35_H					=	120,
		P_INDIRECT_ADDRESS_36_L					=	121,
		P_INDIRECT_ADDRESS_36_H					=	122,
		P_INDIRECT_ADDRESS_37_L					=	123,
		P_INDIRECT_ADDRESS_37_H					=	124,
		P_INDIRECT_ADDRESS_38_L					=	125,
		P_INDIRECT_ADDRESS_38_H					=	126,
		P_INDIRECT_ADDRESS_39_L					=	127,
		P_INDIRECT_ADDRESS_39_H					=	128,
		P_INDIRECT_ADDRESS_40_L					=	129,
		P_INDIRECT_ADDRESS_40_H					=	130,
		P_INDIRECT_ADDRESS_41_L					=	131,
		P_INDIRECT_ADDRESS_41_H					=	132,
		P_INDIRECT_ADDRESS_42_L					=	133,
		P_INDIRECT_ADDRESS_42_H					=	134,
		P_INDIRECT_ADDRESS_43_L					=	135,
		P_INDIRECT_ADDRESS_43_H					=	136,
		P_INDIRECT_ADDRESS_44_L					=	137,
		P_INDIRECT_ADDRESS_44_H					=	138,
		P_INDIRECT_ADDRESS_45_L					=	139,
		P_INDIRECT_ADDRESS_45_H					=	140,
		P_INDIRECT_ADDRESS_46_L					=	141,
		P_INDIRECT_ADDRESS_46_H					=	142,
		P_INDIRECT_ADDRESS_47_L					=	143,
		P_INDIRECT_ADDRESS_47_H					=	144,
		P_INDIRECT_ADDRESS_48_L					=	145,
		P_INDIRECT_ADDRESS_48_H					=	146,
		P_INDIRECT_ADDRESS_49_L					=	147,
		P_INDIRECT_ADDRESS_49_H					=	148,
		P_INDIRECT_ADDRESS_50_L					=	149,
		P_INDIRECT_ADDRESS_50_H					=	150,
		P_INDIRECT_ADDRESS_51_L					=	151,
		P_INDIRECT_ADDRESS_51_H					=	152,
		P_INDIRECT_ADDRESS_52_L					=	153,
		P_INDIRECT_ADDRESS_52_H					=	154,
		P_INDIRECT_ADDRESS_53_L					=	155,
		P_INDIRECT_ADDRESS_53_H					=	156,
		P_INDIRECT_ADDRESS_54_L					=	157,
		P_INDIRECT_ADDRESS_54_H					=	158,
		P_INDIRECT_ADDRESS_55_L					=	159,
		P_INDIRECT_ADDRESS_55_H					=	160,
		P_INDIRECT_ADDRESS_56_L					=	161,
		P_INDIRECT_ADDRESS_56_H					=	162,
		P_INDIRECT_ADDRESS_57_L					=	163,
		P_INDIRECT_ADDRESS_57_H					=	164,
		P_INDIRECT_ADDRESS_58_L					=	165,
		P_INDIRECT_ADDRESS_58_H					=	166,
		P_INDIRECT_ADDRESS_59_L					=	167,
		P_INDIRECT_ADDRESS_59_H					=	168,
		P_INDIRECT_ADDRESS_60_L					=	169,
		P_INDIRECT_ADDRESS_60_H					=	170,
		P_INDIRECT_ADDRESS_61_L					=	171,
		P_INDIRECT_ADDRESS_61_H					=	172,
		P_INDIRECT_ADDRESS_62_L					=	173,
		P_INDIRECT_ADDRESS_62_H					=	174,
		P_INDIRECT_ADDRESS_63_L					=	175,
		P_INDIRECT_ADDRESS_63_H					=	176,
		P_INDIRECT_ADDRESS_64_L					=	177,
		P_INDIRECT_ADDRESS_64_H					=	178,
		P_INDIRECT_ADDRESS_65_L					=	179,
		P_INDIRECT_ADDRESS_65_H					=	180,
		P_INDIRECT_ADDRESS_66_L					=	181,
		P_INDIRECT_ADDRESS_66_H					=	182,
		P_INDIRECT_ADDRESS_67_L					=	183,
		P_INDIRECT_ADDRESS_67_H					=	184,
		P_INDIRECT_ADDRESS_68_L					=	185,
		P_INDIRECT_ADDRESS_68_H					=	186,
		P_INDIRECT_ADDRESS_69_L					=	187,
		P_INDIRECT_ADDRESS_69_H					=	188,
		P_INDIRECT_ADDRESS_70_L					=	189,
		P_INDIRECT_ADDRESS_70_H					=	190,
		P_INDIRECT_ADDRESS_71_L					=	191,
		P_INDIRECT_ADDRESS_71_H					=	192,
		P_INDIRECT_ADDRESS_72_L					=	193,
		P_INDIRECT_ADDRESS_72_H					=	194,
		P_INDIRECT_ADDRESS_73_L					=	195,
		P_INDIRECT_ADDRESS_73_H					=	196,
		P_INDIRECT_ADDRESS_74_L					=	197,
		P_INDIRECT_ADDRESS_74_H					=	198,
		P_INDIRECT_ADDRESS_75_L					=	199,
		P_INDIRECT_ADDRESS_75_H					=	200,
		P_INDIRECT_ADDRESS_76_L					=	201,
		P_INDIRECT_ADDRESS_76_H					=	202,
		P_INDIRECT_ADDRESS_77_L					=	203,
		P_INDIRECT_ADDRESS_77_H					=	204,
		P_INDIRECT_ADDRESS_78_L					=	205,
		P_INDIRECT_ADDRESS_78_H					=	206,
		P_INDIRECT_ADDRESS_79_L					=	207,
		P_INDIRECT_ADDRESS_79_H					=	208,
		P_INDIRECT_ADDRESS_80_L					=	209,
		P_INDIRECT_ADDRESS_80_H					=	210,
		P_INDIRECT_ADDRESS_81_L					=	211,
		P_INDIRECT_ADDRESS_81_H					=	212,
		P_INDIRECT_ADDRESS_82_L					=	213,
		P_INDIRECT_ADDRESS_82_H					=	214,
		P_INDIRECT_ADDRESS_83_L					=	215,
		P_INDIRECT_ADDRESS_83_H					=	216,
		P_INDIRECT_ADDRESS_84_L					=	217,
		P_INDIRECT_ADDRESS_84_H					=	218,
		P_INDIRECT_ADDRESS_85_L					=	219,
		P_INDIRECT_ADDRESS_85_H					=	220,
		P_INDIRECT_ADDRESS_86_L					=	221,
		P_INDIRECT_ADDRESS_86_H					=	222,
		P_INDIRECT_ADDRESS_87_L					=	223,
		P_INDIRECT_ADDRESS_87_H					=	224,
		P_INDIRECT_ADDRESS_88_L					=	225,
		P_INDIRECT_ADDRESS_88_H					=	226,
		P_INDIRECT_ADDRESS_89_L					=	227,
		P_INDIRECT_ADDRESS_89_H					=	228,
		P_INDIRECT_ADDRESS_90_L					=	229,
		P_INDIRECT_ADDRESS_90_H					=	230,
		P_INDIRECT_ADDRESS_91_L					=	231,
		P_INDIRECT_ADDRESS_91_H					=	232,
		P_INDIRECT_ADDRESS_92_L					=	233,
		P_INDIRECT_ADDRESS_92_H					=	234,
		P_INDIRECT_ADDRESS_93_L					=	235,
		P_INDIRECT_ADDRESS_93_H					=	236,
		P_INDIRECT_ADDRESS_94_L					=	237,
		P_INDIRECT_ADDRESS_94_H					=	238,
		P_INDIRECT_ADDRESS_95_L					=	239,
		P_INDIRECT_ADDRESS_95_H					=	240,
		P_INDIRECT_ADDRESS_96_L					=	241,
		P_INDIRECT_ADDRESS_96_H					=	242,
		P_INDIRECT_ADDRESS_97_L					=	243,
		P_INDIRECT_ADDRESS_97_H					=	244,
		P_INDIRECT_ADDRESS_98_L					=	245,
		P_INDIRECT_ADDRESS_98_H					=	246,
		P_INDIRECT_ADDRESS_99_L					=	247,
		P_INDIRECT_ADDRESS_99_H					=	248,
		P_INDIRECT_ADDRESS_100_L				=	249,
		P_INDIRECT_ADDRESS_100_H				=	250,
		P_INDIRECT_ADDRESS_101_L				=	251,
		P_INDIRECT_ADDRESS_101_H				=	252,
		P_INDIRECT_ADDRESS_102_L				=	253,
		P_INDIRECT_ADDRESS_102_H				=	254,
		P_INDIRECT_ADDRESS_103_L				=	255,
		P_INDIRECT_ADDRESS_103_H				=	256,
		P_INDIRECT_ADDRESS_104_L				=	257,
		P_INDIRECT_ADDRESS_104_H				=	258,
		P_INDIRECT_ADDRESS_105_L				=	259,
		P_INDIRECT_ADDRESS_105_H				=	260,
		P_INDIRECT_ADDRESS_106_L				=	261,
		P_INDIRECT_ADDRESS_106_H				=	262,
		P_INDIRECT_ADDRESS_107_L				=	263,
		P_INDIRECT_ADDRESS_107_H				=	264,
		P_INDIRECT_ADDRESS_108_L				=	265,
		P_INDIRECT_ADDRESS_108_H				=	266,
		P_INDIRECT_ADDRESS_109_L				=	267,
		P_INDIRECT_ADDRESS_109_H				=	268,
		P_INDIRECT_ADDRESS_110_L				=	269,
		P_INDIRECT_ADDRESS_110_H				=	270,
		P_INDIRECT_ADDRESS_111_L				=	271,
		P_INDIRECT_ADDRESS_111_H				=	272,
		P_INDIRECT_ADDRESS_112_L				=	273,
		P_INDIRECT_ADDRESS_112_H				=	274,
		P_INDIRECT_ADDRESS_113_L				=	275,
		P_INDIRECT_ADDRESS_113_H				=	276,
		P_INDIRECT_ADDRESS_114_L				=	277,
		P_INDIRECT_ADDRESS_114_H				=	278,
		P_INDIRECT_ADDRESS_115_L				=	279,
		P_INDIRECT_ADDRESS_115_H				=	280,
		P_INDIRECT_ADDRESS_116_L				=	281,
		P_INDIRECT_ADDRESS_116_H				=	282,
		P_INDIRECT_ADDRESS_117_L				=	283,
		P_INDIRECT_ADDRESS_117_H				=	284,
		P_INDIRECT_ADDRESS_118_L				=	285,
		P_INDIRECT_ADDRESS_118_H				=	286,
		P_INDIRECT_ADDRESS_119_L				=	287,
		P_INDIRECT_ADDRESS_119_H				=	288,
		P_INDIRECT_ADDRESS_120_L				=	289,
		P_INDIRECT_ADDRESS_120_H				=	290,
		P_INDIRECT_ADDRESS_121_L				=	291,
		P_INDIRECT_ADDRESS_121_H				=	292,
		P_INDIRECT_ADDRESS_122_L				=	293,
		P_INDIRECT_ADDRESS_122_H				=	294,
		P_INDIRECT_ADDRESS_123_L				=	295,
		P_INDIRECT_ADDRESS_123_H				=	296,
		P_INDIRECT_ADDRESS_124_L				=	297,
		P_INDIRECT_ADDRESS_124_H				=	298,
		P_INDIRECT_ADDRESS_125_L				=	299,
		P_INDIRECT_ADDRESS_125_H				=	300,
		P_INDIRECT_ADDRESS_126_L				=	301,
		P_INDIRECT_ADDRESS_126_H				=	302,
		P_INDIRECT_ADDRESS_127_L				=	303,
		P_INDIRECT_ADDRESS_127_H				=	304,
		P_INDIRECT_ADDRESS_128_L				=	305,
		P_INDIRECT_ADDRESS_128_H				=	306,
		P_INDIRECT_ADDRESS_129_L				=	307,
		P_INDIRECT_ADDRESS_129_H				=	308,
		P_INDIRECT_ADDRESS_130_L				=	309,
		P_INDIRECT_ADDRESS_130_H				=	310,
		P_INDIRECT_ADDRESS_131_L				=	311,
		P_INDIRECT_ADDRESS_131_H				=	312,
		P_INDIRECT_ADDRESS_132_L				=	313,
		P_INDIRECT_ADDRESS_132_H				=	314,
		P_INDIRECT_ADDRESS_133_L				=	315,
		P_INDIRECT_ADDRESS_133_H				=	316,
		P_INDIRECT_ADDRESS_134_L				=	317,
		P_INDIRECT_ADDRESS_134_H				=	318,
		P_INDIRECT_ADDRESS_135_L				=	319,
		P_INDIRECT_ADDRESS_135_H				=	320,
		P_INDIRECT_ADDRESS_136_L				=	321,
		P_INDIRECT_ADDRESS_136_H				=	322,
		P_INDIRECT_ADDRESS_137_L				=	323,
		P_INDIRECT_ADDRESS_137_H				=	324,
		P_INDIRECT_ADDRESS_138_L				=	325,
		P_INDIRECT_ADDRESS_138_H				=	326,
		P_INDIRECT_ADDRESS_139_L				=	327,
		P_INDIRECT_ADDRESS_139_H				=	328,
		P_INDIRECT_ADDRESS_140_L				=	329,
		P_INDIRECT_ADDRESS_140_H				=	330,
		P_INDIRECT_ADDRESS_141_L				=	331,
		P_INDIRECT_ADDRESS_141_H				=	332,
		P_INDIRECT_ADDRESS_142_L				=	333,
		P_INDIRECT_ADDRESS_142_H				=	334,
		P_INDIRECT_ADDRESS_143_L				=	335,
		P_INDIRECT_ADDRESS_143_H				=	336,
		P_INDIRECT_ADDRESS_144_L				=	337,
		P_INDIRECT_ADDRESS_144_H				=	338,
		P_INDIRECT_ADDRESS_145_L				=	339,
		P_INDIRECT_ADDRESS_145_H				=	340,
		P_INDIRECT_ADDRESS_146_L				=	341,
		P_INDIRECT_ADDRESS_146_H				=	342,
		P_INDIRECT_ADDRESS_147_L				=	343,
		P_INDIRECT_ADDRESS_147_H				=	344,
		P_INDIRECT_ADDRESS_148_L				=	345,
		P_INDIRECT_ADDRESS_148_H				=	346,
		P_INDIRECT_ADDRESS_149_L				=	347,
		P_INDIRECT_ADDRESS_149_H				=	348,
		P_INDIRECT_ADDRESS_150_L				=	349,
		P_INDIRECT_ADDRESS_150_H				=	350,
		P_INDIRECT_ADDRESS_151_L				=	351,
		P_INDIRECT_ADDRESS_151_H				=	352,
		P_INDIRECT_ADDRESS_152_L				=	353,
		P_INDIRECT_ADDRESS_152_H				=	354,
		P_INDIRECT_ADDRESS_153_L				=	355,
		P_INDIRECT_ADDRESS_153_H				=	356,
		P_INDIRECT_ADDRESS_154_L				=	357,
		P_INDIRECT_ADDRESS_154_H				=	358,
		P_INDIRECT_ADDRESS_155_L				=	359,
		P_INDIRECT_ADDRESS_155_H				=	360,
		P_INDIRECT_ADDRESS_156_L				=	361,
		P_INDIRECT_ADDRESS_156_H				=	362,
		P_INDIRECT_ADDRESS_157_L				=	363,
		P_INDIRECT_ADDRESS_157_H				=	364,
		P_INDIRECT_ADDRESS_158_L				=	365,
		P_INDIRECT_ADDRESS_158_H				=	366,
		P_INDIRECT_ADDRESS_159_L				=	367,
		P_INDIRECT_ADDRESS_159_H				=	368,
		P_INDIRECT_ADDRESS_160_L				=	369,
		P_INDIRECT_ADDRESS_160_H				=	370,
		P_INDIRECT_ADDRESS_161_L				=	371,
		P_INDIRECT_ADDRESS_161_H				=	372,
		P_INDIRECT_ADDRESS_162_L				=	373,
		P_INDIRECT_ADDRESS_162_H				=	374,
		P_INDIRECT_ADDRESS_163_L				=	375,
		P_INDIRECT_ADDRESS_163_H				=	376,
		P_INDIRECT_ADDRESS_164_L				=	377,
		P_INDIRECT_ADDRESS_164_H				=	378,
		P_INDIRECT_ADDRESS_165_L				=	379,
		P_INDIRECT_ADDRESS_165_H				=	380,
		P_INDIRECT_ADDRESS_166_L				=	381,
		P_INDIRECT_ADDRESS_166_H				=	382,
		P_INDIRECT_ADDRESS_167_L				=	383,
		P_INDIRECT_ADDRESS_167_H				=	384,
		P_INDIRECT_ADDRESS_168_L				=	385,
		P_INDIRECT_ADDRESS_168_H				=	386,
		P_INDIRECT_ADDRESS_169_L				=	387,
		P_INDIRECT_ADDRESS_169_H				=	388,
		P_INDIRECT_ADDRESS_170_L				=	389,
		P_INDIRECT_ADDRESS_170_H				=	390,
		P_INDIRECT_ADDRESS_171_L				=	391,
		P_INDIRECT_ADDRESS_171_H				=	392,
		P_INDIRECT_ADDRESS_172_L				=	393,
		P_INDIRECT_ADDRESS_172_H				=	394,
		P_INDIRECT_ADDRESS_173_L				=	395,
		P_INDIRECT_ADDRESS_173_H				=	396,
		P_INDIRECT_ADDRESS_174_L				=	397,
		P_INDIRECT_ADDRESS_174_H				=	398,
		P_INDIRECT_ADDRESS_175_L				=	399,
		P_INDIRECT_ADDRESS_175_H				=	400,
		P_INDIRECT_ADDRESS_176_L				=	401,
		P_INDIRECT_ADDRESS_176_H				=	402,
		P_INDIRECT_ADDRESS_177_L				=	403,
		P_INDIRECT_ADDRESS_177_H				=	404,
		P_INDIRECT_ADDRESS_178_L				=	405,
		P_INDIRECT_ADDRESS_178_H				=	406,
		P_INDIRECT_ADDRESS_179_L				=	407,
		P_INDIRECT_ADDRESS_179_H				=	408,
		P_INDIRECT_ADDRESS_180_L				=	409,
		P_INDIRECT_ADDRESS_180_H				=	410,
		P_INDIRECT_ADDRESS_181_L				=	411,
		P_INDIRECT_ADDRESS_181_H				=	412,
		P_INDIRECT_ADDRESS_182_L				=	413,
		P_INDIRECT_ADDRESS_182_H				=	414,
		P_INDIRECT_ADDRESS_183_L				=	415,
		P_INDIRECT_ADDRESS_183_H				=	416,
		P_INDIRECT_ADDRESS_184_L				=	417,
		P_INDIRECT_ADDRESS_184_H				=	418,
		P_INDIRECT_ADDRESS_185_L				=	419,
		P_INDIRECT_ADDRESS_185_H				=	420,
		P_INDIRECT_ADDRESS_186_L				=	421,
		P_INDIRECT_ADDRESS_186_H				=	422,
		P_INDIRECT_ADDRESS_187_L				=	423,
		P_INDIRECT_ADDRESS_187_H				=	424,
		P_INDIRECT_ADDRESS_188_L				=	425,
		P_INDIRECT_ADDRESS_188_H				=	426,
		P_INDIRECT_ADDRESS_189_L				=	427,
		P_INDIRECT_ADDRESS_189_H				=	428,
		P_INDIRECT_ADDRESS_190_L				=	429,
		P_INDIRECT_ADDRESS_190_H				=	430,
		P_INDIRECT_ADDRESS_191_L				=	431,
		P_INDIRECT_ADDRESS_191_H				=	432,
		P_INDIRECT_ADDRESS_192_L				=	433,
		P_INDIRECT_ADDRESS_192_H				=	434,
		P_INDIRECT_ADDRESS_193_L				=	435,
		P_INDIRECT_ADDRESS_193_H				=	436,
		P_INDIRECT_ADDRESS_194_L				=	437,
		P_INDIRECT_ADDRESS_194_H				=	438,
		P_INDIRECT_ADDRESS_195_L				=	439,
		P_INDIRECT_ADDRESS_195_H				=	440,
		P_INDIRECT_ADDRESS_196_L				=	441,
		P_INDIRECT_ADDRESS_196_H				=	442,
		P_INDIRECT_ADDRESS_197_L				=	443,
		P_INDIRECT_ADDRESS_197_H				=	444,
		P_INDIRECT_ADDRESS_198_L				=	445,
		P_INDIRECT_ADDRESS_198_H				=	446,
		P_INDIRECT_ADDRESS_199_L				=	447,
		P_INDIRECT_ADDRESS_199_H				=	448,
		P_INDIRECT_ADDRESS_200_L				=	449,
		P_INDIRECT_ADDRESS_200_H				=	450,
		P_INDIRECT_ADDRESS_201_L				=	451,
		P_INDIRECT_ADDRESS_201_H				=	452,
		P_INDIRECT_ADDRESS_202_L				=	453,
		P_INDIRECT_ADDRESS_202_H				=	454,
		P_INDIRECT_ADDRESS_203_L				=	455,
		P_INDIRECT_ADDRESS_203_H				=	456,
		P_INDIRECT_ADDRESS_204_L				=	457,
		P_INDIRECT_ADDRESS_204_H				=	458,
		P_INDIRECT_ADDRESS_205_L				=	459,
		P_INDIRECT_ADDRESS_205_H				=	460,
		P_INDIRECT_ADDRESS_206_L				=	461,
		P_INDIRECT_ADDRESS_206_H				=	462,
		P_INDIRECT_ADDRESS_207_L				=	463,
		P_INDIRECT_ADDRESS_207_H				=	464,
		P_INDIRECT_ADDRESS_208_L				=	465,
		P_INDIRECT_ADDRESS_208_H				=	466,
		P_INDIRECT_ADDRESS_209_L				=	467,
		P_INDIRECT_ADDRESS_209_H				=	468,
		P_INDIRECT_ADDRESS_210_L				=	469,
		P_INDIRECT_ADDRESS_210_H				=	470,
		P_INDIRECT_ADDRESS_211_L				=	471,
		P_INDIRECT_ADDRESS_211_H				=	472,
		P_INDIRECT_ADDRESS_212_L				=	473,
		P_INDIRECT_ADDRESS_212_H				=	474,
		P_INDIRECT_ADDRESS_213_L				=	475,
		P_INDIRECT_ADDRESS_213_H				=	476,
		P_INDIRECT_ADDRESS_214_L				=	477,
		P_INDIRECT_ADDRESS_214_H				=	478,
		P_INDIRECT_ADDRESS_215_L				=	479,
		P_INDIRECT_ADDRESS_215_H				=	480,
		P_INDIRECT_ADDRESS_216_L				=	481,
		P_INDIRECT_ADDRESS_216_H				=	482,
		P_INDIRECT_ADDRESS_217_L				=	483,
		P_INDIRECT_ADDRESS_217_H				=	484,
		P_INDIRECT_ADDRESS_218_L				=	485,
		P_INDIRECT_ADDRESS_218_H				=	486,
		P_INDIRECT_ADDRESS_219_L				=	487,
		P_INDIRECT_ADDRESS_219_H				=	488,
		P_INDIRECT_ADDRESS_220_L				=	489,
		P_INDIRECT_ADDRESS_220_H				=	490,
		P_INDIRECT_ADDRESS_221_L				=	491,
		P_INDIRECT_ADDRESS_221_H				=	492,
		P_INDIRECT_ADDRESS_222_L				=	493,
		P_INDIRECT_ADDRESS_222_H				=	494,
		P_INDIRECT_ADDRESS_223_L				=	495,
		P_INDIRECT_ADDRESS_223_H				=	496,
		P_INDIRECT_ADDRESS_224_L				=	497,
		P_INDIRECT_ADDRESS_224_H				=	498,
		P_INDIRECT_ADDRESS_225_L				=	499,
		P_INDIRECT_ADDRESS_225_H				=	500,
		P_INDIRECT_ADDRESS_226_L				=	501,
		P_INDIRECT_ADDRESS_226_H				=	502,
		P_INDIRECT_ADDRESS_227_L				=	503,
		P_INDIRECT_ADDRESS_227_H				=	504,
		P_INDIRECT_ADDRESS_228_L				=	505,
		P_INDIRECT_ADDRESS_228_H				=	506,
		P_INDIRECT_ADDRESS_229_L				=	507,
		P_INDIRECT_ADDRESS_229_H				=	508,
		P_INDIRECT_ADDRESS_230_L				=	509,
		P_INDIRECT_ADDRESS_230_H				=	510,
		P_INDIRECT_ADDRESS_231_L				=	511,
		P_INDIRECT_ADDRESS_231_H				=	512,
		P_INDIRECT_ADDRESS_232_L				=	513,
		P_INDIRECT_ADDRESS_232_H				=	514,
		P_INDIRECT_ADDRESS_233_L				=	515,
		P_INDIRECT_ADDRESS_233_H				=	516,
		P_INDIRECT_ADDRESS_234_L				=	517,
		P_INDIRECT_ADDRESS_234_H				=	518,
		P_INDIRECT_ADDRESS_235_L				=	519,
		P_INDIRECT_ADDRESS_235_H				=	520,
		P_INDIRECT_ADDRESS_236_L				=	521,
		P_INDIRECT_ADDRESS_236_H				=	522,
		P_INDIRECT_ADDRESS_237_L				=	523,
		P_INDIRECT_ADDRESS_237_H				=	524,
		P_INDIRECT_ADDRESS_238_L				=	525,
		P_INDIRECT_ADDRESS_238_H				=	526,
		P_INDIRECT_ADDRESS_239_L				=	527,
		P_INDIRECT_ADDRESS_239_H				=	528,
		P_INDIRECT_ADDRESS_240_L				=	529,
		P_INDIRECT_ADDRESS_240_H				=	530,
		P_INDIRECT_ADDRESS_241_L				=	531,
		P_INDIRECT_ADDRESS_241_H				=	532,
		P_INDIRECT_ADDRESS_242_L				=	533,
		P_INDIRECT_ADDRESS_242_H				=	534,
		P_INDIRECT_ADDRESS_243_L				=	535,
		P_INDIRECT_ADDRESS_243_H				=	536,
		P_INDIRECT_ADDRESS_244_L				=	537,
		P_INDIRECT_ADDRESS_244_H				=	538,
		P_INDIRECT_ADDRESS_245_L				=	539,
		P_INDIRECT_ADDRESS_245_H				=	540,
		P_INDIRECT_ADDRESS_246_L				=	541,
		P_INDIRECT_ADDRESS_246_H				=	542,
		P_INDIRECT_ADDRESS_247_L				=	543,
		P_INDIRECT_ADDRESS_247_H				=	544,
		P_INDIRECT_ADDRESS_248_L				=	545,
		P_INDIRECT_ADDRESS_248_H				=	546,
		P_INDIRECT_ADDRESS_249_L				=	547,
		P_INDIRECT_ADDRESS_249_H				=	548,
		P_INDIRECT_ADDRESS_250_L				=	549,
		P_INDIRECT_ADDRESS_250_H				=	550,
		P_INDIRECT_ADDRESS_251_L				=	551,
		P_INDIRECT_ADDRESS_251_H				=	552,
		P_INDIRECT_ADDRESS_252_L				=	553,
		P_INDIRECT_ADDRESS_252_H				=	554,
		P_INDIRECT_ADDRESS_253_L				=	555,
		P_INDIRECT_ADDRESS_253_H				=	556,
		P_INDIRECT_ADDRESS_254_L				=	557,
		P_INDIRECT_ADDRESS_254_H				=	558,
		P_INDIRECT_ADDRESS_255_L				=	559,
		P_INDIRECT_ADDRESS_255_H				=	560,
		P_RESET_OPTION							=	561,
		P_TORQUE_ENABLE							=	562,
		P_LED_RED								=	563,
		P_LED_GREEN								=	564,
		P_LED_BLUE								=	565,
		P_CURRENT_I_GAIN_L						=	566,
		P_CURRENT_I_GAIN_H						=	567,
		P_CURRENT_P_GAIN_L						=	568,
		P_CURRENT_P_GAIN_H						=	569,
		P_ACCELATION_FEED_FORWARD_GAIN_LL		=	570,
		P_ACCELATION_FEED_FORWARD_GAIN_LH		=	571,
		P_ACCELATION_FEED_FORWARD_GAIN_HL		=	572,
		P_ACCELATION_FEED_FORWARD_GAIN_HH		=	573,
		P_VELOCITY_FEED_FORWARD_GAIN_LL			=	574,
		P_VELOCITY_FEED_FORWARD_GAIN_LH			=	575,
		P_VELOCITY_FEED_FORWARD_GAIN_HL			=	576,
		P_VELOCITY_FEED_FORWARD_GAIN_HH			=	577,
		P_POSITION_LPF_LL						=	578,
		P_POSITION_LPF_LH						=	579,
		P_POSITION_LPF_HL						=	580,
		P_POSITION_LPF_HH						=	581,
		P_VELOCITY_LPF_LL						=	582,
		P_VELOCITY_LPF_LH						=	583,
		P_VELOCITY_LPF_HL						=	584,
		P_VELOCITY_LPF_HH						=	585,
		P_VELOCITY_I_GAIN_L						=	586,
		P_VELOCITY_I_GAIN_H						=	587,
		P_VELOCITY_P_GAIN_L						=	588,
		P_VELOCITY_P_GAIN_H						=	589,
		P_POSITION_D_GAIN_L						=	590,
		P_POSITION_D_GAIN_H						=	591,
		P_POSITION_I_GAIN_L						=	592,
		P_POSITION_I_GAIN_H						=	593,
		P_POSITION_P_GAIN_L						=	594,
		P_POSITION_P_GAIN_H						=	595,
		P_GOAL_POSITION_LL						=	596,
		P_GOAL_POSITION_LH						=	597,
		P_GOAL_POSITION_HL						=	598,
		P_GOAL_POSITION_HH						=	599,
		P_GOAL_VELOCITY_LL						=	600,
		P_GOAL_VELOCITY_LH						=	601,
		P_GOAL_VELOCITY_HL						=	602,
		P_GOAL_VELOCITY_HH						=	603,
		P_GOAL_TORQUE_L							=	604,
		P_GOAL_TORQUE_H							=	605,
		P_GOAL_ACCELATION_LL					=	606,
		P_GOAL_ACCELATION_LH					=	607,
		P_GOAL_ACCELATION_HL					=	608,
		P_GOAL_ACCELATION_HH					=	609,
		P_MOVING								=	610,
		P_PRESENT_POSITION_LL					=	611,
		P_PRESENT_POSITION_LH					=	612,
		P_PRESENT_POSITION_HL					=	613,
		P_PRESENT_POSITION_HH					=	614,
		P_PRESENT_VELOCITY_LL					=	615,
		P_PRESENT_VELOCITY_LH					=	616,
		P_PRESENT_VELOCITY_HL					=	617,
		P_PRESENT_VELOCITY_HH					=	618,
		P_PRESENT_LOAD_L						=	619,
		P_PRESENT_LOAD_H						=	620,
		P_PRESENT_CURRENT_L						=	621,
		P_PRESENT_CURRENT_H						=	622,
		P_PRESENT_INPUT_VOLTAGE_L				=	623,
		P_PRESENT_INPUT_VOLTAGE_H				=	624,
		P_PRESENT_TEMPERATURE					=	625,
		P_EXTERNAL_PORT_DATA_1_L				=	626,
		P_EXTERNAL_PORT_DATA_1_H				=	627,
		P_EXTERNAL_PORT_DATA_2_L				=	628,
		P_EXTERNAL_PORT_DATA_2_H				=	629,
		P_EXTERNAL_PORT_DATA_3_L				=	630,
		P_EXTERNAL_PORT_DATA_3_H				=	631,
		P_EXTERNAL_PORT_DATA_4_L				=	632,
		P_EXTERNAL_PORT_DATA_4_H				=	633,
		P_INDIRECT_DATA_0						=	634,
		P_INDIRECT_DATA_1						=	635,
		P_INDIRECT_DATA_2						=	636,
		P_INDIRECT_DATA_3						=	637,
		P_INDIRECT_DATA_4						=	638,
		P_INDIRECT_DATA_5						=	639,
		P_INDIRECT_DATA_6						=	640,
		P_INDIRECT_DATA_7						=	641,
		P_INDIRECT_DATA_8						=	642,
		P_INDIRECT_DATA_9						=	643,
		P_INDIRECT_DATA_10						=	644,
		P_INDIRECT_DATA_11						=	645,
		P_INDIRECT_DATA_12						=	646,
		P_INDIRECT_DATA_13						=	647,
		P_INDIRECT_DATA_14						=	648,
		P_INDIRECT_DATA_15						=	649,
		P_INDIRECT_DATA_16						=	650,
		P_INDIRECT_DATA_17						=	651,
		P_INDIRECT_DATA_18						=	652,
		P_INDIRECT_DATA_19						=	653,
		P_INDIRECT_DATA_20						=	654,
		P_INDIRECT_DATA_21						=	655,
		P_INDIRECT_DATA_22						=	656,
		P_INDIRECT_DATA_23						=	657,
		P_INDIRECT_DATA_24						=	658,
		P_INDIRECT_DATA_25						=	659,
		P_INDIRECT_DATA_26						=	660,
		P_INDIRECT_DATA_27						=	661,
		P_INDIRECT_DATA_28						=	662,
		P_INDIRECT_DATA_29						=	663,
		P_INDIRECT_DATA_30						=	664,
		P_INDIRECT_DATA_31						=	665,
		P_INDIRECT_DATA_32						=	666,
		P_INDIRECT_DATA_33						=	667,
		P_INDIRECT_DATA_34						=	668,
		P_INDIRECT_DATA_35						=	669,
		P_INDIRECT_DATA_36						=	670,
		P_INDIRECT_DATA_37						=	671,
		P_INDIRECT_DATA_38						=	672,
		P_INDIRECT_DATA_39						=	673,
		P_INDIRECT_DATA_40						=	674,
		P_INDIRECT_DATA_41						=	675,
		P_INDIRECT_DATA_42						=	676,
		P_INDIRECT_DATA_43						=	677,
		P_INDIRECT_DATA_44						=	678,
		P_INDIRECT_DATA_45						=	679,
		P_INDIRECT_DATA_46						=	680,
		P_INDIRECT_DATA_47						=	681,
		P_INDIRECT_DATA_48						=	682,
		P_INDIRECT_DATA_49						=	683,
		P_INDIRECT_DATA_50						=	684,
		P_INDIRECT_DATA_51						=	685,
		P_INDIRECT_DATA_52						=	686,
		P_INDIRECT_DATA_53						=	687,
		P_INDIRECT_DATA_54						=	688,
		P_INDIRECT_DATA_55						=	689,
		P_INDIRECT_DATA_56						=	690,
		P_INDIRECT_DATA_57						=	691,
		P_INDIRECT_DATA_58						=	692,
		P_INDIRECT_DATA_59						=	693,
		P_INDIRECT_DATA_60						=	694,
		P_INDIRECT_DATA_61						=	695,
		P_INDIRECT_DATA_62						=	696,
		P_INDIRECT_DATA_63						=	697,
		P_INDIRECT_DATA_64						=	698,
		P_INDIRECT_DATA_65						=	699,
		P_INDIRECT_DATA_66						=	700,
		P_INDIRECT_DATA_67						=	701,
		P_INDIRECT_DATA_68						=	702,
		P_INDIRECT_DATA_69						=	703,
		P_INDIRECT_DATA_70						=	704,
		P_INDIRECT_DATA_71						=	705,
		P_INDIRECT_DATA_72						=	706,
		P_INDIRECT_DATA_73						=	707,
		P_INDIRECT_DATA_74						=	708,
		P_INDIRECT_DATA_75						=	709,
		P_INDIRECT_DATA_76						=	710,
		P_INDIRECT_DATA_77						=	711,
		P_INDIRECT_DATA_78						=	712,
		P_INDIRECT_DATA_79						=	713,
		P_INDIRECT_DATA_80						=	714,
		P_INDIRECT_DATA_81						=	715,
		P_INDIRECT_DATA_82						=	716,
		P_INDIRECT_DATA_83						=	717,
		P_INDIRECT_DATA_84						=	718,
		P_INDIRECT_DATA_85						=	719,
		P_INDIRECT_DATA_86						=	720,
		P_INDIRECT_DATA_87						=	721,
		P_INDIRECT_DATA_88						=	722,
		P_INDIRECT_DATA_89						=	723,
		P_INDIRECT_DATA_90						=	724,
		P_INDIRECT_DATA_91						=	725,
		P_INDIRECT_DATA_92						=	726,
		P_INDIRECT_DATA_93						=	727,
		P_INDIRECT_DATA_94						=	728,
		P_INDIRECT_DATA_95						=	729,
		P_INDIRECT_DATA_96						=	730,
		P_INDIRECT_DATA_97						=	731,
		P_INDIRECT_DATA_98						=	732,
		P_INDIRECT_DATA_99						=	733,
		P_INDIRECT_DATA_100						=	734,
		P_INDIRECT_DATA_101						=	735,
		P_INDIRECT_DATA_102						=	736,
		P_INDIRECT_DATA_103						=	737,
		P_INDIRECT_DATA_104						=	738,
		P_INDIRECT_DATA_105						=	739,
		P_INDIRECT_DATA_106						=	740,
		P_INDIRECT_DATA_107						=	741,
		P_INDIRECT_DATA_108						=	742,
		P_INDIRECT_DATA_109						=	743,
		P_INDIRECT_DATA_110						=	744,
		P_INDIRECT_DATA_111						=	745,
		P_INDIRECT_DATA_112						=	746,
		P_INDIRECT_DATA_113						=	747,
		P_INDIRECT_DATA_114						=	748,
		P_INDIRECT_DATA_115						=	749,
		P_INDIRECT_DATA_116						=	750,
		P_INDIRECT_DATA_117						=	751,
		P_INDIRECT_DATA_118						=	752,
		P_INDIRECT_DATA_119						=	753,
		P_INDIRECT_DATA_120						=	754,
		P_INDIRECT_DATA_121						=	755,
		P_INDIRECT_DATA_122						=	756,
		P_INDIRECT_DATA_123						=	757,
		P_INDIRECT_DATA_124						=	758,
		P_INDIRECT_DATA_125						=	759,
		P_INDIRECT_DATA_126						=	760,
		P_INDIRECT_DATA_127						=	761,
		P_INDIRECT_DATA_128						=	762,
		P_INDIRECT_DATA_129						=	763,
		P_INDIRECT_DATA_130						=	764,
		P_INDIRECT_DATA_131						=	765,
		P_INDIRECT_DATA_132						=	766,
		P_INDIRECT_DATA_133						=	767,
		P_INDIRECT_DATA_134						=	768,
		P_INDIRECT_DATA_135						=	769,
		P_INDIRECT_DATA_136						=	770,
		P_INDIRECT_DATA_137						=	771,
		P_INDIRECT_DATA_138						=	772,
		P_INDIRECT_DATA_139						=	773,
		P_INDIRECT_DATA_140						=	774,
		P_INDIRECT_DATA_141						=	775,
		P_INDIRECT_DATA_142						=	776,
		P_INDIRECT_DATA_143						=	777,
		P_INDIRECT_DATA_144						=	778,
		P_INDIRECT_DATA_145						=	779,
		P_INDIRECT_DATA_146						=	780,
		P_INDIRECT_DATA_147						=	781,
		P_INDIRECT_DATA_148						=	782,
		P_INDIRECT_DATA_149						=	783,
		P_INDIRECT_DATA_150						=	784,
		P_INDIRECT_DATA_151						=	785,
		P_INDIRECT_DATA_152						=	786,
		P_INDIRECT_DATA_153						=	787,
		P_INDIRECT_DATA_154						=	788,
		P_INDIRECT_DATA_155						=	789,
		P_INDIRECT_DATA_156						=	790,
		P_INDIRECT_DATA_157						=	791,
		P_INDIRECT_DATA_158						=	792,
		P_INDIRECT_DATA_159						=	793,
		P_INDIRECT_DATA_160						=	794,
		P_INDIRECT_DATA_161						=	795,
		P_INDIRECT_DATA_162						=	796,
		P_INDIRECT_DATA_163						=	797,
		P_INDIRECT_DATA_164						=	798,
		P_INDIRECT_DATA_165						=	799,
		P_INDIRECT_DATA_166						=	800,
		P_INDIRECT_DATA_167						=	801,
		P_INDIRECT_DATA_168						=	802,
		P_INDIRECT_DATA_169						=	803,
		P_INDIRECT_DATA_170						=	804,
		P_INDIRECT_DATA_171						=	805,
		P_INDIRECT_DATA_172						=	806,
		P_INDIRECT_DATA_173						=	807,
		P_INDIRECT_DATA_174						=	808,
		P_INDIRECT_DATA_175						=	809,
		P_INDIRECT_DATA_176						=	810,
		P_INDIRECT_DATA_177						=	811,
		P_INDIRECT_DATA_178						=	812,
		P_INDIRECT_DATA_179						=	813,
		P_INDIRECT_DATA_180						=	814,
		P_INDIRECT_DATA_181						=	815,
		P_INDIRECT_DATA_182						=	816,
		P_INDIRECT_DATA_183						=	817,
		P_INDIRECT_DATA_184						=	818,
		P_INDIRECT_DATA_185						=	819,
		P_INDIRECT_DATA_186						=	820,
		P_INDIRECT_DATA_187						=	821,
		P_INDIRECT_DATA_188						=	822,
		P_INDIRECT_DATA_189						=	823,
		P_INDIRECT_DATA_190						=	824,
		P_INDIRECT_DATA_191						=	825,
		P_INDIRECT_DATA_192						=	826,
		P_INDIRECT_DATA_193						=	827,
		P_INDIRECT_DATA_194						=	828,
		P_INDIRECT_DATA_195						=	829,
		P_INDIRECT_DATA_196						=	830,
		P_INDIRECT_DATA_197						=	831,
		P_INDIRECT_DATA_198						=	832,
		P_INDIRECT_DATA_199						=	833,
		P_INDIRECT_DATA_200						=	834,
		P_INDIRECT_DATA_201						=	835,
		P_INDIRECT_DATA_202						=	836,
		P_INDIRECT_DATA_203						=	837,
		P_INDIRECT_DATA_204						=	838,
		P_INDIRECT_DATA_205						=	839,
		P_INDIRECT_DATA_206						=	840,
		P_INDIRECT_DATA_207						=	841,
		P_INDIRECT_DATA_208						=	842,
		P_INDIRECT_DATA_209						=	843,
		P_INDIRECT_DATA_210						=	844,
		P_INDIRECT_DATA_211						=	845,
		P_INDIRECT_DATA_212						=	846,
		P_INDIRECT_DATA_213						=	847,
		P_INDIRECT_DATA_214						=	848,
		P_INDIRECT_DATA_215						=	849,
		P_INDIRECT_DATA_216						=	850,
		P_INDIRECT_DATA_217						=	851,
		P_INDIRECT_DATA_218						=	852,
		P_INDIRECT_DATA_219						=	853,
		P_INDIRECT_DATA_220						=	854,
		P_INDIRECT_DATA_221						=	855,
		P_INDIRECT_DATA_222						=	856,
		P_INDIRECT_DATA_223						=	857,
		P_INDIRECT_DATA_224						=	858,
		P_INDIRECT_DATA_225						=	859,
		P_INDIRECT_DATA_226						=	860,
		P_INDIRECT_DATA_227						=	861,
		P_INDIRECT_DATA_228						=	862,
		P_INDIRECT_DATA_229						=	863,
		P_INDIRECT_DATA_230						=	864,
		P_INDIRECT_DATA_231						=	865,
		P_INDIRECT_DATA_232						=	866,
		P_INDIRECT_DATA_233						=	867,
		P_INDIRECT_DATA_234						=	868,
		P_INDIRECT_DATA_235						=	869,
		P_INDIRECT_DATA_236						=	870,
		P_INDIRECT_DATA_237						=	871,
		P_INDIRECT_DATA_238						=	872,
		P_INDIRECT_DATA_239						=	873,
		P_INDIRECT_DATA_240						=	874,
		P_INDIRECT_DATA_241						=	875,
		P_INDIRECT_DATA_242						=	876,
		P_INDIRECT_DATA_243						=	877,
		P_INDIRECT_DATA_244						=	878,
		P_INDIRECT_DATA_245						=	879,
		P_INDIRECT_DATA_246						=	880,
		P_INDIRECT_DATA_247						=	881,
		P_INDIRECT_DATA_248						=	882,
		P_INDIRECT_DATA_249						=	883,
		P_INDIRECT_DATA_250						=	884,
		P_INDIRECT_DATA_251						=	885,
		P_INDIRECT_DATA_252						=	886,
		P_INDIRECT_DATA_253						=	887,
		P_INDIRECT_DATA_254						=	888,
		P_INDIRECT_DATA_255						=	889,
		P_SELF_TEST								=	890,
		P_STATUS_RETURN_LEVEL					=	891,
		P_SHUTDOWN_CANCEL						=	892,
		P_RESERVED_LL							=	893,
		P_RESERVED_LH							=	894,
		P_RESERVED_HL							=	895,
		P_RESERVED_HH							=	896,
		P_POT_L									=	897	,
		P_POT_H									=	898	,
		P_PWM__OUT_L							=	899	,
		P_PWM__OUT_H							=	900	,
		P_POSITION_P_ERROR_LL					=	901	,
		P_POSITION_P_ERROR_LH					=	902	,
		P_POSITION_P_ERROR_HL					=	903	,
		P_POSITION_P_ERROR_HH					=	904	,
		P_POSITION_I_ERROR_LL					=	905	,
		P_POSITION_I_ERROR_LH					=	906	,
		P_POSITION_I_ERROR_HL					=	907	,
		P_POSITION_I_ERROR_HH					=	908	,
		P_POSITION_D_ERROR_LL					=	909	,
		P_POSITION_D_ERROR_LH					=	910	,
		P_POSITION_D_ERROR_HL					=	911	,
		P_POSITION_D_ERROR_HH					=	912	,
		P_POSITION_ERROR_OUT_LL					=	913	,
		P_POSITION_ERROR_OUT_LH					=	914	,
		P_POSITION_ERROR_OUT_HL					=	915	,
		P_POSITION_ERROR_OUT_HH					=	916	,
		P_VELOCITY_P_ERROR_LL					=	917	,
		P_VELOCITY_P_ERROR_LH					=	918	,
		P_VELOCITY_P_ERROR_HL					=	919	,
		P_VELOCITY_P_ERROR_HH					=	920	,
		P_VELOCITY_I_ERROR_LL					=	921	,
		P_VELOCITY_I_ERROR_LH					=	922	,
		P_VELOCITY_I_ERROR_HL					=	923	,
		P_VELOCITY_I_ERROR_HH					=	924	,
		P_VELOCITY_ERROR_OUT_LL					=	925	,
		P_VELOCITY_ERROR_OUT_LH					=	926	,
		P_VELOCITY_ERROR_OUT_HL					=	927	,
		P_VELOCITY_ERROR_OUT_HH					=	928	,
		P_CURRENT_P_ERROR_LL					=	929	,
		P_CURRENT_P_ERROR_LH					=	930	,
		P_CURRENT_P_ERROR_HL					=	931	,
		P_CURRENT_P_ERROR_HH					=	932	,
		P_CURRENT_I_ERROR_LL					=	933	,
		P_CURRENT_I_ERROR_LH					=	934	,
		P_CURRENT_I_ERROR_HL					=	935	,
		P_CURRENT_I_ERROR_HH					=	936	,
		P_CURRENT_ERROR_OUT_LL					=	937	,
		P_CURRENT_ERROR_OUT_LH					=	938	,
		P_CURRENT_ERROR_OUT_HL					=	939	,
		P_CURRENT_ERROR_OUT_HH					=	940	,
		P_CALIBRATION_FLAG						=	941	,
		P_PWM_COMPENSATION_DEADTIME				=	942	,
		P_PWM_COMPENSATION_CHARGEPUMP			=	943	,
		P_DELAY_L								=	944	,
		P_DELAY_H								=	945	,
		MAXNUM_ADDRESS
	};

	PRO54() : MIN_ANGLE(-180.0), MAX_ANGLE(180.0), MIN_RAD(-3.14159265), MAX_RAD( 3.14159265), CENTER_VALUE(0),
			DXLInfo(P_GOAL_POSITION_LL, P_PRESENT_POSITION_LL, 4, P_POSITION_P_GAIN_L, 2, 251000, -251000, 54)
	{
		m_SyncWriteLength = 4;
		m_SyncWriteStartAddr = P_GOAL_POSITION_LL;
	}

	~PRO54() {  }

	int Angle2Value(double angle) { return angle*MAX_VALUE/MAX_ANGLE; }
	double Value2Angle(int value) { return value*MAX_ANGLE/MAX_VALUE; }
	int Rad2Value(double radian) { return radian*MAX_VALUE/MAX_RAD; }
	double Value2Rad(int value) { return value*MAX_RAD/MAX_VALUE; }
	int ValueScaleUp(int value) { return (value-2048.0)*251000.0/2048.0; }
	int ValueScaleDown(int value) { return (value+251000.0)*2048.0/251000.0; }

};

}



#endif /* DXLPRO_54_H_ */
