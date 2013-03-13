#ifndef DYNAMIXEL_SETTINGS_H 
#define DYNAMIXEL_SETTINGS_H

#include "config.h"

//motor types
enum DXL_TYPE {
  MX_DXL,
  NX_DXL
};

//mapping of dynamixel motor ids to DCM values
const int dynamixel_id[N_JOINT] = {
  4, 6, 8, 10, 12, 14,
  3, 5, 7, 9, 11, 13,
  16, 18, 20,
  15, 17, 19
};

//types corresponding to each DCM mapping
const DXL_TYPE dynamixel_series[N_JOINT] = {
  NX_DXL, NX_DXL, NX_DXL, NX_DXL, NX_DXL, NX_DXL,
  NX_DXL, NX_DXL, NX_DXL, NX_DXL, NX_DXL, NX_DXL,
  MX_DXL, MX_DXL, MX_DXL, 
  MX_DXL, MX_DXL, MX_DXL
};

#endif
