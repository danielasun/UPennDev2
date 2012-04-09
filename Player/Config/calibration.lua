module(..., package.seeall);

---------------------------------------------
-- Automatically generated calibration data
---------------------------------------------
cal={}

--Initial values for each robots

cal["betty"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
};

cal["linus"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
};

cal["lucy"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
};
cal["scarface"]={
  servoBias={0,0,0,0,0,0, 0,0,0,0,0,0},
  footXComp = 0,
  footYComp = 0,
  kickXComp = 0,
  headPitchComp = 0,
};

-----------------------------------------------------------
-- PID firmware setting for lucy
cal["lucy"].pid = 1;
-----------------------------------------------------------

cal["betty"].servoBias={0,0,2,-6,-1,0,0,0,-3,-1,10,0};
cal["betty"].footXComp = 0.010;
cal["betty"].footYComp = 0.002;
cal["betty"].kickXComp = 0.005;
cal["betty"].headPitchComp = 0.005;

cal["linus"].servoBias={3,1,2,1,1,-3,-8,3,-13,-4,1,-5};
cal["linus"].footXComp = 0.00;
cal["linus"].footYComp = 0.002;
cal["linus"].kickXComp = -0.005;
cal["linus"].headPitchComp = 0.005;

cal["lucy"].servoBias={1,-28,-207,108,-26,-15,-43,-51,110,35,84,-29};
cal["lucy"].footXComp = 0.002;
cal["lucy"].footYComp = 0.002;
cal["lucy"].kickXComp = -0.005;
cal["lucy"].headPitchComp = 0.00;

cal["scarface"].servoBias={0,0,0,0,0,0,0,0,0,-9,-4,0};
cal["scarface"].footXComp = -0.005;
cal["scarface"].footYComp = 0.00;
cal["scarface"].kickXComp = -0.005;
cal["scarface"].headPitchComp = 0.00;

------------------------------------------------------------

--Auto-appended calibration settings
