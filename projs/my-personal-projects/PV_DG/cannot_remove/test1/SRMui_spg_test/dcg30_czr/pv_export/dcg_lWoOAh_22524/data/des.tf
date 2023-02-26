/* $Id:  $ */

Technology	{
		name				= "45_NONRC_8M_5F1M1R2ZA_PG"
		date				= "test"
		dielectric			= 3.45e-05
		unitTimeName			= "ns"
		timePrecision			= 1000000
		unitLengthName			= "micron"
		lengthPrecision			= 1000
		gridResolution			= 5
		unitVoltageName			= "V"
		voltagePrecision		= 1000
		unitCurrentName			= "mA"
		currentPrecision		= 1000
		unitPowerName			= "nW"
		powerPrecision			= 1000
		unitResistanceName		= "ohm"
		resistancePrecision		= 100000
		unitCapacitanceName		= "pf"
		capacitancePrecision		= 10000000
		unitInductanceName		= "nh"
		inductancePrecision		= 100
		minBaselineTemperature		= 25
		nomBaselineTemperature		= 25
		maxBaselineTemperature		= 25
		fatWireExtensionMode		= 1
		stubMode			= 3
		fatTblMinEnclosedAreaMode	= 1
}

Color		16 {
		name				= "16"
		rgbDefined			= 1
		redIntensity			= 90
		greenIntensity			= 0
		blueIntensity			= 0
}

Color		17 {
		name				= "17"
		rgbDefined			= 1
		redIntensity			= 90
		greenIntensity			= 0
		blueIntensity			= 100
}

Color		32 {
		name				= "32"
		rgbDefined			= 1
		redIntensity			= 180
		greenIntensity			= 0
		blueIntensity			= 0
}

Color		36 {
		name				= "36"
		rgbDefined			= 1
		redIntensity			= 180
		greenIntensity			= 80
		blueIntensity			= 0
}

Color		38 {
		name				= "38"
		rgbDefined			= 1
		redIntensity			= 180
		greenIntensity			= 80
		blueIntensity			= 190
}

Color		47 {
		name				= "47"
		rgbDefined			= 1
		redIntensity			= 180
		greenIntensity			= 255
		blueIntensity			= 255
}

Color		53 {
		name				= "53"
		rgbDefined			= 1
		redIntensity			= 255
		greenIntensity			= 80
		blueIntensity			= 100
}

Color		54 {
		name				= "54"
		rgbDefined			= 1
		redIntensity			= 255
		greenIntensity			= 80
		blueIntensity			= 190
}

Color		55 {
		name				= "55"
		rgbDefined			= 1
		redIntensity			= 255
		greenIntensity			= 80
		blueIntensity			= 255
}

Color		57 {
		name				= "57"
		rgbDefined			= 1
		redIntensity			= 255
		greenIntensity			= 175
		blueIntensity			= 100
}

Color		58 {
		name				= "58"
		rgbDefined			= 1
		redIntensity			= 255
		greenIntensity			= 175
		blueIntensity			= 190
}

Color		62 {
		name				= "62"
		rgbDefined			= 1
		redIntensity			= 255
		greenIntensity			= 255
		blueIntensity			= 190
}

Tile		"unit" {
		width				= 0.18
		height				= 0.98
}

Layer		"OD" {
		layerNumber			= 1
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"NT" {
		layerNumber			= 5
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"NW" {
		layerNumber			= 6
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"HV" {
		layerNumber			= 9
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"GA" {
		layerNumber			= 12
		maskName			= "poly"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "red"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0.18
		defaultWidth			= 0.1
		minWidth			= 0.06
		minSpacing			= 0.12
		unitMinResistance		= 0.1313
		unitNomResistance		= 0.142
		unitMaxResistance		= 0.14868
}

Layer		"ND" {
		layerNumber			= 19
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"PD" {
		layerNumber			= 21
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"CA" {
		layerNumber			= 25
		maskName			= "polyCont"
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"PADDEV_BOND" {
		layerNumber			= 30
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "brown"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"PADDEV_BUMP" {
		layerNumber			= 31
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "38"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"M1" {
		layerNumber			= 43
		maskName			= "metal1"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "blue"
		lineStyle			= "solid"
		pattern				= "slash"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.06
		minSpacing			= 0.07
		maxWidth			= 0.7
		unitMinResistance		= 0.285
		unitNomResistance		= 0.285
		unitMaxResistance		= 0.38276
		fatTblDimension			= 5
		fatTblThreshold			= (0,0.085,0.125,0.355,0.505)
		fatTblParallelLength		= (0,0.305,0.305,0,0)
		fatTblSpacing			= (0.07,0.08,0.1,0.14,0.28,
						   0.08,0.08,0.1,0.14,0.28,
						   0.1,0.1,0.1,0.14,0.28,
						   0.14,0.14,0.14,0.14,0.28,
						   0.28,0.28,0.28,0.28,0.28)
		fatTblMinEnclosedArea		= (0.2,0.2,0.4,0.4,0.4)
		minArea				= 0.0147
		minEnclosedArea			= 0.4
		maxNumMinEdge			= 1
		minEdgeLength			= 0.07
}

Layer		"V1" {
		layerNumber			= 46
		maskName			= "via1"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "orange"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		fatTblDimension			= 8
		fatTblThreshold			= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fatTblExtensionRange		= (0,15,15,15,15,15,15,15)
		fatTblThreshold2		= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fat2DTblFatContactNumber	= (15,15,15,15,15,11,11,11,
						   15,15,15,15,15,11,11,11,
						   11,11,11,11,11,11,11,11,
						   11,11,11,11,11,11,11,11,
						   14,14,14,14,14,14,14,14,
						   14,14,14,14,14,14,14,14,
						   14,14,14,14,14,14,14,14,
						   14,14,14,14,14,14,14,14)
		fat2DTblFatContactMinCuts	= (1,2,3,4,4,4,6,8,
						   2,2,3,4,4,4,6,8,
						   3,3,3,4,4,4,6,8,
						   4,4,4,4,4,4,6,8,
						   6,6,6,6,6,6,6,8,
						   8,8,8,8,8,8,8,8,
						   12,12,12,12,12,12,12,12,
						   16,16,16,16,16,16,16,16)
		fatTblExtensionContactNumber	= (0,1,11,11,14,14,14,14)
		fatTblExtensionMinCuts		= (1,2,3,4,6,8,12,16)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 0.098
}

Layer		"M2" {
		layerNumber			= 47
		maskName			= "metal2"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "green"
		lineStyle			= "solid"
		pattern				= "backSlash"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		maxWidth			= 2
		stubSpacing			= 0.08
		stubThreshold			= 0.08
		unitMinResistance		= 0.362
		unitNomResistance		= 0.362
		unitMaxResistance		= 0.48617
		fatTblDimension			= 6
		fatTblThreshold			= (0,0.085,0.125,0.355,0.505,1.005)
		fatTblParallelLength		= (0,0.305,0.305,0,0,0)
		fatTblSpacing			= (0.07,0.08,0.1,0.14,0.28,0.35,
						   0.08,0.08,0.1,0.14,0.28,0.35,
						   0.1,0.1,0.1,0.14,0.28,0.35,
						   0.14,0.14,0.14,0.14,0.28,0.35,
						   0.28,0.28,0.28,0.28,0.28,0.35,
						   0.35,0.35,0.35,0.35,0.35,0.35)
		fatTblMinEnclosedArea		= (0.2,0.2,0.4,0.4,0.4,1.6)
		minArea				= 0.0441
		minEnclosedArea			= 0.4
		maxNumMinEdge			= 1
		minEdgeLength			= 0.07
}

Layer		"V2" {
		layerNumber			= 48
		maskName			= "via2"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "orange"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		fatTblDimension			= 8
		fatTblThreshold			= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fatTblExtensionRange		= (0,15,15,15,15,15,15,15)
		fatTblThreshold2		= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fat2DTblFatContactNumber	= (25,25,25,25,25,21,21,21,
						   25,25,25,25,25,21,21,21,
						   21,21,21,21,21,21,21,21,
						   21,21,21,21,21,21,21,21,
						   24,24,24,24,24,24,24,24,
						   24,24,24,24,24,24,24,24,
						   24,24,24,24,24,24,24,24,
						   24,24,24,24,24,24,24,24)
		fat2DTblFatContactMinCuts	= (1,2,3,4,4,4,6,8,
						   2,2,3,4,4,4,6,8,
						   3,3,3,4,4,4,6,8,
						   4,4,4,4,4,4,6,8,
						   6,6,6,6,6,6,6,8,
						   8,8,8,8,8,8,8,8,
						   12,12,12,12,12,12,12,12,
						   16,16,16,16,16,16,16,16)
		fatTblExtensionContactNumber	= (0,21,21,21,24,24,24,24)
		fatTblExtensionMinCuts		= (1,2,3,4,6,8,12,16)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 0.098
}

Layer		"M3" {
		layerNumber			= 49
		maskName			= "metal3"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "red"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		maxWidth			= 2
		stubSpacing			= 0.08
		stubThreshold			= 0.08
		unitMinResistance		= 0.362
		unitNomResistance		= 0.362
		unitMaxResistance		= 0.48617
		fatTblDimension			= 6
		fatTblThreshold			= (0,0.085,0.125,0.355,0.505,1.005)
		fatTblParallelLength		= (0,0.305,0.305,0,0,0)
		fatTblSpacing			= (0.07,0.08,0.1,0.14,0.28,0.35,
						   0.08,0.08,0.1,0.14,0.28,0.35,
						   0.1,0.1,0.1,0.14,0.28,0.35,
						   0.14,0.14,0.14,0.14,0.28,0.35,
						   0.28,0.28,0.28,0.28,0.28,0.35,
						   0.35,0.35,0.35,0.35,0.35,0.35)
		fatTblMinEnclosedArea		= (0.2,0.2,0.4,0.4,0.4,1.6)
		minArea				= 0.0441
		minEnclosedArea			= 0.4
		maxNumMinEdge			= 1
		minEdgeLength			= 0.07
}

Layer		"V3" {
		layerNumber			= 50
		maskName			= "via3"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "53"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		fatTblDimension			= 8
		fatTblThreshold			= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fatTblExtensionRange		= (0,15,15,15,15,15,15,15)
		fatTblThreshold2		= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fat2DTblFatContactNumber	= (35,35,35,35,35,31,31,31,
						   35,35,35,35,35,31,31,31,
						   31,31,31,31,31,31,31,31,
						   31,31,31,31,31,31,31,31,
						   34,34,34,34,34,34,34,34,
						   34,34,34,34,34,34,34,34,
						   34,34,34,34,34,34,34,34,
						   34,34,34,34,34,34,34,34)
		fat2DTblFatContactMinCuts	= (1,2,3,4,4,4,6,8,
						   2,2,3,4,4,4,6,8,
						   3,3,3,4,4,4,6,8,
						   4,4,4,4,4,4,6,8,
						   6,6,6,6,6,6,6,8,
						   8,8,8,8,8,8,8,8,
						   12,12,12,12,12,12,12,12,
						   16,16,16,16,16,16,16,16)
		fatTblExtensionContactNumber	= (0,31,31,31,34,34,34,34)
		fatTblExtensionMinCuts		= (1,2,3,4,6,8,12,16)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 0.098
}

Layer		"M4" {
		layerNumber			= 51
		maskName			= "metal4"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "yellow"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		maxWidth			= 2
		stubSpacing			= 0.08
		stubThreshold			= 0.08
		unitMinResistance		= 0.362
		unitNomResistance		= 0.362
		unitMaxResistance		= 0.48617
		fatTblDimension			= 6
		fatTblThreshold			= (0,0.085,0.125,0.355,0.505,1.005)
		fatTblParallelLength		= (0,0.305,0.305,0,0,0)
		fatTblSpacing			= (0.07,0.08,0.1,0.14,0.28,0.35,
						   0.08,0.08,0.1,0.14,0.28,0.35,
						   0.1,0.1,0.1,0.14,0.28,0.35,
						   0.14,0.14,0.14,0.14,0.28,0.35,
						   0.28,0.28,0.28,0.28,0.28,0.35,
						   0.35,0.35,0.35,0.35,0.35,0.35)
		fatTblMinEnclosedArea		= (0.2,0.2,0.4,0.4,0.4,1.6)
		minArea				= 0.0441
		minEnclosedArea			= 0.4
		maxNumMinEdge			= 1
		minEdgeLength			= 0.07
}

Layer		"V4" {
		layerNumber			= 52
		maskName			= "via4"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "54"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		fatTblDimension			= 8
		fatTblThreshold			= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fatTblExtensionRange		= (0,15,15,15,15,15,15,15)
		fatTblThreshold2		= (0,0.075,0.145,0.215,0.355,0.495,0.875,1.155)
		fat2DTblFatContactNumber	= (45,45,45,45,45,46,46,46,
						   45,45,45,45,45,46,46,46,
						   41,41,41,41,41,41,41,41,
						   41,41,41,41,41,41,41,41,
						   41,41,41,41,41,41,41,41,
						   41,41,41,41,41,41,41,41,
						   41,41,41,41,41,41,41,41,
						   41,41,41,41,41,41,41,41)
		fat2DTblFatContactMinCuts	= (1,2,3,4,4,4,6,8,
						   2,2,3,4,4,4,6,8,
						   3,3,3,4,4,4,6,8,
						   4,4,4,4,4,4,6,8,
						   6,6,6,6,6,6,6,8,
						   8,8,8,8,8,8,8,8,
						   12,12,12,12,12,12,12,12,
						   16,16,16,16,16,16,16,16)
		fatTblExtensionContactNumber	= (0,41,41,41,41,41,41,41)
		fatTblExtensionMinCuts		= (1,2,3,4,6,8,12,16)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 0.098
}

Layer		"M5" {
		layerNumber			= 53
		maskName			= "metal5"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "55"
		lineStyle			= "solid"
		pattern				= "zigzag"
		pitch				= 0.14
		defaultWidth			= 0.07
		minWidth			= 0.07
		minSpacing			= 0.07
		maxWidth			= 2
		stubSpacing			= 0.08
		stubThreshold			= 0.08
		unitMinResistance		= 0.362
		unitNomResistance		= 0.362
		unitMaxResistance		= 0.48617
		fatTblDimension			= 6
		fatTblThreshold			= (0,0.085,0.125,0.355,0.505,1.005)
		fatTblParallelLength		= (0,0.305,0.305,0,0,0)
		fatTblSpacing			= (0.07,0.08,0.1,0.14,0.28,0.35,
						   0.08,0.08,0.1,0.14,0.28,0.35,
						   0.1,0.1,0.1,0.14,0.28,0.35,
						   0.14,0.14,0.14,0.14,0.28,0.35,
						   0.28,0.28,0.28,0.28,0.28,0.35,
						   0.35,0.35,0.35,0.35,0.35,0.35)
		fatTblMinEnclosedArea		= (0.2,0.2,0.4,0.4,0.4,1.6)
		minArea				= 0.0441
		minEnclosedArea			= 0.4
		maxNumMinEdge			= 1
		minEdgeLength			= 0.07
}

Layer		"ZG" {
		layerNumber			= 56
		maskName			= "via8"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "17"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 9
		defaultWidth			= 6
		minWidth			= 6
		minSpacing			= 3
}

Layer		"ZA" {
		layerNumber			= 57
		maskName			= "metal9"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "58"
		lineStyle			= "solid"
		pattern				= "backSlash"
		pitch				= 10
		defaultWidth			= 7
		minWidth			= 7
		minSpacing			= 3
		maxWidth			= 10
		unitMinResistance		= 0.022
		unitNomResistance		= 0.022
		unitMaxResistance		= 0.0352
}

Layer		"ZP" {
		layerNumber			= 58
		maskName			= "passivation"
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "orange"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"ZB" {
		layerNumber			= 59
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"PADDEV_ALL" {
		layerNumber			= 61
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "purple"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"V6" {
		layerNumber			= 64
		maskName			= "via5"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "purple"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 0.28
		defaultWidth			= 0.14
		minWidth			= 0.14
		minSpacing			= 0.14
		fatTblDimension			= 8
		fatTblThreshold			= (0,0.215,0.425,0.705,1.085,1.645,2.205,3.325)
		fatTblExtensionRange		= (0,15,15,15,15,15,15,15)
		fatTblThreshold2		= (0,0.215,0.425,0.705,1.085,1.645,2.205,3.325)
		fat2DTblFatContactNumber	= (6,6,6,69,69,69,69,69,
						   6,6,6,69,69,69,69,69,
						   6,6,6,69,69,69,69,69,
						   62,62,62,62,62,62,62,62,
						   62,62,62,62,62,62,62,62,
						   62,62,62,62,62,62,62,62,
						   62,62,62,62,62,62,62,62,
						   62,62,62,62,62,62,62,62)
		fat2DTblFatContactMinCuts	= (1,1,2,3,4,6,8,12,
						   2,2,2,3,4,6,8,12,
						   2,2,2,3,4,6,8,12,
						   3,3,3,3,4,6,8,12,
						   4,4,4,4,4,6,8,12,
						   6,6,6,6,6,6,8,12,
						   6,6,6,6,6,6,8,12,
						   6,6,6,6,6,6,8,12)
		fatTblExtensionContactNumber	= (0,6,6,62,62,62,62,62)
		fatTblExtensionMinCuts		= (1,2,2,3,4,6,8,12)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 0.19
}

Layer		"M7" {
		layerNumber			= 65
		maskName			= "metal6"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "57"
		lineStyle			= "solid"
		pattern				= "slash"
		pitch				= 0.28
		defaultWidth			= 0.14
		minWidth			= 0.14
		minSpacing			= 0.14
		maxWidth			= 10
		unitMinResistance		= 0.09
		unitNomResistance		= 0.09
		unitMaxResistance		= 0.18131
		fatTblDimension			= 7
		fatTblThreshold			= (0,0.205,0.285,1.505,3.005,4.505,7.505)
		fatTblParallelLength		= (0,0,0.505,0,0,0,0)
		fatTblSpacing			= (0.14,0.14,0.17,0.5,0.9,1.5,2.5,
						   0.14,0.14,0.17,0.5,0.9,1.5,2.5,
						   0.17,0.17,0.17,0.5,0.9,1.5,2.5,
						   0.5,0.5,0.5,0.5,0.9,1.5,2.5,
						   0.9,0.9,0.9,0.9,0.9,1.5,2.5,
						   1.5,1.5,1.5,1.5,1.5,1.5,2.5,
						   2.5,2.5,2.5,2.5,2.5,2.5,2.5)
		fatTblMinEnclosedArea		= (1,7.2,7.2,7.2,7.2,7.2,7.2)
		minArea				= 0.0784
		minEnclosedArea			= 7.2
		maxNumMinEdge			= 1
		minEdgeLength			= 0.14
}

Layer		"EXDUMOD" {
		layerNumber			= 90
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUMGA" {
		layerNumber			= 91
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUMM0" {
		layerNumber			= 92
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUM1" {
		layerNumber			= 93
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUM2" {
		layerNumber			= 94
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUM3" {
		layerNumber			= 95
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUM4" {
		layerNumber			= 96
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUM5" {
		layerNumber			= 97
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUM7" {
		layerNumber			= 99
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUMB" {
		layerNumber			= 103
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"EXDUMC" {
		layerNumber			= 104
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"PADDEV_DEF" {
		layerNumber			= 107
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "36"
		lineStyle			= "solid"
		pattern				= "rectangleX"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"CD" {
		layerNumber			= 115
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"VH" {
		layerNumber			= 116
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"VM" {
		layerNumber			= 117
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"VSL" {
		layerNumber			= 118
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"VA" {
		layerNumber			= 120
		maskName			= "via6"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "16"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 1.6
		defaultWidth			= 0.6
		minWidth			= 0.6
		minSpacing			= 1
		fatTblDimension			= 2
		fatTblThreshold			= (0,2.405)
		fatTblExtensionRange		= (0,5)
		fatTblFatContactNumber		= (7,7)
		fatTblFatContactMinCuts		= (1,2)
		fatTblExtensionContactNumber	= (0,7)
		fatTblExtensionMinCuts		= (1,2)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 1.12
}

Layer		"MB" {
		layerNumber			= 121
		maskName			= "metal7"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "cyan"
		lineStyle			= "solid"
		pattern				= "slash"
		pitch				= 1.6
		defaultWidth			= 0.8
		minWidth			= 0.8
		minSpacing			= 0.8
		maxWidth			= 10
		fatContactThreshold		= 2.41
		unitMinResistance		= 0.013
		unitNomResistance		= 0.013
		unitMaxResistance		= 0.02149
		fatTblDimension			= 3
		fatTblThreshold			= (0,4.505,7.505)
		fatTblSpacing			= (0.8,1.5,2.5,
						   1.5,1.5,2.5,
						   2.5,2.5,2.5)
		minArea				= 1.92
		minEnclosedArea			= 9
		maxNumMinEdge			= 1
		minEdgeLength			= 0.1
}

Layer		"VB" {
		layerNumber			= 122
		maskName			= "via7"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "62"
		lineStyle			= "solid"
		pattern				= "solid"
		pitch				= 1.6
		defaultWidth			= 0.6
		minWidth			= 0.6
		minSpacing			= 1
		fatTblDimension			= 2
		fatTblThreshold			= (0,2.405)
		fatTblExtensionRange		= (0,5)
		fatTblFatContactNumber		= (8,8)
		fatTblFatContactMinCuts		= (1,2)
		fatTblExtensionContactNumber	= (0,8)
		fatTblExtensionMinCuts		= (1,2)
		maxNumAdjacentCut		= 2
		adjacentCutRange		= 1.12
}

Layer		"MC" {
		layerNumber			= 123
		maskName			= "metal8"
		isDefaultLayer			= 1
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "32"
		lineStyle			= "solid"
		pattern				= "backSlash"
		pitch				= 1.6
		defaultWidth			= 0.8
		minWidth			= 0.8
		minSpacing			= 0.8
		maxWidth			= 10
		fatContactThreshold		= 2.41
		unitMinResistance		= 0.013
		unitNomResistance		= 0.013
		unitMaxResistance		= 0.02149
		fatTblDimension			= 3
		fatTblThreshold			= (0,4.505,7.505)
		fatTblSpacing			= (0.8,1.5,2.5,
						   1.5,1.5,2.5,
						   2.5,2.5,2.5)
		minArea				= 1.92
		minEnclosedArea			= 9
		maxNumMinEdge			= 1
		minEdgeLength			= 0.1
}

Layer		"GADUM" {
		layerNumber			= 127
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"WLBI_TEXT" {
		layerNumber			= 144
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"PT" {
		layerNumber			= 155
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"DD" {
		layerNumber			= 162
		maskName			= ""
		visible				= 0
		selectable			= 0
		blink				= 0
		color				= "white"
		lineStyle			= "solid"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

Layer		"FDATA" {
		layerNumber			= 167
		maskName			= ""
		visible				= 1
		selectable			= 1
		blink				= 0
		color				= "yellow"
		lineStyle			= "dot"
		pattern				= "dot"
		pitch				= 0
		defaultWidth			= 0
		minWidth			= 0
		minSpacing			= 0
}

ContactCode	"V10" {
		contactCodeNumber		= 1
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		isDefaultContact		= 1
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V20" {
		contactCodeNumber		= 2
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		isDefaultContact		= 1
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.08
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V30" {
		contactCodeNumber		= 3
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		isDefaultContact		= 1
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.08
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V40" {
		contactCodeNumber		= 4
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		isDefaultContact		= 1
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.08
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V60" {
		contactCodeNumber		= 6
		cutLayer			= "V6"
		lowerLayer			= "M5"
		upperLayer			= "M7"
		isDefaultContact		= 1
		cutWidth			= 0.14
		cutHeight			= 0.14
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.14
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 1.74
		unitNomResistance		= 1.74
		unitMaxResistance		= 3.84098
}

ContactCode	"VA0" {
		contactCodeNumber		= 7
		cutLayer			= "VA"
		lowerLayer			= "M7"
		upperLayer			= "MB"
		isDefaultContact		= 1
		cutWidth			= 0.6
		cutHeight			= 0.6
		upperLayerEncWidth		= 0.1
		upperLayerEncHeight		= 0.1
		lowerLayerEncWidth		= 0.1
		lowerLayerEncHeight		= 0.1
		minCutSpacing			= 1.12
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 0.17
		unitNomResistance		= 0.17
		unitMaxResistance		= 0.33575
}

ContactCode	"VB0" {
		contactCodeNumber		= 8
		cutLayer			= "VB"
		lowerLayer			= "MB"
		upperLayer			= "MC"
		isDefaultContact		= 1
		cutWidth			= 0.6
		cutHeight			= 0.6
		upperLayerEncWidth		= 0.1
		upperLayerEncHeight		= 0.1
		lowerLayerEncWidth		= 0.1
		lowerLayerEncHeight		= 0.1
		minCutSpacing			= 1.12
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 0.17
		unitNomResistance		= 0.17
		unitMaxResistance		= 0.33575
}

ContactCode	"ZG0" {
		contactCodeNumber		= 9
		cutLayer			= "ZG"
		lowerLayer			= "MC"
		upperLayer			= "ZA"
		isDefaultContact		= 1
		cutWidth			= 6
		cutHeight			= 6
		upperLayerEncWidth		= 2
		upperLayerEncHeight		= 2
		lowerLayerEncWidth		= 2
		lowerLayerEncHeight		= 2
		minCutSpacing			= 3
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 0.5
		unitNomResistance		= 0.5
		unitMaxResistance		= 0.6519
}

ContactCode	"CA" {
		contactCodeNumber		= 10
		cutLayer			= "CA"
		lowerLayer			= "GA"
		upperLayer			= "M1"
		isDefaultContact		= 1
		cutWidth			= 0.08
		cutHeight			= 0.08
		upperLayerEncWidth		= 0.005
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.03
		lowerLayerEncHeight		= 0.03
		minCutSpacing			= 0.12
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V1SP" {
		contactCodeNumber		= 11
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V1F1" {
		contactCodeNumber		= 12
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V13" {
		contactCodeNumber		= 13
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.08
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V1SPF" {
		contactCodeNumber		= 14
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V100" {
		contactCodeNumber		= 15
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V1SP3" {
		contactCodeNumber		= 17
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V1SH" {
		contactCodeNumber		= 19
		cutLayer			= "V1"
		lowerLayer			= "M1"
		upperLayer			= "M2"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0.04
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0.04
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V2FZ" {
		contactCodeNumber		= 20
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.1
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V2SP" {
		contactCodeNumber		= 21
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V2F1" {
		contactCodeNumber		= 22
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V23" {
		contactCodeNumber		= 23
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.08
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V2SPF" {
		contactCodeNumber		= 24
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V200" {
		contactCodeNumber		= 25
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.07
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V2SP3" {
		contactCodeNumber		= 27
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V2SH" {
		contactCodeNumber		= 29
		cutLayer			= "V2"
		lowerLayer			= "M2"
		upperLayer			= "M3"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0.04
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.04
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V3FZ" {
		contactCodeNumber		= 30
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.1
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V3SP" {
		contactCodeNumber		= 31
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V3F1" {
		contactCodeNumber		= 32
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V33" {
		contactCodeNumber		= 33
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.08
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V3SPF" {
		contactCodeNumber		= 34
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V300" {
		contactCodeNumber		= 35
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V3SP3" {
		contactCodeNumber		= 37
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V3SH" {
		contactCodeNumber		= 39
		cutLayer			= "V3"
		lowerLayer			= "M3"
		upperLayer			= "M4"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0.04
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0.04
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4FZ" {
		contactCodeNumber		= 40
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.1
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4SP" {
		contactCodeNumber		= 41
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4F1" {
		contactCodeNumber		= 42
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V43" {
		contactCodeNumber		= 43
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.08
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4SPF" {
		contactCodeNumber		= 44
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.055
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0.055
		minCutSpacing			= 0.095
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V400" {
		contactCodeNumber		= 45
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.07
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4SRAM" {
		contactCodeNumber		= 46
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0.07
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4SP3" {
		contactCodeNumber		= 47
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.07
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4MCR" {
		contactCodeNumber		= 48
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0
		upperLayerEncHeight		= 0.07
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V4SH" {
		contactCodeNumber		= 49
		cutLayer			= "V4"
		lowerLayer			= "M4"
		upperLayer			= "M5"
		cutWidth			= 0.07
		cutHeight			= 0.07
		upperLayerEncWidth		= 0.08
		upperLayerEncHeight		= 0.04
		lowerLayerEncWidth		= 0.08
		lowerLayerEncHeight		= 0.04
		minCutSpacing			= 0.07
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 2.33
		unitNomResistance		= 2.33
		unitMaxResistance		= 12.3153
}

ContactCode	"V6SP" {
		contactCodeNumber		= 61
		cutLayer			= "V6"
		lowerLayer			= "M5"
		upperLayer			= "M7"
		cutWidth			= 0.14
		cutHeight			= 0.14
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0.07
		lowerLayerEncHeight		= 0
		minCutSpacing			= 0.14
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 1.74
		unitNomResistance		= 1.74
		unitMaxResistance		= 3.84098
}

ContactCode	"V6F1" {
		contactCodeNumber		= 62
		cutLayer			= "V6"
		lowerLayer			= "M5"
		upperLayer			= "M7"
		cutWidth			= 0.14
		cutHeight			= 0.14
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0.05
		lowerLayerEncHeight		= 0.05
		minCutSpacing			= 0.19
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 1.74
		unitNomResistance		= 1.74
		unitMaxResistance		= 3.84098
}

ContactCode	"V63" {
		contactCodeNumber		= 63
		cutLayer			= "V6"
		lowerLayer			= "M5"
		upperLayer			= "M7"
		cutWidth			= 0.14
		cutHeight			= 0.14
		upperLayerEncWidth		= 0.07
		upperLayerEncHeight		= 0
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.19
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 1.74
		unitNomResistance		= 1.74
		unitMaxResistance		= 3.84098
}

ContactCode	"V6F2" {
		contactCodeNumber		= 68
		cutLayer			= "V6"
		lowerLayer			= "M5"
		upperLayer			= "M7"
		cutWidth			= 0.14
		cutHeight			= 0.14
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.14
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 1.74
		unitNomResistance		= 1.74
		unitMaxResistance		= 3.84098
}

ContactCode	"V6F3" {
		contactCodeNumber		= 69
		cutLayer			= "V6"
		lowerLayer			= "M5"
		upperLayer			= "M7"
		cutWidth			= 0.14
		cutHeight			= 0.14
		upperLayerEncWidth		= 0.05
		upperLayerEncHeight		= 0.05
		lowerLayerEncWidth		= 0
		lowerLayerEncHeight		= 0.07
		minCutSpacing			= 0.19
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 1.74
		unitNomResistance		= 1.74
		unitMaxResistance		= 3.84098
}

ContactCode	"VA3" {
		contactCodeNumber		= 73
		cutLayer			= "VA"
		lowerLayer			= "M7"
		upperLayer			= "MB"
		cutWidth			= 0.6
		cutHeight			= 0.6
		upperLayerEncWidth		= 0.1
		upperLayerEncHeight		= 0.1
		lowerLayerEncWidth		= 0.1
		lowerLayerEncHeight		= 0.1
		minCutSpacing			= 1.12
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 0.17
		unitNomResistance		= 0.17
		unitMaxResistance		= 0.33575
}

ContactCode	"VB3" {
		contactCodeNumber		= 83
		cutLayer			= "VB"
		lowerLayer			= "MB"
		upperLayer			= "MC"
		cutWidth			= 0.6
		cutHeight			= 0.6
		upperLayerEncWidth		= 0.1
		upperLayerEncHeight		= 0.1
		lowerLayerEncWidth		= 0.1
		lowerLayerEncHeight		= 0.1
		minCutSpacing			= 1.12
		maxNumRowsNonTurning		= 5
		unitMinResistance		= 0.17
		unitNomResistance		= 0.17
		unitMaxResistance		= 0.33575
}

DesignRule	{
		layer1				= "via1Blockage"
		layer2				= "V1"
		minSpacing			= 0.07
}

DesignRule	{
		layer1				= "via2Blockage"
		layer2				= "V2"
		minSpacing			= 0.07
}

DesignRule	{
		layer1				= "via3Blockage"
		layer2				= "V3"
		minSpacing			= 0.07
}

DesignRule	{
		layer1				= "via4Blockage"
		layer2				= "V4"
		minSpacing			= 0.07
}

DesignRule	{
		layer1				= "via5Blockage"
		layer2				= "V6"
		minSpacing			= 0.14
}

DesignRule	{
		layer1				= "via6Blockage"
		layer2				= "VA"
		minSpacing			= 1
}

DesignRule	{
		layer1				= "via7Blockage"
		layer2				= "VB"
		minSpacing			= 1
}

DesignRule	{
		layer1				= "M5"
		layer2				= "V6"
		diffNetMinSpacing		= 0.14
}

PRRule		{
		rowSpacingTopTop		= 0.2
		rowSpacingTopBot		= 1.14
		rowSpacingBotBot		= 0.2
		abuttableTopTop			= 1
		abuttableTopBot			= 0
		abuttableBotBot			= 1
}

ResModel	"metal1ResModel" {
		layerNumber			= 43
		size				= 6
		wireWidth			= (0.06, 0.09, 0.12, 0.18, 0.2, 0.7)
		tempCoeff			= (0, 0, 0, 0, 0, 0)
		minRes				= (0.285, 0.267, 0.255, 0.243, 0.239, 0.214)
		nomRes				= (0.285, 0.267, 0.255, 0.243, 0.239, 0.214)
		maxRes				= (0.382755, 0.358581, 0.342465, 0.326349, 0.320977, 0.287402)
}

ResModel	"metal2ResModel" {
		layerNumber			= 47
		size				= 5
		wireWidth			= (0.07, 0.1, 0.14, 0.2, 2)
		tempCoeff			= (0, 0, 0, 0, 0)
		minRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		nomRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		maxRes				= (0.486166, 0.445876, 0.419016, 0.400214, 0.33575)
}

ResModel	"metal3ResModel" {
		layerNumber			= 49
		size				= 5
		wireWidth			= (0.07, 0.1, 0.14, 0.2, 2)
		tempCoeff			= (0, 0, 0, 0, 0)
		minRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		nomRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		maxRes				= (0.486166, 0.445876, 0.419016, 0.400214, 0.33575)
}

ResModel	"metal4ResModel" {
		layerNumber			= 51
		size				= 5
		wireWidth			= (0.07, 0.1, 0.14, 0.2, 2)
		tempCoeff			= (0, 0, 0, 0, 0)
		minRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		nomRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		maxRes				= (0.486166, 0.445876, 0.419016, 0.400214, 0.33575)
}

ResModel	"metal5ResModel" {
		layerNumber			= 53
		size				= 5
		wireWidth			= (0.07, 0.1, 0.14, 0.2, 2)
		tempCoeff			= (0, 0, 0, 0, 0)
		minRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		nomRes				= (0.362, 0.332, 0.312, 0.298, 0.25)
		maxRes				= (0.486166, 0.445876, 0.419016, 0.400214, 0.33575)
}

ResModel	"metal6ResModel" {
		layerNumber			= 65
		size				= 4
		wireWidth			= (0.14, 0.2, 2, 10)
		tempCoeff			= (0, 0, 0, 0)
		minRes				= (0.09, 0.082, 0.079, 0.084)
		nomRes				= (0, 0, 0, 0)
		maxRes				= (0.181305, 0.155788, 0.142358, 0.154445)
}

ResModel	"metal7ResModel" {
		layerNumber			= 121
		size				= 3
		wireWidth			= (0.8, 2, 10)
		tempCoeff			= (0, 0, 0)
		minRes				= (0.013, 0.013, 0.013)
		nomRes				= (0.013, 0.013, 0.013)
		maxRes				= (0.021488, 0.020145, 0.020145)
}

ResModel	"metal8ResModel" {
		layerNumber			= 123
		size				= 3
		wireWidth			= (0.8, 2, 10)
		tempCoeff			= (0, 0, 0)
		minRes				= (0.013, 0.013, 0.013)
		nomRes				= (0.013, 0.013, 0.013)
		maxRes				= (0.021488, 0.020145, 0.020145)
}

ResModel	"metal9ResModel" {
		layerNumber			= 57
		size				= 1
		wireWidth			= (10)
		tempCoeff			= (0)
		minRes				= (0.022)
		nomRes				= (0.022)
		maxRes				= (0.0352026)
}
