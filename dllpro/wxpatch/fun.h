#pragma once
#include <stdint.h>


#define PATCH_OFFSET40517 0x8B67C5 // For Weixin 4.0.5.17 (for 64-bit)
#define PATCH_OFFSET40518 0x8B6F35 // For Weixin 4.0.5.18 (for 64-bit)
#define PATCH_OFFSET40523 0x8B6F25 // For Weixin 4.0.5.23 (for 64-bit)



void PatchRevokeMsg(ULONG_PTR PATCH_OFFSET);