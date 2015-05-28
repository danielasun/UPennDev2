module(..., package.seeall)
local vector = require'vector'

cal={}
cal[HOSTNAME] = {}
cal["asus"] = {}
cal["alvin"]={}
cal["teddy"]={}
cal["chipette"]={}
cal["teddy2"]={}

cal["chip"]={}
cal["dale"]={}

cal["alvin"].legBias=vector.new({
   0,0,0,0,0,0, 0,0,0,0,0,0})

cal["asus"].legBias=vector.new({
   0,0,0,0,0,0, 0,0,0,0,0,0})

-- Updated date: Tue Sep 23 00:00:50 2014
cal["teddy"].legBias=vector.new({
   1.000000,0.720000,0.020000,-0.365000,0.320000,0.720000,
   0.470000,-0.690000,1.190000,-0.880000,-0.660000,-0.375000,
   })*math.pi/180

-- Updated date: Thu Apr  9 13:20:13 2015
cal["alvin"].legBias=vector.new({
   2.092500,2.290000,-0.337500,-2.360000,-0.540000,-0.477500,
   1.140000,-2.227500,-0.335000,-0.607500,-0.350000,0.675000,
   })*math.pi/180


-- Updated date: Thu Apr  9 13:20:52 2015
cal["alvin"].legBias=vector.new({
   2.092500,2.290000,-0.337500,-2.360000,-0.540000,-0.477500,
   1.140000,-2.227500,-0.335000,-0.607500,-0.350000,0.675000,
   })*math.pi/180



-- Updated date: Sun May 17 19:28:15 2015
cal["chip"].legBias=vector.new({
   0,0,0,0,0,0,
   0,0,0,0,0,0,
   })*math.pi/180


-- Updated date: Mon May 18 16:18:03 2015
cal["dale"].legBias=vector.new({
   -1.417500,0.000000,0.000000,0.000000,-2.295000,0.472500,
   0.000000,0.000000,0.000000,0.000000,-1.485000,-0.945000,
   })*math.pi/180

-- Updated date: Thu May 28 01:00:49 2015
cal["chip"].legBias=vector.new({
   0.000000,0.000000,-2.025000,0.000000,1.080000,0.000000,
   0.000000,-0.202500,-0.000000,0.000000,0.810000,0.000000,
   })*math.pi/180

cal["chip"].legBias=vector.new({
0.00, 0.67, -2.02, 0.00, 1.28, -0.07,
0.00, -0.20, -0.00, 0.00, 0.81, -0.27 
   })*math.pi/180



-- Updated date: Thu May 28 02:04:56 2015
cal["chip"].legBias=vector.new({
   0.000000,0.670000,-2.020000,0.000000,1.280000,-0.070000,
   0.000000,-0.200000,-0.000000,0.000000,0.810000,-0.270000,
   })*math.pi/180


-- Updated date: Thu May 28 02:07:29 2015
cal["chip"].legBias=vector.new({
   0.000000,0.670000,-2.020000,0.000000,0.470000,-0.070000,
   0.000000,-0.200000,-0.000000,0.000000,0.000000,-0.270000,
   })*math.pi/180
