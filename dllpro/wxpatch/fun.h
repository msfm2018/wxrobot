#pragma once
#include <stdint.h>


#define PATCH_OFFSET40517 0x8B67C5 // For Weixin 4.0.5.17 (for 64-bit)
#define PATCH_OFFSET40518 0x8B6F35 // For Weixin 4.0.5.18 (for 64-bit)
#define PATCH_OFFSET40523 0x8B6F25 // For Weixin 4.0.5.23 (for 64-bit)
#define PATCH_OFFSET40526 0x8B7825 // For Weixin 4.0.5.26 (for 64-bit)

#define PATCH_OFFSET405270 0x8B86BF // For Weixin 4.0.5.27 (for 64-bit) qiye
#define PATCH_OFFSET40527 0x8B8635 // For Weixin 4.0.5.27 (for 64-bit)



#define PATCH_OFFSET40613 0x8F09E5 // For Weixin 4.0.6.13 (for 64-bit)
#define PATCH_OFFSET406130 0x8F0A6F // For Weixin 4.0.6.13 (for 64-bit) QIYE

#define PATCH_OFFSET40617 0x8F3BB5 // For Weixin 4.0.6.13 (for 64-bit)
#define PATCH_OFFSET406170 0x8F3C3F // For Weixin 4.0.6.13 (for 64-bit) QIYE
   
#define PATCH_OFFSET40621 0x8F4675 // For Weixin 4.0.6.13 (for 64-bit)
#define PATCH_OFFSET406210 0x8F46FF // For Weixin 4.0.6.13 (for 64-bit) QIYE

void PatchRevokeMsg(ULONG_PTR PATCH_OFFSET);