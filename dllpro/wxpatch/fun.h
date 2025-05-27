#pragma once
#include <stdint.h>


#define PATCH_OFFSET 0x8B67C5 // For Weixin 4.0.5.17 (for 64-bit)

void PatchRevokeMsg();